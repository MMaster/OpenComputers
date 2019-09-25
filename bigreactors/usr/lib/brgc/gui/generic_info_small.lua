local oop = require("oop")
local frame_base = require("libGUI/frame")
local colors = require("libGUI/colors")


local generic_info_small = {
	mBar = nil,
	mMessage = nil,
	mOutputString = nil,
	mOutputStringLenMax = 11,
	mDisplayName = nil,
	mDisplayNameLenMax = 3,
	mHasChanged = true
}
oop.inherit(generic_info_small, frame_base)

function generic_info_small:construct()
	frame_base.construct(self)
end

function generic_info_small:updateInfo()
end

function generic_info_small:onDraw(allowPartial)
	self:updateInfo()
	frame_base.onDraw(self, allowPartial and not self.mHasChanged)

	if not allowPartial or self.mHasChanged then
		local height_center = math.floor(self:getHeight()/2+0.5)

		self:setForeground(colors.white);
		self:set(1, height_center, self.mDisplayName or string.rep("-", self.mDisplayNameLenMax))

		if self.mOutputString ~= nil then
			local ostr = string.rep(" ", 1 + self.mOutputStringLenMax - string.len(self.mOutputString)) .. string.sub(self.mOutputString, 1, self.mOutputStringLenMax)
			self:set(self:getWidth()-string.len(ostr)+1, height_center, ostr)
		end

		if self.mMessage then
			local messageSpace = math.max(0, self:getWidth() - self.mDisplayNameLenMax - self.mOutputStringLenMax - 2)
			if messageSpace > 0 then
				local message = string.sub(self.mMessage, 1, messageSpace)
				local x = self.mDisplayNameLenMax + math.floor((messageSpace - string.len(message))/2+0.5) + 1
				self:setForeground(colors.red)
				self:setBackground(colors.black)
				self:set(x, height_center, self.mMessage)
			end
		end
		self.mHasChanged = false;
	end
end

function generic_info_small:onResize()
	frame_base.onResize(self)
	local width = self:getWidth()

	if self.mBar ~= nil then
		if width > self.mDisplayNameLenMax + self.mOutputStringLenMax + 2 then
			self:addChild(self.mBar)
			self.mBar:setRegion(self.mDisplayNameLenMax + 2, 1, width - self.mDisplayNameLenMax - self.mOutputStringLenMax - 2, self:getHeight())
		else
			self:removeChild(self.mBar)
		end
	end
end

return generic_info_small
