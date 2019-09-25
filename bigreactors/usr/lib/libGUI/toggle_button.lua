local oop = require("oop")
local label_base = require("libGUI/label")
local colors = require("libGUI/colors")

local toggle_button_base = {
	mInactiveBackground = colors.red,
	mInactiveForeground = colors.white,
	mActiveBackground = colors.green,
	mActiveForeground = colors.black,

	mToggleState = false
}
oop.inherit(toggle_button_base, label_base)

function toggle_button_base:construct(label, alignment)
	label_base.construct(self, label, alignment)
end

function toggle_button_base:setInactiveBackground(background)
	local oldBackground = self.mInactiveBackground
	self.mInactiveBackground = background
	return oldBackground
end

function toggle_button_base:getInactiveBackground()
	return self.mInactiveBackground
end

function toggle_button_base:setInactiveForeground(foreground)
	local oldForeground = self.mInactiveForeground
	self.mInactiveForeground = foreground
	return oldForeground
end

function toggle_button_base:getInactiveForeground()
	return self.mInactiveForeground
end

function toggle_button_base:setActiveBackground(background)
	local oldBackground = self.mActiveBackground
	self.mActiveBackground = background
	return oldBackground
end

function toggle_button_base:getActiveBackground()
	return self.mActiveBackground
end

function toggle_button_base:setActiveForeground(foreground)
	local oldForeground = self.mActiveForeground
	self.mActiveForeground = foreground
	return oldForeground
end

function toggle_button_base:getActiveForeground()
	return self.mActiveForeground
end

function toggle_button_base:getToggleState()
	return self.mToggleState
end

function toggle_button_base:onDraw(allowpartial)
	local toggleState = self:getToggleState()
	if toggleState then
		self:setBackground(self:getActiveBackground())
		self:setForeground(self:getActiveForeground())
	else
		self:setBackground(self:getInactiveBackground())
		self:setForeground(self:getInactiveForeground())
	end

	label_base.onDraw(self, allowpartial and toggleState == self.mToggleState)
	self.mToggleState = toggleState
end

function toggle_button_base:onTouch()
	label_base.onTouch(self)

	self.mToggleState = not self.mToggleState

	if self.onStateChange then
		self:onStateChange()
	end

	self:onDraw()
end

return toggle_button_base
