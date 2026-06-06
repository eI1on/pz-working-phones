local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local App = setmetatable({}, { __index = Base })
App.__index = App

local MONTH_LENGTHS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function isLeap(year) return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) end
local function monthLength(month, year) return month == 2 and isLeap(year) and 29 or MONTH_LENGTHS[month] end

local function gameDate()
	local gt = getGameTime()
	local month = (gt:getMonth() or 0) + 1
	local year = gt:getYear() or 1993
	local day = gt.getDayPlusOne and gt:getDayPlusOne() or gt:getDay() or 1
	return month, year, math.min(math.max(1, day), monthLength(month, year))
end

function App:new(os)
	local o = Base.new(self, os)
	o.id = "calendar"
	o.name = I18N.app("calendar")
	o.month, o.year, o.selectedDay = gameDate()
	o.optionsOpen = false
	o.optionIndex = 1
	o.options = { I18N.get("Today") }
	return o
end

function App:today()
	self.month, self.year, self.selectedDay = gameDate()
end

function App:changeMonth(delta)
	self.month = self.month + delta
	while self.month < 1 do
		self.month = self.month + 12; self.year = self.year - 1
	end
	while self.month > 12 do
		self.month = self.month - 12; self.year = self.year + 1
	end
	self.selectedDay = math.min(self.selectedDay, monthLength(self.month, self.year))
end

function App:firstWeekday()
	local y, m = self.year, self.month
	if m < 3 then
		m = m + 12; y = y - 1
	end
	local k, j = y % 100, math.floor(y / 100)
	local h = (1 + math.floor((13 * (m + 1)) / 5) + k + math.floor(k / 4) + math.floor(j / 4) + 5 * j) % 7
	return ((h + 5) % 7) + 1
end

function App:dayOrder()
	local days = {}
	local first, maxDay = self:firstWeekday(), monthLength(self.month, self.year)
	for day = 1, maxDay do
		local index = first + day - 2
		table.insert(days, {
			day = day,
			col = index % 7,
			row = math.floor(index / 7),
		})
	end
	table.sort(days, function(a, b)
		if a.col == b.col then return a.row < b.row end
		return a.col < b.col
	end)
	return days
end

function App:moveSelectedDay(action)
	local days = self:dayOrder()
	local selectedIndex = 1
	for i = 1, #days do
		if days[i].day == self.selectedDay then
			selectedIndex = i
			break
		end
	end
	local target = selectedIndex
	if action == "UP" then target = selectedIndex - 1 end
	if action == "DOWN" then target = selectedIndex + 1 end
	if action == "LEFT" then target = selectedIndex - 6 end
	if action == "RIGHT" then target = selectedIndex + 6 end
	target = math.max(1, math.min(#days, target))
	self.selectedDay = days[target].day
	return true
end

function App:handleInput(event)
	if self.optionsOpen then
		if event.action == "LEFT_SOFT" or event.action == "OK" then
			self:today(); self.optionsOpen = false; return true
		end
		if event.action == "RIGHT_SOFT" then
			self.optionsOpen = false; return true
		end
		return Base.handleInput(self, event)
	end
	if event.action == "LEFT_SOFT" then
		if self.os.definition.hardwareType == "smartphone" then
			self:today()
		else
			self.optionsOpen = true
		end
		return true
	end
	if self.os.definition.hardwareType == "smartphone" and event.action == "MOUSE_DOWN" and event.displayX and event.displayY then
		if self.prevRect and event.displayX >= self.prevRect.x and event.displayX <= self.prevRect.x + self.prevRect.w
			and event.displayY >= self.prevRect.y and event.displayY <= self.prevRect.y + self.prevRect.h then
			self:changeMonth(-1)
			return true
		end
		if self.nextRect and event.displayX >= self.nextRect.x and event.displayX <= self.nextRect.x + self.nextRect.w
			and event.displayY >= self.nextRect.y and event.displayY <= self.nextRect.y + self.nextRect.h then
			self:changeMonth(1)
			return true
		end
		for i = 1, #(self.dayRects or {}) do
			local rect = self.dayRects[i]
			if event.displayX >= rect.x and event.displayX <= rect.x + rect.w
				and event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
				self.selectedDay = rect.day
				return true
			end
		end
	end
	if event.action == "UP" or event.action == "DOWN" or event.action == "LEFT" or event.action == "RIGHT" then
		return self:moveSelectedDay(event.action)
	end
	if event.action == "OK" then
		self:today(); return true
	end
	return Base.handleInput(self, event)
end

function App:renderOptions(display)
	display:clear()
	display:drawHeader(I18N.get("CalendarOptions"))
	display:fillRect(display.x + 4, display.contentY, display.width - 8, 18, display.colors.accent)
	display:drawText(I18N.get("Today"), display.x + 10, display.contentY + 2, display.colors.bg)
	display:drawFooter(I18N.get("Select"), I18N.get("Back"))
end

function App:renderSmartphone(display)
	display:clear()
	local todayMonth, todayYear, todayDay = gameDate()
	local headerY = display.y + 34
	display:drawText(I18N.monthShort(self.month) .. " " .. tostring(self.year), display.x + 54, headerY,
		display.colors.fg, UIFont.Medium)
	display:fillRect(display.x + 14, headerY - 2, 28, 24, display.colors.bg)
	display:drawBorder(display.x + 14, headerY - 2, 28, 24, display.colors.border)
	display:drawText("<", display.x + 24, headerY + 2, display.colors.fg, UIFont.Medium)
	display:fillRect(display.x + display.width - 42, headerY - 2, 28, 24, display.colors.bg)
	display:drawBorder(display.x + display.width - 42, headerY - 2, 28, 24, display.colors.border)
	display:drawText(">", display.x + display.width - 32, headerY + 2, display.colors.fg, UIFont.Medium)
	self.prevRect = { x = 14, y = headerY - display.y - 2, w = 28, h = 24 }
	self.nextRect = { x = display.width - 42, y = headerY - display.y - 2, w = 28, h = 24 }
	local gridX = display.x + 12
	local gridY = display.y + 76
	local cellW = math.floor((display.width - 24) / 7)
	local cellH = math.floor((display.contentBottom - gridY - 8) / 7)
	self.dayRects = {}
	for i = 1, 7 do
		display:drawTextCentered(I18N.dayShort(i), gridY + 2, display.colors.dim, UIFont.Small, gridX + (i - 1) * cellW,
			gridX + i * cellW)
	end
	local first, maxDay = self:firstWeekday(), monthLength(self.month, self.year)
	for day = 1, maxDay do
		local index = first + day - 2
		local col, row = index % 7, math.floor(index / 7)
		local x, y = gridX + col * cellW, gridY + cellH + row * cellH
		local isSelected = day == self.selectedDay
		local isToday = day == todayDay and self.month == todayMonth and self.year == todayYear
		if isToday then
			display:fillRect(x + 3, y + 3, cellW - 6, cellH - 6, display.colors.accent)
		elseif isSelected then
			display:fillRect(x + 3, y + 3, cellW - 6, cellH - 6, display.colors.bg)
			display:drawBorder(x + 3, y + 3, cellW - 6, cellH - 6, display.colors.accent)
		end
		display:drawTextCentered(tostring(day), y + math.max(4, math.floor((cellH - 13) / 2)),
			isToday and { r = 1, g = 1, b = 1, a = 1 } or display.colors.fg, UIFont.Small, x, x + cellW)
		table.insert(self.dayRects, { x = x - display.x, y = y - display.y, w = cellW, h = cellH, day = day })
	end
	display:drawFooter(I18N.get("Today"), I18N.get("Back"))
end

function App:render(display)
	if self.optionsOpen then return self:renderOptions(display) end
	if self.os.definition.hardwareType == "smartphone" then
		return self:renderSmartphone(display)
	end
	display:clear()
	display:drawHeader("< " .. I18N.monthShort(self.month) .. " " .. tostring(self.year) .. " >")
	local todayMonth, todayYear, todayDay = gameDate()
	local gridX = display.x + 6
	local gridY = display.y + display.statusBarHeight + display.headerHeight + 2
	local cellW = math.floor((display.width - 12) / 7)
	local cellH = math.floor((display.contentBottom - gridY - 2) / 7)
	cellH = math.max(13, cellH)
	for i = 1, 7 do
		display:drawTextCentered(I18N.dayShort(i), gridY + 1, display.colors.dim, UIFont.Small, gridX + (i - 1) * cellW,
			gridX + i * cellW)
	end
	local first, maxDay = self:firstWeekday(), monthLength(self.month, self.year)
	for day = 1, maxDay do
		local index = first + day - 2
		local col, row = index % 7, math.floor(index / 7)
		local x, y = gridX + col * cellW, gridY + cellH + row * cellH
		local isSelected = day == self.selectedDay
		local isToday = day == todayDay and self.month == todayMonth and self.year == todayYear
		if isSelected then display:fillRect(x + 1, y + 1, cellW - 2, cellH - 2, display.colors.accent) end
		if isToday then display:drawBorder(x + 1, y + 1, cellW - 2, cellH - 2, display.colors.fg) end
		display:drawTextCentered(tostring(day), y + math.max(1, math.floor((cellH - 12) / 2)),
			isSelected and display.colors.bg or display.colors.fg, UIFont.Small, x, x + cellW)
	end
	display:drawFooter(I18N.get("Options"), I18N.get("Back"))
end

return App
