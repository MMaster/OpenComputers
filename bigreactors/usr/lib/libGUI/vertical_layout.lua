local oop = require("oop")
local frame_base = require("libGUI/frame")

local vertical_layout = {
	mPadding = 0
}
oop.inherit(vertical_layout, frame_base)

function vertical_layout:construct(padding)
	frame_base.construct(self)
	self.mPadding = padding or 0
end

function vertical_layout:addChild(child)
	frame_base.addChild(self, child)
	self:resizeChildren()
end

function vertical_layout:removeChild(child)
	frame_base.removeChild(self, child)
	self:resizeChildren()
end

function vertical_layout:resizeChildren()
	local i = 0
	local height = math.floor( (self:getHeight() - self.mPadding) / #self.mChildren - self.mPadding)
	for _, child in pairs(self.mChildren) do
		child:setRegion(1, 1 + self.mPadding + (height + self.mPadding) * i, self:getWidth(), height)
		i = i + 1
	end
end

function vertical_layout:onResize()
	frame_base.onResize(self)
	self:resizeChildren()
end

return vertical_layout