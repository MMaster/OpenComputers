local oop = require("oop")
local stringutils = require("stringutils")
local turbineState = require("brgc/turbine_state")
local turbine_speed_bar = require("brgc/gui/turbine_speed_bar")
local generic_info_small = require("brgc/gui/generic_info_small")


local turbine_info_small = {
	mTurbine = nil
}
oop.inherit(turbine_info_small, generic_info_small)

function turbine_info_small:construct(turbine)
	generic_info_small.construct(self)

	self.mBar = turbine_speed_bar()

	self.mTurbine = turbine
end

function turbine_info_small:updateInfo()
	local message = nil
	local outputString = nil
	if self.mTurbine:isConnected() then
		local state = self.mTurbine:getState()
		local RFt = self.mTurbine:getOutputGenerationRate()
		self.mDisplayName = self.mTurbine:getAddressShort()
		if RFt > 0 then
			outputString = stringutils.formatRFt(RFt, true)
		else
			outputString = string.format("%4d RPM", math.floor(self.mTurbine:getRPM() + 0.5))
		end

		if self.mTurbine:getRPMOptimal() ~= nil and self.mBar:getPercentageOptimal() ~= self.mTurbine:getRPMOptimal() / 1850 then
			self.mBar:setPercentageOptimal(self.mTurbine:getRPMOptimal() / 1850)
		end
		self.mBar:setPercentage(self.mTurbine:getRPM() / 1850, false)
		if state == turbineState.ERROR then
			message = "ERROR"
		elseif state == turbineState.OFFLINE then
			message = "OFFLINE"
		elseif state == turbineState.CALIBRATING then
			message = "CALIBRATING"
		elseif state == turbineState.SUSPENDED then
			message = "SUSPENDED"
		elseif state == turbineState.KICKOFF then
			message = "KICKOFF"
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

return turbine_info_small
