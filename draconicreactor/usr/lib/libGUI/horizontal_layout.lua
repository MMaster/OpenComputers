local oop = require("oop");
local frame_base = require("libGUI/frame");

local horizontal_layout = {};
oop.inherit(horizontal_layout, frame_base);

function horizontal_layout:addChild(child)
	frame_base.addChild(self, child);
	self:resizeChildren();
end

function horizontal_layout:removeChild(child)
	frame_base.removeChild(self, child);
	self:resizeChildren();
end

function horizontal_layout:resizeChildren()
	local i = 0;
	local width = math.floor(self:getWidth()/#self.mChildren);
	for _, child in pairs(self.mChildren) do
		child:setSize(width, self:getHeight());
		child:setPosition(1+width*i, 1);
		i = i + 1;
	end
end

return horizontal_layout;