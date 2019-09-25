local oop = require("oop")
local stringutils = require("stringutils")
local libGUI = require("libGUI")
local colors = require("libGUI/colors")
local frame_base = require("libGUI/frame")
local reactorState = require("brgc/reactor_state")
local regulationState = require("brgc/regulation_state")
local reactor_load_bar = require("brgc/gui/reactor_load_bar")
local grid_controller = require("brgc/grid_controller")

local controller_info_big = {
	mReactorLoadBarLabel = nil,
	mReactorLoadBar = nil,
	mReactorLoadText = nil,

	mTurbineLoadBarLabel = nil,
	mTurbineLoadBar = nil,
	mTurbineLoadText = nil,

	mTotalLoadBarLabel = nil,
	mTotalLoadBar = nil,
	mTotalLoadText = nil,

	mInfoList = nil,

	mModeLabel = nil,
	mEnergyStoredLabel = nil,
	mEnergyProductionLabel = nil,
	mEnergyDemandLabel = nil,

	mStorageBar = nil,
	mModeButtonGroup = nil
}
oop.inherit(controller_info_big, frame_base)

function controller_info_big:construct()
	frame_base.construct(self)

	self.mReactorLoadBarLabel = libGUI.newFrame("label", "Reactors", "right")
	self.mReactorLoadBar = reactor_load_bar()
	self.mReactorLoadText = libGUI.newFrame("label", nil, "left")

	self.mTurbineLoadBarLabel = libGUI.newFrame("label", "Turbines", "right")
	self.mTurbineLoadBar = libGUI.newFrame("bar")
	self.mTurbineLoadBar:setBorderWidth(0)
	self.mTurbineLoadText = libGUI.newFrame("label", nil, "left")

	self.mStorageBar = libGUI.newFrame("bar")
	self.mStorageBar:setBorderWidth(2)
	self.mStorageBar:setBarPalette({{math.huge, colors.red}})

	self.mTotalLoadBarLabel = libGUI.newFrame("label", "Total", "right")
	self.mTotalLoadBar = reactor_load_bar()
	self.mTotalLoadText = libGUI.newFrame("label", nil, "left")

	self.mModeLabel = libGUI.newFrame("label", nil, "right")
	self.mEnergyStoredLabel = libGUI.newFrame("label", nil, "right")
	self.mEnergyProductionLabel = libGUI.newFrame("label", nil, "right")
	self.mEnergyDemandLabel = libGUI.newFrame("label", nil, "right")

	local infoListFrame = libGUI.newFrame("list")
	infoListFrame:addChild(libGUI.newFrame("label", "Mode", "left"))
	infoListFrame:addChild(self.mModeLabel)
	infoListFrame:addChild(libGUI.newFrame("label", "Energy Stored / Energy Max"))
	infoListFrame:addChild(self.mEnergyStoredLabel)
	infoListFrame:addChild(libGUI.newFrame("label", "Energy Generation Rate (Optimal)", "left"))
	infoListFrame:addChild(self.mEnergyProductionLabel)
	infoListFrame:addChild(libGUI.newFrame("label", "Energy Demand (Weighted)", "left"))
	infoListFrame:addChild(self.mEnergyDemandLabel)

	self.mModeButtonGroup = libGUI.newFrame("horizontal_layout", 1)
	local btnOnOff = libGUI.newFrame("toggle_button", "ON/OFF", "center")
	local btnCharge = libGUI.newFrame("toggle_button", "Charge", "center")

	function btnOnOff:onStateChange()
		if not self:getToggleState() then
			grid_controller.start()
		else
			grid_controller.stop()
		end
	end
	function btnOnOff:getToggleState()
		return grid_controller.isRunning()
	end

	function btnCharge:onStateChange()
		grid_controller.setChargeMode(not grid_controller.getChargeMode())
	end
	function btnCharge:getToggleState()
		return grid_controller.getChargeMode()
	end

	self.mModeButtonGroup:addChild(btnCharge)
	self.mModeButtonGroup:addChild(btnOnOff)

	self:addChild(self.mStorageBar)
	self:addChild(self.mReactorLoadBarLabel)
	self:addChild(self.mReactorLoadBar)
	self:addChild(self.mReactorLoadText)
	self:addChild(self.mTurbineLoadBarLabel)
	self:addChild(self.mTurbineLoadBar)
	self:addChild(self.mTurbineLoadText)
	self:addChild(self.mTotalLoadBarLabel)
	self:addChild(self.mTotalLoadBar)
	self:addChild(self.mTotalLoadText)
	self:addChild(infoListFrame)
	self:addChild(self.mModeButtonGroup)

	self.mInfoList = infoListFrame
end

function controller_info_big:updateInfo()
	if grid_controller.isRunning() then

		local energyStoredMax = grid_controller.getMaxEnergyStored()
		local energyStoredCurrent = grid_controller.getEnergyStored()
		local energyProducedReactors = grid_controller.getEnergyProductionRateReactors()
		local energyProducedTurbines = grid_controller.getEnergyProductionRateTurbines()
		local energyProducedTotal = grid_controller.getEnergyProductionRate()
		local energyProductionReactorsMax = grid_controller.getEnergyProductionRateReactorsMax()
		local energyProductionTurbinesMax = grid_controller.getEnergyProductionRateTurbinesMax()
		local energyProductionTotalMax = energyProductionReactorsMax + energyProductionTurbinesMax
		local energyProductionTotalOpt = grid_controller.getOptEnergyProduction()
		local energyProductionReactorOpt = energyProductionTotalOpt - energyProductionTurbinesMax

		self.mReactorLoadText:setText(stringutils.formatRFt(energyProducedReactors), false)
		self.mTurbineLoadText:setText(stringutils.formatRFt(energyProducedTurbines), false)
		self.mTotalLoadText:setText(stringutils.formatRFt(energyProducedTotal), false)

		if energyProductionReactorsMax <= 0 then
			self.mReactorLoadBar:setPercentage(0, false)
		else
			self.mReactorLoadBar:setPercentage(energyProducedReactors / energyProductionReactorsMax, false)
		end
		if self.mReactorLoadBar:getPercentageOptimal() ~= energyProductionReactorOpt / energyProductionReactorsMax then
			self.mReactorLoadBar:setPercentageOptimal(energyProductionReactorOpt / energyProductionReactorsMax)
		end

		if energyProductionTurbinesMax <= 0 then
			self.mTurbineLoadBar:setPercentage(0, false)
		else
			self.mTurbineLoadBar:setPercentage(energyProducedTurbines / energyProductionTurbinesMax, false)
		end

		if energyProductionTotalMax <= 0 then
			self.mTotalLoadBar:setPercentage(0, false)
		else
			self.mTotalLoadBar:setPercentage(energyProducedTotal / energyProductionTotalMax, false)
		end
		if self.mTotalLoadBar:getPercentageOptimal() ~= energyProductionTotalOpt / energyProductionTotalMax then
			self.mTotalLoadBar:setPercentageOptimal(energyProductionTotalOpt / energyProductionTotalMax)
		end

		if energyStoredMax <= 0 then
			self.mStorageBar:setPercentage(0, false)
		else
			self.mStorageBar:setPercentage(energyStoredCurrent / energyStoredMax, false)
		end

		if grid_controller.mState == 2 then
			self.mModeLabel:setText("HOLDING CHARGE", false)
		elseif grid_controller.getChargeMode() then
			self.mModeLabel:setText("CHARGING", false)
		elseif grid_controller.mState == 1 then
			self.mModeLabel:setText("INCREASING CHARGE", false)
		elseif grid_controller.mState == 0 then
			self.mModeLabel:setText("DECREASING CHARGE", false)
		else
			self.mModeLabel:setText("UNKNOWN", false)
		end

		self.mEnergyStoredLabel:setText( " " .. stringutils.formatNumber(energyStoredCurrent, "RF", 0, 3) .. " / " .. stringutils.formatNumber(energyStoredMax, "RF", 0, 3) .. string.format(" ( %5.02f%% )", 100 * energyStoredCurrent / energyStoredMax), false)
		self.mEnergyProductionLabel:setText(stringutils.formatRFt(energyProducedTotal) .. " (" .. stringutils.formatRFt(energyProductionTotalOpt) .. ")", false)
		self.mEnergyDemandLabel:setText(stringutils.formatRFt(grid_controller.getEnergyExtractionRate()) .. " (" .. stringutils.formatRFt(grid_controller.getEnergyExtractionRateWeighted()) .. ")", false)

	else
		self.mModeLabel:setText("DISABLED", false)
		self.mReactorLoadBar:setPercentage(0, false)
		self.mTurbineLoadBar:setPercentage(0, false)
		self.mTotalLoadBar:setPercentage(0, false)
		self.mStorageBar:setPercentage(0, false)
		self.mEnergyStoredLabel:setText("---", false)
		self.mEnergyProductionLabel:setText("---", false)
		self.mEnergyDemandLabel:setText("--- (---)", false)
	end
end

function controller_info_big:onDraw(allowPartial)
	self:updateInfo()
	frame_base.onDraw(self, allowPartial)
end

function controller_info_big:onResize()
	frame_base.onResize(self)
	local width, height = self:getSize()

	self.mStorageBar:setRegion(2, 2, 8, height - 2)

	self.mReactorLoadBarLabel:setRegion(13, 2, 8, 1)
	self.mReactorLoadBar:setRegion(22, 2, width - 35, 1)
	self.mReactorLoadText:setRegion(width - 12, 2, 11, 1)

	self.mTurbineLoadBarLabel:setRegion(13, 3, 8, 1)
	self.mTurbineLoadBar:setRegion(22, 3, width - 35, 1)
	self.mTurbineLoadText:setRegion(width - 12, 3, 11, 1)

	self.mTotalLoadBarLabel:setRegion(13, 4, 8, 1)
	self.mTotalLoadBar:setRegion(22, 4, width - 35, 1)
	self.mTotalLoadText:setRegion(width - 12, 4, 11, 1)

	if height < 10 and self.mInfoList:getParent() ~= nil then
		self:removeChild(self.mInfoList)
	elseif height >= 10 and self.mInfoList:getParent() == nil then
		self:addChild(self.mInfoList)
	end

	if self.mInfoList:getParent() ~= nil then
		self.mInfoList:setRegion(13, 6, width - 13, math.min(#self.mInfoList.mChildren, height - 9))
	end
	self.mModeButtonGroup:setRegion(12, height - 3, width - 12, 3)
end

return controller_info_big
