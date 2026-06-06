require "ISUI/ISTextEntryBox"

local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local PhoneUtils = require("WorkingPhones/Core/PhoneUtils")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local SoundRegistry = require("WorkingPhones/Registries/PhoneSoundRegistry")
local PhoneAudioEngine = require("WorkingPhones/Audio/PhoneAudioEngine")
local App = setmetatable({}, { __index = Base })
App.__index = App

local function tr(key, ...)
	return I18N.get(key, ...)
end

local OPTIONS = { "NewAlarm", "EditAlarm", "DeleteAlarm" }

local function findSoundIndex(list, id, eventName)
	for i = 1, #list do
		if tostring(list[i].id) == tostring(id or "") or tostring(list[i].event) == tostring(eventName or "") then
			return i
		end
	end
	return 1
end

function App:new(os)
	local o = Base.new(self, os)
	o.id = "clock"
	o.name = I18N.app("clock")
	o.alarms = os.instance.data.alarms or {}
	o.alarmSounds = SoundRegistry.list("alarm", os.definition)
	for i = 1, #o.alarms do
		local alarm = o.alarms[i]
		alarm.days = alarm.days or { true, true, true, true, true, true, true }
		local sound = SoundRegistry.resolve(alarm.soundId or os.instance.data.alarmId, "alarm", os.definition)
		alarm.soundId = sound and sound.id or alarm.soundId
		alarm.soundEvent = sound and sound.event or alarm.soundEvent
	end
	o.selected = 1
	o.mode = "list"
	o.editField = 1
	o.optionIndex = 1
	o.lastRingKey = nil
	o.nameEntry = nil
	return o
end

function App:newAlarm()
	local gt = getGameTime()
	local hour = (gt:getHour() + 1) % 24
	local sound = SoundRegistry.resolve(self.os.instance.data.alarmId, "alarm", self.os.definition)
	return {
		name = tr("Alarm"),
		hour = hour,
		minute = 0,
		enabled = true,
		soundId = sound and sound.id or nil,
		soundEvent = sound and sound.event or self.os.instance.data.alarmEvent,
		days = { true, true, true, true, true, true, true },
	}
end

function App:onClose()
	PhoneAudioEngine.stopPreview()
	self:removeNameEntry()
end

function App:removeNameEntry()
	if self.nameEntry then
		if self.os.instance.os and self.os.instance.os.displayPanel then
			self.os.instance.os.displayPanel:removeChild(self.nameEntry)
		else
			self.nameEntry:removeFromUIManager()
		end
		self.nameEntry = nil
	end
end

function App:save()
	self.os.instance.data.alarms = self.alarms
end

function App:dayIndex()
	local gt = getGameTime()
	local day = gt:getDay()
	return ((day - 1) % 7) + 1
end

function App:alarmLabel(alarm)
	local days = {}
	for i = 1, 7 do
		if alarm.days[i] then table.insert(days, I18N.dayShort(i)) end
	end
	local suffix = #days == 7 and tr("EveryDay") or table.concat(days, " ")
	local name = tostring(alarm.name or tr("Alarm"))
	return name .. " " .. string.format("%02d:%02d %s", alarm.hour or 0, alarm.minute or 0, alarm.enabled and suffix or tr("Off"))
end

function App:alarmSound(alarm)
	alarm = alarm or {}
	return SoundRegistry.resolve(alarm.soundId or self.os.instance.data.alarmId, "alarm", self.os.definition)
end

function App:cycleAlarmSound(alarm, delta)
	local list = self.alarmSounds or {}
	if #list == 0 then return false end
	local index = findSoundIndex(list, alarm.soundId, alarm.soundEvent) + delta
	if index < 1 then index = #list end
	if index > #list then index = 1 end
	local sound = list[index]
	alarm.soundId = sound.id
	alarm.soundEvent = sound.event
	self.os.instance.data.alarmId = sound.id
	self.os.instance.data.alarmEvent = sound.event
	return true
end

function App:update(deltaTime)
	local gt = getGameTime()
	local key = string.format("%d:%02d:%02d", gt:getDay(), gt:getHour(), gt:getMinutes())
	if key == self.lastRingKey then return end
	for i = 1, #self.alarms do
		local alarm = self.alarms[i]
		if alarm.enabled and alarm.hour == gt:getHour() and alarm.minute == gt:getMinutes() and alarm.days[self:dayIndex()] then
			self.os:pushNotification({
				kind = "alarm",
				text = tostring(alarm.name or tr("Alarm")) .. " " .. tr("AlarmAt", string.format("%02d:%02d", alarm.hour, alarm.minute)),
				primary = tr("Open"),
				secondary = tr("Dismiss"),
			})
			local sound = self:alarmSound(alarm)
			PhoneUtils.playPhoneAlert(self.os.instance.playerObj,
				(sound and sound.event) or self.os.instance.data.alarmEvent or self.os.instance.data.ringtoneEvent,
				self.os.instance.data, true, "alarm")
			self.lastRingKey = key
			break
		end
	end
end

function App:activateOption()
	local option = OPTIONS[self.optionIndex]
	if option == "NewAlarm" then
		table.insert(self.alarms, self:newAlarm())
		self.selected = #self.alarms
		self.mode = "edit"
		self.editField = 1
		self:save()
	elseif option == "EditAlarm" then
		if self.alarms[self.selected] then
			self.mode = "edit"
			self.editField = 1
		end
	elseif option == "DeleteAlarm" then
		if self.alarms[self.selected] then
			table.remove(self.alarms, self.selected)
			self.selected = math.max(1, math.min(self.selected, #self.alarms))
			self:save()
		end
		self.mode = "list"
	end
end

function App:handleListInput(event)
	if event.action == "UP" then
		self.selected = math.max(1, self.selected - 1)
		return true
	elseif event.action == "DOWN" then
		self.selected = math.min(math.max(1, #self.alarms), self.selected + 1)
		return true
	elseif event.action == "LEFT_SOFT" then
		self.mode = "options"
		self.optionIndex = 1
		return true
	elseif event.action == "OK" then
		if self.alarms[self.selected] then
			self.mode = "edit"
			self.editField = 1
		end
		return true
	elseif event.action == "MOUSE_DOWN" and event.displayY then
		local row = self.listOffset and (self.listOffset + math.floor((event.displayY - (self.listTop or 0)) / 18) + 1) or
		nil
		if row and self.alarms[row] then
			self.selected = row; self.mode = "edit"; self.editField = 1; return true
		end
	elseif event.action == "RIGHT" and self.alarms[self.selected] then
		table.remove(self.alarms, self.selected)
		self.selected = math.max(1, math.min(self.selected, #self.alarms))
		self:save()
		return true
	end
	return false
end

function App:handleOptionsInput(event)
	if event.action == "UP" then
		self.optionIndex = math.max(1, self.optionIndex - 1); return true
	end
	if event.action == "DOWN" then
		self.optionIndex = math.min(#OPTIONS, self.optionIndex + 1); return true
	end
	if event.action == "LEFT_SOFT" or event.action == "OK" then
		self:activateOption(); return true
	end
	if event.action == "MOUSE_DOWN" and event.displayY then
		local row = self.optionOffset and
		(self.optionOffset + math.floor((event.displayY - (self.optionTop or 0)) / 18) + 1) or nil
		if row and OPTIONS[row] then
			self.optionIndex = row; self:activateOption(); return true
		end
	end
	if event.action == "RIGHT_SOFT" then
		self.mode = "list"; return true
	end
	return false
end

function App:handleEditInput(event)
	local alarm = self.alarms[self.selected]
	if not alarm then
		self.mode = "list"; return true
	end
	if self.nameEntry then alarm.name = self.nameEntry:getText() end
	if event.action == "UP" then
		self.editField = math.max(1, self.editField - 1)
		return true
	elseif event.action == "DOWN" then
		self.editField = math.min(12, self.editField + 1)
		return true
	elseif event.action == "MOUSE_DOWN" and event.displayY then
		local row = self.editOffset and (self.editOffset + math.floor((event.displayY - (self.editTop or 0)) / 18) + 1) or nil
		if row then
			self.editField = math.max(1, math.min(12, row))
			if self.editField == 1 and self.nameEntry then
				self.nameEntry:focus()
				return true
			end
			if self.editField == 2 or self.editField == 3 or self.editField == 5 then
				local midpoint = math.floor((tonumber(self.editRightLocal) or 0) / 2)
				return self:handleEditInput({ action = event.displayX and event.displayX < midpoint and "LEFT" or "RIGHT" })
			end
			return self:handleEditInput({ action = "OK" })
		end
	elseif event.action == "LEFT" or event.action == "RIGHT" or event.action == "OK" then
		local delta = event.action == "LEFT" and -1 or 1
		if self.editField == 1 then
			if self.nameEntry then self.nameEntry:focus() end
		elseif self.editField == 2 then
			alarm.hour = (alarm.hour + delta) % 24
		elseif self.editField == 3 then
			alarm.minute = (alarm.minute + delta * 5) % 60
		elseif self.editField == 4 then
			alarm.enabled = not alarm.enabled
		elseif self.editField == 5 then
			if event.action == "OK" then
				local sound = self:alarmSound(alarm)
				PhoneUtils.playPhoneAlert(self.os.instance.playerObj,
					(sound and sound.event) or self.os.instance.data.alarmEvent or self.os.instance.data.ringtoneEvent,
					self.os.instance.data, false, "alarm", true)
			else
				self:cycleAlarmSound(alarm, delta)
				local sound = self:alarmSound(alarm)
				PhoneUtils.playPhoneAlert(self.os.instance.playerObj,
					(sound and sound.event) or self.os.instance.data.alarmEvent or self.os.instance.data.ringtoneEvent,
					self.os.instance.data, false, "alarm", true)
			end
		else
			local day = self.editField - 5
			alarm.days[day] = not alarm.days[day]
		end
		self:save()
		return true
	elseif event.action == "LEFT_SOFT" then
		if self.nameEntry then alarm.name = self.nameEntry:getText() end
		PhoneAudioEngine.stopPreview()
		self:removeNameEntry()
		self.mode = "list"
		self:save()
		return true
	elseif event.action == "RIGHT_SOFT" then
		PhoneAudioEngine.stopPreview()
		self:removeNameEntry()
		self.mode = "list"
		return true
	end
	return false
end

function App:handleInput(event)
	if self.mode == "options" then
		if self:handleOptionsInput(event) then return true end
	elseif self.mode == "edit" then
		if self:handleEditInput(event) then return true end
	else
		if self:handleListInput(event) then return true end
	end
	return Base.handleInput(self, event)
end

function App:renderList(display)
	self:removeNameEntry()
	display:clear()
	display:drawHeader(I18N.app("clock"))
	local gt = getGameTime()
	local timeText = string.format("%02d:%02d", gt:getHour(), gt:getMinutes())
	display:drawTextCentered(timeText, display.y + 44, display.colors.fg, UIFont.Large)
	local top = display.y + 82
	local visible = math.max(1, math.floor((display.contentBottom - top) / 18))
	local hasScrollbar = #self.alarms > visible
	local right = hasScrollbar and (display.contentRight - display.scrollbarWidth - 3) or display.contentRight
	local offset = math.max(0, math.min(self.selected - visible, math.max(0, #self.alarms - visible)))
	self.listTop = top - display.y
	self.listOffset = offset
	for i = offset + 1, math.min(#self.alarms, offset + visible) do
		local alarm = self.alarms[i]
		local y = top + (i - offset - 1) * 18
		if i == self.selected then display:fillRect(display.x + 4, y - 1, right - display.x - 4, 16,
				display.colors.accent) end
		display:drawText(display:ellipsize(self:alarmLabel(alarm), right - display.x - 12), display.x + 8, y,
			i == self.selected and display.colors.bg or display.colors.fg)
	end
	if hasScrollbar then display:drawScrollbar(#self.alarms, visible, offset, top, display.contentBottom) end
	if #self.alarms == 0 then display:drawText(tr("NoAlarms"), display.x + 12, top, display.colors.dim) end
	display:drawFooter(tr("Options"), tr("Back"))
end

function App:renderOptions(display)
	self:removeNameEntry()
	display:clear()
	display:drawHeader(tr("AlarmOptions"))
	local top, visible, right, hasScrollbar = display:getVisibleListMetrics(18, #OPTIONS)
	local offset = math.max(0, math.min(self.optionIndex - visible, math.max(0, #OPTIONS - visible)))
	self.optionTop = top - display.y
	self.optionOffset = offset
	for i = offset + 1, math.min(#OPTIONS, offset + visible) do
		local y = top + (i - offset - 1) * 18
		if i == self.optionIndex then display:fillRect(display.x + 4, y - 1, right - display.x - 4, 16,
				display.colors.accent) end
		display:drawText(tr(OPTIONS[i]), display.x + 8, y, i == self.optionIndex and display.colors.bg or display.colors.fg)
	end
	if hasScrollbar then display:drawScrollbar(#OPTIONS, visible, offset, top, display.contentBottom) end
	display:drawFooter(tr("Select"), tr("Back"))
end

function App:ensureNameEntry(display, alarm, x, y, w, h)
	if not self.nameEntry then
		self.nameEntry = ISTextEntryBox:new(tostring(alarm.name or tr("Alarm")), x, y, w, h)
		self.nameEntry:initialise()
		self.nameEntry:instantiate()
		self.nameEntry:setMaxTextLength(24)
		self.nameEntry.font = UIFont.Small
		display.panel:addChild(self.nameEntry)
	else
		self.nameEntry:setX(x); self.nameEntry:setY(y); self.nameEntry:setWidth(w); self.nameEntry:setHeight(h)
	end
	self.nameEntry:setVisible(true)
end

function App:renderEdit(display)
	display:clear()
	display:drawHeader(tr("EditAlarm"))
	local alarm = self.alarms[self.selected]
	local alarmSound = self:alarmSound(alarm)
	local rows = {
		{ tr("AlarmName"), tostring(alarm.name or tr("Alarm")) },
		{ tr("Hour"),      string.format("%02d", alarm.hour) },
		{ tr("Minute"),    string.format("%02d", alarm.minute) },
		{ tr("Enabled"),   alarm.enabled and tr("On") or tr("Off") },
		{ tr("AlarmSound"), alarmSound and SoundRegistry.label(alarmSound) or tr("None") },
	}
	for i = 1, 7 do table.insert(rows, { I18N.dayShort(i), alarm.days[i] and tr("On") or tr("Off") }) end
	local top, visible, right, hasScrollbar = display:getVisibleListMetrics(18, #rows)
	local offset = math.max(0, math.min(self.editField - visible, math.max(0, #rows - visible)))
	self.editTop = top - display.y
	self.editOffset = offset
	self.editRightLocal = right - display.x
	if offset > 0 then
		self:removeNameEntry()
	end
	for i = offset + 1, math.min(#rows, offset + visible) do
		local y = top + (i - offset - 1) * 18
		if i == self.editField then display:fillRect(display.x + 4, y - 1, right - display.x - 4, 16,
				display.colors.accent) end
		local color = i == self.editField and display.colors.bg or display.colors.fg
		display:drawText(rows[i][1], display.x + 8, y, color)
		if i == 1 then
			local entryX = display.x + 82
			local entryW = right - entryX - 2
			self:ensureNameEntry(display, alarm, entryX, y - 2, entryW, 18)
		else
			display:drawTextRight(rows[i][2], right - 2, y, color)
		end
	end
	if hasScrollbar then display:drawScrollbar(#rows, visible, offset, top, display.contentBottom) end
	display:drawFooter(tr("Save"), tr("Back"))
end

function App:render(display)
	if self.mode == "options" then
		self:renderOptions(display)
	elseif self.mode == "edit" and self.alarms[self.selected] then
		self:renderEdit(display)
	else
		self:renderList(display)
	end
end

return App
