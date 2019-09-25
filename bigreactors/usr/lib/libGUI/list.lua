local oop = require("oop")
local frame_base = require("libGUI/frame")

local list_frame = {}
oop.inherit(list_frame, frame_base)

function list_frame:addChild(child)
	local nextPosition = 1
	for _, child in pairs(self.mChildren) do
		nextPosition = nextPosition + child:getHeight()
	end

	frame_base.addChild(self, child)

	child:setRegion(1, nextPosition, self:getWidth(), 1)
end

function list_frame:removeChild(child)
	frame_base.removeChild(self, child)
	self:repositionChildren()
end

function list_frame:repositionChildren()
	local i = 1
	for _, child in pairs(self.mChildren) do
		child:setPosition(1, i)
		i = i + child:getHeight()
	end
end

function list_frame:onResize()
	frame_base.onResize(self)

	for _, child in pairs(self.mChildren) do
		child:setWidth(self:getWidth())
	end
end

return list_frame
