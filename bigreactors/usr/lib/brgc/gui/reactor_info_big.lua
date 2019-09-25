local oop = require("oop")
local stringutils = require("stringutils")
local libGUI = require("libGUI")
local colors = require("libGUI/colors")
local frame_base = require("libGUI/frame")
local reactorState = require("brgc/reactor_state")
local regulationState = require("brgc/regulation_state")
local reactor_load_bar = require("brgc/gui/reactor_load_bar")


local reactor_info_big = {
	mReactor = nil,
	mLoadBar = nil,
	mStorageBar = nil,

	mInfoList = nil,

	mAddressLabel = nil,
	mAddressCaptionLabel = nil,

	mStateLabel = nil,
	mStateCaptionLabel = nil,

	mModeLabel = nil,
	mModeCaptionLabel = nil,

	mHeatLabel = nil,
	mHeatCaptionLabel = nil,

	mGenerationLabel = nil,
	mGenerationCaptionLabel = nil,

	mOutputLabel = nil,
	mOutputCaptionLabel = nil,

	mConsumptionLabel = nil,
	mConsumptionCaptionLabel = nil,

	mModeToggleButtonGroup = nil,
	mModeToggleButtonGroup2 = nil,
	mDisableButton = nil,
	mModeGridButton = nil
}
oop.inherit(reactor_info_big, frame_base)

function reactor_info_big:construct(reactor)
	frame_base.construct(self)

	self.mLoadBar = reactor_load_bar()
	self.mLoadBar:setBorderWidth(2)
	self.mStorageBar = libGUI.newFrame("bar")
	self.mStorageBar:setBorderWidth(2)

	local infoListFrame = libGUI.newFrame("list")

	self.mAddressLabel = libGUI.newFrame("label", reactor:getAddress(), "right")
	self.mAddressCaptionLabel = libGUI.newFrame("label", "Reactor")

	self.mStateLabel = libGUI.newFrame("label", nil, "right")
	self.mStateCaptionLabel = libGUI.newFrame("label", "State")

	self.mModeLabel = libGUI.newFrame("label", nil, "right")
	self.mModeCaptionLabel = libGUI.newFrame("label", "Mode")

	self.mHeatLabel = libGUI.newFrame("label", nil, "right")
	self.mHeatCaptionLabel = libGUI.newFrame("label", "Core Heat")

	self.mGenerationLabel = libGUI.newFrame("label", nil, "right")
	self.mGenerationCaptionLabel = libGUI.newFrame("label", "Current Generation")

	self.mOutputLabel = libGUI.newFrame("label", nil, "right")
	self.mOutputCaptionLabel = libGUI.newFrame("label", "Current Output")

	self.mConsumptionLabel = libGUI.newFrame("label", nil, "right")
	self.mConsumptionCaptionLabel = libGUI.newFrame("label", "Fuel Consumption (Level %)")

	infoListFrame:addChild(self.mAddressCaptionLabel); infoListFrame:addChild(self.mAddressLabel)
	infoListFrame:addChild(self.mStateCaptionLabel); infoListFrame:addChild(self.mStateLabel)
	infoListFrame:addChild(self.mModeCaptionLabel); infoListFrame:addChild(self.mModeLabel)
	infoListFrame:addChild(self.mHeatCaptionLabel); infoListFrame:addChild(self.mHeatLabel)
	infoListFrame:addChild(self.mGenerationCaptionLabel); infoListFrame:addChild(self.mGenerationLabel)
	infoListFrame:addChild(self.mOutputCaptionLabel); infoListFrame:addChild(self.mOutputLabel)
	infoListFrame:addChild(self.mConsumptionCaptionLabel); infoListFrame:addChild(self.mConsumptionLabel)

	self.mModeToggleButtonGroup = libGUI.newFrame("horizontal_layout", 1)
	self.mModeToggleButtonGroup2 = libGUI.newFrame("horizontal_layout", 1)
	local btnModeAuto = libGUI.newFrame("toggle_button", "AUTO", "center")
	local btnModePWM = libGUI.newFrame("toggle_button", "PWM", "center")
	local btnModeLoad = libGUI.newFrame("toggle_button", "LOAD", "center")
	local btnModeGrid = libGUI.newFrame("toggle_button", "GRID", "center")

	function btnModeAuto:onStateChange()
		reactor:setRegulationBehaviour(regulationState.AUTO)
		btnModePWM:onDraw(); btnModeLoad:onDraw(); btnModeGrid:onDraw()
	end
	function btnModeAuto:getToggleState()
		return reactor:getRegulationBehaviour() == regulationState.AUTO
	end

	function btnModePWM:onStateChange()
		reactor:setRegulationBehaviour(regulationState.PWM)
		btnModeAuto:onDraw(); btnModeLoad:onDraw(); btnModeGrid:onDraw()
	end
	function btnModePWM:getToggleState()
		return reactor:getRegulationBehaviour() == regulationState.PWM
	end

	function btnModeLoad:onStateChange()
		reactor:setRegulationBehaviour(regulationState.LOAD)
		btnModeAuto:onDraw(); btnModePWM:onDraw(); btnModeGrid:onDraw()
	end
	function btnModeLoad:getToggleState()
		return reactor:getRegulationBehaviour() == regulationState.LOAD
	end

	function btnModeGrid:onStateChange()
		reactor:setRegulationBehaviour(regulationState.GRID)
		btnModeAuto:onDraw(); btnModePWM:onDraw(); btnModeLoad:onDraw()
	end
	function btnModeGrid:getToggleState()
		return reactor:getRegulationBehaviour() == regulationState.GRID
	end

	self.mModeToggleButtonGroup:addChild(btnModeAuto)
	self.mModeToggleButtonGroup:addChild(btnModePWM)
	self.mModeToggleButtonGroup:addChild(btnModeLoad)


	self.mDisableButton = libGUI.newFrame("toggle_button", "ON/OFF", "center")
	function self.mDisableButton:onStateChange()
		if not self:getToggleState() then
			reactor:setState(reactorState.ONLINE)
			reactor:setDisabled(false)
		else
			reactor:setState(reactorState.OFFLINE)
			reactor:setDisabled(true)
		end
	end
	function self.mDisableButton:getToggleState()
		return reactor:getState() ~= reactorState.OFFLINE and reactor:getState() ~= reactorState.ERROR
	end

	self.mModeToggleButtonGroup2:addChild(btnModeGrid)
	self.mModeToggleButtonGroup2:addChild(self.mDisableButton)

	self:addChild(self.mLoadBar)
	self:addChild(self.mStorageBar)
	self:addChild(infoListFrame)
	self:addChild(self.mModeToggleButtonGroup)
	self:addChild(self.mModeToggleButtonGroup2)

	self.mModeGridButton = btnModeGrid
	self.mReactor = reactor
	self.mInfoList = infoListFrame
end

function reactor_info_big:updateInfo()
	if self.mReactor:isConnected() then
		local state = self.mReactor:getState()
		if self.mReactor:isActivelyCooled() then
			self.mAddressCaptionLabel:setText("Active Reactor", false)
			self.mGenerationLabel:setText(stringutils.formatBt(self.mReactor:getOutputGenerationRate() / 1000), false)
			self.mOutputLabel:setText(stringutils.formatBt(self.mReactor:getOutputExtractionRate() / 1000), false)
			self.mModeLabel:setText("LOAD", false)

			self.mStorageBar:setBarPalette({{math.huge, colors.white}})

			if self.mModeToggleButtonGroup:getParent() ~= nil then
				self:removeChild(self.mModeToggleButtonGroup)
				self.mModeToggleButtonGroup2:removeChild(self.mModeGridButton)
			end
		else
			self.mAddressCaptionLabel:setText("Passive Reactor", false)
			self.mGenerationLabel:setText(stringutils.formatRFt(self.mReactor:getOutputGenerationRate()), false)
			self.mOutputLabel:setText(stringutils.formatRFt(self.mReactor:getOutputExtractionRate()), false)
			if self.mReactor:getRegulationBehaviour() == regulationState.AUTO then
				self.mModeLabel:setText(string.upper(self.mReactor.mRegulationState or "---") .. " (" .. regulationState.toString(self.mReactor:getRegulationBehaviour()) .. ")", false)
			else
				self.mModeLabel:setText(string.upper(self.mReactor.mRegulationState or "---"), false)
			end
			self.mStorageBar:setBarPalette({{math.huge, colors.red}})

			if self.mModeToggleButtonGroup:getParent() == nil then
				self:addChild(self.mModeToggleButtonGroup)
				self.mModeToggleButtonGroup2:addChild(self.mModeGridButton)
			end
		end

		self.mStorageBar:setPercentage((self.mReactor:getOutputStored() + self.mReactor:getOutputGenerationRate()) / self.mReactor:getOutputStoredMax(), false)
		if self.mLoadBar:getPercentageOptimal() ~= self.mReactor:getOutputOpt() then
			self.mLoadBar:setPercentageOptimal(self.mReactor:getOutputOpt())
		end
		self.mLoadBar:setPercentage(self.mReactor:getOutput(), false)
		self.mStateLabel:setText(reactorState.toString(self.mReactor:getState()), false)
		self.mHeatLabel:setText(math.floor(self.mReactor:getFuelTemperature() + 0.5) .. " °C")
		self.mConsumptionLabel:setText(
			string.format("(%3d%%) %s",
				math.floor(self.mReactor:getFuelLevel() * 100 + 0.5),
				stringutils.formatBt(self.mReactor:getFuelConsumedLastTick() / 1000, false)
			)
		)
	else
		self.mAddressCaptionLabel:setText("Reactor", false)
		self.mStateLabel:setForeground(colors.red)
		self.mStateLabel:setText("DISCONNECTED", false)
		self.mLoadBar:setPercentage(0, false)
		self.mStorageBar:setPercentage(0, false)
		self.mHeatLabel:setText("N/A", false)
		self.mGenerationLabel:setText("N/A", false)
		self.mOutputLabel:setText("N/A", false)
		self.mConsumptionLabel:setText("N/A", false)
	end
end

function reactor_info_big:onDraw(allowPartial)
	self:updateInfo()
	frame_base.onDraw(self, allowPartial)
end

function reactor_info_big:onResize()
	frame_base.onResize(self)

	local width, height = self:getSize()

	self.mLoadBar:setRegion(2, 2, 8, height - 2)
	self.mStorageBar:setRegion(12, 2, 8, height - 2)
	self.mInfoList:setRegion(24, 2, width - 25, #self.mInfoList.mChildren)
	self.mModeToggleButtonGroup:setRegion(24, height - 7, width - 24, 3)
	self.mModeToggleButtonGroup2:setRegion(24, height - 3, width - 24, 3)
end

return reactor_info_big
