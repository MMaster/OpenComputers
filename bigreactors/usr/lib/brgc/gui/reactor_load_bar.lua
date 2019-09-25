local oop = require("oop")
local frame_base = require("libGUI/frame")
local bar_base = require("libGUI/bar")
local colors = require("libGUI/colors")

local reactor_load_bar = {
	mPercentageOptimal = nil
}
oop.inherit(reactor_load_bar, bar_base)

function reactor_load_bar:construct()
	bar_base.construct(self)

	self:setBorderWidth(0)
	self:setBackground(colors.gray)
	self:setPercentageOptimal(self.mPercentageOptimal)
end

function reactor_load_bar:setPercentageOptimal(percentage)
	local newPalette

	if percentage == nil then
		newPalette = {
			{ math.huge, colors.green }
		}
	else
		newPalette = {
			{ percentage * 0.8, colors.blue },
			{ percentage * 0.9, colors.lightblue },
			{ percentage * 1.1, colors.green },
			{ percentage * 1.2, colors.purple },
			{ percentage * 1.3, colors.orange },
			{    math.huge    , colors.red }
		}
	end

	self.mPercentageOptimal = percentage
	self:setBarPalette(newPalette)
end

function reactor_load_bar:getPercentageOptimal()
	return self.mPercentageOptimal
end


return reactor_load_bar
