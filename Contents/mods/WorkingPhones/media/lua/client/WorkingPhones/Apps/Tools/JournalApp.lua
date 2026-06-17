require "ISUI/ISTextEntryBox"

local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local App = setmetatable({}, { __index = Base })
App.__index = App

local OPTIONS = { "NewEntry", "EditEntry", "DeleteEntry" }

function App:new(os)
	local o = Base.new(self, os)
	o.id = "journal"
	o.name = I18N.app("journal")
	o.entries = os.instance.data.journalEntries or {}
	if #o.entries == 0 and os.instance.data.notes then
		for i = 1, #os.instance.data.notes do table.insert(o.entries, { title = I18N.get("NoteNumber", tostring(i)), body = tostring(os.instance.data.notes[i] or "") }) end
	end
	o.selected = 1
	o.optionIndex = 1
	o.mode = "list"
	o.entryBox = nil
	return o
end

function App:save() self.os.instance.data.journalEntries = self.entries end
function App:current() return self.entries[self.selected] end

function App:onClose()
	self:removeEntryBox()
end

function App:removeEntryBox()
	if self.entryBox then
		if self.os.instance.os and self.os.instance.os.displayPanel then
			self.os.instance.os.displayPanel:removeChild(self.entryBox)
		else
			self.entryBox:removeFromUIManager()
		end
		self.entryBox = nil
	end
end

function App:isTextEntryFocused()
	return self.entryBox and self.entryBox.isFocused and self.entryBox:isFocused()
end

function App:addEntry()
	table.insert(self.entries, { title = I18N.get("EntryNumber", tostring(#self.entries + 1)), body = "" })
	self.selected = #self.entries
	self.mode = "edit"
	self:save()
end

function App:deleteCurrent()
	self:removeEntryBox()
	if self:current() then
		table.remove(self.entries, self.selected)
		self.selected = math.max(1, math.min(self.selected, #self.entries))
		self.mode = "list"
		self:save()
	end
end

function App:saveEdit()
	local entry = self:current()
	if entry and self.entryBox then
		entry.body = self.entryBox:getText()
		entry.title = string.sub(entry.body or "", 1, 18)
		if entry.title == "" then entry.title = I18N.get("EntryNumber", tostring(self.selected)) end
		self:save()
	end
	self:removeEntryBox()
	self.mode = "view"
end

function App:activateOption()
	local option = OPTIONS[self.optionIndex]
	if option == "NewEntry" then self:addEntry()
	elseif option == "EditEntry" and self:current() then self.mode = "edit"
	elseif option == "DeleteEntry" then self:deleteCurrent() end
end

function App:handleInput(event)
	if self.mode == "options" then
		if event.action == "MOUSE_DOWN" and event.displayY then
			local top = self.lastOptionsTop or 0
			local visibleRows = self.lastOptionsVisibleRows or #OPTIONS
			if event.displayY >= top and event.displayY <= top + visibleRows * 20 then
				local row = math.floor((event.displayY - top) / 20) + 1
				if row >= 1 and row <= #OPTIONS then
					self.optionIndex = row
					self:activateOption()
					return true
				end
			end
			return true
		end
		if event.action == "UP" then self.optionIndex = math.max(1, self.optionIndex - 1); return true end
		if event.action == "DOWN" then self.optionIndex = math.min(#OPTIONS, self.optionIndex + 1); return true end
		if event.action == "LEFT_SOFT" or event.action == "OK" then self:activateOption(); return true end
		if event.action == "RIGHT_SOFT" then self.mode = "list"; return true end
	elseif self.mode == "edit" then
		if event.action == "CLEAR" and self.entryBox then self.entryBox:setText(""); self.entryBox:focus(); return true end
		if event.action == "MOUSE_DOWN" and self.entryBox then self.entryBox:focus(); return true end
		if event.action == "LEFT_SOFT" or event.action == "OK" then self:saveEdit(); return true end
		if event.action == "RIGHT_SOFT" then self:saveEdit(); return true end
	elseif self.mode == "view" then
		if event.action == "LEFT_SOFT" or event.action == "OK" then self.mode = "edit"; return true end
		if event.action == "RIGHT" then self:deleteCurrent(); return true end
		if event.action == "RIGHT_SOFT" then self.mode = "list"; return true end
	else
		if event.action == "UP" then self.selected = math.max(1, self.selected - 1); return true end
		if event.action == "DOWN" then self.selected = math.min(math.max(1, #self.entries), self.selected + 1); return true end
		if event.action == "MOUSE_DOWN" and event.displayY then
			local top = self.lastListTop or 0
			local visibleRows = self.lastListVisibleRows or 0
			local offset = self.lastListOffset or 0
			if event.displayY >= top and event.displayY <= top + visibleRows * 20 then
				local row = offset + math.floor((event.displayY - top) / 20) + 1
				if self.entries[row] then
					self.selected = row
					self.mode = "view"
					return true
				end
			end
			return true
		end
		if event.action == "LEFT_SOFT" then self.mode = "options"; self.optionIndex = 1; return true end
		if event.action == "OK" and self:current() then self.mode = "view"; return true end
		if event.action == "RIGHT" then self:deleteCurrent(); return true end
	end
	return Base.handleInput(self, event)
end

function App:renderWrapped(display, text, top, bottom)
	local y, line = top, ""
	for word in string.gmatch(tostring(text or "") .. " ", "([^ ]*) ") do
		local candidate = line == "" and word or (line .. " " .. word)
		if display:measureText(candidate) > display.width - 16 then
			display:drawText(line, display.x + 8, y, display.colors.fg); y = y + 15; line = word
		else line = candidate end
		if y > bottom - 15 then break end
	end
	if line ~= "" and y <= bottom then display:drawText(line, display.x + 8, y, display.colors.fg) end
end

function App:ensureEntryBox(display)
	local entry = self:current()
	local x, y = display.x + 6, display.contentY
	local w, h = display.width - 12, display.contentBottom - display.contentY
	if not self.entryBox then
		self.entryBox = ISTextEntryBox:new(entry and entry.body or "", x, y, w, h)
		self.entryBox:initialise()
		self.entryBox:instantiate()
		self.entryBox:setMultipleLine(true)
		self.entryBox:setMaxTextLength(900)
		self.entryBox.backgroundColor = { r = 0.05, g = 0.08, b = 0.05, a = 1 }
		self.entryBox.borderColor = { r = 0.55, g = 0.75, b = 0.45, a = 1 }
		self.entryBox.font = UIFont.Small
		display.panel:addChild(self.entryBox)
		self.entryBox:focus()
	else
		self.entryBox:setX(x); self.entryBox:setY(y); self.entryBox:setWidth(w); self.entryBox:setHeight(h)
	end
	self.entryBox:setVisible(true)
end

function App:drawEntryBox(display)
	if not self.entryBox then return end
	local x, y = display.x + 6, display.contentY
	local w, h = display.width - 12, display.contentBottom - display.contentY
	display:fillRect(x, y, w, h, display.colors.bg)
	display:drawBorder(x, y, w, h, self.entryBox:isFocused() and display.colors.fg or display.colors.dim)
	local text = tostring(self.entryBox:getText() or "")
	if self.entryBox:isFocused() and (not getTimestampMs or math.floor(getTimestampMs() / 500) % 2 == 0) then
		text = text .. "|"
	end
	self:renderWrapped(display, text, y + 4, y + h - 4)
end

function App:renderList(display)
	self:removeEntryBox()
	display:clear()
	display:drawHeader(I18N.app("journal"))
	local top, visibleRows, contentRight, hasScrollbar = display:getVisibleListMetrics(20, #self.entries)
	local offset = math.max(0, math.min(self.selected - visibleRows, math.max(0, #self.entries - visibleRows)))
	self.lastListTop = top - display.y
	self.lastListVisibleRows = visibleRows
	self.lastListOffset = offset
	for i = offset + 1, math.min(#self.entries, offset + visibleRows) do
		local y = top + (i - offset - 1) * 20
		if i == self.selected then display:fillRect(display.x + 4, y - 1, contentRight - display.x - 4, 18, display.colors.accent) end
		display:drawText(display:ellipsize(self.entries[i].title or I18N.get("EntryNumber", tostring(i)), contentRight - display.x - 12), display.x + 10, y, i == self.selected and display.colors.bg or display.colors.fg)
	end
	if #self.entries == 0 then display:drawText(I18N.get("NoEntries"), display.x + 12, top, display.colors.dim) end
	if hasScrollbar then display:drawScrollbar(#self.entries, visibleRows, offset, top, display.contentBottom) end
	display:drawFooter(I18N.get("Options"), I18N.get("Back"))
end

function App:renderOptions(display)
	self:removeEntryBox()
	display:clear()
	display:drawHeader(I18N.get("JournalOptions"))
	local top, visibleRows, contentRight, hasScrollbar = display:getVisibleListMetrics(20, #OPTIONS)
	self.lastOptionsTop = top - display.y
	self.lastOptionsVisibleRows = visibleRows
	for i = 1, #OPTIONS do
		local y = top + (i - 1) * 20
		if i == self.optionIndex then display:fillRect(display.x + 4, y - 1, contentRight - display.x - 4, 18, display.colors.accent) end
		display:drawText(I18N.get(OPTIONS[i]), display.x + 8, y, i == self.optionIndex and display.colors.bg or display.colors.fg)
	end
	if hasScrollbar then display:drawScrollbar(#OPTIONS, visibleRows, 0, top, display.contentBottom) end
	display:drawFooter(I18N.get("Select"), I18N.get("Back"))
end

function App:renderView(display)
	self:removeEntryBox()
	display:clear()
	local entry = self:current()
	display:drawHeader(entry and entry.title or I18N.get("Entry"))
	self:renderWrapped(display, entry and entry.body or "", display.contentY, display.contentBottom)
	display:drawFooter(I18N.get("Edit"), I18N.get("Back"))
end

function App:renderEdit(display)
	display:clear()
	display:drawHeader(I18N.get("Writing"))
	self:ensureEntryBox(display)
	self:drawEntryBox(display)
	display:drawFooter(I18N.get("Done"), I18N.get("Back"))
end

function App:render(display)
	if self.mode == "edit" then return self:renderEdit(display) end
	if self.mode == "options" then return self:renderOptions(display) end
	if self.mode == "view" then return self:renderView(display) end
	return self:renderList(display)
end

return App
