local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local App = setmetatable({}, { __index = Base })
App.__index = App

local BUTTONS = {
	{ "7", "8", "9", "/", "C" },
	{ "4", "5", "6", "*", "<" },
	{ "1", "2", "3", "-", "." },
	{ "0", "00", "+/-", "+", "=" },
}

local SMART_BUTTONS = {
	{ "C", "+/-", "%", "/" },
	{ "7", "8", "9", "*" },
	{ "4", "5", "6", "-" },
	{ "1", "2", "3", "+" },
	{ "0", ".", "<", "=" },
}

function App:new(os)
	local o = Base.new(self, os)
	o.id = "calculator"
	o.name = I18N.app("calculator")
	o.displayValue = "0"
	o.accumulator = nil
	o.operator = nil
	o.newEntry = true
	o.selectedRow = 1
	o.selectedCol = 1
	o.error = nil
	return o
end

function App:numberValue()
	return tonumber(self.displayValue) or 0
end

function App:setValue(value)
	if value == math.huge or value == -math.huge or value ~= value then
		self.displayValue = I18N.get("Error")
		self.error = true
		self.newEntry = true
		return
	end
	local text = math.floor(value) == value and tostring(math.floor(value)) or string.format("%.6f", value):gsub("0+$", ""):gsub("%.$", "")
	self.displayValue = string.sub(text, 1, 14)
	self.error = nil
end

function App:clear()
	self.displayValue = "0"
	self.accumulator = nil
	self.operator = nil
	self.newEntry = true
	self.error = nil
end

function App:inputDigit(digit)
	if self.error then self:clear() end
	digit = tostring(digit)
	if self.newEntry or self.displayValue == "0" then
		self.displayValue = digit == "00" and "0" or digit
		self.newEntry = false
	elseif #self.displayValue < 14 then
		self.displayValue = self.displayValue .. digit
	end
end

function App:inputDecimal()
	if self.error then self:clear() end
	if self.newEntry then
		self.displayValue = "0."
		self.newEntry = false
	elseif not string.find(self.displayValue, ".", 1, true) then
		self.displayValue = self.displayValue .. "."
	end
end

function App:toggleSign()
	if self.displayValue == "0" or self.displayValue == I18N.get("Error") then return end
	if string.sub(self.displayValue, 1, 1) == "-" then
		self.displayValue = string.sub(self.displayValue, 2)
	else
		self.displayValue = "-" .. self.displayValue
	end
end

function App:backspace()
	if self.newEntry or self.error then self:clear(); return end
	self.displayValue = #self.displayValue <= 1 and "0" or string.sub(self.displayValue, 1, #self.displayValue - 1)
	self.newEntry = self.displayValue == "0"
end

function App:applyOperator(nextOperator)
	local current = self:numberValue()
	if self.operator and not self.newEntry then
		self:evaluate()
		current = self:numberValue()
	elseif self.accumulator == nil then
		self.accumulator = current
	end
	self.operator = nextOperator
	self.newEntry = true
end

function App:evaluate()
	if not self.operator or self.accumulator == nil then return end
	local rhs = self:numberValue()
	local result = self.accumulator
	if self.operator == "+" then result = result + rhs
	elseif self.operator == "-" then result = result - rhs
	elseif self.operator == "*" then result = result * rhs
	elseif self.operator == "/" then
		if rhs == 0 then self.displayValue = I18N.get("Error"); self.error = true; self.accumulator = nil; self.operator = nil; self.newEntry = true; return end
		result = result / rhs
	end
	self:setValue(result)
	self.accumulator = nil
	self.operator = nil
	self.newEntry = true
end

function App:press(label)
	if label == "00" or (label >= "0" and label <= "9") then self:inputDigit(label)
	elseif label == "." then self:inputDecimal()
	elseif label == "+/-" then self:toggleSign()
	elseif label == "%" then self:setValue(self:numberValue() / 100); self.newEntry = true
	elseif label == "C" then self:clear()
	elseif label == "<" then self:backspace()
	elseif label == "=" then self:evaluate()
	elseif label == "+" or label == "-" or label == "*" or label == "/" then self:applyOperator(label)
	end
end

function App:getGridRect(display)
	if not display then return nil end
	if self.os.definition.hardwareType == "smartphone" then
		local buttons = SMART_BUTTONS
		local x = display.x + 14
		local y = display.y + 160
		local w = math.floor((display.width - 28) / 4)
		local h = math.floor((display.contentBottom - y - 8) / #buttons)
		return x, y, w, h, buttons
	end
	local x = display.x + 6
	local y = display.y + 78
	local w = math.floor((display.width - 12) / 5)
	local h = math.floor((display.contentBottom - y - 2) / #BUTTONS)
	return x, y, w, h, BUTTONS
end

function App:handleInput(event)
	local buttons = self.os.definition.hardwareType == "smartphone" and SMART_BUTTONS or BUTTONS
	if event.action == "UP" then self.selectedRow = math.max(1, self.selectedRow - 1); return true end
	if event.action == "DOWN" then self.selectedRow = math.min(#buttons, self.selectedRow + 1); return true end
	if event.action == "LEFT" then self.selectedCol = math.max(1, self.selectedCol - 1); return true end
	if event.action == "RIGHT" then self.selectedCol = math.min(#buttons[self.selectedRow], self.selectedCol + 1); return true end
	if event.action == "OK" then self:press(buttons[self.selectedRow][self.selectedCol]); return true end
	if event.action == "LEFT_SOFT" then self:clear(); return true end
	if event.action == "MOUSE_DOWN" and event.displayX and event.displayY then
		local x, y, w, h, gridButtons = self:getGridRect(self.lastDisplay)
		if x then
			local col = math.floor((event.displayX - (x - self.lastDisplay.x)) / w) + 1
			local row = math.floor((event.displayY - (y - self.lastDisplay.y)) / h) + 1
			if gridButtons[row] and gridButtons[row][col] then
				self.selectedRow = row
				self.selectedCol = col
				self:press(gridButtons[row][col])
				return true
			end
		end
	end
	return Base.handleInput(self, event)
end

function App:renderSmartphone(display)
	self.lastDisplay = display
	display:clear()
	local value = self.displayValue
	display:drawTextRight(value, display.contentRight - 12, display.y + 78, display.colors.fg, UIFont.Large)
	if self.operator then
		display:drawTextRight(tostring(self.accumulator or "") .. " " .. self.operator, display.contentRight - 14,
			display.y + 54, display.colors.dim, UIFont.Small)
	end
	display:drawBorder(display.x + 14, display.y + 46, display.width - 28, 88, display.colors.border)
	local x, y, cellW, cellH, buttons = self:getGridRect(display)
	for row = 1, #buttons do
		for col = 1, #buttons[row] do
			local label = buttons[row][col]
			local bx, by = x + (col - 1) * cellW, y + (row - 1) * cellH
			local selected = row == self.selectedRow and col == self.selectedCol
			local isOperator = label == "+" or label == "-" or label == "*" or label == "/" or label == "="
			local fill = isOperator and display.colors.accent or display.colors.bg
			display:fillRect(bx + 4, by + 4, cellW - 8, cellH - 8, selected and display.colors.accent or fill)
			display:drawBorder(bx + 4, by + 4, cellW - 8, cellH - 8, selected and display.colors.fg or display.colors.border)
			display:drawTextCentered(label, by + math.max(7, math.floor((cellH - 16) / 2)),
				isOperator and { r = 1, g = 1, b = 1, a = 1 } or display.colors.fg, UIFont.Medium, bx, bx + cellW)
		end
	end
end

function App:render(display)
	if self.os.definition.hardwareType == "smartphone" then
		return self:renderSmartphone(display)
	end
	self.lastDisplay = display
	display:clear()
	display:drawHeader(I18N.app("calculator"))
	local value = self.displayValue
	display:fillRect(display.x + 8, display.y + 43, display.width - 16, 28, display.colors.bg)
	display:drawBorder(display.x + 8, display.y + 43, display.width - 16, 28, display.colors.fg)
	display:drawTextRight(value, display.contentRight - 8, display.y + 50, display.colors.fg, UIFont.Small)
	if self.operator then
		display:drawText(display:ellipsize(tostring(self.accumulator or "") .. " " .. self.operator, 70), display.x + 12, display.y + 50, display.colors.dim)
	end

	local x, y, cellW, cellH = self:getGridRect(display)
	for row = 1, #BUTTONS do
		for col = 1, #BUTTONS[row] do
			local label = BUTTONS[row][col]
			local bx, by = x + (col - 1) * cellW, y + (row - 1) * cellH
			local selected = row == self.selectedRow and col == self.selectedCol
			if selected then display:fillRect(bx + 1, by + 1, cellW - 4, cellH - 4, display.colors.accent) end
			display:drawBorder(bx, by, cellW - 3, cellH - 2, selected and display.colors.fg or display.colors.dim)
			display:drawTextCentered(label, by + math.max(2, math.floor((cellH - 12) / 2)), selected and display.colors.bg or display.colors.fg, UIFont.Small, bx, bx + cellW - 3)
		end
	end
	display:drawFooter(I18N.get("Clear"), I18N.get("Back"))
end

return App
