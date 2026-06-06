local AppRegistry = require("WorkingPhones/Core/PhoneAppRegistry")
local PhoneUtils = require("WorkingPhones/Core/PhoneUtils")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local SmartphoneOS = require("WorkingPhones/Core/SmartphoneOS")

local PhoneOS = {}
PhoneOS.__index = PhoneOS

function PhoneOS:new(instance)
	local o = setmetatable({}, self)
	o.instance = instance
	o.definition = instance.definition
	o.apps = AppRegistry.getAppsForPhone(o.definition)
	o.selectedIndex = 1
	o.scrollOffset = 0
	o.mode = "launcher"
	o.currentApp = nil
	o.stack = {}
	o.notification = nil
	o.notifications = instance.data.notifications or {}
	instance.data.notifications = o.notifications
	o.notification = o.notifications[#o.notifications]
	if SmartphoneOS.isSmartphone(o) then
		SmartphoneOS.init(o)
	end
	return o
end

function PhoneOS:pushNotification(notification)
	notification.id = notification.id or tostring(getTimestampMs())
	table.insert(self.notifications, notification)
	self.notification = notification
	if self.currentApp and self.currentApp.pauseForNotification then
		self.currentApp:pauseForNotification(notification)
	end
	return notification
end

function PhoneOS:dismissNotification(notification)
	notification = notification or self.notification
	for i = #self.notifications, 1, -1 do
		if self.notifications[i] == notification or self.notifications[i].id == notification.id then
			table.remove(self.notifications, i)
			break
		end
	end
	self.notification = self.notifications[#self.notifications]
end

function PhoneOS:openNotification(notification)
	notification = notification or self.notification
	if not notification then return false end
	if notification.kind == "message" then
		self:openApp("messages")
		if self.currentApp and self.currentApp.openThreadForNumber then
			self.currentApp:openThreadForNumber(notification.fromNumber)
		end
	elseif notification.kind == "call" then
		self:openApp("phone")
		if self.currentApp and self.currentApp.showIncoming then
			self.currentApp:showIncoming(notification.fromNumber)
		end
	end
	self:dismissNotification(notification)
	return true
end

function PhoneOS:openApp(appId)
	local app = AppRegistry.create(appId, self)
	if not app then
		return false
	end
	if self.currentApp then
		table.insert(self.stack, self.currentApp)
		if self.currentApp.onClose then
			self.currentApp:onClose()
		end
	end
	self.currentApp = app
	if app.onOpen then
		app:onOpen()
	end
	return true
end

function PhoneOS:back()
	if SmartphoneOS.isSmartphone(self) then
		return SmartphoneOS.back(self)
	end
	if self.currentApp then
		if self.currentApp.onClose then
			self.currentApp:onClose()
		end
		self.currentApp = table.remove(self.stack)
		return true
	end
	return false
end

function PhoneOS:menu()
	if SmartphoneOS.isSmartphone(self) then
		if self.currentApp and self.currentApp.onClose then
			self.currentApp:onClose()
		end
		self.currentApp = nil
		self.stack = {}
		self.smartMode = "drawer"
		return true
	end
	if self.currentApp and self.currentApp.onClose then
		self.currentApp:onClose()
	end
	self.currentApp = nil
	self.stack = {}
	self.mode = "menu"
end

function PhoneOS:launcher()
	if SmartphoneOS.isSmartphone(self) then
		return SmartphoneOS.home(self)
	end
	if self.currentApp and self.currentApp.onClose then
		self.currentApp:onClose()
	end
	self.currentApp = nil
	self.stack = {}
	self.mode = "launcher"
end

function PhoneOS:moveSelection(delta)
	self.selectedIndex = math.max(1, math.min(#self.apps, self.selectedIndex + delta))
end

function PhoneOS:updateScroll(display)
	if not display then
		return
	end
	local _, visibleRows = display:getVisibleListMetrics(20, #self.apps)
	if self.selectedIndex < self.scrollOffset + 1 then
		self.scrollOffset = self.selectedIndex - 1
	elseif self.selectedIndex > self.scrollOffset + visibleRows then
		self.scrollOffset = self.selectedIndex - visibleRows
	end
	self.scrollOffset = math.max(0, math.min(self.scrollOffset, math.max(0, #self.apps - visibleRows)))
end

function PhoneOS:handleInput(event)
	if SmartphoneOS.isSmartphone(self) then
		return SmartphoneOS.handleInput(self, event)
	end

	if self.currentApp and self.currentApp.handleInput and self.currentApp:handleInput(event) then
		return true
	end

	if event.action == "BACK" then
		if self.currentApp then
			return self:back()
		end
		self:launcher()
		return true
	elseif event.action == "MENU" then
		self:menu()
		return true
	elseif event.action == "LEFT_SOFT" then
		if self.mode == "launcher" and not self.currentApp then
			self:menu()
			return true
		end
		if self.mode == "menu" and not self.currentApp then
			local selected = self.apps[self.selectedIndex]
			return selected and self:openApp(selected.id) or false
		end
		return self:back()
	elseif event.action == "RIGHT_SOFT" then
		if self.mode == "launcher" and not self.currentApp then
			self:openApp("contacts")
			return true
		end
		if self.mode == "menu" and not self.currentApp then
			self:launcher()
			return true
		end
		return self:back()
	elseif event.action == "UP" then
		if self.mode == "menu" then
			self:moveSelection(-1)
		end
		return true
	elseif event.action == "DOWN" then
		if self.mode == "menu" then
			self:moveSelection(1)
		end
		return true
	elseif event.action == "OK" then
		if self.mode == "menu" then
			local selected = self.apps[self.selectedIndex]
			return selected and self:openApp(selected.id) or false
		end
	elseif event.action == "MOUSE_DOWN" and event.displayX and event.displayY and not self.currentApp then
		if self.mode == "launcher" then
			return false
		end
		local top, visibleRows = self.lastMenuLocalTop or 0, self.lastMenuVisibleRows or 0
		if event.displayY < top or event.displayY > top + visibleRows * 20 then
			return false
		end
		local row = self.scrollOffset + math.floor((event.displayY - top) / 20) + 1
		if self.apps[row] then
			self.selectedIndex = row
			return self:openApp(self.apps[row].id)
		end
	end

	return false
end

function PhoneOS:update(deltaTime)
	self.instance.hardware:update(deltaTime)
	if self.currentApp and self.currentApp.update then
		self.currentApp:update(deltaTime)
	end
end

function PhoneOS:renderLauncher(display)
	display:clear()
	local gt = getGameTime()
	local timeText = string.format("%02d:%02d", gt:getHour(), gt:getMinutes())
	local dateText = PhoneUtils.gameDateTime()
	display:drawTextCentered(timeText, display.y + 48, display.colors.fg, UIFont.Large)
	display:drawTextCentered(dateText, display.y + 82, display.colors.dim)
	display:drawTextCentered(self.instance.displayName or self.definition.displayName, display.y + 108, display.colors.fg)
	display:drawTextCentered(I18N.get("GSM"), display.y + 130, display.colors.dim)
	display:drawFooter(I18N.get("Menu"), I18N.get("Names"))
end

function PhoneOS:renderMenu(display)
	display:clear()
	display:drawHeader(I18N.get("MainMenu"))
	self:updateScroll(display)
	local top, visibleRows, contentRight, hasScrollbar = display:getVisibleListMetrics(20, #self.apps)
	self.lastMenuTop = top
	self.lastMenuLocalTop = top - display.y
	self.lastMenuVisibleRows = visibleRows
	local last = math.min(#self.apps, self.scrollOffset + visibleRows)
	for index = self.scrollOffset + 1, last do
		local app = self.apps[index]
		local row = index - self.scrollOffset
		local y = top + (row - 1) * 20
		if index == self.selectedIndex then
			display:fillRect(display.x + 4, y - 1, contentRight - display.x - 4, 18, display.colors.accent)
			display:drawText(app.name, display.x + 10, y, display.colors.bg)
		else
			display:drawText(app.name, display.x + 10, y, display.colors.fg)
		end
	end
	if hasScrollbar then
		display:drawScrollbar(#self.apps, visibleRows, self.scrollOffset, top, display.contentBottom)
	end
	display:drawFooter(I18N.get("Select"), I18N.get("Back"))
end

function PhoneOS:render(display)
	self.displayPanel = display and display.panel or nil
	if SmartphoneOS.isSmartphone(self) then
		SmartphoneOS.render(self, display)
		return
	end

	if self.currentApp then
		self.currentApp:render(display)
		return
	end

	if self.mode == "launcher" then
		self:renderLauncher(display)
	else
		self:renderMenu(display)
	end
end

return PhoneOS
