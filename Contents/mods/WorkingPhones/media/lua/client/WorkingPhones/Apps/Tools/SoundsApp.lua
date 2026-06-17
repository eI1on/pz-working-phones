local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local PhoneUtils = require("WorkingPhones/Core/PhoneUtils")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local SoundRegistry = require("WorkingPhones/Registries/PhoneSoundRegistry")
local PhoneAudioEngine = require("WorkingPhones/Audio/PhoneAudioEngine")
local VoiceBridge = require("WorkingPhones/Core/PhoneVoiceBridge")
local App = setmetatable({}, { __index = Base })
App.__index = App

local MODES = { "sound", "vibrate", "silent" }
local SOUND_ROWS = {
	{ category = "ringtone", labelKey = "Ringtone" },
	{ category = "notification", labelKey = "NotificationTone" },
	{ mode = true, labelKey = "AlertMode" },
	{ volume = true, labelKey = "Volume" },
}

local function soundFields(category)
	if category == "notification" then return "notificationId", "notificationEvent" end
	return "ringtoneId", "ringtoneEvent"
end

local function findSoundIndex(list, id, eventName)
	for i = 1, #list do
		if tostring(list[i].id) == tostring(id or "") or tostring(list[i].event) == tostring(eventName or "") then
			return i
		end
	end
	return 1
end

local function saveVolume(app, volume)
	app.volume = math.max(0, math.min(1, tonumber(volume) or 0))
	app.os.instance.data.volume = app.volume
	VoiceBridge.refreshVolume(app.os.instance.data)
end

function App:new(os)
	local o = Base.new(self, os)
	o.id = "sounds"
	o.name = I18N.app("sounds")
	o.volume = os.instance.data.volume or 0.7
	o.soundMode = os.instance.data.soundMode or "sound"
	o.sounds = {
		ringtone = SoundRegistry.list("ringtone", os.definition),
		notification = SoundRegistry.list("notification", os.definition),
	}
	o.selected = {}
	for i = 1, #SOUND_ROWS do
		local category = SOUND_ROWS[i].category
		if category then
			local idField, eventField = soundFields(category)
			o.selected[category] = findSoundIndex(o.sounds[category], os.instance.data[idField], os.instance.data[eventField])
		end
	end
	o.focus = 1
	o.rowRects = {}
	return o
end

function App:onClose()
	PhoneAudioEngine.stopPreview()
end

function App:currentSound(category)
	local list = self.sounds[category] or {}
	return list[self.selected[category] or 1] or list[1]
end

function App:saveSound(category)
	local sound = self:currentSound(category)
	if not sound then return false end
	local idField, eventField = soundFields(category)
	self.os.instance.data[idField] = sound.id
	self.os.instance.data[eventField] = sound.event
	return true
end

function App:saveMode()
	self.os.instance.data.soundMode = self.soundMode
end

function App:modeIndex()
	for i = 1, #MODES do
		if MODES[i] == self.soundMode then return i end
	end
	return 1
end

function App:changeMode(delta)
	local index = self:modeIndex() + delta
	if index < 1 then index = #MODES end
	if index > #MODES then index = 1 end
	self.soundMode = MODES[index]
	self:saveMode()
end

function App:cycleSound(category, delta)
	local list = self.sounds[category] or {}
	if #list == 0 then return false end
	local index = (self.selected[category] or 1) + delta
	if index < 1 then index = #list end
	if index > #list then index = 1 end
	self.selected[category] = index
	self:saveSound(category)
	self:previewSound(category)
	return true
end

function App:previewSound(category)
	local sound = self:currentSound(category)
	if not sound or not sound.event then return end
	self.os.instance.data.volume = self.volume
	self.os.instance.data.soundMode = self.soundMode
	PhoneUtils.playPhoneAlert(self.os.instance.playerObj, sound.event, self.os.instance.data, false,
		category == "notification" and "notification" or "call", true)
end

function App:previewFocusedSound()
	local row = SOUND_ROWS[self.focus]
	if row and row.category then
		self:previewSound(row.category)
	else
		self:previewSound("ringtone")
	end
	return true
end

function App:handleInput(event)
	if event.action == "MOUSE_DOWN" and event.displayX and event.displayY then
		for i = 1, #self.rowRects do
			local rect = self.rowRects[i]
			if event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
				self.focus = i
				if SOUND_ROWS[i].volume then
					local rel = math.max(0, math.min(1, (event.displayX - rect.sliderX) / math.max(1, rect.sliderW)))
					saveVolume(self, rel)
					return true
				end
				if event.displayX < rect.x + rect.w / 2 then
					return self:handleInput({ action = "LEFT" })
				end
				return self:handleInput({ action = "RIGHT" })
			end
		end
	end
	if event.action == "UP" then
		self.focus = math.max(1, self.focus - 1)
		return true
	elseif event.action == "DOWN" then
		self.focus = math.min(#SOUND_ROWS, self.focus + 1)
		return true
	elseif event.action == "LEFT" then
		local row = SOUND_ROWS[self.focus]
		if row and row.category then
			self:cycleSound(row.category, -1)
		elseif row and row.mode then
			self:changeMode(-1)
			self:previewSound("ringtone")
		else
			saveVolume(self, self.volume - 0.1)
		end
		return true
	elseif event.action == "RIGHT" then
		local row = SOUND_ROWS[self.focus]
		if row and row.category then
			self:cycleSound(row.category, 1)
		elseif row and row.mode then
			self:changeMode(1)
			self:previewSound("ringtone")
		else
			saveVolume(self, self.volume + 0.1)
		end
		return true
	elseif event.action == "OK" then
		return self:previewFocusedSound()
	elseif event.action == "LEFT_SOFT" then
		return self:previewFocusedSound()
	elseif event.action == "SCROLL_UP" or event.action == "SCROLL_DOWN" then
		local delta = event.action == "SCROLL_UP" and 0.05 or -0.05
		saveVolume(self, self.volume + delta)
		return true
	end
	return Base.handleInput(self, event)
end

function App:render(display)
	display:clear()
	display:drawHeader(I18N.app("sounds"))
	self.rowRects = {}
	local rowH = 24
	local y = display.contentY + 4
	local valueRight = display.x + display.width - 12
	for i = 1, #SOUND_ROWS do
		local row = SOUND_ROWS[i]
		local active = self.focus == i
		local color = active and display.colors.bg or display.colors.fg
		local rectY = y + (i - 1) * rowH
		self.rowRects[i] = { x = 4, y = rectY - display.y - 2, w = display.width - 8, h = rowH - 2 }
		if active then display:fillRect(display.x + 4, rectY - 2, display.width - 8, rowH - 2, display.colors.accent) end
		if row.category then
			local sound = self:currentSound(row.category)
			display:drawText("<", display.x + 10, rectY + 2, color)
			display:drawText(I18N.get(row.labelKey), display.x + 24, rectY + 2, color)
			display:drawTextRight(display:ellipsize((sound and SoundRegistry.label(sound) or I18N.get("None")) .. " >", 112),
				valueRight, rectY + 2, color)
		elseif row.mode then
			display:drawText("<", display.x + 10, rectY + 2, color)
			display:drawText(I18N.get(row.labelKey), display.x + 24, rectY + 2, color)
			display:drawTextRight(I18N.get("SoundMode_" .. tostring(self.soundMode)) .. " >", valueRight, rectY + 2, color)
		else
			display:drawText(I18N.get(row.labelKey), display.x + 12, rectY + 2, color)
			local sliderX = display.x + 86
			local sliderW = display.width - 104
			self.slider = { x = sliderX, y = rectY + 5, localX = sliderX - display.x, localY = rectY - display.y + 5, w = sliderW, h = 10 }
			self.rowRects[i].sliderX = self.slider.localX
			self.rowRects[i].sliderW = self.slider.w
			display:drawBorder(self.slider.x, self.slider.y, self.slider.w, self.slider.h, color)
			display:fillRect(self.slider.x + 2, self.slider.y + 2, math.floor((self.slider.w - 4) * self.volume),
				self.slider.h - 4, color)
		end
	end
	display:drawFooter(I18N.get("Preview"), I18N.get("Back"))
end

function App:isMouseOverVolume(display)
	if not self.slider then return false end
	local x, y = display.panel:getMouseX(), display.panel:getMouseY()
	return x >= self.slider.x and x <= self.slider.x + self.slider.w and y >= self.slider.y - 8 and
		y <= self.slider.y + self.slider.h + 8
end

return App
