local oop = require("oop")
local stringutils = require("stringutils")
local reactorState = require("brgc/reactor_state")
local reactor_load_bar = require("brgc/gui/reactor_load_bar")
local generic_info_small = require("brgc/gui/generic_info_small")


local reactor_info_small = {
	mReactor = nil
}
oop.inherit(reactor_info_small, generic_info_small)

function reactor_info_small:construct(reactor)
	generic_info_small.construct(self)

	self.mBar = reactor_load_bar()

	self.mReactor = reactor
end

function reactor_info_small:updateInfo()
	local message = nil
	local outputString = nil
	if self.mReactor:isConnected() then
		local state = self.mReactor:getState()
		self.mDisplayName = self.mReactor:getAddressShort()
		if self.mReactor:isActivelyCooled() then
			outputString = stringutils.formatBt(self.mReactor:getOutputGenerationRate() / 1000)
		else
			outputString = stringutils.formatRFt(self.mReactor:getOutputGenerationRate())
		end

		if self.mBar:getPercentageOptimal() ~= self.mReactor:getOutputOpt() then
			self.mBar:setPercentageOptimal(self.mReactor:getOutputOpt())
		end
		self.mBar:setPercentage(self.mReactor:getOutput(), false)
		if state == reactorState.ERROR then
			message = "ERROR"
		elseif state == reactorState.OFFLINE then
			message = "OFFLINE"
		elseif state == reactorState.CALIBRATING then
			message = "CALIBRATING"
		elseif state == reactorState.OPTIMIZING then
			message = "OPTIMIZING"
		end
	else
		outputString = nil
		self.mBar:setPercentage(0, false)
		message = "DISCONNECTED"
	end

	self.mHasChanged = message ~= self.mMessage or outputString ~= self.mOutputString or self.mBar.mHasChanged
	self.mMessage = message
	self.mOutputString = outputString
end

return reactor_info_small
