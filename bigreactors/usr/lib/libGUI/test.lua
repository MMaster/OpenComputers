local oop = require("oop")
local frame_base = require("libGUI/frame")

local test_frame = {
	mTouched = false
}
oop.inherit(test_frame, frame_base)

function test_frame:onDraw()
	frame_base.onDraw(self)

	if not self.mTouched then
		self:set(1, 1, "I'm at offsetY" .. self.mOffsetY .. "   ")
	else
		self:set(1, 1, "I've been clicked!")
	end
end

function test_frame:onTouch(x, y, button, playerName)
	frame_base.onTouch(self, x, y, button, playerName)

	self.mTouched = not self.mTouched
	self:onDraw()
end

return test_frame