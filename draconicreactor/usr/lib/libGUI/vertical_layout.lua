local oop = require("oop");
local frame_base = require("libGUI/frame");

local vertical_layout = {};
oop.inherit(vertical_layout, frame_base);

function vertical_layout:addChild(child)
	frame_base.addChild(self, child);
	self:resizeChildren();
end

function vertical_layout:removeChild(child)
	frame_base.removeChild(self, child);
	self:resizeChildren();
end

function vertical_layout:resizeChildren()
	local i = 0;
	local height = math.floor(self:getHeight()/#self.mChildren);
	for _, child in pairs(self.mChildren) do
		child:setSize(self:getWidth(), height);
		child:setPosition(1, 1+height*i);
		i = i + 1;
	end
end

return vertical_layout;