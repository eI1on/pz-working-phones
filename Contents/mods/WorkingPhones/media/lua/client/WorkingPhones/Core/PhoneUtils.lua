require("WorkingPhones/Core/WorkingPhonesGlobals")

local PhoneUtils = {}
local I18N = require("WorkingPhones/Core/PhoneI18N")
local PhoneAudioEngine = require("WorkingPhones/Audio/PhoneAudioEngine")
local Common = require("WorkingPhones/Common/PhoneCommon")
local HudNotify = require("ElyonLib/UI/Notifications/HudNotify")
local VIBRATE_EVENT = "phone_vibrating_short"

local function vibrationForAlert(data, alertKind)
	alertKind = tostring(alertKind or "")
	if alertKind == "call" then
		return data.callVibrationEvent or VIBRATE_EVENT
	elseif alertKind == "alarm" then
		return data.alarmVibrationEvent or data.callVibrationEvent or VIBRATE_EVENT
	end
	return data.notificationVibrationEvent or VIBRATE_EVENT
end

function PhoneUtils.gameDateTime()
	local gt = getGameTime()
	local day = gt.getDayPlusOne and gt:getDayPlusOne() or gt:getDay() or 1
	local month = (gt:getMonth() or 0) + 1
	return string.format("%02d %s %04d %02d:%02d", day, I18N.monthShort(month), gt:getYear() or 1993, gt:getHour() or 0,
		gt:getMinutes() or 0)
end

function PhoneUtils.playPhoneSound(playerObj, eventName, volume, audible, broadcast, preview)
	if not eventName or eventName == "" or not playerObj then return end
	local normalizedVolume = Common.clamp01(volume, 0.7)
	local radius = Common.phoneSoundRadius(normalizedVolume)
	PhoneAudioEngine.play({
		sound = eventName,
		volume = normalizedVolume,
		playerObj = playerObj,
		preview = preview == true,
	})
	if audible ~= false and radius > 0 and playerObj.getX and not isClient() then
		addSound(playerObj, playerObj:getX(), playerObj:getY(), playerObj:getZ(), radius, math.max(1, math.floor(normalizedVolume * 10)))
	end
	if audible ~= false and broadcast ~= false and radius > 0 and isClient() and WorkingPhones.NET_MODULE then
		sendClientCommand(playerObj, WorkingPhones.NET_MODULE, "PhoneSound", {
			event = eventName,
			volume = normalizedVolume,
			radius = radius,
			x = playerObj.getX and playerObj:getX() or nil,
			y = playerObj.getY and playerObj:getY() or nil,
			z = playerObj.getZ and playerObj:getZ() or nil,
		})
	end
end

function PhoneUtils.playPhoneAlert(playerObj, eventName, data, broadcast, alertKind, preview)
	data = data or {}
	local mode = Common.soundMode(data)
	if mode == "silent" then
		if preview then PhoneAudioEngine.stopPreview() end
		return false
	end
	local volume = Common.clamp01(data.volume, 0.7)
	local audible = true
	local radius = Common.phoneSoundRadius(volume)
	local sound = eventName
	if mode == "vibrate" then
		sound = tostring(vibrationForAlert(data, alertKind))
		volume = math.min(0.25, math.max(0.08, volume * 0.35))
		audible = false
		radius = Common.phoneVibrationRadius(volume)
	end
	if not sound or sound == "" or not playerObj then return false end
	PhoneAudioEngine.play({
		sound = sound,
		volume = volume,
		playerObj = playerObj,
		preview = preview == true,
		alertKey = preview and nil or tostring(alertKind or "notification"),
		loop = alertKind == "call",
		loopInterval = alertKind == "call" and 3500 or nil,
	})
	if audible and radius > 0 and playerObj.getX and not isClient() then
		addSound(playerObj, playerObj:getX(), playerObj:getY(), playerObj:getZ(), radius, math.max(1, math.floor(volume * 10)))
	end
	if broadcast ~= false and radius > 0 and isClient() and WorkingPhones.NET_MODULE then
		sendClientCommand(playerObj, WorkingPhones.NET_MODULE, "PhoneSound", {
			event = sound,
			volume = volume,
			radius = radius,
			audible = audible,
			alertKind = tostring(alertKind or "notification"),
			sourceKey = tostring(data.phoneKey or ""),
			loop = alertKind == "call",
			x = playerObj.getX and playerObj:getX() or nil,
			y = playerObj.getY and playerObj:getY() or nil,
			z = playerObj.getZ and playerObj:getZ() or nil,
		})
	end
	return true
end

function PhoneUtils.stopPhoneAlert(alertKind)
	PhoneAudioEngine.stopAlert(tostring(alertKind or "notification"))
end

function PhoneUtils.toast(title, body, kind, id, ttlSeconds)
	if HudNotify and HudNotify.push then
		HudNotify.push({
			id = id ~= "" and id or nil,
			title = title,
			body = body,
			kind = kind or "info",
			ttlSeconds = tonumber(ttlSeconds) or 8,
		})
		return true
	end
	return false
end

return PhoneUtils
