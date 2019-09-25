local oop = require("oop")
local frame_base = require("libGUI/frame")

local horizontal_layout = {
	mPadding = 0
}
oop.inherit(horizontal_layout, frame_base)

function horizontal_layout:construct(padding)
	frame_base.construct(self)
	self.mPadding = padding or 0
end

function horizontal_layout:addChild(child)
	frame_base.addChild(self, child)
	self:resizeChildren()
end

function horizontal_layout:removeChild(child)
	frame_base.removeChild(self, child)
	self:resizeChildren()
end

function horizontal_layout:resizeChildren()
	local i = 0
	local width = math.floor( (self:getWidth() - self.mPadding) / #self.mChildren - self.mPadding)
	for _, child in pairs(self.mChildren) do
		child:setRegion(1 + self.mPadding + (width + self.mPadding) * i, 1, width, self:getHeight())
		i = i + 1
	end
end

function horizontal_layout:onResize()
	frame_base.onResize(self)
	self:resizeChildren()
end

return horizontal_layout