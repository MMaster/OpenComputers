local oop = require("oop");
local frame_base = require("libGUI/frame");
local colors = require("libGUI/colors");

local tabframe_base = {
	mClientFrame = nil,
	mItems = nil,
	mCaptionSpacing = 3,
	mCaptionPadding = 1,
};
oop.inherit(tabframe_base, frame_base);

function tabframe_base:construct(parent)
	frame_base.construct(self, parent);
	self.mItems = {};

	self.mClientFrame = frame_base();
	frame_base.addChild(self, self.mClientFrame);
	self:setForeground(colors.black);
	self:setBackground(colors.lightGray);
end

function tabframe_base:addItem(caption, callback, frame)
	local item = {
		width = string.len(caption) + 2 * self.mCaptionPadding,
		caption = caption,
		callback = callback,
		frame = frame;
	};
	table.insert(self.mItems, item);
end

function tabframe_base:removeItem(caption)
	for i, item in pairs(self.mItems) do
		if item.caption == caption then
			table.remove(self.mItems, i);
			break;
		end
	end
end

function tabframe_base:activateItem(caption)
	for i, item in pairs(self.mItems) do
		if item.caption == caption then
			self:activateItemIndex(i);
			break;
		end
	end
end

function tabframe_base:activateItemIndex(index)
	local item = self.mItems[index];
	if item.frame ~= nil and item.frame ~= self.mClientFrame then
		self:setFrameActive(item.frame);
	end
	if item.callback ~= nil then
		item.callback(self);
	end
	self.mClientFrame:onDraw();
end

function tabframe_base:setFrameActive(frame)
	local width, height = self:getSize();
	if frame ~= nil and frame ~= self.mClientFrame then
		frame_base.removeChild(self, self.mClientFrame);
		self.mClientFrame = frame;
		frame_base.addChild(self, self.mClientFrame);
		self:setBackground(colors.black);
		self:fill(1, 2, width, height - 1, ' ');
		self:setBackground(colors.lightGray);
		self.mClientFrame:setRegion(1, 2, width, height - 1);
	end
	self.mClientFrame:onDraw();
end

function tabframe_base:drawTabItems()
	local width = self:getWidth();
	local offset = math.floor(self.mCaptionSpacing/2 + 0.5);

	local oldbg = self:setBackground(colors.gray);
	self:fill(1, 1, width, 1, ' ');
	self:setBackground(oldbg);

	for _, item in pairs(self.mItems) do
		local caption = item.caption; --string.sub(item.caption, 1, item.width);
		local x = math.floor( (item.width - string.len(caption)) / 2 + 0.5 );
		caption = string.rep(" ", x) .. caption .. string.rep(" ", item.width - x - string.len(caption));
		self:set(offset, 1, caption);
		offset = offset + item.width + self.mCaptionSpacing;
	end
end

function tabframe_base:onResize()
	frame_base.onResize(self);

	local width, height = self:getSize();

	self.mClientFrame:setRegion(1, 2, width, height - 1);
end

function tabframe_base:onDraw()
	frame_base.onDraw(self);
	self:drawTabItems();
end

function tabframe_base:addChild(child)
	self.mClientFrame:addChild(child);
end

function tabframe_base:removeChild(child)
	self.mClientFrame:removeChild(child);
end

function tabframe_base:onTouch(x, y, button, playerName)
	frame_base.onTouch(self, x, y, button, playerName);
	if y ~= 1 then return; end

	local offset = math.floor(self.mCaptionSpacing/2 + 0.5);

	for i, item in pairs(self.mItems) do
		if x >= offset and x <= offset + item.width then
			self:activateItemIndex(i);
			break;
		end
		offset = offset + item.width + self.mCaptionSpacing;
	end
end

return tabframe_base;
