local oop = require("oop")
local component = require("component")
local event = require("event")
local filesystem = require("filesystem")

local DraconicControlApi = {
	version = 1.41,
	controllers = {},
	timerId = nil
}

local DraconicController = {
	-- Default configuration
	drainback = 1.25,  -- Keep the containment field at ~20%
	targetSaturation = 0.5, -- The target saturation for the reactor is 50%.
	throttleSaturation = 0.90, -- Bias the target saturation towards 90% if the throttle temperature has been reached.
	throttleTemperature = 8000, -- Start throtteling when exceepding 8000°C
	throttleExponent = 2.5, -- Exponent to control the throttle curve
	limitTemperature = 9000, -- Start choking the reactor when exceeding 9000°C, reactor will be shut down at 9900°C (9000°C + 10%)
	limitExponent = 6, -- Exponent to control the limit curve
	burnConversion = 0, -- Don't burn any fuel
	burnRFt = 0, -- Don't burn any fuel

	-- Component configuration
	fluxGateDrainbackAddress = nil,
	fluxGateDrainback = nil,

	fluxGateOutputAddress = nil,
	fluxGateOutput = nil,

	reactorAddress = nil,
	reactor = nil,

	-- Constants
	STATE_OFFLINE = "cold",
	STATE_CHARGING = "warming_up",
	STATE_ONLINE = "running",
	STATE_SHUTDOWN = "stopping",
	STATE_COOLDOWN = "cooling",
	FUEL_MAX = 10368,

	-- State
	tickControlDistance = 20,
	tickControlLast = 0,
	temperatureLast = 20,
	outputLast = 0,
	throttleLast = 0,
	reactorInfoLast = nil
}
oop.make(DraconicController)

function DraconicController:construct(reactorAddress, fluxGateDrainbackAddress, fluxGateOutputAddress)
	self.reactorAddress = reactorAddress
	self.fluxGateDrainbackAddress = fluxGateDrainbackAddress
	self.fluxGateOutputAddress = fluxGateOutputAddress

	self.reactor = component.proxy(self.reactorAddress)
	self.fluxGateDrainback = component.proxy(self.fluxGateDrainbackAddress)
	self.fluxGateOutput = component.proxy(self.fluxGateOutputAddress)

	self.tickControlDistance = 0
	self.temperatureLast = 20

	if self.reactor ~= nil and self.reactor.getReactorInfo == nil then
		self.reactor = nil
	else
		local reactorInfo = self.reactor.getReactorInfo()
		if reactorInfo == nil then
			self.reactor = nil
		else
			self.temperatureLast = reactorInfo.temperature
		end
	end
end

function DraconicController:isConnected()
	return self.reactor ~= nil and self.fluxGateDrainback ~= nil and self.fluxGateOutput ~= nil
end

function DraconicController:isOffline()
	if not self:isConnected() then
		return true
	end

	local reactorInfo = self.reactor.getReactorInfo()
	return reactorInfo.status == DraconicController.STATE_COOLDOWN or reactorInfo.status == DraconicController.STATE_OFFLINE
end

function DraconicController:toggleState()
	if not self:isConnected() then
		return
	end

	local reactorInfo = self.reactor.getReactorInfo()
	if reactorInfo.status == DraconicController.STATE_ONLINE then
		self.reactor.stopReactor()
	elseif reactorInfo.status == DraconicController.STATE_SHUTDOWN then
		self.reactor.activateReactor()
	end
end

function DraconicController.calculateTempDrainFactor(temperature)
	if temperature > 8000 then
		return 1 + (temperature - 8000) * (temperature - 8000) * 2.5e-6
	elseif temperature > 2000 then
		return 1
	elseif temperature > 1000 then
		return (temperature - 1000) / 1000
	else
		return 0
	end
end

function DraconicController.calculateReactorMaxRFT(reactorInfo)
	local energySaturationLastTick = reactorInfo.energySaturation - reactorInfo.generationRate
	local saturation = energySaturationLastTick / reactorInfo.maxEnergySaturation
	return math.floor(reactorInfo.generationRate / (1 - saturation) + 0.5)
end

function DraconicController.calculateReactorFuelUsageMultiplier(reactorInfo)
	local tempDrainFactor = DraconicController.calculateTempDrainFactor(reactorInfo.temperature)
	local saturation = reactorInfo.energySaturation / reactorInfo.maxEnergySaturation

	return reactorInfo.fuelConversionRate / 1000 / (tempDrainFactor * (1 - saturation))
end

function DraconicController:decideShutdown(reactorInfo)
	if reactorInfo.generationRate == 0 then
		return false
	end

	local avgSaturationFillRate = (reactorInfo.generationRate - reactorInfo.fieldDrainRate * self.drainback * 2) / 2
	if avgSaturationFillRate <= 0 then
		return false
	end

	local estTicksTillFull = math.floor((reactorInfo.maxEnergySaturation - reactorInfo.energySaturation) / avgSaturationFillRate + 0.5)
	if estTicksTillFull > 5000 then
		return false
	end

	local saturation = reactorInfo.energySaturation / reactorInfo.maxEnergySaturation
	local tempRiseRate = math.max(0, reactorInfo.temperature - self.temperatureLast) / self.tickControlDistance
	local tempDrainFactor = self.calculateTempDrainFactor(reactorInfo.temperature)
	local estTempAtEnd = reactorInfo.temperature + math.pow(tempRiseRate, 0.25) * estTicksTillFull
	local estTempDrainFactorAtEnd = self.calculateTempDrainFactor(estTempAtEnd)
	local estFuelUsageAtEnd = reactorInfo.fuelConversionRate / (tempDrainFactor * (1 - saturation)) * estTempDrainFactorAtEnd * 0.1
	local fuelUsageTillFull = estTicksTillFull * (reactorInfo.fuelConversionRate + estFuelUsageAtEnd) / 2e6

	return reactorInfo.maxFuelConversion - reactorInfo.fuelConversion <= 1.5 + fuelUsageTillFull
end

function DraconicController:shutdown()
	if self.reactor ~= nil then
		local reactorInfo = self.reactor.getReactorInfo()
		if reactorInfo ~= nil and reactorInfo.status == DraconicController.STATE_ONLINE then
			self.reactor.stopReactor()
		end
	end
end

function DraconicController:runOnce()
	if not self:isConnected() then
		return false
	end

	local reactorInfo = self.reactor.getReactorInfo()
	if reactorInfo == nil then
		return false
	end

	-- Move these values to the initialization at some point
	local output_base = math.floor(reactorInfo.maxEnergySaturation / 2222)
	local output_max = math.floor(reactorInfo.maxEnergySaturation / 100)
	local saturation = reactorInfo.energySaturation / reactorInfo.maxEnergySaturation
	local conversion = reactorInfo.fuelConversion / reactorInfo.maxFuelConversion
	local output = 0
	local inject = 0

	if reactorInfo.status == DraconicController.STATE_ONLINE then
		if self:decideShutdown(reactorInfo) then
			self.reactor.stopReactor()
		else
			local temp_delta = reactorInfo.temperature - self.temperatureLast
			local panic_temp = math.max(20, self.limitTemperature - math.max(0, temp_delta))
			local maxRFt = self.calculateReactorMaxRFT(reactorInfo)

			local throttle_weight = math.min(1, math.max(0, (reactorInfo.temperature - self.throttleTemperature) / (panic_temp - self.throttleTemperature)))
			local panic_mult = math.max(0, math.min(1, 1 - (reactorInfo.temperature - panic_temp) / (panic_temp * 0.1)))

			if maxRFt * (1 - self.targetSaturation) < self.burnRFt or conversion < self.burnConversion then
				throttle_weight = 0
			end

			throttle_weight	= math.pow(throttle_weight, self.throttleExponent)
			panic_mult		= math.pow(panic_mult, self.limitExponent)

			local target_saturation = self.targetSaturation * (1 - throttle_weight) + self.throttleSaturation * throttle_weight
			output = math.floor(maxRFt * (1 - target_saturation) * panic_mult)
			if panic_mult == 0 then
				self.reactor.stopReactor()
			end
			self.throttleLast = throttle_weight
		end
	end

-- Doesn't seem to work yet.
--
--	if not reactorInfo.failsafe then
--		self.reactor.setFailSafe(true)
--	end

	if reactorInfo.status == DraconicController.STATE_CHARGING then
		inject = 1000000
	else
		inject = reactorInfo.fieldDrainRate * self.drainback
	end

	self.fluxGateDrainback.setOverrideEnabled(true)
	self.fluxGateDrainback.setFlowOverride(inject)
	self.fluxGateOutput.setOverrideEnabled(true)
	self.fluxGateOutput.setFlowOverride(output)

	local tick = os.time() * 1000/60/60
	if self.tickControlLast > 0 then
		self.tickControlDistance = self.tickControlDistance * 0.9 + (tick - self.tickControlLast) * 0.1
	end
	self.tickControlLast = tick
	self.temperatureLast = reactorInfo.temperature
	self.outputLast = output
	self.reactorInfoLast = reactorInfo

	return true
end

function DraconicController:failsafe(reactorInfo)
	if self:isConnected() then
		return
	end

	if self.fluxGateOutput ~= nil then
		self.fluxGateOutput.setOverrideEnabled(true)
		self.fluxGateOutput.setFlowOverride(0)
	end

	if self.reactor ~= nil then
		reactorInfo = self.reactor.getReactorInfo()
	end

	if reactorInfo ~= nil and self.fluxGateDrainback ~= nil then
		self.fluxGateDrainback.setOverrideEnabled(true)
		self.fluxGateDrainback.setFlowOverride(reactorInfo.fieldDrainRate * self.drainback)
	end

	if self.reactor ~= nil then
		local saturation = reactorInfo.energySaturation / reactorInfo.maxEnergySaturation
		if saturation > 0.99 then
			self.reactor.stopReactor()
		end
	end
end

function DraconicControlApi.isRunning()
	return DraconicControlApi.timerId ~= nil
end

function DraconicControlApi.start()
	if DraconicControlApi.timerId == nil then
		DraconicControlApi.timerId = event.timer(1, DraconicControlApi.timer, math.huge)
		event.listen("component_added", DraconicControlApi.asyncComponentAddedHandler)
		event.listen("component_removed", DraconicControlApi.asyncComponentRemovedHandler)
	end
end

function DraconicControlApi.stop()
	if DraconicControlApi.timerId ~= nil then
		event.cancel(DraconicControlApi.timerId)
		event.ignore("component_added", DraconicControlApi.asyncComponentAddedHandler)
		event.ignore("component_removed", DraconicControlApi.asyncComponentRemovedHandler)
		DraconicControlApi.timerId = nil
	end
end

function DraconicControlApi.shutdown()
	local shutdownInProgress = false
	for _, controller in pairs(DraconicControlApi.controllers) do
		controller:shutdown()
		shutdownInProgress = shutdownInProgress or controller:isOffline()
	end

	DraconicControlApi.start()
	while shutdownInProgress do
		os.sleep(1)
		for _, controller in pairs(DraconicControlApi.controllers) do
			shutdownInProgress = shutdownInProgress or controller:isOffline()
		end
	end
	DraconicControlApi.stop()
end

function DraconicControlApi.timer()
	for _, controller in pairs(DraconicControlApi.controllers) do
		if not controller:runOnce() then
			controller:failsafe(controller.reactorInfoLast)
		end
	end
end

function DraconicControlApi.loadConfig()
	DraconicControlApi.controllers = {}
	local env = {}
	local config = loadfile("/etc/draconic_control.cfg", nil, env)
	if config then
		pcall(config)
		if env.reactors then
			for _, reactor in pairs(env.reactors) do
				local controller = DraconicControlApi.add(reactor.reactorAddress, reactor.fluxGateDrainbackAddress, reactor.fluxGateOutputAddress)
				if reactor.drainback ~= nil then
					controller.drainback = reactor.drainback
				end
				if reactor.targetSaturation ~= nil then
					controller.targetSaturation = reactor.targetSaturation
				end
				if reactor.throttleSaturation ~= nil then
					controller.throttleSaturation = reactor.throttleSaturation
				end
				if reactor.throttleTemperature ~= nil then
					controller.throttleTemperature = reactor.throttleTemperature
				end
				if reactor.limitTemperature ~= nil then
					controller.limitTemperature = reactor.limitTemperature
				end
				if reactor.throttleExponent ~= nil then
					controller.throttleExponent = reactor.throttleExponent
				end
				if reactor.limitExponent ~= nil then
					controller.limitExponent = reactor.limitExponent
				end
				if reactor.burnConversion ~= nil then
					controller.burnConversion = reactor.burnConversion
				end
				if reactor.burnRFt ~= nil then
					controller.burnRFt = reactor.burnRFt
				end
			end
		end
		return true
	else
		return false
	end
end

function DraconicControlApi.add(reactorAddress, fluxGateDrainbackAddress, fluxGateOutputAddress)
	local instance = DraconicController(reactorAddress, fluxGateDrainbackAddress, fluxGateOutputAddress)
	table.insert(DraconicControlApi.controllers, instance)
	return instance
end

function DraconicControlApi.getVersion()
	return DraconicControlApi.version
end

-- Async handlers

function DraconicControlApi.asyncComponentAddedHandler(eventID, address, typeID)
	if typeID == "flux_gate" or typeID == "draconic_reactor" then
		for _, controller in pairs(DraconicControlApi.controllers) do
			if controller.fluxGateDrainbackAddress == address then
				controller.fluxGateDrainback = component.proxy(address)
			elseif controller.fluxGateOutputAddress == address then
				controller.fluxGateOutput = component.proxy(address)
			elseif controller.reactorAddress == address then
				controller.reactor = component.proxy(address)
			end
		end
	end
end

function DraconicControlApi.asyncComponentRemovedHandler(eventID, address, typeID)
	if typeID == "flux_gate" or typeID == "draconic_reactor" then
		for _, controller in pairs(DraconicControlApi.controllers) do
			if controller.fluxGateDrainbackAddress == address then
				controller.fluxGateDrainback = nil
			elseif controller.fluxGateOutputAddress == address then
				controller.fluxGateOutput = nil
			elseif controller.reactorAddress == address then
				controller.reactor = nil
			end
		end
	end
end

return DraconicControlApi