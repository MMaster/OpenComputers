local oop = require("oop");
local frame_base = require("libGUI/frame");

local label_base = {
	mText = nil,
	mVerticalAlignment = "middle",
	mHorizontalAlignment = "left",
	mLabelOffsetX = 0,
	mLabelOffsetY = 0
};
oop.inherit(label_base, frame_base);

function label_base:construct(label, alignment)
	frame_base.construct(self);
	if label ~= nil then
		self:setSize(string.len(label), 1);
	end
	if alignment ~= nil then
		self.mHorizontalAlignment = alignment;
	end
	self:setText(label, false);
end

function label_base:setText(label, redraw)
	self.mText = label;
	self:recalculateOffset();
	if redraw == nil or redraw then
		self:onDraw();
	end
end

function label_base:setTextAlignment(alignment)
	self.mHorizontalAlignment = alignment;
	self:recalculateOffset();
end

function label_base:setVerticalAlignment(alignment)
	self.mVerticalAlignment = alignment;
	self:recalculateOffset();
end

function label_base:onDraw()
	frame_base.onDraw(self);
	local width, height = self:getSize();
	
	self:fill(1, 1, width, height, ' ');
	if self.mText ~= nil and string.len(self.mText) > 0 then
		self:set(1 + self.mLabelOffsetX, 1 + self.mLabelOffsetY, self.mText);
	end
end

function label_base:recalculateOffset()
	local width, height = self:getSize();
	
	if self.mText ~= nil and string.len(self.mText) > 0 then
		if self.mHorizontalAlignment == "left" then
			self.mLabelOffsetX = 0;
		elseif self.mHorizontalAlignment == "center" then
			self.mLabelOffsetX = math.floor( (width - string.len(self.mText)) / 2);
		elseif self.mHorizontalAlignment == "right" then
			self.mLabelOffsetX = width - string.len(self.mText);
		end
		
		if self.mVerticalAlignment == "top" then
			self.mLabelOffsetY = 0;
		elseif self.mVerticalAlignment == "middle" then
			self.mLabelOffsetY = math.floor(height/2);
		elseif self.mVerticalAlignment == "bottom" then
			self.mLabelOffsetY = height - 1;
		end
	end
end

function label_base:onResize()
	frame_base.onResize(self);
	self:recalculateOffset();
end

return label_base;
