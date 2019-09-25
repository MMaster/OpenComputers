local oop = require("oop")
local frame_base = require("libGUI/frame")
local colors = require("libGUI/colors")

local window_base = {
	mTitle = nil,
	mClientFrame = nil
}
oop.inherit(window_base, frame_base)

function window_base:construct(parent)
	frame_base.construct(self, parent)

	self.mClientFrame = frame_base()
	frame_base.addChild(self, self.mClientFrame)

	self:setForeground(colors.white)
	self:setBackground(colors.blue)
end

function window_base:setTitle(title)
	self.mTitle = title
	self:drawTitle()
end

function window_base:drawTitle()
	local width = self:getWidth()
	local title = self.mTitle or ""
	local title_X = math.floor((width - string.len(title)) / 2 + 0.5)

	local output_str = string.rep(" ", title_X) .. title .. string.rep(" ", width - string.len(title) - title_X)

	self:set(1, 1, output_str)
end

function window_base:onResize()
	frame_base.onResize(self)

	local width, height = self:getSize()

	self.mClientFrame:setRegion(2, 3, width - 2, height - 3)
end

function window_base:onDraw()
	frame_base.onDraw(self)
	self:drawTitle()
end

function window_base:addChild(child)
	self.mClientFrame:addChild(child)
end

function window_base:removeChild(child)
	self.mClientFrame:removeChild(child)
end

return window_base
