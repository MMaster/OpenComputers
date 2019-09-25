local oop = require("oop")
local frame_base = require("libGUI/frame")
local colors = require("libGUI/colors")

local bar_base = {
	mPercentage = 0,
	mBarPalette = nil,
	mBarBackgroundColor = colors.gray,
	mBorderColor = colors.lightGray,
	mBorderWidth = 1,
	mHasChanged = true
}
oop.inherit(bar_base, frame_base)

function bar_base:construct()
	frame_base.construct(self)
	self.mBarPalette = {{1, colors.green}}
end

function bar_base:setBarPalette(palette)
	self.mHasChanged = true
	self.mBarPalette = palette
end

function bar_base:setPercentage(percentage, redraw)
	self.mHasChanged = math.floor(8 * (math.max(self.mHeight, self.mWidth) - 2 * self.mBorderWidth) * math.min(1, math.max(0, self:getTranslatedPercentage(self.mPercentage))) + 0.5) ~= math.floor(8 * (math.max(self.mHeight, self.mWidth) - 2 * self.mBorderWidth) * math.min(1, math.max(0, self:getTranslatedPercentage(percentage))) + 0.5)
	self.mPercentage = percentage
	if redraw == nil or redraw then
		self:drawBar()
	end
end

function bar_base:setBorderWidth(width)
	self.mHasChanged = self.mBorderWidth ~= width
	self.mBorderWidth = width
end

function bar_base:getBarColor()
	local barColor = self.mBarPalette[#self.mBarPalette][2]

	for _, v in pairs(self.mBarPalette) do
		if v[1] >= self.mPercentage then
			barColor = v[2]
			break
		end
	end

	return barColor or colors.green
end

function bar_base:getTranslatedPercentage(percentage)
	return percentage or self.mPercentage
end

function bar_base:drawBarVertical()
	local barColor = self:getBarColor()
	local width, height = self:getSize()
	local barHeightReal = (height - 2 * self.mBorderWidth) * math.min(1, math.max(0, self:getTranslatedPercentage()))
	local barHeight = math.floor(barHeightReal)
	local barSubHeight = math.floor(8 * (barHeightReal - barHeight) + 0.5)
	local barSubBlocks = { '▁▏', '▂', '▃', '▄', '▅', '▆', '▇'}

	if barSubHeight > 7 then
		barSubHeight = 0
		barHeight = barHeight + 1
	end

	self:setBackground(self.mBarBackgroundColor)
	self:fill(1 + self.mBorderWidth, 1 + self.mBorderWidth, width - 2 * self.mBorderWidth, height - 2 * self.mBorderWidth - barHeight, ' ')
	if barSubHeight > 0 then
		self:setForeground(barColor)
		self:fill(1 + self.mBorderWidth, height - barHeight - self.mBorderWidth, width - 2 * self.mBorderWidth, 1, barSubBlocks[barSubHeight])
	end
	self:setBackground(barColor)
	self:fill(1 + self.mBorderWidth, 1 + height - barHeight - self.mBorderWidth, width - 2 * self.mBorderWidth, barHeight, ' ')
end

function bar_base:drawBarHorizontal()
	local barColor = self:getBarColor()
	local width, height = self:getSize()
	local barWidthReal = (width - 2 * self.mBorderWidth) * math.min(1, math.max(0, self:getTranslatedPercentage()))
	local barWidth = math.floor(barWidthReal)
	local barSubWidth = math.floor(8 * (barWidthReal - barWidth) + 0.5)
	local barSubBlocks = { '▏', '▎', '▍', '▌', '▋', '▊', '▉'}

	if barSubWidth > 7 then
		barSubWidth = 0
		barWidth = barWidth + 1
	end


	self:setBackground(self.mBarBackgroundColor)
	self:fill(1 + self.mBorderWidth + barWidth, 1 + self.mBorderWidth, width - 2 * self.mBorderWidth - barWidth, height - 2 * self.mBorderWidth, ' ')
	if barSubWidth > 0 then
		self:setForeground(barColor)
		self:fill(1 + self.mBorderWidth + barWidth, 1 + self.mBorderWidth, 1, height - 2 * self.mBorderWidth, barSubBlocks[barSubWidth])
	end
	self:setBackground(barColor)
	self:fill(1 + self.mBorderWidth, 1 + self.mBorderWidth, barWidth, height - 2 * self.mBorderWidth, ' ')
end

function bar_base:drawBar()
	if self:getWidth() >= self:getHeight() then
		self:drawBarHorizontal()
	else
		self:drawBarVertical()
	end
end

function bar_base:onDraw(allowPartial)
	frame_base.onDraw(self, allowPartial)

	if not allowPartial or self.mHasChanged then
		local width, height = self:getSize()
		if self.mBorderWidth > 0 then
			self:setBackground(self.mBorderColor)
			self:fill(1, 1, width, height, ' ')
		end

		self:drawBar()
		self.mHasChanged = false
	end
end

return bar_base
