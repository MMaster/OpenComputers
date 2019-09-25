local oop = require("oop");
local component = require("component");

local frame_base = {
	mGPU = nil,
	mParent = nil,
	mChildren = nil,
	mOffsetX = 0,
	mOffsetY = 0,
	mWidth = 0,
	mHeight = 0,
	mBackgroundColor = 0, mBackgroundIndex = false,
	mForegroundColor = 16777215, mForegroundIndex = false
};

oop.make(frame_base);
function frame_base:construct(parent)
	self.mParent = parent;
	self.mChildren = {};
	if self.mParent and self:getGPU() then
		self.mGPU = self:getGPU();
		self.mBackgroundColor, self.mBackgroundIndex = self.mGPU.getBackground();
		self.mForegroundColor, self.mForegroundIndex = self.mGPU.getForeground();
	end
end

function frame_base:getGPU()
	if self.mParent then
		return self.mParent:getGPU();
	else
		return self.mGPU;
	end
end

function frame_base:setGPU(gpu)
	self.mGPU = gpu;
end

function frame_base:getParent()
	return self.mParent;
end

function frame_base:setParent(parent)
	self.mParent = parent;
	if parent ~= nil then
		self.mGPU = parent:getGPU();
	else
		self.mGPU = nil;
	end
end

function frame_base:setPosition(x, y)
	self.mOffsetX = x-1;
	self.mOffsetY = y-1;
	self:onResize();
end

function frame_base:getPosition()
	return self.mOffsetX+1, self.mOffsetY+1;
end

function frame_base:setSize(width, height)
	self.mWidth = width;
	self.mHeight = height;
	self:onResize();
end

function frame_base:getSize()
	return self.mWidth, self.mHeight;
end

function frame_base:setRegion(x, y, width, height)
	self.mOffsetX = x-1;
	self.mOffsetY = y-1;
	self.mWidth = width;
	self.mHeight = height;

	self:onResize();
end

function frame_base:setWidth(width)
	self.mWidth = width;
	
	self:onResize();
end

function frame_base:getWidth()
	return self.mWidth;
end

function frame_base:setHeight(height)
	self.mHeight = height;
	
	self:onResize();
end

function frame_base:getHeight()
	return self.mHeight;
end

function frame_base:addChild(child)
	if child:getParent() then
		if child:getParent() == self then
			return;
		end
		child:getParent():removeChild(child);
	end
	table.insert(self.mChildren, child);
	child:setParent(self);
end

function frame_base:removeChild(child)
	if not (child:getParent() == self) then
		return;
	end

	for idx,c in pairs(self.mChildren) do
		if c == child then
			self.mChildren[idx] = nil;
			child:setParent(nil);
			break;
		end
	end
end

function frame_base:onDraw()
	self.mGPU = self:getGPU();
	
	for _, child in pairs(self.mChildren) do
		child:onDraw();
	end
	
	local currentBackgroundColor, currentBackgroundIndex = self.mGPU.getBackground();
	local currentForegroundColor, currentForegroundIndex = self.mGPU.getForeground();

	if not ( currentBackgroundColor == self.mBackgroundColor and currentBackgroundIndex == self.mBackgroundIndex ) then
		self.mGPU.setBackground(self.mBackgroundColor, not not self.mBackgroundIndex);
	end

	if not ( currentForegroundColor == self.mForegroundColor and currentForegroundIndex == self.mForegroundIndex ) then
		self.mGPU.setForeground(self.mForegroundColor, not not self.mForegroundIndex);
	end
end

function frame_base:onTouch(x, y, button, playerName)
	for _, child in pairs(self.mChildren) do
		local childX, childY = child:getPosition();
		local childW, childH = child:getSize();

		if x >= childX and x < childX+childW and y >= childY and y < childY+childH then
			child:onTouch(x - childX + 1, y - childY + 1, button, playerName);
		end
	end
end

function frame_base:onResize()
end

-- Wrappers

function frame_base:getBackground()
	return self.mBackgroundColor, self.mBackgroundIndex;
end

function frame_base:setBackground(color, isPaletteColor)
	if not (self.mBackgroundColor == color and self.mBackgroundIndex == isPaletteColor) then
		self.mBackgroundColor = color;
		self.mBackgroundIndex = isPaletteColor;
		if self.mGPU ~= nil then
			return self.mGPU.setBackground(color, not not isPaletteColor);
		else
			return nil;
		end
	else
		return self.mGPU.getBackground();
	end
end

function frame_base:getForeground()
	return self.mForegroundColor, self.mForegroundIndex;
end

function frame_base:setForeground(color, isPaletteColor)
	if not (self.mForegroundColor == color and self.mForegroundIndex == isPaletteColor) then
		self.mForegroundColor = color;
		self.mForegroundIndex = isPaletteColor;
		if self.mGPU ~= nil then
			return self.mGPU.setForeground(color, not not isPaletteColor);
		else
			return nil;
		end
	else
		return self.mGPU.getForeground();
	end
end

function frame_base:get(x, y)
	if self.mWidth < x or self.mHeight < y then
		return nil;
	elseif self.mParent then
		return self.mParent:get(self.mOffsetX + x, self.mOffsetY + y);
	else
		return self.mGPU.get(self.mOffsetX + x, self.mOffsetY + y);
	end
end

function frame_base:set(x, y, value, vertical)
	if not vertical then
		value = string.sub(value, 1, self.mWidth - x + 1);
	else
		value = string.sub(value, 1, self.mHeight - y + 1);
	end

	if self.mWidth < x or self.mHeight < y then
		return false;
	elseif self.mParent then
		return self.mParent:set(self.mOffsetX + x, self.mOffsetY + y, value, vertical);
	else
		return self.mGPU.set(self.mOffsetX + x, self.mOffsetY + y, value, not not vertical);
	end
end

function frame_base:copy(x, y, width, height, tx, ty)
	if tx < 0 then
		x = x - tx;
		width = width + tx;
	end
	if ty < 0 then
		y = y - ty;
		height = height + ty;
	end
	if x < 0 then
		width = width + x;
		x = 0;
	end
	if y < 0 then
		height = height + y;
		y = 0;
	end
	width = math.min(width, self.mWidth);
	height = math.min(height, self.mHeight);

	if self.mWidth < x or self.mWidth < tx or self.mHeight < y or self.mHeight < ty then
		return false;
	elseif self.mParent then
		return self.mParent:copy(self.mOffsetX + x, self.mOffsetY + y, width, height, self.mOffsetX + tx, self.mOffsetY + ty);
	else
		return self.mGPU.copy(self.mOffsetX + x, self.mOffsetY + y, width, height, self.mOffsetX + tx, self.mOffsetY + ty);
	end
end

function frame_base:fill(x, y, width, height, char)
	if x < 0 then
		width = width + x;
		x = 0;
	end
	if y < 0 then
		height = height + y;
		y = 0;
	end
	width = math.min(width, self.mWidth - x + 1);
	height = math.min(height, self.mHeight - y + 1);

	if self.mWidth < x or self.mHeight < y then
		return false;
	elseif self.mParent then
		return self.mParent:fill(self.mOffsetX + x, self.mOffsetY + y, width, height, char);
	else
		return self.mGPU.fill(self.mOffsetX + x, self.mOffsetY + y, width, height, char);
	end
end

return frame_base;
