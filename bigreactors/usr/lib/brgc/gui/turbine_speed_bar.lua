local oop = require("oop")
local frame_base = require("libGUI/frame")
local bar_base = require("libGUI/bar")
local colors = require("libGUI/colors")

local turbine_speed_bar = {
	mPercentageOptimal = 1777/1850
}
oop.inherit(turbine_speed_bar, bar_base)

function turbine_speed_bar:construct()
	bar_base.construct(self)

	self:setBorderWidth(0)
	self:setBackground(colors.gray)
	self:setPercentageOptimal(self.mPercentageOptimal)
end

function turbine_speed_bar:setPercentageOptimal(percentage)
	local newPalette = {
		{  350 / 1850, colors.blue },
		{  750 / 1850, colors.lightblue },
		{ 1050 / 1850, colors.lime },
		{ 1600 / 1850, colors.cyan },
		{  percentage, colors.lime },
		{ 1800 / 1850, colors.green },
		{ 1850 / 1850, colors.yellow },
		{  math.huge , colors.red }
	}

	self.mPercentageOptimal = percentage
	self:setBarPalette(newPalette)
end

function turbine_speed_bar:getPercentageOptimal()
	return self.mPercentageOptimal
end

function turbine_speed_bar:getTranslatedPercentage(percentage)
	return percentage and (percentage * percentage) or self.mPercentage * self.mPercentage
end


return turbine_speed_bar
