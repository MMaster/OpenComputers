local oop = require("oop")
local stringutils = require("stringutils")
local libGUI = require("libGUI")
local colors = require("libGUI/colors")
local frame_base = require("libGUI/frame")
local turbineState = require("brgc/turbine_state")
local turbine_speed_bar = require("brgc/gui/turbine_speed_bar")


local turbine_info_big = {
	mTurbine = nil,
	mSpeedBar = nil,
	mStorageBar = nil,

	mInfoList = nil,

	mAddressLabel = nil,
	mAddressCaptionLabel = nil,

	mStateLabel = nil,
	mStateCaptionLabel = nil,

	mSpeedLabel = nil,
	mSpeedCaptionLabel = nil,

	mGenerationLabel = nil,
	mGenerationCaptionLabel = nil,

	mOutputLabel = nil,
	mOutputCaptionLabel = nil,

	mConsumptionLabel = nil,
	mConsumptionCaptionLabel = nil,

	mModeToggleButtonGroup = nil
}
oop.inherit(turbine_info_big, frame_base)

function turbine_info_big:construct(turbine)
	frame_base.construct(self)

	self.mSpeedBar = turbine_speed_bar()
	self.mSpeedBar:setBorderWidth(2)
	self.mStorageBar = libGUI.newFrame("bar")
	self.mStorageBar:setBorderWidth(2)
	self.mStorageBar:setBarPalette({{math.huge, colors.red}})

	local infoListFrame = libGUI.newFrame("list")

	self.mAddressLabel = libGUI.newFrame("label", turbine:getAddress(), "right")
	self.mAddressCaptionLabel = libGUI.newFrame("label", "Turbine")

	self.mStateLabel = libGUI.newFrame("label", nil, "right")
	self.mStateCaptionLabel = libGUI.newFrame("label", "State")

	self.mSpeedLabel = libGUI.newFrame("label", nil, "right")
	self.mSpeedCaptionLabel = libGUI.newFrame("label", "Speed (Target)")

	self.mGenerationLabel = libGUI.newFrame("label", nil, "right")
	self.mGenerationCaptionLabel = libGUI.newFrame("label", "Current Generation")

	self.mOutputLabel = libGUI.newFrame("label", nil, "right")
	self.mOutputCaptionLabel = libGUI.newFrame("label", "Current Output")

	self.mConsumptionLabel = libGUI.newFrame("label", nil, "right")
	self.mConsumptionCaptionLabel = libGUI.newFrame("label", "Steam Consumption")

	infoListFrame:addChild(self.mAddressCaptionLabel); infoListFrame:addChild(self.mAddressLabel)
	infoListFrame:addChild(self.mStateCaptionLabel); infoListFrame:addChild(self.mStateLabel)
	infoListFrame:addChild(self.mSpeedCaptionLabel); infoListFrame:addChild(self.mSpeedLabel)
	infoListFrame:addChild(self.mGenerationCaptionLabel); infoListFrame:addChild(self.mGenerationLabel)
	infoListFrame:addChild(self.mOutputCaptionLabel); infoListFrame:addChild(self.mOutputLabel)
	infoListFrame:addChild(self.mConsumptionCaptionLabel); infoListFrame:addChild(self.mConsumptionLabel)

	self.mModeToggleButtonGroup = libGUI.newFrame("horizontal_layout", 1)
	local btnOnOff = libGUI.newFrame("toggle_button", "ON/OFF", "center")
	local btnIndependent = libGUI.newFrame("toggle_button", "Independent", "center")

	function btnOnOff:onStateChange()
		if not self:getToggleState() then
			turbine:setState(turbineState.STARTING)
			turbine:setDisabled(false)
		else
			turbine:setState(turbineState.OFFLINE)
			turbine:setDisabled(true)
		end
	end
	function btnOnOff:getToggleState()
		return turbine:getState() ~= turbineState.OFFLINE and turbine:getState() ~= turbineState.ERROR
	end

	function btnIndependent:onStateChange()
		turbine:setIndependent(not turbine:isIndependent())
		config:setTurbineAttribute(turbine:getAddress(), "independent", turbine:isIndependent())
	end
	function btnIndependent:getToggleState()
		return turbine:isIndependent()
	end

	self.mModeToggleButtonGroup:addChild(btnOnOff)
	self.mModeToggleButtonGroup:addChild(btnIndependent)

	self:addChild(self.mSpeedBar)
	self:addChild(self.mStorageBar)
	self:addChild(infoListFrame)
	self:addChild(self.mModeToggleButtonGroup)

	self.mTurbine = turbine
	self.mInfoList = infoListFrame
end

function turbine_info_big:updateInfo()
	if self.mTurbine:isConnected() then
		local state = self.mTurbine:getState()
		self.mGenerationLabel:setText(stringutils.formatRFt(self.mTurbine:getOutputGenerationRate()), false)
		self.mOutputLabel:setText(stringutils.formatRFt(self.mTurbine:getOutputExtractionRate()), false)

		self.mStorageBar:setPercentage(self.mTurbine:getOutputStored() / self.mTurbine:getOutputStoredMax(), false)
		if self.mTurbine:getRPMOptimal() ~= nil and self.mSpeedBar:getPercentageOptimal() ~= self.mTurbine:getRPMOptimal() / 1850 then
			self.mSpeedBar:setPercentageOptimal(self.mTurbine:getRPMOptimal() / 1850)
		end
		self.mSpeedBar:setPercentage(self.mTurbine:getRPM() / 1850, false)

		self.mStateLabel:setText(turbineState.toString(self.mTurbine:getState()), false)
		self.mSpeedLabel:setText(math.floor(self.mTurbine:getRPM() + 0.5) .. " RPM (" .. math.floor(self.mTurbine:getRPMTarget() or 0 + 0.5) .. " RPM)")
		self.mConsumptionLabel:setText(stringutils.formatBt(self.mTurbine:getSteamRate() / 1000, false))
	else
		self.mStateLabel:setForeground(colors.red)
		self.mStateLabel:setText("DISCONNECTED", false)
		self.mSpeedBar:setPercentage(0, false)
		self.mStorageBar:setPercentage(0, false)
		self.mSpeedLabel:setText("N/A", false)
		self.mGenerationLabel:setText("N/A", false)
		self.mOutputLabel:setText("N/A", false)
		self.mConsumptionLabel:setText("N/A", false)
	end
end

function turbine_info_big:onDraw(allowPartial)
	self:updateInfo()
	frame_base.onDraw(self, allowPartial)
end

function turbine_info_big:onResize()
	frame_base.onResize(self)

	local width, height = self:getSize()

	self.mSpeedBar:setRegion(2, 2, 8, height - 2)
	self.mStorageBar:setRegion(12, 2, 8, height - 2)
	self.mInfoList:setRegion(24, 2, width - 25, #self.mInfoList.mChildren)
	self.mModeToggleButtonGroup:setRegion(24, height - 3, width - 24, 3)
end

return turbine_info_big
