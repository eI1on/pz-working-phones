require "ISUI/ISTextEntryBox"

local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local Networking = require("WorkingPhones/Core/PhoneNetworking")
local Persistence = require("WorkingPhones/Core/PhonePersistence")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local Assets = require("WorkingPhones/Assets/PhoneAssets")

local App = setmetatable({}, { __index = Base })
App.__index = App

local OPTIONS = { "NewContact", "Modify", "Delete", "Call", "SendMessage", "NearbyPhones" }
local AVATAR_TEXTURE = Assets.SMARTPHONE_AVATARS .. "ui_working_smartphone_avatar_default.png"

function App:new(os)
	local o = Base.new(self, os)
	o.id = "contacts"
	o.name = I18N.app("contacts")
	o.selected = 1
	o.optionIndex = 1
	o.mode = "list"
	o.editing = nil
	o.error = nil
	o.candidates = {}
	o.entries = {}
	return o
end

function App:contacts()
	return Persistence.getContacts(self.os.instance.item, self.os.instance.definition.id)
end

function App:onClose()
	self:removeEntries()
end

function App:isTextEntryFocused()
	local entryKeys = { "name", "number" }
	for i = 1, #entryKeys do
		local entry = self.entries and self.entries[entryKeys[i]]
		if entry and entry.isFocused and entry:isFocused() then
			return true
		end
	end
	return false
end

function App:removeEntries()
	local entryKeys = { "name", "number" }
	for i = 1, #entryKeys do
		local entry = self.entries and self.entries[entryKeys[i]]
		if entry and self.os.instance.os and self.os.instance.os.displayPanel then
			self.os.instance.os.displayPanel:removeChild(entry)
		elseif entry and entry.removeFromUIManager then
			entry:removeFromUIManager()
		end
	end
	self.entries = {}
end

function App:buildCandidates()
	self.candidates = self.os.instance.data.openPhonesCache or {}
	Networking.requestOpenPhones(self.os.instance.phoneKey)
	if #self.candidates == 0 then table.insert(self.candidates, { name = I18N.get("Emergency"), number = "555-000000" }) end
end

function App:onOpenPhonesList(phones)
	self.candidates = phones or {}
	if self.mode == "add" and #self.candidates == 0 then
		table.insert(self.candidates, { name = I18N.get("Emergency"), number = "555-000000" })
	end
end

function App:startEdit(contact)
	self.mode = "edit"
	self.editing = {
		name = contact and tostring(contact.name or "") or "",
		number = contact and tostring(contact.number or "") or "",
		original = contact,
	}
	self.error = nil
end

function App:saveEdit()
	if self.entries.name then self.editing.name = self.entries.name:getText() end
	if self.entries.number then self.editing.number = self.entries.number:getText() end
	if not self.editing or self.editing.number == "" then
		self.error = I18N.get("NumberRequired")
		return
	end
	if self.editing.original then
		self.editing.original.name = self.editing.name ~= "" and self.editing.name or self.editing.number
		self.editing.original.number = self.editing.number
	else
		Persistence.addContact(self.os.instance.item, self.editing.name ~= "" and self.editing.name or self.editing.number, self.editing.number, self.os.instance.definition.id)
		self.selected = #self:contacts()
	end
	self:removeEntries()
	self.mode = "list"
	self.editing = nil
end

function App:deleteSelected()
	local contacts = self:contacts()
	if contacts[self.selected] then
		table.remove(contacts, self.selected)
		self.selected = math.max(1, math.min(self.selected, #contacts))
	end
end

function App:callContact(contact)
	if not contact then
		return false
	end
	self:removeEntries()
	self.os:openApp("phone")
	local app = self.os.currentApp
	if app and app.call then
		app:call(contact)
	end
	return true
end

function App:messageContact(contact)
	if not contact then
		return false
	end
	self:removeEntries()
	self.os:openApp("messages")
	local app = self.os.currentApp
	if app and app.openThreadForNumber then
		app:openThreadForNumber(contact.number)
	end
	return true
end

function App:activateOption()
	local option = OPTIONS[self.optionIndex]
	local contact = self:contacts()[self.selected]
	if option == "NewContact" then
		self:startEdit(nil)
	elseif option == "Modify" then
		if contact then self:startEdit(contact) end
	elseif option == "Delete" then
		self:deleteSelected()
		self.mode = "list"
	elseif option == "Call" then
		self:callContact(contact)
	elseif option == "SendMessage" then
		self:messageContact(contact)
	elseif option == "NearbyPhones" then
		self:buildCandidates()
		self.mode = "add"
		self.selected = 1
	end
end

function App:handleInput(event)
	if self.mode == "edit" then
		if event.action == "MOUSE_DOWN" and event.displayX and event.displayY then
			local entryKeys = { "name", "number" }
			for i = 1, #entryKeys do
				local entry = self.entries and self.entries[entryKeys[i]]
				if entry then
					local x = entry.phoneLocalX or 0
					local y = entry.phoneLocalY or 0
					if event.displayX >= x and event.displayX <= x + entry:getWidth()
						and event.displayY >= y and event.displayY <= y + entry:getHeight() then
						entry:focus()
						return true
					end
				end
			end
		end
		if event.action == "LEFT_SOFT" or event.action == "OK" then self:saveEdit(); return true end
		if event.action == "RIGHT_SOFT" then self:removeEntries(); self.mode = "list"; return true end
		return Base.handleInput(self, event)
	elseif self.mode == "options" then
		if event.action == "UP" then self.optionIndex = math.max(1, self.optionIndex - 1); return true end
		if event.action == "DOWN" then self.optionIndex = math.min(#OPTIONS, self.optionIndex + 1); return true end
		if event.action == "LEFT_SOFT" or event.action == "OK" then self:activateOption(); return true end
		if event.action == "MOUSE_DOWN" and event.displayY then
			local row = self.optionOffset and (self.optionOffset + math.floor((event.displayY - (self.optionTop or 0)) / 20) + 1) or nil
			if row and OPTIONS[row] then self.optionIndex = row; self:activateOption(); return true end
		end
		if event.action == "RIGHT_SOFT" then self.mode = "list"; return true end
		return Base.handleInput(self, event)
	elseif self.mode == "add" then
		if event.action == "UP" then self.selected = math.max(1, self.selected - 1); return true end
		if event.action == "DOWN" then self.selected = math.min(#self.candidates, self.selected + 1); return true end
		if event.action == "MOUSE_DOWN" and event.displayY then
			local row = self.rowOffset and (self.rowOffset + math.floor((event.displayY - (self.rowTopLocal or 0)) / 20) + 1) or nil
			if row and self.candidates[row] then
				self.selected = row
				local c = self.candidates[row]
				Persistence.addContact(self.os.instance.item, c.name, c.number, self.os.instance.definition.id)
				self.mode = "list"; self.selected = #self:contacts()
				return true
			end
		end
		if event.action == "LEFT_SOFT" or event.action == "OK" then
			local c = self.candidates[self.selected]
			if c then Persistence.addContact(self.os.instance.item, c.name, c.number, self.os.instance.definition.id) end
			self.mode = "list"; self.selected = #self:contacts()
			return true
		end
		if event.action == "RIGHT_SOFT" then self.mode = "options"; return true end
		return Base.handleInput(self, event)
	end

	local contacts = self:contacts()
	if event.action == "UP" then self.selected = math.max(1, self.selected - 1); return true end
	if event.action == "DOWN" then self.selected = math.min(math.max(1, #contacts), self.selected + 1); return true end
	if event.action == "MOUSE_DOWN" and event.displayY then
		if self.os.definition.hardwareType == "smartphone" and self.smartRowRects then
			for i = 1, #self.smartRowRects do
				local rect = self.smartRowRects[i]
				if event.displayX >= rect.x and event.displayX <= rect.x + rect.w
					and event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
					self.selected = rect.index
					if rect.callX and event.displayX >= rect.callX and event.displayX <= rect.callX + rect.buttonW then
						return self:callContact(contacts[self.selected])
					end
					if rect.messageX and event.displayX >= rect.messageX and event.displayX <= rect.messageX + rect.buttonW then
						return self:messageContact(contacts[self.selected])
					end
					return true
				end
			end
		end
		local row = self.rowOffset and (self.rowOffset + math.floor((event.displayY - (self.rowTopLocal or 0)) / 20) + 1) or nil
		if row and contacts[row] then self.selected = row; self.mode = "options"; self.optionIndex = 2; return true end
	end
	if event.action == "LEFT_SOFT" then self.mode = "options"; self.optionIndex = 1; return true end
	if event.action == "OK" and contacts[self.selected] then self.mode = "options"; self.optionIndex = 2; return true end
	return Base.handleInput(self, event)
end

function App:ensureEntry(display, key, text, x, y, w, h)
	local entry = self.entries[key]
	if not entry then
		entry = ISTextEntryBox:new(text or "", x, y, w, h)
		entry:initialise()
		entry:instantiate()
		entry:setMaxTextLength(key == "name" and 24 or 16)
		if self.os.definition.hardwareType == "smartphone" then
			entry.backgroundColor = { r = 0.96, g = 0.97, b = 0.98, a = 1 }
			entry.borderColor = { r = 0.18, g = 0.48, b = 0.86, a = 1 }
		else
			entry.backgroundColor = { r = 0.05, g = 0.08, b = 0.05, a = 1 }
			entry.borderColor = { r = 0.55, g = 0.75, b = 0.45, a = 1 }
		end
		entry.font = UIFont.Small
		display.panel:addChild(entry)
		self.entries[key] = entry
	else
		entry:setX(x); entry:setY(y); entry:setWidth(w); entry:setHeight(h)
	end
	entry:setVisible(true)
	entry.phoneLocalX = x - display.x
	entry.phoneLocalY = y - display.y
	return entry
end

function App:drawEntry(display, entry, label, x, y, w, h)
	local focused = entry and entry.isFocused and entry:isFocused()
	display:drawText(label, display.x + 10, y + 3, display.colors.dim)
	display:fillRect(x, y, w, h, display.colors.bg)
	display:drawBorder(x, y, w, h, focused and display.colors.fg or display.colors.dim)
	local text = entry and entry.getText and entry:getText() or ""
	if focused and (not getTimestampMs or math.floor(getTimestampMs() / 500) % 2 == 0) then
		text = text .. "|"
	end
	display:drawText(display:ellipsize(text, w - 8), x + 4, y + 4, display.colors.fg)
end

function App:renderSmartRows(display, title, list, emptyText)
	self:removeEntries()
	display:clear()
	display:drawText(title, display.x + 14, display.y + 34, display.colors.fg, UIFont.Medium)
	display:drawText(I18N.get("MyNumberLabel", tostring(self.os.instance.number)), display.x + 14, display.y + 58,
		display.colors.dim)
	local avatar = getTexture(AVATAR_TEXTURE)
	local rowTop = display.y + 84
	local rowH = 52
	local visibleRows = math.max(1, math.floor((display.contentBottom - rowTop - 4) / rowH))
	local offset = math.max(0, math.min(self.selected - visibleRows, math.max(0, #list - visibleRows)))
	self.rowTopLocal = rowTop - display.y
	self.rowOffset = offset
	self.smartRowRects = {}
	for i = offset + 1, math.min(#list, offset + visibleRows) do
		local item = list[i]
		local y = rowTop + (i - offset - 1) * rowH
		local selected = i == self.selected
		display:fillRect(display.x + 10, y, display.width - 20, rowH - 7, selected and display.colors.accent or display.colors.bg)
		display:drawBorder(display.x + 10, y, display.width - 20, rowH - 7, selected and display.colors.fg or display.colors.border)
		if avatar then
			display.panel:drawTextureScaledAspect(avatar, display.x + 18, y + 7, 32, 32, 1, 1, 1, 1)
		else
			display:fillRect(display.x + 18, y + 7, 32, 32, display.colors.dim)
		end
		local textColor = selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.fg
		local actionW = 36
		local actionGap = 5
		local actionRight = display.width - 18
		local messageX = actionRight - actionW
		local callX = messageX - actionGap - actionW
		local textW = callX - 62
		display:drawText(display:ellipsize(tostring(item.name or item.number), textW), display.x + 58, y + 8,
			textColor)
		display:drawText(display:ellipsize(tostring(item.number or ""), textW), display.x + 58, y + 26,
			selected and { r = 0.9, g = 0.94, b = 1, a = 1 } or display.colors.dim)
		display:drawBorder(display.x + callX, y + 10, actionW, 25, selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.accent)
		display:drawTextCentered(I18N.get("Call"), y + 16, selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.accent,
			UIFont.Small, display.x + callX, display.x + callX + actionW)
		display:drawBorder(display.x + messageX, y + 10, actionW, 25, selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.accent)
		display:drawTextCentered(I18N.get("Msg"), y + 16, selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.accent,
			UIFont.Small, display.x + messageX, display.x + messageX + actionW)
		table.insert(self.smartRowRects, {
			x = 10,
			y = y - display.y,
			w = display.width - 20,
			h = rowH - 7,
			index = i,
			callX = callX,
			messageX = messageX,
			buttonW = actionW,
		})
	end
	if #list == 0 then
		display:drawText(emptyText, display.x + 14, rowTop + 20, display.colors.dim)
	end
	display:drawFooter(I18N.get("Options"), I18N.get("Back"))
end

function App:renderRows(display, title, list, emptyText)
	if self.os.definition.hardwareType == "smartphone" then
		return self:renderSmartRows(display, title, list, emptyText)
	end
	self:removeEntries()
	display:clear()
	display:drawHeader(title)
	display:drawText(I18N.get("MyNumberLabel", tostring(self.os.instance.number)), display.x + 8, display.y + display.statusBarHeight + display.headerHeight + 4, display.colors.fg)
	local rowTop = display.y + display.statusBarHeight + display.headerHeight + 24
	local visibleRows = math.max(1, math.floor((display.contentBottom - rowTop) / 20))
	local hasScrollbar = #list > visibleRows
	local contentRight = hasScrollbar and (display.contentRight - display.scrollbarWidth - 3) or display.contentRight
	local offset = math.max(0, math.min(self.selected - visibleRows, math.max(0, #list - visibleRows)))
	self.rowTopLocal = rowTop - display.y
	self.rowOffset = offset
	for i = offset + 1, math.min(#list, offset + visibleRows) do
		local item = list[i]
		local y = rowTop + (i - offset - 1) * 20
		if i == self.selected then display:fillRect(display.x + 4, y - 1, contentRight - display.x - 4, 18, display.colors.accent) end
		local color = i == self.selected and display.colors.bg or display.colors.fg
		display:drawText(display:ellipsize(tostring(item.name or item.number), contentRight - display.x - 70), display.x + 8, y, color)
		display:drawTextRight(tostring(item.number or ""), contentRight - 2, y, i == self.selected and display.colors.bg or display.colors.dim)
	end
	if #list == 0 then display:drawText(emptyText, display.x + 12, rowTop, display.colors.dim) end
	if hasScrollbar then display:drawScrollbar(#list, visibleRows, offset, rowTop, display.contentBottom) end
end

function App:renderOptions(display)
	self:removeEntries()
	display:clear()
	display:drawHeader(I18N.get("ContactOptions"))
	local top, visibleRows, contentRight, hasScrollbar = display:getVisibleListMetrics(20, #OPTIONS)
	local offset = math.max(0, math.min(self.optionIndex - visibleRows, math.max(0, #OPTIONS - visibleRows)))
	self.optionTop = top - display.y
	self.optionOffset = offset
	for i = offset + 1, math.min(#OPTIONS, offset + visibleRows) do
		local y = top + (i - offset - 1) * 20
		if i == self.optionIndex then display:fillRect(display.x + 4, y - 1, contentRight - display.x - 4, 18, display.colors.accent) end
		display:drawText(I18N.get(OPTIONS[i]), display.x + 8, y, i == self.optionIndex and display.colors.bg or display.colors.fg)
	end
	if hasScrollbar then display:drawScrollbar(#OPTIONS, visibleRows, offset, top, display.contentBottom) end
	display:drawFooter(I18N.get("Select"), I18N.get("Back"))
end

function App:renderEdit(display)
	display:clear()
	display:drawHeader(self.editing and self.editing.original and I18N.get("EditContact") or I18N.get("NewContact"))
	local x = display.x + 68
	local w = display.width - 78
	local y1 = display.contentY + 4
	local y2 = y1 + 34
	local nameEntry = self:ensureEntry(display, "name", self.editing and self.editing.name or "", x, y1, w, 22)
	local numberEntry = self:ensureEntry(display, "number", self.editing and self.editing.number or "", x, y2, w, 22)
	self:drawEntry(display, nameEntry, I18N.get("Name"), x, y1, w, 22)
	self:drawEntry(display, numberEntry, I18N.get("Number"), x, y2, w, 22)
	if self.error then display:drawText(self.error, display.x + 10, display.contentY + 74, display.colors.accent) end
	display:drawFooter(I18N.get("Save"), I18N.get("Back"))
end

function App:render(display)
	if self.mode == "edit" then return self:renderEdit(display) end
	if self.mode == "options" then return self:renderOptions(display) end
	if self.mode == "add" then
		self:renderRows(display, I18N.get("NearbyPhones"), self.candidates, I18N.get("NoPlayers"))
		display:drawFooter(I18N.get("Add"), I18N.get("Back"))
		return
	end
	self:renderRows(display, I18N.app("contacts"), self:contacts(), I18N.get("NoContactsShort"))
	display:drawFooter(I18N.get("Options"), I18N.get("Back"))
end

return App
