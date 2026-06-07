local Common = require("WorkingPhones/Common/PhoneCommon")

local PhoneAudioEngine = {}

PhoneAudioEngine._initialized = false
PhoneAudioEngine._emitter = nil
PhoneAudioEngine._current = nil
PhoneAudioEngine._preview = nil
PhoneAudioEngine._alerts = {}
PhoneAudioEngine._alertKeys = {}

local function isPlaying(emitter, soundId)
	return emitter and soundId and emitter:isPlaying(soundId)
end

local function distanceVolume(req)
	local volume = Common.clamp(req.volume, 0, 1)
	local radius = tonumber(req.radius) or 0
	local x = tonumber(req.x)
	local y = tonumber(req.y)
	if radius <= 0 or not x or not y then
		return volume
	end
	local playerObj = getPlayer()
	if not playerObj or not playerObj.getX then
		return volume
	end
	local dx = playerObj:getX() - x
	local dy = playerObj:getY() - y
	local distance = math.sqrt(dx * dx + dy * dy)
	if distance >= radius then
		return 0
	end
	return volume * (1 - distance / radius)
end

local function addAlertKey(key)
	for i = 1, #PhoneAudioEngine._alertKeys do
		if PhoneAudioEngine._alertKeys[i] == key then return end
	end
	table.insert(PhoneAudioEngine._alertKeys, key)
end

local function removeAlertKey(key)
	for i = #PhoneAudioEngine._alertKeys, 1, -1 do
		if PhoneAudioEngine._alertKeys[i] == key then
			table.remove(PhoneAudioEngine._alertKeys, i)
			return
		end
	end
end

function PhoneAudioEngine.init()
	if PhoneAudioEngine._initialized then
		return
	end
	if FMODSoundEmitter then
		PhoneAudioEngine._emitter = FMODSoundEmitter.new()
		Events.OnTick.Add(PhoneAudioEngine.update)
	end
	PhoneAudioEngine._initialized = true
end

function PhoneAudioEngine.update()
	if not PhoneAudioEngine._emitter then
		return
	end
	PhoneAudioEngine._emitter:tick()
	if PhoneAudioEngine._current and not isPlaying(PhoneAudioEngine._emitter, PhoneAudioEngine._current) then
		PhoneAudioEngine._current = nil
	end
	if PhoneAudioEngine._preview and not isPlaying(PhoneAudioEngine._emitter, PhoneAudioEngine._preview) then
		PhoneAudioEngine._preview = nil
	end
	local now = getTimestampMs()
	for i = #PhoneAudioEngine._alertKeys, 1, -1 do
		local key = PhoneAudioEngine._alertKeys[i]
		local alert = PhoneAudioEngine._alerts[key]
		if not alert then
			table.remove(PhoneAudioEngine._alertKeys, i)
		else
			if alert.soundId and not isPlaying(PhoneAudioEngine._emitter, alert.soundId) then
				alert.soundId = nil
			end
			if alert.loop and (not alert.soundId) and now >= (alert.nextPlayAt or 0) then
				PhoneAudioEngine._emitter:setVolumeAll(alert.volume)
				alert.soundId = PhoneAudioEngine._emitter:playSoundImpl(tostring(alert.sound), false, nil)
				PhoneAudioEngine._emitter:setVolumeAll(alert.volume)
				alert.nextPlayAt = now + alert.interval
			end
		end
	end
end

function PhoneAudioEngine.stopPreview()
	if not PhoneAudioEngine._initialized then
		PhoneAudioEngine.init()
	end
	if PhoneAudioEngine._emitter and PhoneAudioEngine._preview then
		PhoneAudioEngine._emitter:stopSound(PhoneAudioEngine._preview)
	end
	PhoneAudioEngine._preview = nil
end

function PhoneAudioEngine.stopAlert(key)
	if not PhoneAudioEngine._initialized then
		PhoneAudioEngine.init()
	end
	key = tostring(key or "")
	if key == "" then return end
	local alert = PhoneAudioEngine._alerts[key]
	if alert and PhoneAudioEngine._emitter and alert.soundId then
		PhoneAudioEngine._emitter:stopSound(alert.soundId)
	end
	PhoneAudioEngine._alerts[key] = nil
	removeAlertKey(key)
end

function PhoneAudioEngine.play(req)
	if type(req) ~= "table" or not req.sound or req.sound == "" then
		return false
	end
	if not PhoneAudioEngine._initialized then
		PhoneAudioEngine.init()
	end
	local volume = distanceVolume(req)
	if req.preview and PhoneAudioEngine._emitter then
		PhoneAudioEngine.stopPreview()
	end
	local alertKey = req.alertKey and tostring(req.alertKey) or nil
	if alertKey and PhoneAudioEngine._emitter then
		PhoneAudioEngine.stopAlert(alertKey)
	end
	if volume <= 0 then
		return false
	end
	if PhoneAudioEngine._emitter then
		PhoneAudioEngine._emitter:setVolumeAll(volume)
		local soundId = PhoneAudioEngine._emitter:playSoundImpl(tostring(req.sound), false, nil)
		if req.preview then
			PhoneAudioEngine._preview = soundId
		elseif alertKey then
			PhoneAudioEngine._alerts[alertKey] = {
				sound = tostring(req.sound),
				soundId = soundId,
				volume = volume,
				loop = req.loop == true,
				interval = tonumber(req.loopInterval) or 3500,
				nextPlayAt = getTimestampMs() + (tonumber(req.loopInterval) or 3500),
			}
			addAlertKey(alertKey)
		else
			PhoneAudioEngine._current = soundId
		end
		PhoneAudioEngine._emitter:setVolumeAll(volume)
		return true
	end
	local playerObj = req.playerObj or getPlayer()
	if playerObj and playerObj.playSoundLocal then
		playerObj:playSoundLocal(tostring(req.sound))
		return true
	end
	return false
end

return PhoneAudioEngine
