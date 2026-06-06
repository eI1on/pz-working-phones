local Registry = {}

Registry._sounds = {}
Registry._order = {}

local function contains(list, value)
	if type(list) ~= "table" then return false end
	value = tostring(value or "")
	for i = 1, #list do
		if tostring(list[i]) == value then return true end
	end
	return false
end

local function overlaps(left, right)
	if type(left) ~= "table" or type(right) ~= "table" then return false end
	for i = 1, #left do
		if contains(right, left[i]) then return true end
	end
	return false
end

local function categoryMatches(sound, category)
	category = tostring(category or "")
	if tostring(sound.kind or "") == category then return true end
	if contains(sound.kinds, category) then return true end
	return false
end

local function profileAllows(sound, category, definition)
	if type(definition) ~= "table" then return true end
	local profile = definition.soundProfile or {}
	local disabled = profile.disabledSounds or {}
	if contains(disabled, sound.id) then return false end
	if contains(disabled, sound.event) then return false end

	local allowedByCategory = profile.allowedSounds and profile.allowedSounds[category] or nil
	if allowedByCategory then
		return contains(allowedByCategory, sound.id) or contains(allowedByCategory, sound.event)
	end

	if type(sound.phones) == "table" and not contains(sound.phones, definition.id) then return false end
	if type(sound.hardwareTypes) == "table" and not contains(sound.hardwareTypes, definition.hardwareType) then return false end
	if type(sound.packs) == "table" then
		return overlaps(sound.packs, profile.soundPacks or {})
	end
	return true
end

local function sortedInsert(list, sound)
	table.insert(list, sound)
	table.sort(list, function(a, b)
		local ao = tonumber(a.order) or 1000
		local bo = tonumber(b.order) or 1000
		if ao == bo then return tostring(a.id) < tostring(b.id) end
		return ao < bo
	end)
end

function Registry.register(id, definition)
	if type(definition) ~= "table" then return nil end
	local sound = definition
	sound.id = tostring(id or sound.id or sound.event or "")
	if sound.id == "" then return nil end
	sound.event = tostring(sound.event or sound.id)
	if Registry._sounds[sound.id] == nil then
		table.insert(Registry._order, sound.id)
	end
	Registry._sounds[sound.id] = sound
	return sound
end

function Registry.registerMany(list)
	if type(list) ~= "table" then return end
	for i = 1, #list do
		Registry.register(list[i].id, list[i])
	end
end

function Registry.remove(id)
	id = tostring(id or "")
	if id == "" then return false end
	if Registry._sounds[id] == nil then return false end
	Registry._sounds[id] = nil
	for i = #Registry._order, 1, -1 do
		if Registry._order[i] == id then table.remove(Registry._order, i) end
	end
	return true
end

function Registry.setEnabled(id, enabled)
	local sound = Registry._sounds[tostring(id or "")]
	if not sound then return false end
	sound.enabled = enabled ~= false
	return true
end

function Registry.get(id)
	return Registry._sounds[tostring(id or "")]
end

function Registry.list(category, definition)
	local out = {}
	category = tostring(category or "")
	for i = 1, #Registry._order do
		local sound = Registry._sounds[Registry._order[i]]
		if sound and sound.enabled ~= false and categoryMatches(sound, category) and profileAllows(sound, category, definition) then
			sortedInsert(out, sound)
		end
	end
	return out
end

function Registry.first(category, definition)
	local list = Registry.list(category, definition)
	return list[1]
end

function Registry.resolve(id, category, definition)
	local sound = Registry.get(id)
	if sound and sound.enabled ~= false and categoryMatches(sound, category) and profileAllows(sound, category, definition) then
		return sound
	end
	return Registry.first(category, definition)
end

function Registry.label(sound)
	if type(sound) ~= "table" then return "" end
	if sound.labelKey and getText then
		return getText("IGUI_WorkingPhones_" .. tostring(sound.labelKey))
	end
	return tostring(sound.label or sound.id or "")
end

local function applyDefaultSound(data, definition, category, idField, eventField, profileField, fallbackEvent)
	local soundProfile = definition.soundProfile or {}
	local selectedId = data[idField] or soundProfile[profileField]
	local sound = Registry.resolve(selectedId, category, definition)
	if sound then
		data[idField] = sound.id
		data[eventField] = sound.event
	elseif data[eventField] == nil then
		data[eventField] = tostring(fallbackEvent or "")
	end
end

function Registry.applyDefaults(data, definition)
	if type(data) ~= "table" or type(definition) ~= "table" then return data end
	local soundProfile = definition.soundProfile or {}
	if data.volume == nil then data.volume = tonumber(soundProfile.volume) or 0.7 end
	if data.soundMode == nil then data.soundMode = tostring(soundProfile.defaultMode or "sound") end
	applyDefaultSound(data, definition, "ringtone", "ringtoneId", "ringtoneEvent", "defaultRingtone", soundProfile.ringtoneEvent)
	applyDefaultSound(data, definition, "notification", "notificationId", "notificationEvent", "defaultNotification", soundProfile.notificationEvent or data.ringtoneEvent)
	applyDefaultSound(data, definition, "alarm", "alarmId", "alarmEvent", "defaultAlarm", data.ringtoneEvent)
	applyDefaultSound(data, definition, "vibration", "notificationVibrationId", "notificationVibrationEvent", "defaultNotificationVibration", "phone_vibrating_short")
	applyDefaultSound(data, definition, "vibration", "callVibrationId", "callVibrationEvent", "defaultCallVibration", data.notificationVibrationEvent)
	applyDefaultSound(data, definition, "vibration", "alarmVibrationId", "alarmVibrationEvent", "defaultAlarmVibration", data.callVibrationEvent)
	return data
end

return Registry
