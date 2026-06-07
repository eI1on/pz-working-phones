require("WorkingPhones/Core/WorkingPhonesGlobals")
local PhoneInstance = require("WorkingPhones/Core/PhoneInstance")
local PhoneItemRegistry = require("WorkingPhones/Registries/PhoneItemRegistry")
local PhoneUtils = require("WorkingPhones/Core/PhoneUtils")
local Persistence = require("WorkingPhones/Core/PhonePersistence")
local Networking = require("WorkingPhones/Core/PhoneNetworking")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local PhoneSettings = require("WorkingPhones/Core/PhoneSettings")
local Common = require("WorkingPhones/Common/PhoneCommon")
local DisplayRenderer = require("WorkingPhones/UI/PhoneDisplayRenderer")
local ClassicRenderer = require("WorkingPhones/UI/ClassicPhoneRenderer")
local SmartphoneRenderer = require("WorkingPhones/UI/SmartphoneRenderer")

local PhonePanel = ISPanel:derive("WorkingPhones_PhonePanel")
PhonePanel.activePanel = nil

local function definitionBaseSize(definition, texture)
	local panel = definition.panel or {}
	local texWidth, texHeight = Common.textureSize(texture)
	return tonumber(panel.width) or texWidth or 379, tonumber(panel.height) or texHeight or 720
end

local function panelScale(definition, baseHeight)
	local panel = definition.panel or {}
	local wantedScale = (tonumber(panel.scale) or 1) * (tonumber(PhoneSettings.uiScale) or 1)
	local maxScreenRatio = tonumber(panel.maxScreenHeightRatio) or 0.7
	local maxHeight = math.floor(getCore():getScreenHeight() * maxScreenRatio)
	return math.min(wantedScale, maxHeight / baseHeight)
end

local function tr(key, ...)
	return I18N.get(key, ...)
end

local FALLBACK_KEYS = {
	UP = Keyboard and Keyboard.KEY_UP or 0,
	DOWN = Keyboard and Keyboard.KEY_DOWN or 0,
	LEFT = Keyboard and Keyboard.KEY_LEFT or 0,
	RIGHT = Keyboard and Keyboard.KEY_RIGHT or 0,
	ALT_UP = Keyboard and Keyboard.KEY_W or 0,
	ALT_DOWN = Keyboard and Keyboard.KEY_S or 0,
	ALT_LEFT = Keyboard and Keyboard.KEY_A or 0,
	ALT_RIGHT = Keyboard and Keyboard.KEY_D or 0,
	OK = Keyboard and Keyboard.KEY_RETURN or 0,
	BACK = Keyboard and Keyboard.KEY_BACK or 0,
	LEFT_SOFT = Keyboard and Keyboard.KEY_Q or 0,
	RIGHT_SOFT = Keyboard and Keyboard.KEY_E or 0,
	MENU = Keyboard and Keyboard.KEY_TAB or 0,
	POWER = Keyboard and Keyboard.KEY_P or 0,
	OPEN_PHONE = Keyboard and Keyboard.KEY_NONE or 0,
}

local HINT_LINE_KEYS = {
	{ "InputHintLineUp", "UP", "ALT_UP" },
	{ "InputHintLineDown", "DOWN", "ALT_DOWN" },
	{ "InputHintLineLeft", "LEFT", "ALT_LEFT" },
	{ "InputHintLineRight", "RIGHT", "ALT_RIGHT" },
	{ "InputHintLineOK", "OK" },
	{ "InputHintLineBack", "BACK" },
	{ "InputHintLineSoft", "LEFT_SOFT", "RIGHT_SOFT" },
	{ "InputHintLineMenu", "MENU" },
	{ "InputHintLinePower", "POWER" },
	{ "InputHintLineOpen", "OPEN_PHONE" },
}

local HINT_CONTROLLER_LINES = {
	"InputHintPadLineNav",
	"InputHintPadLineOK",
	"InputHintPadLineBack",
	"InputHintPadLineSoft",
	"InputHintPadLineMenu",
	"InputHintPadLinePower",
}

local function boundKey(action)
	local bindings = WorkingPhones and WorkingPhones.PhoneKeyBindings or nil
	local data = bindings and bindings[action] or nil
	local key = data and data.key or FALLBACK_KEYS[action] or 0
	return tonumber(key) or 0
end

local function keyMatches(key, action)
	local assigned = boundKey(action)
	return assigned ~= 0 and key == assigned
end

local function keyLabel(action)
	local key = boundKey(action)
	if key == 0 then
		return tr("Unassigned")
	end
	if Keyboard and Keyboard.getKeyName then
		local name = Keyboard.getKeyName(key)
		if name and name ~= "" then
			return tostring(name)
		end
	end
	return tostring(key)
end

local function combinedKeyLabel(primary, alternate)
	local first = keyLabel(primary)
	local second = alternate and keyLabel(alternate) or nil
	if not second or second == tr("Unassigned") then
		return first
	end
	if first == tr("Unassigned") then
		return second
	end
	return first .. "/" .. second
end

local function keyAction(key)
	if not Keyboard then
		return nil
	end
	if keyMatches(key, "UP") or keyMatches(key, "ALT_UP") then return "UP" end
	if keyMatches(key, "DOWN") or keyMatches(key, "ALT_DOWN") then return "DOWN" end
	if keyMatches(key, "LEFT") or keyMatches(key, "ALT_LEFT") then return "LEFT" end
	if keyMatches(key, "RIGHT") or keyMatches(key, "ALT_RIGHT") then return "RIGHT" end
	if keyMatches(key, "LEFT_SOFT") then return "LEFT_SOFT" end
	if keyMatches(key, "RIGHT_SOFT") then return "RIGHT_SOFT" end
	if keyMatches(key, "OK") then return "OK" end
	if keyMatches(key, "BACK") then return "BACK" end
	if keyMatches(key, "MENU") then return "MENU" end
	if keyMatches(key, "POWER") then return "POWER" end

	local digitKeys = {}
	if Keyboard.KEY_0 then digitKeys[Keyboard.KEY_0] = 0 end
	if Keyboard.KEY_1 then digitKeys[Keyboard.KEY_1] = 1 end
	if Keyboard.KEY_2 then digitKeys[Keyboard.KEY_2] = 2 end
	if Keyboard.KEY_3 then digitKeys[Keyboard.KEY_3] = 3 end
	if Keyboard.KEY_4 then digitKeys[Keyboard.KEY_4] = 4 end
	if Keyboard.KEY_5 then digitKeys[Keyboard.KEY_5] = 5 end
	if Keyboard.KEY_6 then digitKeys[Keyboard.KEY_6] = 6 end
	if Keyboard.KEY_7 then digitKeys[Keyboard.KEY_7] = 7 end
	if Keyboard.KEY_8 then digitKeys[Keyboard.KEY_8] = 8 end
	if Keyboard.KEY_9 then digitKeys[Keyboard.KEY_9] = 9 end
	if digitKeys[key] ~= nil then
		return "DIGIT", { value = digitKeys[key] }
	end
	if key == Keyboard.KEY_EQUALS then return "OPERATOR", { value = "+" } end
	if key == Keyboard.KEY_MINUS then return "OPERATOR", { value = "-" } end
	if key == Keyboard.KEY_SLASH then return "OPERATOR", { value = "/" } end
	if key == Keyboard.KEY_MULTIPLY then return "OPERATOR", { value = "*" } end
	return nil
end

local function textInputForKey(key)
	if not Keyboard then
		return nil
	end
	if key == Keyboard.KEY_SPACE then return " " end
	if key == Keyboard.KEY_PERIOD then return "." end
	if key == Keyboard.KEY_COMMA then return "," end
	if key == Keyboard.KEY_MINUS then return "-" end
	if key == Keyboard.KEY_SLASH then return "/" end
	if key == Keyboard.KEY_BACK then return nil, "BACKSPACE" end
	for i = 0, 9 do
		if Keyboard["KEY_" .. tostring(i)] and key == Keyboard["KEY_" .. tostring(i)] then
			return tostring(i)
		end
	end
	for code = string.byte("A"), string.byte("Z") do
		local ch = string.char(code)
		if Keyboard["KEY_" .. ch] and key == Keyboard["KEY_" .. ch] then
			return ch
		end
	end
	return nil
end

function PhonePanel:initialise()
	ISPanel.initialise(self)
	self.phoneTexture = self.phoneTexture or (self.definition.texture and getTexture(self.definition.texture)) or nil
	self.screenRect = Common.scaledRect(self.definition.screenRect, self.scale)
	self.scaledButtons = {}
	for action, rect in pairs(self.definition.buttons or {}) do
		self.scaledButtons[action] = Common.scaledRect(rect, self.scale)
	end
	self.display = DisplayRenderer:new(self, self.screenRect, self.definition.theme)
	self.renderer = self.definition.hardwareType == "smartphone" and SmartphoneRenderer or ClassicRenderer
end

function PhonePanel:close()
	PhonePanel.activePanel = nil
	if self.instance and self.instance.os and self.instance.os.currentApp and self.instance.os.currentApp.onClose then
		self.instance.os.currentApp:onClose()
	end
	local notification = self.instance and self.instance.os and self.instance.os.notification
	if notification and notification.kind == "call" then
		Networking.declineCall(notification.callId, self.instance.number, "Declined")
		self.instance.os:dismissNotification(notification)
	end
	if self.instance and self.instance.data and self.instance.data.activeCall then
		local active = self.instance.data.activeCall
		Networking.hangupCall(active.callId, self.instance.number, "HungUp")
		self.instance.data.activeCall = nil
	end
	if self.prevJoypadFocus ~= nil and setJoypadFocus then
		setJoypadFocus(self.playerNum or 0, self.prevJoypadFocus)
	elseif self.joyfocus and setJoypadFocus then
		setJoypadFocus(self.playerNum or 0, nil)
	end
	self:setVisible(false)
	self:removeFromUIManager()
end

function PhonePanel:bringToTop()
	if ISUIElement and ISUIElement.bringToTop then
		ISUIElement.bringToTop(self)
	end
	local currentApp = self.instance and self.instance.os and self.instance.os.currentApp
	if currentApp and currentApp.bringOverlayToTop then
		currentApp:bringOverlayToTop()
	end
end

function PhonePanel:contactLabel(number)
	local contacts = Persistence.getContacts(self.instance.item, self.instance.definition.id)
	for i = 1, #contacts do
		local contact = contacts[i]
		if tostring(contact.number) == tostring(number) then
			return tostring(contact.name or number) .. " (" .. tostring(number) .. ")"
		end
	end
	return tostring(number)
end

function PhonePanel:showIncomingCall(fromNumber, callId)
	local fromLabel = self:contactLabel(fromNumber)
	local phoneName = self.instance.displayName or self.definition.displayName or tr("UnknownPhone")
	local notification = self.instance.os:pushNotification({
		kind = "call",
		callId = callId,
		fromNumber = tostring(fromNumber),
		title = tr("IncomingCall"),
		text = fromLabel,
		primary = tr("Answer"),
		secondary = tr("Decline"),
	})
	self.incomingCall = fromNumber
	local event = self.instance.data and self.instance.data.ringtoneEvent or nil
	PhoneUtils.playPhoneAlert(self.playerObj, event, self.instance.data, true, "call")
	self.instance.data.callHistory = self.instance.data.callHistory or {}
	table.insert(self.instance.data.callHistory, 1, {
		name = fromLabel,
		number = tostring(fromNumber),
		type = tr("IncomingType"),
		result = tr("Ringing"),
		date = PhoneUtils.gameDateTime(),
	})
	Common.trimList(self.instance.data.callHistory, Common.callHistoryLimit())
	PhoneUtils.toast(tr("PhoneCallOn", phoneName), tr("FromContact", fromLabel), "warning", nil, 8)
end

function PhonePanel:showIncomingMessage(fromNumber, body)
	local fromLabel = self:contactLabel(fromNumber)
	local phoneName = self.instance.displayName or self.definition.displayName or tr("UnknownPhone")
	local notification = self.instance.os:pushNotification({
		kind = "message",
		fromNumber = tostring(fromNumber),
		title = tr("IncomingMessage"),
		text = fromLabel,
		primary = tr("Read"),
		secondary = tr("Dismiss"),
	})
	local event = self.instance.data and (self.instance.data.notificationEvent or self.instance.data.ringtoneEvent) or
	nil
	PhoneUtils.playPhoneAlert(self.playerObj, event, self.instance.data, true, "notification")
	PhoneUtils.toast(tr("PhoneMessageOn", phoneName), tr("FromContactWithBody", fromLabel, tostring(body or "")), "info",
		nil, 8)
end

function PhonePanel:handleNotificationAction(primary)
	local notification = self.instance.os.notification
	if not notification then return false end
	if primary then
		if notification.kind == "call" then
			Networking.answerCall(notification.callId, self.instance.number)
			if self.instance.data.callHistory and self.instance.data.callHistory[1] then
				self.instance.data.callHistory[1].result = tr("Answered")
				self.instance.data.callHistory[1].date = PhoneUtils.gameDateTime()
			end
			return self.instance.os:openNotification(notification)
		end
		return self.instance.os:openNotification(notification)
	end
	if notification.kind == "call" then
		Networking.declineCall(notification.callId, self.instance.number, "Declined")
		if self.instance.data.callHistory and self.instance.data.callHistory[1] then
			self.instance.data.callHistory[1].result = tr("Declined")
			self.instance.data.callHistory[1].date = PhoneUtils.gameDateTime()
		end
	end
	self.instance.os:dismissNotification(notification)
	return true
end

function PhonePanel:handleAction(action, payload)
	if self.instance and self.instance.os and self.instance.os.notification then
		if action == "LEFT_SOFT" or action == "OK" then
			return self:handleNotificationAction(true)
		elseif action == "RIGHT_SOFT" or action == "BACK" then
			return self:handleNotificationAction(false)
		end
	end
	if action == "POWER" then
		self.instance.hardware:togglePower()
		return true
	end
	if not self.instance.hardware:isPowered() then
		return false
	end
	local handled = self.instance.os:handleInput({
		action = action,
		displayX = payload and payload.displayX,
		displayY = payload and payload.displayY,
		value = payload and payload.value,
		special = payload and payload.special,
	})
	local currentApp = self.instance and self.instance.os and self.instance.os.currentApp
	if currentApp and currentApp.bringOverlayToTop then
		currentApp:bringOverlayToTop()
	end
	return handled
end

function PhonePanel:onMouseDown(x, y)
	self.lastInputMode = "keyboardMouse"
	if x >= (self.phoneFrameWidth or self.width) - 28 and y <= 28 then
		self:close()
		return true
	end

	local buttons = self.scaledButtons or {}
	for action, rect in pairs(buttons) do
		if x >= rect.x and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height then
			return self:handleAction(action)
		end
	end

	local screen = self.screenRect
	if x >= screen.x and x <= screen.x + screen.width and y >= screen.y and y <= screen.y + screen.height then
		local isSmartphone = self.definition and self.definition.hardwareType == "smartphone"
		if not isSmartphone and y >= screen.y + screen.height - self.display.footerHeight then
			if x < screen.x + screen.width / 2 then
				return self:handleAction("LEFT_SOFT")
			end
			return self:handleAction("RIGHT_SOFT")
		end
		if isSmartphone then
			local navHeight = self.display.navBarHeight or 0
			local footerHeight = self.display.softFooterHeight or self.display.footerHeight or 0
			local footerY = screen.y + screen.height - navHeight - footerHeight
			local navY = screen.y + screen.height - navHeight
			if footerHeight > 0 and y >= footerY and y < navY then
				if x < screen.x + screen.width / 2 then
					return self:handleAction("LEFT_SOFT")
				end
				return self:handleAction("RIGHT_SOFT")
			end
		end
		local notification = self.instance and self.instance.os and self.instance.os.notification
		if notification then
			local lines = Common.wrapTextToWidth(
			(notification.title and (notification.title .. " ") or "") .. tostring(notification.text or ""), UIFont
			.Small, screen.width - 24, 3)
			local notificationHeight = math.max(38, 24 + #lines * 13)
			local reservedBottom = (self.display.navBarHeight or 0) + (self.display.softFooterHeight or self.display.footerHeight or 0)
			local nY = screen.y + screen.height - reservedBottom - notificationHeight - 4
			if y >= nY and y <= nY + notificationHeight then
				return self:handleNotificationAction(x < screen.x + screen.width / 2)
			end
		end
		return self:handleAction("MOUSE_DOWN", { displayX = x - screen.x, displayY = y - screen.y })
	end

	ISPanel.onMouseDown(self, x, y)
	local currentApp = self.instance and self.instance.os and self.instance.os.currentApp
	if currentApp and currentApp.bringOverlayToTop then
		currentApp:bringOverlayToTop()
	end
	return true
end

function PhonePanel:onMouseMove(dx, dy)
	if self.moving then
		ISPanel.onMouseMove(self, dx, dy)
		return true
	end
	local screen = self.screenRect
	local mx = self:getMouseX()
	local my = self:getMouseY()
	if screen and mx >= screen.x and mx <= screen.x + screen.width and my >= screen.y and my <= screen.y + screen.height then
		self:handleAction("MOUSE_MOVE", { displayX = mx - screen.x, displayY = my - screen.y })
		return true
	end
	ISPanel.onMouseMove(self, dx, dy)
	return true
end

function PhonePanel:onMouseUp(x, y)
	if self.moving then
		ISPanel.onMouseUp(self, x, y)
		return true
	end
	local screen = self.screenRect
	if screen and x >= screen.x and x <= screen.x + screen.width and y >= screen.y and y <= screen.y + screen.height then
		self:handleAction("MOUSE_UP", { displayX = x - screen.x, displayY = y - screen.y })
		return true
	end
	ISPanel.onMouseUp(self, x, y)
	return true
end

function PhonePanel:onKeyPress(key)
	self.lastInputMode = "keyboardMouse"
	local action, payload = keyAction(key)
	if action then
		return self:handleAction(action, payload)
	end
	return false
end

function PhonePanel:takeJoypadFocus()
	if not JoypadState or not setJoypadFocus then
		return
	end
	local playerNum = self.playerNum or 0
	local joypadData = JoypadState.players and JoypadState.players[playerNum + 1] or nil
	if joypadData then
		self.prevJoypadFocus = getJoypadFocus and getJoypadFocus(playerNum) or nil
		setJoypadFocus(playerNum, self)
	end
end

function PhonePanel:onGainJoypadFocus(joypadData)
	self.joyfocus = joypadData
	self.drawJoypadFocus = true
end

function PhonePanel:onLoseJoypadFocus()
	self.joyfocus = nil
	self.drawJoypadFocus = false
end

function PhonePanel:onJoypadDown(button, joypadData)
	self.lastInputMode = "controller"
	if not Joypad then
		return
	end
	if button == Joypad.AButton then return self:handleAction("OK") end
	if button == Joypad.BButton then return self:handleAction("BACK") end
	if button == Joypad.XButton then return self:handleAction("LEFT_SOFT") end
	if button == Joypad.YButton then return self:handleAction("RIGHT_SOFT") end
	if button == Joypad.LBumper then return self:handleAction("LEFT_SOFT") end
	if button == Joypad.RBumper then return self:handleAction("RIGHT_SOFT") end
	if Joypad.Start and button == Joypad.Start then return self:handleAction("MENU") end
	if Joypad.Back and button == Joypad.Back then self:close(); return true end
	if Joypad.L3 and button == Joypad.L3 then return self:handleAction("POWER") end
	if Joypad.R3 and button == Joypad.R3 then return self:handleAction("POWER") end
end

function PhonePanel:onJoypadDirUp(joypadData)
	self.lastInputMode = "controller"
	return self:handleAction("UP")
end

function PhonePanel:onJoypadDirDown(joypadData)
	self.lastInputMode = "controller"
	return self:handleAction("DOWN")
end

function PhonePanel:onJoypadDirLeft(joypadData)
	self.lastInputMode = "controller"
	return self:handleAction("LEFT")
end

function PhonePanel:onJoypadDirRight(joypadData)
	self.lastInputMode = "controller"
	return self:handleAction("RIGHT")
end

function PhonePanel:onJoypadBeforeDeactivate(joypadData)
	self:close()
end

function PhonePanel:onMouseWheel(delta)
	self.lastInputMode = "keyboardMouse"
	local currentApp = self.instance and self.instance.os and self.instance.os.currentApp
	if currentApp and currentApp.id == "map" then
		if currentApp.optionsOpen then
			return self:handleAction(delta < 0 and "SCROLL_UP" or "SCROLL_DOWN")
		end
		if currentApp.isMouseOverMap and currentApp:isMouseOverMap(self.display) then
			return self:handleAction(delta < 0 and "SCROLL_UP" or "SCROLL_DOWN")
		end
		return false
	end
	if currentApp and currentApp.id == "sounds" and currentApp.isMouseOverVolume and currentApp:isMouseOverVolume(self.display) then
		return self:handleAction(delta < 0 and "SCROLL_UP" or "SCROLL_DOWN")
	end
	if delta < 0 then
		return self:handleAction("UP")
	end
	return self:handleAction("DOWN")
end

function PhonePanel:update()
	ISPanel.update(self)
	self.instance.os:update(33)
	local currentApp = self.instance and self.instance.os and self.instance.os.currentApp
	if currentApp and currentApp.syncOverlayGeometry then
		currentApp:syncOverlayGeometry(self.display)
	end
end

function PhonePanel:hintRows(maxWidth)
	local inputMode = self.lastInputMode or "keyboardMouse"
	local rows = {
		{ kind = "title", text = tr("InputHintsTitle") },
		{ kind = "section", text = inputMode == "controller" and tr("InputHintsController") or tr("InputHintsKeyboard") },
	}

	if inputMode == "controller" then
		for i = 1, #HINT_CONTROLLER_LINES do
			table.insert(rows, { kind = "text", text = tr(HINT_CONTROLLER_LINES[i]) })
		end
	else
		for i = 1, #HINT_LINE_KEYS do
			local row = HINT_LINE_KEYS[i]
			local label
			if row[3] then
				label = combinedKeyLabel(row[2], row[3])
			else
				label = keyLabel(row[2])
			end
			table.insert(rows, { kind = "text", text = tr(row[1], label) })
		end
	end

	local wrapped = {}
	for i = 1, #rows do
		local row = rows[i]
		if row.kind == "text" then
			local lines = Common.wrapTextToWidth(row.text, UIFont.Small, maxWidth, nil)
			for j = 1, #lines do
				table.insert(wrapped, { kind = "text", text = lines[j] })
			end
		else
			table.insert(wrapped, row)
		end
	end
	return wrapped
end

function PhonePanel:renderInputHints()
	local margin = math.max(8, math.floor(8 * self.scale))
	local titleHeight = 13
	local rowHeight = 12
	local sectionHeight = 12
	local innerPad = 5
	local panelWidth = self.hintsWidth or math.max(120, math.floor((self.phoneFrameWidth or self.width) * 0.5))
	local rows = self:hintRows(panelWidth - innerPad * 2)
	local contentHeight = innerPad * 2
	for i = 1, #rows do
		local row = rows[i]
		if row.kind == "title" then
			contentHeight = contentHeight + titleHeight
		elseif row.kind == "section" then
			contentHeight = contentHeight + sectionHeight
		else
			contentHeight = contentHeight + rowHeight
		end
	end
	local maxHeight = math.max(44, (self.phoneFrameHeight or self.height) - margin * 2)
	local panelHeight = math.min(contentHeight, maxHeight)
	local x = (self.phoneFrameWidth or self.width) + margin
	local y = margin
	local clipHeight = panelHeight - innerPad * 2

	local isSmartphone = self.definition and self.definition.hardwareType == "smartphone"
	if isSmartphone then
		self:drawRect(x, y, panelWidth, panelHeight, 0.88, 0.97, 0.97, 0.95)
		self:drawRectBorder(x, y, panelWidth, panelHeight, 0.9, 1, 1, 1)
	else
		self:drawRect(x, y, panelWidth, panelHeight, 0.82, 0.02, 0.03, 0.02)
		self:drawRectBorder(x, y, panelWidth, panelHeight, 0.85, 0.35, 0.45, 0.3)
	end

	if self.setStencilRect then
		self:setStencilRect(x + innerPad, y + innerPad, panelWidth - innerPad * 2, clipHeight)
	end

	local drawY = y + innerPad
	for i = 1, #rows do
		local row = rows[i]
		if drawY > y + panelHeight - innerPad then
			break
		end
		if row.kind == "title" then
			if isSmartphone then
				self:drawText(row.text, x + innerPad, drawY, 0.08, 0.1, 0.12, 1, UIFont.Small)
			else
				self:drawText(row.text, x + innerPad, drawY, 0.78, 0.95, 0.68, 1, UIFont.Small)
			end
			drawY = drawY + titleHeight
		elseif row.kind == "section" then
			if isSmartphone then
				self:drawText(row.text, x + innerPad, drawY, 0.22, 0.28, 0.35, 1, UIFont.Small)
			else
				self:drawText(row.text, x + innerPad, drawY, 0.55, 0.72, 0.48, 1, UIFont.Small)
			end
			drawY = drawY + sectionHeight
		else
			if isSmartphone then
				self:drawText(row.text, x + innerPad + 5, drawY, 0.08, 0.1, 0.12, 1, UIFont.Small)
			else
				self:drawText(row.text, x + innerPad + 5, drawY, 0.86, 0.92, 0.82, 1, UIFont.Small)
			end
			drawY = drawY + rowHeight
		end
	end

	if self.clearStencilRect then
		self:clearStencilRect()
	end
end

function PhonePanel:render()
	ISPanel.render(self)
	self.renderer.renderShell(self, self.definition)
	if self.instance.hardware:isPowered() then
		local screen = self.screenRect
		if self.setStencilRect then
			self:setStencilRect(screen.x, screen.y, screen.width, screen.height)
		end
		self.instance.os:render(self.display)
		if self.clearStencilRect then
			self:clearStencilRect()
		end
	else
		self:drawRect(self.screenRect.x, self.screenRect.y, self.screenRect.width, self.screenRect.height, 0.95, 0, 0, 0)
	end
	self.renderer.renderOverlay(self, self.definition)
	local closeX = (self.phoneFrameWidth or self.width) - 28
	self:drawRect(closeX, 0, 28, 28, 0.65, 0.1, 0.1, 0.1)
	self:drawText("X", closeX + 9, 5, 1, 1, 1, 1, UIFont.Small)
	if self.instance.os.notification then
		local notification = self.instance.os.notification
		local rect = self.screenRect
		local text = (notification.title and (notification.title .. " ") or "") ..
		tostring(notification.text or tr("Notification"))
		local lines = Common.wrapTextToWidth(text, UIFont.Small, rect.width - 24, 3)
		local notificationHeight = math.max(38, 24 + #lines * 13)
		local reservedBottom = (self.display.navBarHeight or 0) + (self.display.softFooterHeight or self.display.footerHeight or 0)
		local y = rect.y + rect.height - reservedBottom - notificationHeight - 4
		self:drawRect(rect.x + 6, y, rect.width - 12, notificationHeight, 0.94, 0.05, 0.12, 0.06)
		for i = 1, #lines do
			self:drawText(lines[i], rect.x + 12, y + 4 + (i - 1) * 13, 0.75, 0.9, 0.65, 1, UIFont.Small)
		end
		local actionY = y + notificationHeight - 15
		self:drawText(tostring(notification.primary or tr("Open")), rect.x + 12, actionY, 0.75, 0.9, 0.65, 1,
			UIFont.Small)
		self:drawTextRight(tostring(notification.secondary or tr("Dismiss")), rect.x + rect.width - 12, actionY, 0.75,
			0.9, 0.65, 1, UIFont.Small)
	end
	if PhoneSettings.showInputHints then
		self:renderInputHints()
	end
end

function PhonePanel:new(definition, playerNum, item, variantId)
	definition = Common.copyTable(definition)
	local variant = PhoneItemRegistry.getVariant(definition.id, variantId or "default")
	if variant then
		definition.displayNameKey = variant.displayNameKey or definition.displayNameKey
		definition.displayName = I18N.translatedName(definition.displayNameKey, variant.displayName or definition.displayName)
		definition.texture = variant.texture or definition.texture
		definition.variant = variant
	end
	definition.displayName = I18N.translatedName(definition.displayNameKey, definition.displayName)

	local phoneTexture = definition.texture and getTexture(definition.texture) or nil
	local baseWidth, baseHeight = definitionBaseSize(definition, phoneTexture)
	local scale = panelScale(definition, baseHeight)
	local phoneFrameWidth = math.floor(baseWidth * scale)
	local phoneFrameHeight = math.floor(baseHeight * scale)
	local hintMargin = math.max(8, math.floor(8 * scale))
	local hintsWidth = 0
	local hintsHeight = 0
	if PhoneSettings.showInputHints then
		local longestModeLines = math.max(#HINT_LINE_KEYS, #HINT_CONTROLLER_LINES)
		hintsHeight = 5 + 13 + 12 + longestModeLines * 12 + 5
		hintsWidth = math.max(132, math.min(220, math.floor(phoneFrameWidth * 0.58)))
	end
	local width = phoneFrameWidth + (hintsWidth > 0 and (hintMargin + hintsWidth + hintMargin) or 0)
	local height = phoneFrameHeight
	local x = (getCore():getScreenWidth() - width) / 2
	local y = (getCore():getScreenHeight() - height) / 2
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.definition = definition
	o.playerNum = playerNum or 0
	o.playerObj = getSpecificPlayer(o.playerNum)
	o.item = item
	o.variantId = variantId
	o.scale = scale
	o.phoneTexture = phoneTexture
	o.phoneFrameWidth = phoneFrameWidth
	o.phoneFrameHeight = phoneFrameHeight
	o.hintsWidth = hintsWidth
	o.hintsHeight = hintsHeight
	o.lastInputMode = "keyboardMouse"
	o.instance = PhoneInstance:new(definition, o.playerObj, item)
	o.moveWithMouse = true
	o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
	o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
	return o
end

function PhonePanel.open(definition, playerNum, item, variantId)
	if PhonePanel.activePanel then
		PhonePanel.activePanel:close()
	end
	local panel = PhonePanel:new(definition, playerNum, item, variantId)
	panel:initialise()
	panel:addToUIManager()
	panel:takeJoypadFocus()
	PhonePanel.activePanel = panel
	return panel
end

local function onKeyPressed(key)
	if PhonePanel.activePanel and PhonePanel.activePanel:isVisible() then
		local currentApp = PhonePanel.activePanel.instance and PhonePanel.activePanel.instance.os and
			PhonePanel.activePanel.instance.os.currentApp
		if currentApp and currentApp.isTextEntryFocused and currentApp:isTextEntryFocused() then
			return
		end
		if currentApp and currentApp.acceptsTextInput then
			local char, special = textInputForKey(key)
			if char or special then
				PhonePanel.activePanel:handleAction("TEXT_INPUT", { value = char, special = special })
				return
			end
		end
		PhonePanel.activePanel:onKeyPress(key)
	end
end

Events.OnKeyPressed.Add(onKeyPressed)

WorkingPhones.PhonePanel = PhonePanel
return PhonePanel
