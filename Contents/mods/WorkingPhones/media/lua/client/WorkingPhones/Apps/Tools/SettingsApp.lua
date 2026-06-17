local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local SmartphoneOS = require("WorkingPhones/Core/SmartphoneOS")

local App = setmetatable({}, { __index = Base })
App.__index = App

local MAIN_ROWS = {
	{ id = "display", labelKey = "SmartDisplayTheme" },
	{ id = "grid", labelKey = "SmartGridSize" },
	{ id = "reset", labelKey = "SmartResetHome" },
}

local DISPLAY_ROWS = {
	{ id = "theme", labelKey = "SmartTheme" },
	{ id = "wallpaper", labelKey = "SmartWallpaper" },
}

local LAYOUT_ROWS = {
	{ id = "rearrange", labelKey = "SmartRearrangeApps" },
	{ id = "reset", labelKey = "SmartResetHome" },
}

local textureCache = {}

local function texture(path)
	if not path or path == "" then
		return nil
	end
	if textureCache[path] == nil then
		textureCache[path] = getTexture(path) or false
	end
	return textureCache[path] ~= false and textureCache[path] or nil
end

local function smartData(os)
	os.instance.data.smartphone = os.instance.data.smartphone or {}
	local smart = os.instance.data.smartphone
	smart.themeMode = smart.themeMode or "dark"
	smart.wallpaper = smart.wallpaper or "midnight"
	smart.gridColumns = tonumber(smart.gridColumns) or 4
	if smart.gridColumns ~= 5 then
		smart.gridColumns = 4
	end
	smart.widgets = smart.widgets or {}
	return smart
end

local function wallpaperIndex(os, id)
	local wallpapers = SmartphoneOS.wallpapers(os)
	for i = 1, #wallpapers do
		if wallpapers[i].id == id then
			return i
		end
	end
	return 1
end

local function selectedWallpaper(os)
	local wallpapers = SmartphoneOS.wallpapers(os)
	return wallpapers[wallpaperIndex(os, smartData(os).wallpaper)] or wallpapers[1]
end

local function drawHeader(display, text, colors)
	local headerY = display.y + display.statusBarHeight
	display.panel:drawRect(display.x, headerY, display.width, display.headerHeight, colors.surface.a or 1,
		colors.surface.r, colors.surface.g, colors.surface.b)
	display.panel:drawText(text, display.x + 10, headerY + 4, colors.fg.r, colors.fg.g, colors.fg.b,
		colors.fg.a or 1, UIFont.Small)
end

function App:new(os)
	local o = Base.new(self, os)
	o.id = "settings"
	o.name = I18N.app("settings")
	o.mode = "main"
	o.selected = 1
	o.displaySelected = 1
	o.layoutSelected = 1
	o.rowRects = {}
	o.previewRects = {}
	return o
end

function App:currentRows()
	if self.mode == "display" then
		return DISPLAY_ROWS, self.displaySelected
	elseif self.mode == "layout" then
		return LAYOUT_ROWS, self.layoutSelected
	end
	return MAIN_ROWS, self.selected
end

function App:setCurrentSelection(value)
	if self.mode == "display" then
		self.displaySelected = value
	elseif self.mode == "layout" then
		self.layoutSelected = value
	else
		self.selected = value
	end
end

function App:changeWallpaper(delta)
	local smart = smartData(self.os)
	local wallpapers = SmartphoneOS.wallpapers(self.os)
	if #wallpapers == 0 then return end
	local index = wallpaperIndex(self.os, smart.wallpaper) + delta
	if index < 1 then
		index = #wallpapers
	elseif index > #wallpapers then
		index = 1
	end
	smart.wallpaper = wallpapers[index].id
end

function App:activate(row)
	local smart = smartData(self.os)
	if row.id == "display" then
		self.mode = "display"
		self.displaySelected = 1
	elseif row.id == "layout" then
		self.mode = "layout"
		self.layoutSelected = 1
	elseif row.id == "theme" then
		smart.themeMode = smart.themeMode == "light" and "dark" or "light"
	elseif row.id == "wallpaper" then
		self:changeWallpaper(1)
	elseif row.id == "grid" then
		smart.gridColumns = smart.gridColumns == 4 and 5 or 4
	elseif row.id == "rearrange" then
		smart.rearrangeApps = not smart.rearrangeApps
		smart.moveWidgets = false
	elseif row.id == "reset" then
		SmartphoneOS.resetHome(self.os)
	end
	SmartphoneOS.refreshLayout(self.os)
end

function App:adjust(delta)
	local rows, selected = self:currentRows()
	local row = rows[selected]
	local smart = smartData(self.os)
	if not row then
		return
	end
	if row.id == "theme" then
		smart.themeMode = smart.themeMode == "light" and "dark" or "light"
	elseif row.id == "wallpaper" then
		self:changeWallpaper(delta)
	elseif row.id == "grid" then
		smart.gridColumns = smart.gridColumns == 4 and 5 or 4
	end
	SmartphoneOS.refreshLayout(self.os)
end

function App:handleSmartphoneInput(event)
	if event.action == "BACK" or event.action == "RIGHT_SOFT" then
		if self.mode ~= "main" then
			self.mode = "main"
			return true
		end
		return self.os:back()
	end
	local rows, selected = self:currentRows()
	if event.action == "UP" then
		self:setCurrentSelection(math.max(1, selected - 1))
		return true
	elseif event.action == "DOWN" then
		self:setCurrentSelection(math.min(#rows, selected + 1))
		return true
	elseif event.action == "LEFT" then
		self:adjust(-1)
		return true
	elseif event.action == "RIGHT" then
		self:adjust(1)
		return true
	elseif event.action == "OK" or event.action == "LEFT_SOFT" then
		self:activate(rows[selected])
		return true
	elseif event.action == "MOUSE_DOWN" and event.displayX and event.displayY then
		for i = 1, #self.previewRects do
			local rect = self.previewRects[i]
			if event.displayX >= rect.x and event.displayX <= rect.x + rect.w
				and event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
				if rect.delta then
					self:changeWallpaper(rect.delta)
				else
					smartData(self.os).wallpaper = rect.wallpaperId
				end
				return true
			end
		end
		for i = 1, #self.rowRects do
			local rect = self.rowRects[i]
			if event.displayX >= rect.x and event.displayX <= rect.x + rect.w
				and event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
				self:setCurrentSelection(rect.index)
				self:activate(rows[rect.index])
				return true
			end
		end
	end
	return false
end

function App:handleInput(event)
	if self.os.definition.hardwareType == "smartphone" then
		return self:handleSmartphoneInput(event)
	end
	if event.action == "OK" or event.action == "LEFT_SOFT" then
		return true
	end
	return Base.handleInput(self, event)
end

function App:valueFor(row)
	local smart = smartData(self.os)
	if row.id == "theme" then
		return I18N.get(smart.themeMode == "light" and "SmartLightTheme" or "SmartDarkTheme")
	elseif row.id == "wallpaper" then
		return I18N.get(selectedWallpaper(self.os).nameKey)
	elseif row.id == "grid" then
		return tostring(smart.gridColumns) .. "x5"
	elseif row.id == "rearrange" then
		return I18N.get(smart.rearrangeApps and "On" or "Off")
	end
	return ""
end

function App:renderWallpaperPreview(display)
	local smart = smartData(self.os)
	local colors = SmartphoneOS.colors(self.os)
	local wallpapers = SmartphoneOS.wallpapers(self.os)
	local selected = wallpaperIndex(self.os, smart.wallpaper)
	local center = wallpapers[selected]
	if not center then
		display:drawTextCentered(I18N.get("None"), display.contentY + 42, colors.dim, UIFont.Small)
		return
	end
	local previewW = math.floor(display.width / 3)
	local previewH = math.floor(previewW * 1.78)
	local previewX = display.x + math.floor((display.width - previewW) / 2)
	local previewY = display.y + display.statusBarHeight + display.headerHeight + 76
	local maxPreviewBottom = display.contentBottom - 52
	if previewY + previewH > maxPreviewBottom then
		previewH = math.max(72, maxPreviewBottom - previewY)
		previewW = math.floor(previewH / 1.78)
		previewX = display.x + math.floor((display.width - previewW) / 2)
	end
	display:fillRect(previewX, previewY, previewW, previewH, colors.surface)
	display:drawBorder(previewX, previewY, previewW, previewH, colors.accent)
	if center.kind == "texture" then
		local tex = texture(center.texture)
		if tex then
			display.panel:drawTextureScaled(tex, previewX + 4, previewY + 4, previewW - 8, previewH - 8, 1, 1, 1, 1)
		end
	else
		display.panel:drawRect(previewX + 4, previewY + 4, previewW - 8, previewH - 8, 1, center.r, center.g, center.b)
	end
	local arrowY = previewY + math.floor(previewH / 2) - 6
	local leftArrowX = previewX - 34
	local rightArrowX = previewX + previewW + 18
	display:drawText("<", leftArrowX, arrowY, colors.fg, UIFont.Medium)
	display:drawText(">", rightArrowX, arrowY, colors.fg, UIFont.Medium)
	self.previewRects[1] = { x = leftArrowX - display.x - 8, y = previewY - display.y, w = 34, h = previewH, delta = -1 }
	self.previewRects[2] = { x = rightArrowX - display.x - 8, y = previewY - display.y, w = 34, h = previewH, delta = 1 }
	display:drawTextCentered(SmartphoneOS.wallpaperLabel(center), previewY + previewH + 6, colors.fg, UIFont.Small)

	local thumbSize = 22
	local gap = 5
	local maxThumbs = math.max(1, math.floor((display.width - 16 + gap) / (thumbSize + gap)))
	local firstThumb = math.max(1, selected - math.floor(maxThumbs / 2))
	local lastThumb = math.min(#wallpapers, firstThumb + maxThumbs - 1)
	firstThumb = math.max(1, lastThumb - maxThumbs + 1)
	local visibleThumbs = lastThumb - firstThumb + 1
	local total = visibleThumbs * thumbSize + (visibleThumbs - 1) * gap
	local startX = math.max(8, math.floor((display.width - total) / 2))
	local y = math.min(display.contentBottom - 34, previewY + previewH + 24)
	for i = firstThumb, lastThumb do
		local wp = wallpapers[i]
		local x = startX + (i - firstThumb) * (thumbSize + gap)
		if wp.kind == "texture" then
			local tex = texture(wp.texture)
			if tex then
				display.panel:drawTextureScaled(tex, display.x + x, y, thumbSize, thumbSize, 1, 1, 1, 1)
			else
				display.panel:drawRect(display.x + x, y, thumbSize, thumbSize, 1, wp.r, wp.g, wp.b)
			end
		else
			display.panel:drawRect(display.x + x, y, thumbSize, thumbSize, 1, wp.r, wp.g, wp.b)
		end
		local border = wp.id == smart.wallpaper and colors.accent or colors.border
		display.panel:drawRectBorder(display.x + x - 1, y - 1, thumbSize + 2, thumbSize + 2, border.a or 1, border.r, border.g, border.b)
		self.previewRects[#self.previewRects + 1] = { x = x, y = y - display.y, w = thumbSize, h = thumbSize, wallpaperId = wp.id }
	end
end

function App:renderRows(display, title, rows, selected)
	local colors = SmartphoneOS.colors(self.os)
	drawHeader(display, title, colors)
	local top = display.contentY
	local rowH = 30
	local right = display.contentRight - 4
	self.rowRects = {}
	for i = 1, #rows do
		local row = rows[i]
		local y = top + (i - 1) * rowH
		if y + rowH > display.contentBottom - 8 then
			break
		end
		if i == selected then
			display:fillRect(display.x + 8, y - 2, display.width - 16, rowH - 4, display.colors.accent)
		end
		local color = i == selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.fg
		display:drawText(I18N.get(row.labelKey), display.x + 14, y + 5, color)
		local value = self:valueFor(row)
		if value ~= "" then
			display:drawTextRight(value, right, y + 5, color)
		end
		self.rowRects[i] = { x = 0, y = y - display.y - 2, w = display.width, h = rowH, index = i }
	end
end

function App:renderSmartphone(display)
	display:clear()
	self.previewRects = {}
	local rows, selected = self:currentRows()
	local title = I18N.get("SmartHomeOptions")
	if self.mode == "display" then
		title = I18N.get("SmartDisplayTheme")
	elseif self.mode == "layout" then
		title = I18N.get("SmartHomeLayout")
	end
	self:renderRows(display, title, rows, selected)
	if self.mode == "display" then
		self:renderWallpaperPreview(display)
	end
	display:drawFooter(self.mode == "main" and I18N.get("Select") or I18N.get("Apply"), I18N.get("Back"))
end

function App:render(display)
	if self.os.definition.hardwareType == "smartphone" then
		self:renderSmartphone(display)
		return
	end
	display:clear()
	display:drawHeader(I18N.app("settings"))
	display:drawText(I18N.get("HardwareLabel", self.os.definition.hardwareType), display.x + 10, display.y + 42, display.colors.fg)
	display:drawText(I18N.get("ModeLabel", tostring(self.os.definition.inputMode)), display.x + 10, display.y + 66, display.colors.fg)
	display:drawText(I18N.get("VariantLabel", tostring(self.os.definition.variant and self.os.definition.variant.displayName or I18N.get("Default"))), display.x + 10, display.y + 90, display.colors.dim)
	display:drawFooter("", I18N.get("Back"))
end

return App
