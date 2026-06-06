local Themes = require("WorkingPhones/UI/Themes")

local Display = {}
Display.__index = Display

function Display:new(panel, rect, themeId)
	local o = setmetatable({}, self)
	o.panel = panel
	o.x = rect.x
	o.y = rect.y
	o.width = rect.width
	o.height = rect.height
	o.theme = Themes.get(themeId)
	o.colors = o.theme
	o.font = UIFont.Small
	o.statusBarHeight = 18
	o.headerHeight = 22
	o.footerHeight = 18
	o.scrollbarWidth = 7
	o.contentY = o.y + o.statusBarHeight + o.headerHeight + 4
	o.contentBottom = o.y + o.height - o.footerHeight - 4
	o.contentX = o.x + 4
	o.contentRight = o.x + o.width - 4
	return o
end

function Display:clear()
	self:fillRect(self.x, self.y, self.width, self.height, self.colors.bg)
	self:drawBorder(self.x, self.y, self.width, self.height, self.colors.border)
	self:drawStatusBar()
end

function Display:fillRect(x, y, w, h, color)
	self.panel:drawRect(x, y, w, h, color.a or 1, color.r or 1, color.g or 1, color.b or 1)
end

function Display:drawBorder(x, y, w, h, color)
	self.panel:drawRectBorder(x, y, w, h, color.a or 1, color.r or 1, color.g or 1, color.b or 1)
end

function Display:drawText(text, x, y, color, font)
	color = color or self.colors.fg
	self.panel:drawText(tostring(text or ""), x, y, color.r, color.g, color.b, color.a or 1, font or self.font)
end

function Display:drawTextRight(text, x, y, color, font)
	local tm = getTextManager()
	local w = tm and tm:MeasureStringX(font or self.font, tostring(text or "")) or 0
	self:drawText(text, x - w, y, color, font)
end

function Display:drawTextCentered(text, y, color, font, left, right)
	left = left or self.x
	right = right or (self.x + self.width)
	local w = self:measureText(text, font)
	self:drawText(text, left + math.floor((right - left - w) / 2), y, color, font)
end

function Display:ellipsize(text, maxWidth, font)
	text = tostring(text or "")
	if self:measureText(text, font) <= maxWidth then
		return text
	end
	while #text > 0 and self:measureText(text .. "...", font) > maxWidth do
		text = string.sub(text, 1, #text - 1)
	end
	return text .. "..."
end

function Display:drawStatusBar()
	local gt = getGameTime()
	local clock = string.format("%02d:%02d", gt:getHour(), gt:getMinutes())
	local y = self.y
	local barBg = self.colors.bg
	local barFg = self.colors.fg
	local barDim = self.colors.dim
	if self.colors.mode == "color" then
		local light = (self.colors.bg.r or 0) + (self.colors.bg.g or 0) + (self.colors.bg.b or 0) > 1.5
		barBg = light and { r = 1, g = 1, b = 1, a = 0.94 } or { r = 0, g = 0, b = 0, a = 0.82 }
		barFg = light and { r = 0.06, g = 0.07, b = 0.08, a = 1 } or { r = 1, g = 1, b = 1, a = 1 }
		barDim = light and { r = 0.32, g = 0.36, b = 0.42, a = 1 } or { r = 0.72, g = 0.76, b = 0.82, a = 1 }
	end
	self:fillRect(self.x, y, self.width, self.statusBarHeight, barBg)
	if self.colors.mode == "color" then
		self:drawText(clock, self.x + 12, y + 3, barFg)
	else
		self:drawText(clock, self.x + math.floor(self.width / 2) - 18, y + 2, barFg)
	end

	local signal = self.panel and self.panel.instance and self.panel.instance.signalStrength or 4
	local sx = self.colors.mode == "color" and (self.x + self.width - 70) or (self.x + 6)
	for i = 1, 5 do
		local h = 3 + i * 2
		local color = i <= signal and barFg or barDim
		self:fillRect(sx + (i - 1) * 5, y + self.statusBarHeight - h - 2, 3, h, color)
	end

	local battery = self.panel and self.panel.instance and self.panel.instance.hardware.battery or 1
	local bx = self.x + self.width - 36
	local by = y + 4
	self:drawBorder(bx, by, 26, 9, barFg)
	self:fillRect(bx + 26, by + 3, 2, 3, barFg)
	self:fillRect(bx + 2, by + 2, math.floor(22 * math.max(0, math.min(1, battery))), 5, barFg)
end

function Display:drawHeader(text)
	local y = self.y + self.statusBarHeight
	if self.colors.mode == "color" then
		self:fillRect(self.x, y, self.width, self.headerHeight, self.colors.accent)
		self:drawText(text, self.x + 6, y + 4, { r = 1, g = 1, b = 1, a = 1 })
	else
		self:fillRect(self.x, y, self.width, self.headerHeight, self.colors.fg)
		self:drawText(text, self.x + 6, y + 4, self.colors.bg)
	end
end

function Display:drawFooter(leftText, rightText)
	local footerHeight = self.softFooterHeight or self.footerHeight
	local navOffset = self.navBarHeight or 0
	local y = self.y + self.height - navOffset - footerHeight
	if self.colors.mode == "color" then
		self:fillRect(self.x, y, self.width, footerHeight, self.colors.bg)
		self:drawBorder(self.x, y, self.width, footerHeight, self.colors.border)
	else
		self:fillRect(self.x, y, self.width, footerHeight, self.colors.fg)
	end
	leftText = leftText or ""
	rightText = rightText or ""
	if self.navBarHeight and tostring(rightText) == tostring(getText("IGUI_WorkingPhones_Back")) then
		rightText = ""
	end
	local footerTextColor = self.colors.mode == "color" and self.colors.fg or self.colors.bg
	self:drawText(leftText, self.x + 6, y + 2, footerTextColor)
	if rightText ~= "" then
		self:drawTextRight(rightText, self.x + self.width - 6, y + 2, footerTextColor)
	end
end

function Display:getVisibleListMetrics(rowHeight, totalRows)
	rowHeight = rowHeight or 20
	local top = self.contentY
	local height = math.max(0, self.contentBottom - top)
	local visibleRows = math.max(1, math.floor(height / rowHeight))
	local hasScrollbar = totalRows and totalRows > visibleRows
	local right = hasScrollbar and (self.contentRight - self.scrollbarWidth - 3) or self.contentRight
	return top, visibleRows, right, hasScrollbar
end

function Display:drawScrollbar(totalRows, visibleRows, scrollOffset, top, bottom)
	if not totalRows or totalRows <= visibleRows then
		return
	end
	top = top or self.contentY
	bottom = bottom or self.contentBottom
	local trackX = self.x + self.width - self.scrollbarWidth - 3
	local trackH = math.max(1, bottom - top)
	self:drawBorder(trackX, top, self.scrollbarWidth, trackH, self.colors.dim)
	local thumbH = math.max(8, math.floor(trackH * (visibleRows / totalRows)))
	local maxOffset = math.max(1, totalRows - visibleRows)
	local travel = math.max(0, trackH - thumbH - 2)
	local thumbY = top + 1 + math.floor(travel * (scrollOffset or 0) / maxOffset)
	self:fillRect(trackX + 2, thumbY, self.scrollbarWidth - 4, thumbH, self.colors.fg)
end

function Display:measureText(text, font)
	local tm = getTextManager()
	return tm and tm:MeasureStringX(font or self.font, tostring(text or "")) or 0
end

return Display
