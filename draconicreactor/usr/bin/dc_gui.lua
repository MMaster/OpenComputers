local libGUI = require("libGUI")
local frame_base = require("libGUI/frame")
local window_base = require("libGUI/window")
local bar_base = require("libGUI/bar")
local colors = require("libGUI/colors")
local draconic_control = require("draconic_control")

local oop = require("oop")
local component = require("component")

local DraconicControllerSummaryFrame = {
	mController = nil,
	mReactorInfo = nil
}
oop.inherit(DraconicControllerSummaryFrame, frame_base)

function DraconicControllerSummaryFrame:construct(controller)
	frame_base.construct(self)
	self.mController = controller
	self.mReactorInfo = {
		status = "unknown",
		temperature = 0,
		fieldStrength = 0,
		fieldDrainRate = 0,
		generationRate = 0,
		fuelConversionRate = 0,
		energySaturation = 0,
		maxFuelConversion = 0,
		fuelConversion = 0,
		maxFieldStrength = 0,
		maxEnergySaturation = 0
	}
end

function DraconicControllerSummaryFrame:update(reactorInfo)
	self.mReactorInfo = reactorInfo
end

function DraconicControllerSummaryFrame:onDraw()
	frame_base.onDraw(self)
	self:setBackground(colors.black)
	self:setForeground(colors.white)

	self:fill(1, 1, self.mWidth, self.mHeight, ' ')
	local statusText = self.mReactorInfo.status

	local captions = {
		{"Reactor Status:", string.upper(statusText), 3},
		{"Temperature Load Factor:", string.format("%6.2f%%", math.max(1, self.mController.calculateTempDrainFactor(self.mReactorInfo.temperature)) * 100), 21},
		{"Core Mass:", string.format("%3.1f m^3", self.mReactorInfo.maxFuelConversion / 1296), 18},
		{"Generation Rate:", string.format("%d RF/t", self.mReactorInfo.generationRate), 12},
		{"Field Input Rate:", string.format("%d RF/t", self.mReactorInfo.fieldDrainRate), 15},
		{"Output Rate:", string.format("%d RF/t", self.mController.outputLast), 6},
		{"Fuel Conversion Rate:", string.format("%d nB/t", self.mReactorInfo.fuelConversionRate), 9}
	}

	local offset_Y = 1
	for _, v in pairs(captions) do
		if self.mHeight >= v[3] then
			self:set(1, offset_Y, v[1])
			self:set(self.mWidth - string.len(v[2]), offset_Y + 1, v[2])
			offset_Y = offset_Y + 3
		end
	end
end

local DraconicControllerHealthFrame = {
	mController = nil,
	mReactorInfo = nil,
	mFieldPercentage = 0,
	mFieldPercentageLast = 0,
	mSaturation = 0,
	mMaxRFt = 0,
	mDrawTicks = 0,
}
oop.inherit(DraconicControllerHealthFrame, frame_base)
function DraconicControllerHealthFrame:construct(controller)
	frame_base.construct(self)
	self.mController = controller
	self.mShutdownHits = 0
	self.mReactorInfo = {
		status = "unknown",
		temperature = 0,
		fieldStrength = 0,
		fieldDrainRate = 0,
		generationRate = 0,
		fuelConversionRate = 0,
		energySaturation = 0,
		maxFuelConversion = 0,
		fuelConversion = 0,
		maxFieldStrength = 0,
		maxEnergySaturation = 0
	}
end

function DraconicControllerHealthFrame:update(reactorInfo)
	self.mReactorInfo = reactorInfo
	self.mFieldPercentageLast = self.mFieldPercentage
	self.mFieldPercentage = reactorInfo.fieldStrength / reactorInfo.maxFieldStrength
	self.mSaturation = reactorInfo.energySaturation / reactorInfo.maxEnergySaturation
	self.mMaxRFt = self.mController.calculateReactorMaxRFT(reactorInfo)
	self.mShutdownHits = 0
end

function DraconicControllerHealthFrame:onDraw()
	frame_base.onDraw(self)
	local warning = false
	local danger = false
	local throttled = false

	if self.mReactorInfo.temperature > self.mController.limitTemperature then
		danger = true
	elseif self.mReactorInfo.temperature > (self.mController.limitTemperature-self.mController.throttleTemperature) / 2 + self.mController.throttleTemperature then
		warning = true
	elseif self.mReactorInfo.temperature > self.mController.throttleTemperature then
		throttled = true
	end

	local burnmode = throttled and self.mController:isConnected() and self.mController.throttleLast > 0

	if self.mFieldPercentage < 0.05 then
		danger = true
	elseif self.mFieldPercentage < 0.09 and (not burnmode or self.mFieldPercentageLast < self.mFieldPercentage) then
		warning = true
	end

	if self.mSaturation < 0.09 then
		danger = true
	elseif self.mSaturation < math.min(0.15, self.mController.targetSaturation) then
		warning = true
	end

	if self.mMaxRFt * 0.33 < self.mReactorInfo.fieldDrainRate then
		danger = true
	elseif self.mMaxRFt * 0.25 < self.mReactorInfo.fieldDrainRate then
		warning = true
	end

	local displayString
	if not self.mController:isConnected() then
		if self.mDrawTicks % 2 == 0 then
			self:setBackground(colors.red)
			self:setForeground(colors.white)
		else
			self:setBackground(colors.black)
			self:setForeground(colors.red)
		end
		displayString = "Connection Failure"
	elseif danger then
		if self.mDrawTicks % 2 == 0 then
			self:setBackground(colors.red)
			self:setForeground(colors.white)
		else
			self:setBackground(colors.black)
			self:setForeground(colors.red)
		end
		displayString = "danger"
	elseif warning then
		if self.mDrawTicks % 2 == 0 then
			self:setBackground(colors.yellow)
			self:setForeground(colors.black)
		else
			self:setBackground(colors.black)
			self:setForeground(colors.yellow)
		end
		displayString = "warning"
	elseif throttled then
		self:setBackground(colors.gray)
		self:setForeground(colors.orange)
		if self.mController.throttleLast > 0 then
			displayString = "throttled"
		else
			displayString = "burn mode"
		end
	else
		self:setBackground(colors.green)
		self:setForeground(colors.black)
		displayString = "healthy"
	end

	self:fill(1, 1, self.mWidth, self.mHeight, ' ')
	self:set(1+math.ceil((self.mWidth-string.len(displayString))/2), math.ceil(self.mHeight/2), string.upper(displayString))
	self.mDrawTicks = self.mDrawTicks + 1
end

function DraconicControllerHealthFrame:onTouch(x, y, button, playerName)
	if self.mController.reactorInfoLast ~= nil and (self.mController.reactorInfoLast.status == self.mController.STATE_ONLINE or self.mController.reactorInfoLast.status == self.mController.STATE_SHUTDOWN) then
		self.mShutdownHits = self.mShutdownHits + 1
		if self.mShutdownHits == 5 then
			self.mController:toggleState()
			component.computer.beep(1000, 0.05)
		end
	end
end

local DraconicControllerGUI = {
	mController = nil,
	mBarTemperature = nil,
	mBarContainment = nil,
	mBarSaturation = nil,
	mBarFuel = nil,
	mSummaryFrame = nil,
	mHealthFrame = nil
}
oop.inherit(DraconicControllerGUI, frame_base)

function DraconicControllerGUI:construct(controller)
	frame_base.construct(self)
	self.mController = controller

	self.mBarTemperature = bar_base()
	self.mBarTemperature:setBarPalette({
		{2000 / controller.limitTemperature, colors.cyan},
		{(controller.throttleTemperature / 2 - 1000) / controller.limitTemperature, colors.lightBlue},
		{controller.throttleTemperature / controller.limitTemperature, colors.green},
		{((controller.limitTemperature-controller.throttleTemperature) / 2 + controller.throttleTemperature) / controller.limitTemperature, colors.orange},
		{1, colors.red}
	})
	self:addChild(self.mBarTemperature)

	self.mBarContainment = bar_base()
	self.mBarContainment:setBarPalette({
		{0.1, colors.red},
		{0.25, colors.purple},
		{0.66, colors.blue},
		{1, colors.lightBlue}
	})
	self:addChild(self.mBarContainment)

	self.mBarSaturation = bar_base()
	self.mBarSaturation:setBarPalette({
		{0.15, colors.red},
		{0.85, colors.green},
		{1, colors.lightBlue}
	})
	self:addChild(self.mBarSaturation)

	self.mBarFuel = bar_base()
	self.mBarFuel:setBarPalette({
		{0.04, colors.yellow},
		{0.41, colors.green},
		{0.9, colors.orange},
		{1, colors.red}
	})
	self:addChild(self.mBarFuel)

	self.mSummaryFrame = DraconicControllerSummaryFrame(controller)
	self:addChild(self.mSummaryFrame)

	self.mHealthFrame = DraconicControllerHealthFrame(controller)
	self:addChild(self.mHealthFrame)
end

function DraconicControllerGUI:update(reactorInfo)
	self.mBarTemperature:setPercentage(reactorInfo.temperature / self.mController.limitTemperature, false)
	self.mBarContainment:setPercentage(reactorInfo.fieldStrength / reactorInfo.maxFieldStrength, false)
	self.mBarSaturation:setPercentage(reactorInfo.energySaturation / reactorInfo.maxEnergySaturation, false)
	self.mBarFuel:setPercentage(reactorInfo.fuelConversion / reactorInfo.maxFuelConversion, false)
	self.mSummaryFrame:update(reactorInfo)
	self.mHealthFrame:update(reactorInfo)
end

function DraconicControllerGUI:setParent(parent)
	frame_base.setParent(self, parent)
	local width, height = parent:getSize()
	self:setSize(width, height)
end

function DraconicControllerGUI:getRootFrame()
	return self.mWindow
end

function DraconicControllerGUI:onResize()
	self.mBarTemperature:setRegion(1, 1, 4, self.mHeight)
	self.mBarContainment:setRegion(6, 1, 4, self.mHeight)
	self.mBarSaturation:setRegion(self.mWidth - 8, 1, 4, self.mHeight)
	self.mBarFuel:setRegion(self.mWidth - 3, 1, 4, self.mHeight)
	self.mSummaryFrame:setRegion(11, 1, self.mWidth - 19, self.mHeight - 3)
	self.mHealthFrame:setRegion(11, self.mHeight - 2, self.mWidth - 20, 3)
end

local reactorInfoFake = {
	status = "unknown",
	temperature = 20,
	fieldStrength = 0,
	fieldDrainRate = 0,
	generationRate = 0,
	fuelConversionRate = 0,
	energySaturation = 0,
	maxFuelConversion = 0,
	fuelConversion = 0,
	maxFieldStrength = 0,
	maxEnergySaturation = 0
}

function DraconicControllerGUI:onDraw()
	self:update(self.mController.reactorInfoLast or reactorInfoFake)
	frame_base.onDraw(self)
end

if not draconic_control.isRunning() then
	draconic_control.loadConfig()
	draconic_control.start()
end

if #draconic_control.controllers < 1 then
	print("Draconic Control has not been configured yet.")
	print("Please make sure everything is set up correctly and start this program again.")
	draconic_control.stop()
	return 1
end

local controller = draconic_control.controllers[1]

libGUI.init()
libGUI.setOptimalResolution(0.65)

local window = window_base()
local dcGUI = DraconicControllerGUI(controller)
local terminateGUI = false

function window:onTouch(x, y, button, playerName)
	window_base.onTouch(self, x, y, button, playerName)
	if y == 1 then
		libGUI.exit()
	end
end

function window:onResize()
	window_base.onResize(self)

	local width, height = self.mClientFrame:getSize()
	dcGUI:setRegion(1, 1, width, height)

	if self:getGPU() then
		local oldColor, oldPalette = self:getBackground()
		self:setBackground(colors.black)
		self:fill(1, 1, self.mWidth, self.mHeight, ' ')
		self:setBackground(oldColor, oldPalette)
		self:onDraw()
	end
end

window:setTitle("Draconic Control v" .. tostring(draconic_control.getVersion()) .. " by XyFreak")
window:addChild(dcGUI)

libGUI.setRootFrame(window)
libGUI.setRedrawInterval(1)
libGUI.runOrFork()

print("Please keep in mind that the draconic control service will not shut down automatically if the gui is closed.")