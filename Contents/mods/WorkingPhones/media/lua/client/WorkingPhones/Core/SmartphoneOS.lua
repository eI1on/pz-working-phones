local AppRegistry = require("WorkingPhones/Core/PhoneAppRegistry")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local PhoneUtils = require("WorkingPhones/Core/PhoneUtils")
local WallpaperRegistry = require("WorkingPhones/Registries/SmartphoneWallpaperRegistry")

local SmartphoneOS = {}

local NAV_HEIGHT = 38
local APP_FOOTER_HEIGHT = 22
local STATUS_HEIGHT = 20
local MAX_PAGES = 5

local LIGHT_COLORS = {
	bg = { r = 0.95, g = 0.96, b = 0.98, a = 1 },
	surface = { r = 1, g = 1, b = 1, a = 0.88 },
	surfaceDim = { r = 0.9, g = 0.92, b = 0.95, a = 0.75 },
	fg = { r = 0.07, g = 0.08, b = 0.1, a = 1 },
	dim = { r = 0.34, g = 0.38, b = 0.44, a = 1 },
	accent = { r = 0.11, g = 0.43, b = 0.86, a = 1 },
	border = { r = 0.68, g = 0.72, b = 0.78, a = 1 },
	nav = { r = 0.98, g = 0.99, b = 1, a = 0.92 },
}

local DARK_COLORS = {
	bg = { r = 0.04, g = 0.045, b = 0.055, a = 1 },
	surface = { r = 0.1, g = 0.11, b = 0.13, a = 0.88 },
	surfaceDim = { r = 0.16, g = 0.17, b = 0.2, a = 0.74 },
	fg = { r = 0.94, g = 0.96, b = 0.98, a = 1 },
	dim = { r = 0.56, g = 0.61, b = 0.68, a = 1 },
	accent = { r = 0.2, g = 0.56, b = 0.96, a = 1 },
	border = { r = 0.28, g = 0.31, b = 0.35, a = 1 },
	nav = { r = 0.03, g = 0.035, b = 0.045, a = 0.92 },
}

local textureCache = {}

local function color(r, g, b, a)
	return { r = r, g = g, b = b, a = a or 1 }
end

local function copyColor(src, alpha)
	return { r = src.r, g = src.g, b = src.b, a = alpha or src.a or 1 }
end

local function texture(path)
	if not path or path == "" then
		return nil
	end
	if textureCache[path] == nil then
		textureCache[path] = getTexture(path) or false
	end
	return textureCache[path] ~= false and textureCache[path] or nil
end

local function textWidth(text, font)
	local tm = getTextManager()
	return tm and tm:MeasureStringX(font or UIFont.Small, tostring(text or "")) or 0
end

local function pointIn(x, y, rect)
	return rect and x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function pageCount(total, perPage)
	local count = math.max(1, math.ceil((total or 0) / math.max(1, perPage)))
	return math.min(MAX_PAGES, count)
end

local function wallpaperById(id, os)
	local definition = os and os.definition or nil
	return WallpaperRegistry.get(id, definition) or WallpaperRegistry.first(definition) or {
		id = "fallback",
		kind = "color",
		r = 0.05,
		g = 0.06,
		b = 0.09,
	}
end

local smartData

local function wallpaperLuminance(os)
	local wp = wallpaperById(smartData(os).wallpaper, os)
	return wp.r * 0.299 + wp.g * 0.587 + wp.b * 0.114
end

local function homeTextColor(os, dim)
	local lum = wallpaperLuminance(os)
	local lightText = lum < 0.42
	if lightText then
		return dim and color(0.82, 0.86, 0.9, 0.9) or color(1, 1, 1, 1)
	end
	return dim and color(0.18, 0.22, 0.28, 0.9) or color(0.03, 0.04, 0.05, 1)
end

local function clampIndex(index, count)
	if count <= 0 then
		return 1
	end
	return math.max(1, math.min(count, index or 1))
end

smartData = function(os)
	local data = os.instance.data
	data.smartphone = data.smartphone or {}
	local smart = data.smartphone
	smart.themeMode = smart.themeMode or "dark"
	smart.wallpaper = smart.wallpaper or "midnight"
	if not WallpaperRegistry.get(smart.wallpaper, os.definition) then
		local firstWallpaper = WallpaperRegistry.first(os.definition)
		smart.wallpaper = firstWallpaper and firstWallpaper.id or "midnight"
	end
	smart.gridColumns = tonumber(smart.gridColumns) or 4
	if smart.gridColumns ~= 5 then
		smart.gridColumns = 4
	end
	smart.homeOrder = smart.homeOrder or {}
	if #smart.homeOrder == 0 then
		for i = 1, #os.apps do
			table.insert(smart.homeOrder, os.apps[i].id)
		end
	else
		for i = 1, #os.apps do
			local exists = false
			for j = 1, #smart.homeOrder do
				if smart.homeOrder[j] == os.apps[i].id then
					exists = true
					break
				end
			end
			if not exists then
				table.insert(smart.homeOrder, os.apps[i].id)
			end
		end
	end
	smart.widgets = {
		{ id = "clock",  type = "clock",  page = 1, x = 1, y = 1, w = 2, h = 1 },
		{ id = "status", type = "status", page = 1, x = 3, y = 1, w = 2, h = 1 },
	}
	smart.selectedHomeIndex = clampIndex(tonumber(smart.selectedHomeIndex) or 1, #smart.homeOrder)
	smart.selectedDrawerIndex = clampIndex(tonumber(smart.selectedDrawerIndex) or 1, #os.apps)
	smart.homePage = tonumber(smart.homePage) or 1
	smart.drawerPage = tonumber(smart.drawerPage) or 1
	smart.rearrangeApps = smart.rearrangeApps or false
	smart.moveWidgets = false
	return smart
end

local function colors(os)
	local smart = smartData(os)
	return smart.themeMode == "light" and LIGHT_COLORS or DARK_COLORS
end

local function setDisplayColors(os, display)
	local c = colors(os)
	display.colors = {
		mode = "color",
		bg = c.bg,
		fg = c.fg,
		dim = c.dim,
		accent = c.accent,
		border = c.border,
	}
	display.theme = display.colors
	display.statusBarHeight = STATUS_HEIGHT
	display.footerHeight = APP_FOOTER_HEIGHT
	display.softFooterHeight = APP_FOOTER_HEIGHT
	display.navBarHeight = NAV_HEIGHT
	display.contentY = display.y + STATUS_HEIGHT + display.headerHeight + 4
	display.contentBottom = display.y + display.height - NAV_HEIGHT - APP_FOOTER_HEIGHT - 4
	display.contentX = display.x + 8
	display.contentRight = display.x + display.width - 8
end

local function drawRect(display, x, y, w, h, c)
	display.panel:drawRect(display.x + x, display.y + y, w, h, c.a or 1, c.r, c.g, c.b)
end

local function drawBorder(display, x, y, w, h, c)
	display.panel:drawRectBorder(display.x + x, display.y + y, w, h, c.a or 1, c.r, c.g, c.b)
end

local function drawText(display, text, x, y, c, font)
	display.panel:drawText(tostring(text or ""), display.x + x, display.y + y, c.r, c.g, c.b, c.a or 1,
		font or UIFont.Small)
end

local function drawCentered(display, text, x, w, y, c, font)
	drawText(display, text, x + math.floor((w - textWidth(text, font)) / 2), y, c, font)
end

local function drawWallpaper(os, display)
	local c = colors(os)
	local wp = wallpaperById(smartData(os).wallpaper, os)
	local wpTexture = wp.kind == "texture" and texture(wp.texture) or nil
	if wpTexture then
		display.panel:drawTextureScaled(wpTexture, display.x, display.y, display.width, display.height, 1, 1, 1, 1)
		drawRect(display, 0, 0, display.width, display.height, color(0, 0, 0, 0.18))
	else
		drawRect(display, 0, 0, display.width, display.height, color(wp.r, wp.g, wp.b, 1))
		drawRect(display, 0, 0, display.width, math.floor(display.height * 0.38),
			color(math.min(1, wp.r + 0.08), math.min(1, wp.g + 0.08), math.min(1, wp.b + 0.08), 0.42))
		drawRect(display, 0, display.height - math.floor(display.height * 0.35), display.width,
			math.floor(display.height * 0.35),
			color(math.max(0, wp.r - 0.035), math.max(0, wp.g - 0.035), math.max(0, wp.b - 0.035), 0.34))
	end
	drawBorder(display, 0, 0, display.width, display.height, c.border)
end

local function statusBarSurface(os)
	local smart = smartData(os)
	if smart.themeMode == "light" then
		return color(1, 1, 1, 0.94), color(0.06, 0.07, 0.08, 1), color(0.32, 0.36, 0.42, 1)
	end
	return color(0, 0, 0, 0.82), color(1, 1, 1, 1), color(0.72, 0.76, 0.82, 1)
end

local function drawSmartStatus(os, display)
	local bg, fg, dim = statusBarSurface(os)
	local gt = getGameTime()
	local clock = string.format("%02d:%02d", gt:getHour(), gt:getMinutes())
	drawRect(display, 0, 0, display.width, STATUS_HEIGHT, bg)
	drawText(display, clock, 12, 3, fg)

	local signal = os.instance.signalStrength or 4
	local sx = display.width - 70
	for i = 1, 5 do
		local h = 3 + i * 2
		local bar = i <= signal and fg or dim
		drawRect(display, sx + (i - 1) * 5, STATUS_HEIGHT - h - 4, 3, h, bar)
	end

	local battery = os.instance.hardware and os.instance.hardware.battery or 1
	local bx = display.width - 38
	drawBorder(display, bx, 6, 25, 9, fg)
	drawRect(display, bx + 25, 9, 2, 3, fg)
	drawRect(display, bx + 2, 8, math.floor(21 * math.max(0, math.min(1, battery))), 5, fg)
end

local function appById(os, appId)
	for i = 1, #os.apps do
		if os.apps[i].id == appId then
			return os.apps[i]
		end
	end
	return nil
end

local function appIconPath(os, app)
	local meta = AppRegistry.getMetadata(app.id)
	if meta and meta.smartphoneIcon then
		return meta.smartphoneIcon
	end
	return app.smartphoneIcon
end

local function drawAppIcon(os, display, app, rect, selected, alpha)
	local c = colors(os)
	local iconSize = rect.icon
	local iconX = rect.x + math.floor((rect.w - iconSize) / 2)
	local iconY = rect.y + 4
	local bg = selected and copyColor(c.accent, 0.34) or color(0, 0, 0, 0.18)
	drawRect(display, rect.x + 4, rect.y + 1, rect.w - 8, rect.h - 3, bg)
	if selected then
		drawBorder(display, rect.x + 4, rect.y + 1, rect.w - 8, rect.h - 3, c.accent)
	end

	local tex = texture(appIconPath(os, app))
	if tex then
		display.panel:drawTextureScaledAspect(tex, display.x + iconX, display.y + iconY, iconSize, iconSize, alpha or 1,
			1, 1, 1)
	else
		drawRect(display, iconX, iconY, iconSize, iconSize, c.surface)
		drawCentered(display, string.sub(app.name or "?", 1, 1), iconX, iconSize, iconY + math.floor(iconSize / 2) - 7,
			c.fg, UIFont.Medium)
	end

	local name = display:ellipsize(app.name or app.id, rect.w - 8, UIFont.Small)
	drawCentered(display, name, rect.x + 4, rect.w - 8, rect.y + iconSize + 8,
		rect.homeIcon and homeTextColor(os, selected) or c.fg, UIFont.Small)
end

local function gridMetrics(display, columns, rows, top, bottom)
	local width = display.width - 16
	local height = math.max(1, bottom - top)
	local cellW = math.floor(width / columns)
	local cellH = math.floor(height / rows)
	local icon = columns == 5 and 36 or 44
	icon = math.min(icon, cellW - 12, cellH - 22)
	return {
		x = 8,
		y = top,
		w = width,
		h = height,
		columns = columns,
		rows = rows,
		cellW = cellW,
		cellH = cellH,
		icon = math.max(24, icon),
	}
end

local function gridRect(metrics, indexOnPage)
	local col = (indexOnPage - 1) % metrics.columns
	local row = math.floor((indexOnPage - 1) / metrics.columns)
	return {
		x = metrics.x + col * metrics.cellW,
		y = metrics.y + row * metrics.cellH,
		w = metrics.cellW,
		h = metrics.cellH,
		icon = metrics.icon,
	}
end

local function drawPageDots(os, display, currentPage, pages, y)
	local c = colors(os)
	local dotSize = 4
	local gap = 8
	local total = pages * dotSize + (pages - 1) * gap
	local startX = math.floor((display.width - total) / 2)
	for i = 1, pages do
		local dot = i == currentPage and c.fg or copyColor(c.dim, 0.7)
		drawRect(display, startX + (i - 1) * (dotSize + gap), y, dotSize, dotSize, dot)
	end
end

local function drawNav(os, display)
	local c = colors(os)
	local y = display.height - NAV_HEIGHT
	local section = math.floor(display.width / 3)
	os.smartNavRects = {
		{ id = "back",   x = 0,           y = y, w = section,                     h = NAV_HEIGHT },
		{ id = "home",   x = section,     y = y, w = section,                     h = NAV_HEIGHT },
		{ id = "drawer", x = section * 2, y = y, w = display.width - section * 2, h = NAV_HEIGHT },
	}
	drawRect(display, 0, y, display.width, NAV_HEIGHT, c.nav)
	drawBorder(display, 0, y, display.width, NAV_HEIGHT, copyColor(c.border, 0.55))

	local nav = os.smartNavRects
	drawCentered(display, "<", nav[1].x, nav[1].w, y + 10, c.fg, UIFont.Medium)
	drawBorder(display, nav[2].x + math.floor(nav[2].w / 2) - 7, y + 11, 14, 14, c.fg)
	drawRect(display, nav[3].x + math.floor(nav[3].w / 2) - 10, y + 11, 5, 5, c.fg)
	drawRect(display, nav[3].x + math.floor(nav[3].w / 2) - 2, y + 11, 5, 5, c.fg)
	drawRect(display, nav[3].x + math.floor(nav[3].w / 2) + 6, y + 11, 5, 5, c.fg)
	drawRect(display, nav[3].x + math.floor(nav[3].w / 2) - 10, y + 19, 5, 5, c.fg)
	drawRect(display, nav[3].x + math.floor(nav[3].w / 2) - 2, y + 19, 5, 5, c.fg)
	drawRect(display, nav[3].x + math.floor(nav[3].w / 2) + 6, y + 19, 5, 5, c.fg)
end

local function openSmartApp(os, appId)
	os.smartMode = "app"
	return os:openApp(appId)
end

local function appFromGrid(os, x, y, rects)
	for i = 1, #rects do
		if pointIn(x, y, rects[i]) then
			return rects[i]
		end
	end
	return nil
end

local function moveSelectedApp(os, delta)
	local smart = smartData(os)
	local order = smart.homeOrder
	if #order <= 1 then
		return true
	end
	local index = clampIndex(smart.selectedHomeIndex, #order)
	local target = clampIndex(index + delta, #order)
	if index ~= target then
		local value = order[index]
		table.remove(order, index)
		table.insert(order, target, value)
		smart.selectedHomeIndex = target
		smart.homePage = math.ceil(target / (smart.gridColumns * 5))
	end
	return true
end

local visibleWidgets

local function moveSelectionColumnFlow(index, action, rows, count)
	local target = index
	if action == "UP" then target = index - 1 end
	if action == "DOWN" then target = index + 1 end
	if action == "LEFT" then target = index - rows end
	if action == "RIGHT" then target = index + rows end
	return clampIndex(target, count)
end

local function drawWidget(os, display, widget, rect, selected)
	local c = colors(os)
	drawRect(display, rect.x, rect.y, rect.w, rect.h,
		selected and copyColor(c.accent, 0.34) or copyColor(c.surface, 0.78))
	drawBorder(display, rect.x, rect.y, rect.w, rect.h, selected and c.accent or copyColor(c.border, 0.7))
	local text = homeTextColor(os, false)
	local dim = homeTextColor(os, true)
	if widget.type == "clock" or widget.type == "status" then
		text = c.fg
		dim = c.dim
	end
	if widget.type == "clock" then
		local gt = getGameTime()
		local timeText = string.format("%02d:%02d", gt:getHour(), gt:getMinutes())
		drawText(display, timeText, rect.x + 8, rect.y + 7, text, UIFont.Large)
		drawText(display, PhoneUtils.gameDateTime(), rect.x + 10, rect.y + 33, dim, UIFont.Small)
	elseif widget.type == "status" then
		drawText(display, os.instance.displayName or I18N.get("Phone"), rect.x + 8, rect.y + 8, text, UIFont.Small)
		drawText(display, I18N.get("MyNumberLabel", tostring(os.instance.number or "")), rect.x + 8, rect.y + 27, dim,
			UIFont.Small)
	else
		drawText(display, I18N.get("Widget"), rect.x + 8, rect.y + 18, text, UIFont.Small)
	end
end

local function widgetRect(display, widget)
	local columns = 4
	local cellW = math.floor((display.width - 20) / columns)
	local x = 10 + (math.max(1, widget.x) - 1) * cellW
	local y = STATUS_HEIGHT + 11 + (math.max(1, widget.y) - 1) * 58
	local w = math.max(cellW - 6, cellW * math.max(1, widget.w) - 6)
	local h = 50 * math.max(1, widget.h)
	return { x = x, y = y, w = math.min(w, display.width - x - 10), h = h }
end

visibleWidgets = function(os, page)
	local smart = smartData(os)
	local widgets = {}
	for i = 1, #smart.widgets do
		if (tonumber(smart.widgets[i].page) or 1) == page then
			table.insert(widgets, smart.widgets[i])
		end
	end
	return widgets
end

local function resetHome(os)
	local smart = smartData(os)
	smart.homeOrder = {}
	for i = 1, #os.apps do
		table.insert(smart.homeOrder, os.apps[i].id)
	end
	smart.widgets = {
		{ id = "clock",  type = "clock",  page = 1, x = 1, y = 1, w = 2, h = 1 },
		{ id = "status", type = "status", page = 1, x = 3, y = 1, w = 2, h = 1 },
	}
	smart.homePage = 1
	smart.selectedHomeIndex = 1
	smart.rearrangeApps = false
	smart.moveWidgets = false
end

local HOME_OPTIONS = {
	{ id = "drawer",       labelKey = "SmartOpenAppDrawer" },
	{ id = "rearrange",    labelKey = "SmartRearrangeApps" },
	{ id = "settings",     labelKey = "SmartHomeSettings" },
}

local function drawOptions(os, display)
	if not os.smartOptionsOpen then
		return
	end
	local c = colors(os)
	local w = display.width - 42
	local h = math.min(display.height - NAV_HEIGHT - 58, 30 + #HOME_OPTIONS * 24)
	local x = 21
	local y = STATUS_HEIGHT + 28
	drawRect(display, x, y, w, h, copyColor(c.surface, 0.96))
	drawBorder(display, x, y, w, h, c.accent)
	drawText(display, I18N.get("SmartHomeOptions"), x + 10, y + 8, c.fg, UIFont.Small)
	os.smartOptionRects = {}
	for i = 1, #HOME_OPTIONS do
		local rowY = y + 26 + (i - 1) * 24
		local selected = i == (os.smartOptionIndex or 1)
		if selected then
			drawRect(display, x + 6, rowY - 2, w - 12, 20, copyColor(c.accent, 0.28))
		end
		local label = I18N.get(HOME_OPTIONS[i].labelKey)
		local smart = smartData(os)
		if HOME_OPTIONS[i].id == "rearrange" then
			label = label .. ": " .. I18N.get(smart.rearrangeApps and "On" or "Off")
		end
		drawText(display, label, x + 12, rowY, selected and c.fg or c.dim, UIFont.Small)
		os.smartOptionRects[i] = { x = x + 6, y = rowY - 2, w = w - 12, h = 20, optionIndex = i }
	end
end

local function activateHomeOption(os, index)
	local option = HOME_OPTIONS[index or os.smartOptionIndex or 1]
	if not option then
		return false
	end
	local smart = smartData(os)
	if option.id == "drawer" then
		os.smartOptionsOpen = false
		os.smartMode = "drawer"
	elseif option.id == "rearrange" then
		smart.rearrangeApps = not smart.rearrangeApps
		smart.moveWidgets = false
	elseif option.id == "settings" then
		os.smartOptionsOpen = false
		openSmartApp(os, "settings")
	end
	return true
end

local drawHome

local function drawLock(os, display)
	local c = colors(os)
	local wp = wallpaperById(smartData(os).wallpaper, os)
	local wpTexture = wp.kind == "texture" and texture(wp.texture) or nil
	if wpTexture then
		display.panel:drawTextureScaled(wpTexture, display.x, display.y, display.width, display.height, 1, 1, 1, 1)
	else
		drawRect(display, 0, 0, display.width, display.height, color(wp.r, wp.g, wp.b, 1))
	end
	drawRect(display, 0, 0, display.width, display.height, color(0, 0, 0, 0.18))
	drawSmartStatus(os, display)
	local gt = getGameTime()
	local clock = string.format("%02d:%02d", gt:getHour(), gt:getMinutes())
	drawCentered(display, clock, 0, display.width, 110, c.fg, UIFont.Large)
	drawCentered(display, PhoneUtils.gameDateTime(), 0, display.width, 142, c.fg, UIFont.Small)
	drawCentered(display, I18N.get("SmartSwipeUp"), 0, display.width, display.height - 88, c.fg, UIFont.Small)
	drawCentered(display, "^", 0, display.width, display.height - 68, c.fg, UIFont.Medium)
	local handleW = 86
	drawRect(display, math.floor((display.width - handleW) / 2), display.height - 36, handleW, 4, copyColor(c.fg, 0.8))
end

local function startUnlock(os)
	os.smartMode = "unlocking"
	os.unlockStartedAt = getTimestampMs()
	return true
end

local function drawUnlocking(os, display)
	local now = getTimestampMs()
	if not os.unlockStartedAt then
		os.smartMode = "home"
		drawHome(os, display)
		return
	end
	local t = math.max(0, math.min(1, (now - os.unlockStartedAt) / 260))
	local eased = 1 - ((1 - t) * (1 - t) * (1 - t))
	if t >= 1 then
		os.smartMode = "home"
		os.unlockStartedAt = nil
		drawHome(os, display)
		return
	end
	drawWallpaper(os, display)
	drawSmartStatus(os, display)
	local c = colors(os)
	local offset = math.floor(-display.height * eased)
	local gt = getGameTime()
	local clock = string.format("%02d:%02d", gt:getHour(), gt:getMinutes())
	drawRect(display, 0, offset, display.width, display.height, color(0, 0, 0, 0.22 * (1 - t)))
	drawCentered(display, clock, 0, display.width, offset + 110, c.fg, UIFont.Large)
	drawCentered(display, PhoneUtils.gameDateTime(), 0, display.width, offset + 142, c.fg, UIFont.Small)
	drawCentered(display, I18N.get("SmartSwipeUp"), 0, display.width, offset + display.height - 88, c.fg, UIFont.Small)
end

drawHome = function(os, display)
	local smart = smartData(os)
	local c = colors(os)
	drawWallpaper(os, display)
	drawSmartStatus(os, display)

	local columns = smart.gridColumns
	local rows = 5
	local perPage = columns * rows
	local pages = pageCount(#smart.homeOrder, perPage)
	smart.homePage = math.max(1, math.min(pages, smart.homePage))
	local widgets = visibleWidgets(os, smart.homePage)
	local gridTop = STATUS_HEIGHT + 20
	if #widgets > 0 then
		gridTop = STATUS_HEIGHT + 112
	end
	local gridBottom = display.height - NAV_HEIGHT - APP_FOOTER_HEIGHT - 18
	local metrics = gridMetrics(display, columns, rows, gridTop, gridBottom)
	os.smartHomeRects = {}
	os.smartWidgetRects = {}

	for i = 1, #widgets do
		local rect = widgetRect(display, widgets[i])
		drawWidget(os, display, widgets[i], rect, smart.moveWidgets and i == (smart.selectedWidgetIndex or 1))
		rect.widgetIndex = i
		rect.widget = widgets[i]
		table.insert(os.smartWidgetRects, rect)
	end

	local first = (smart.homePage - 1) * perPage + 1
	local last = math.min(#smart.homeOrder, first + perPage - 1)
	for index = first, last do
		local app = appById(os, smart.homeOrder[index])
		if app then
			local rect = gridRect(metrics, index - first + 1)
			rect.appIndex = index
			rect.appId = app.id
			table.insert(os.smartHomeRects, rect)
			rect.homeIcon = true
			drawAppIcon(os, display, app, rect, index == smart.selectedHomeIndex)
		end
	end

	if smart.rearrangeApps then
		drawText(display, I18N.get("SmartRearrangeMode"), 12, STATUS_HEIGHT + 3, homeTextColor(os, false), UIFont.Small)
	end
	drawPageDots(os, display, smart.homePage, pages, display.height - NAV_HEIGHT - APP_FOOTER_HEIGHT - 11)
	display:drawFooter(I18N.get("SmartAppDrawer"), I18N.get("Options"))
	drawOptions(os, display)
	drawNav(os, display)
end

local function drawDrawer(os, display)
	local smart = smartData(os)
	local c = colors(os)
	drawWallpaper(os, display)
	drawSmartStatus(os, display)
	drawText(display, I18N.get("SmartAppDrawer"), 14, STATUS_HEIGHT + 12, homeTextColor(os, false), UIFont.Medium)

	local columns = smart.gridColumns
	local rows = 5
	local perPage = columns * rows
	local pages = pageCount(#os.apps, perPage)
	smart.drawerPage = math.max(1, math.min(pages, smart.drawerPage))
	local metrics = gridMetrics(display, columns, rows, STATUS_HEIGHT + 48, display.height - NAV_HEIGHT - APP_FOOTER_HEIGHT - 18)
	os.smartDrawerRects = {}
	local first = (smart.drawerPage - 1) * perPage + 1
	local last = math.min(#os.apps, first + perPage - 1)
	for index = first, last do
		local app = os.apps[index]
		local rect = gridRect(metrics, index - first + 1)
		rect.appIndex = index
		rect.appId = app.id
		rect.homeIcon = true
		table.insert(os.smartDrawerRects, rect)
		drawAppIcon(os, display, app, rect, index == smart.selectedDrawerIndex)
	end
	drawPageDots(os, display, smart.drawerPage, pages, display.height - NAV_HEIGHT - APP_FOOTER_HEIGHT - 11)
	display:drawFooter(I18N.get("SmartHomeOptions"), I18N.get("Back"))
	drawNav(os, display)
end

local function handleNav(os, x, y)
	local nav = os.smartNavRects or {}
	for i = 1, #nav do
		if pointIn(x, y, nav[i]) then
			if nav[i].id == "back" then
				if os.currentApp and os.currentApp.handleInput and os.currentApp:handleInput({ action = "BACK" }) then
					return true
				end
				return SmartphoneOS.back(os)
			elseif nav[i].id == "home" then
				return SmartphoneOS.home(os)
			elseif nav[i].id == "drawer" then
				if os.currentApp and os.currentApp.onClose then
					os.currentApp:onClose()
				end
				os.smartMode = "drawer"
				os.currentApp = nil
				os.stack = {}
				return true
			end
		end
	end
	return false
end

local function handleMouseDown(os, event)
	local smart = smartData(os)
	local x = event.displayX
	local y = event.displayY
	os.smartPointer = { startX = x, startY = y, x = x, y = y, moved = false }

	if os.smartMode == "lock" then
		return true
	end

	if handleNav(os, x, y) then
		return true
	end

	if os.smartOptionsOpen then
		for i = 1, #(os.smartOptionRects or {}) do
			if pointIn(x, y, os.smartOptionRects[i]) then
				os.smartOptionIndex = i
				return activateHomeOption(os, i)
			end
		end
		os.smartOptionsOpen = false
		return true
	end

	if os.smartMode == "home" then
		local rect = appFromGrid(os, x, y, os.smartHomeRects or {})
		if rect then
			smart.selectedHomeIndex = rect.appIndex
			os.smartPointer.dragAppIndex = rect.appIndex
			os.smartPointer.dragAppId = rect.appId
			os.smartPointer.dragMode = true
			return true
		end
	elseif os.smartMode == "drawer" then
		local rect = appFromGrid(os, x, y, os.smartDrawerRects or {})
		if rect then
			smart.selectedDrawerIndex = rect.appIndex
			return openSmartApp(os, rect.appId)
		end
	end

	return false
end

local function handleMouseMove(os, event)
	if not os.smartPointer then
		return false
	end
	os.smartPointer.x = event.displayX
	os.smartPointer.y = event.displayY
	if math.abs(os.smartPointer.x - os.smartPointer.startX) > 4 or math.abs(os.smartPointer.y - os.smartPointer.startY) > 4 then
		os.smartPointer.moved = true
	end
	return true
end

local function handleMouseUp(os, event)
	local pointer = os.smartPointer
	os.smartPointer = nil
	if not pointer then
		return false
	end
	local smart = smartData(os)
	local dx = event.displayX - pointer.startX
	local dy = event.displayY - pointer.startY
	if os.smartMode == "lock" and dy < -42 then
		return startUnlock(os)
	end
	if pointer.dragMode and pointer.dragAppIndex then
		local rect = appFromGrid(os, event.displayX, event.displayY, os.smartHomeRects or {})
		if pointer.moved and rect and rect.appIndex and rect.appIndex ~= pointer.dragAppIndex then
			local from = pointer.dragAppIndex
			local to = rect.appIndex
			local appId = smart.homeOrder[from]
			table.remove(smart.homeOrder, from)
			table.insert(smart.homeOrder, to, appId)
			smart.selectedHomeIndex = to
		elseif not pointer.moved and pointer.dragAppId then
			return openSmartApp(os, pointer.dragAppId)
		end
		return true
	end
	if os.smartMode == "home" and math.abs(dx) > 60 and math.abs(dx) > math.abs(dy) then
		local perPage = smart.gridColumns * 5
		local pages = pageCount(#smart.homeOrder, perPage)
		if dx < 0 then
			smart.homePage = math.min(pages, smart.homePage + 1)
		else
			smart.homePage = math.max(1, smart.homePage - 1)
		end
		smart.selectedHomeIndex = clampIndex((smart.homePage - 1) * perPage + 1, #smart.homeOrder)
		return true
	end
	if os.smartMode == "drawer" and math.abs(dx) > 60 and math.abs(dx) > math.abs(dy) then
		local perPage = smart.gridColumns * 5
		local pages = pageCount(#os.apps, perPage)
		if dx < 0 then
			smart.drawerPage = math.min(pages, smart.drawerPage + 1)
		else
			smart.drawerPage = math.max(1, smart.drawerPage - 1)
		end
		smart.selectedDrawerIndex = clampIndex((smart.drawerPage - 1) * perPage + 1, #os.apps)
		return true
	end
	return false
end

function SmartphoneOS.init(os)
	smartData(os)
	os.smartMode = "lock"
	os.smartOptionsOpen = false
	os.smartOptionIndex = 1
end

function SmartphoneOS.isSmartphone(os)
	return os and os.definition and os.definition.hardwareType == "smartphone"
end

function SmartphoneOS.refreshLayout(os)
	local smart = smartData(os)
	smart.selectedHomeIndex = clampIndex(smart.selectedHomeIndex, #smart.homeOrder)
	smart.selectedDrawerIndex = clampIndex(smart.selectedDrawerIndex, #os.apps)
end

function SmartphoneOS.home(os)
	if os.currentApp and os.currentApp.onClose then
		os.currentApp:onClose()
	end
	os.currentApp = nil
	os.stack = {}
	os.smartMode = "home"
	os.smartOptionsOpen = false
	return true
end

function SmartphoneOS.back(os)
	if os.currentApp then
		if os.currentApp.onClose then
			os.currentApp:onClose()
		end
		os.currentApp = nil
		os.stack = {}
		os.smartMode = "home"
		return true
	end
	if os.smartOptionsOpen then
		os.smartOptionsOpen = false
		return true
	end
	if os.smartMode == "drawer" then
		os.smartMode = "home"
		return true
	end
	return true
end

function SmartphoneOS.handleInput(os, event)
	local smart = smartData(os)
	if os.currentApp then
		if event.action == "MOUSE_DOWN" and event.displayX and event.displayY and event.displayY >= (os.lastSmartDisplayHeight or 0) - NAV_HEIGHT then
			return handleNav(os, event.displayX, event.displayY)
		end
		if os.currentApp.handleInput and os.currentApp:handleInput(event) then
			return true
		end
		if event.action == "BACK" then
			return SmartphoneOS.back(os)
		elseif event.action == "MENU" or event.action == "OK" and os.smartMode ~= "app" then
			return SmartphoneOS.home(os)
		end
		return false
	end

	if event.action == "MOUSE_DOWN" and event.displayX and event.displayY then
		return handleMouseDown(os, event)
	elseif event.action == "MOUSE_MOVE" and event.displayX and event.displayY then
		return handleMouseMove(os, event)
	elseif event.action == "MOUSE_UP" and event.displayX and event.displayY then
		return handleMouseUp(os, event)
	elseif event.action == "BACK" then
		return SmartphoneOS.back(os)
	elseif event.action == "MENU" then
		if os.smartMode == "home" then
			os.smartMode = "drawer"
		else
			os.smartMode = "home"
		end
		os.smartOptionsOpen = false
		return true
	elseif event.action == "RIGHT_SOFT" then
		if os.smartMode == "home" then
			os.smartOptionsOpen = not os.smartOptionsOpen
			return true
		end
		return SmartphoneOS.back(os)
	elseif event.action == "LEFT_SOFT" then
		if os.smartMode == "home" then
			os.smartMode = "drawer"
			return true
		end
		return SmartphoneOS.back(os)
	elseif event.action == "OK" then
		if os.smartMode == "lock" then
			return startUnlock(os)
		elseif os.smartOptionsOpen then
			return activateHomeOption(os, os.smartOptionIndex)
		elseif os.smartMode == "home" then
			local appId = smart.homeOrder[smart.selectedHomeIndex]
			return appId and openSmartApp(os, appId) or false
		elseif os.smartMode == "drawer" then
			local app = os.apps[smart.selectedDrawerIndex]
			return app and openSmartApp(os, app.id) or false
		end
	elseif event.action == "LEFT" or event.action == "RIGHT" or event.action == "UP" or event.action == "DOWN" then
		if os.smartMode == "lock" and event.action == "UP" then
			return startUnlock(os)
		end
		if os.smartOptionsOpen then
			local delta = event.action == "UP" and -1 or event.action == "DOWN" and 1 or 0
			os.smartOptionIndex = clampIndex((os.smartOptionIndex or 1) + delta, #HOME_OPTIONS)
			return true
		end
		if os.smartMode == "home" then
			if smart.rearrangeApps then
				local delta = 0
				if event.action == "LEFT" then delta = -1 end
				if event.action == "RIGHT" then delta = 1 end
				if event.action == "UP" then delta = -smart.gridColumns end
				if event.action == "DOWN" then delta = smart.gridColumns end
				return moveSelectedApp(os, delta)
			end
			smart.selectedHomeIndex = moveSelectionColumnFlow(smart.selectedHomeIndex, event.action, 5, #smart.homeOrder)
			local perPage = smart.gridColumns * 5
			smart.homePage = math.ceil(smart.selectedHomeIndex / perPage)
			return true
		elseif os.smartMode == "drawer" then
			smart.selectedDrawerIndex = moveSelectionColumnFlow(smart.selectedDrawerIndex, event.action, 5, #os.apps)
			local perPage = smart.gridColumns * 5
			smart.drawerPage = math.ceil(smart.selectedDrawerIndex / perPage)
			return true
		end
	end
	return false
end

function SmartphoneOS.render(os, display)
	setDisplayColors(os, display)
	os.lastSmartDisplayHeight = display.height
	os.lastSmartDisplayWidth = display.width
	if os.currentApp then
		os.smartMode = "app"
		os.currentApp:render(display)
		drawNav(os, display)
		return
	end

	if os.smartMode == "lock" then
		drawLock(os, display)
	elseif os.smartMode == "unlocking" then
		drawUnlocking(os, display)
	elseif os.smartMode == "drawer" then
		drawDrawer(os, display)
	else
		os.smartMode = "home"
		drawHome(os, display)
	end
end

function SmartphoneOS.wallpapers(os)
	return WallpaperRegistry.list(os and os.definition or nil)
end

function SmartphoneOS.wallpaper(id, os)
	return wallpaperById(id, os)
end

function SmartphoneOS.wallpaperLabel(wallpaper)
	return WallpaperRegistry.label(wallpaper)
end

function SmartphoneOS.colors(os)
	return colors(os)
end

function SmartphoneOS.resetHome(os)
	resetHome(os)
end

return SmartphoneOS
