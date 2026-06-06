-- Template only. Copy this into your addon if you want to register sounds.
--
-- Lua registration suggested location:
--   media/lua/shared/MyPhoneAddon/RegisterSounds.lua
--
-- Sound files suggested locations:
--   media/sound/phones/my_phone/ringtones/
--   media/sound/phones/my_phone/alarms/
--   media/sound/shared/vibration/
--
-- You must also define matching Project Zomboid sound events in media/scripts.

local SoundRegistry = require("WorkingPhones/Registries/PhoneSoundRegistry")

--[[
SoundRegistry.registerMany({
	{
		id = "my_mod_ring_soft",
		event = "my_mod_ring_soft",
		label = "Soft Ring",
		kinds = { "ringtone", "notification" },
		packs = { "my_mod_phone_pack" },
		order = 10,
	},
	{
		id = "my_mod_alarm_beep",
		event = "my_mod_alarm_beep",
		label = "Beep Alarm",
		kind = "alarm",
		packs = { "my_mod_phone_pack" },
		order = 20,
	},
	{
		id = "my_mod_vibrate_short",
		event = "my_mod_vibrate_short",
		label = "Short Buzz",
		kind = "vibration",
		packs = { "my_mod_vibration_pack" },
		order = 30,
	},
	{
		id = "my_mod_vibrate_long",
		event = "my_mod_vibrate_long",
		label = "Long Buzz",
		kind = "vibration",
		packs = { "my_mod_vibration_pack" },
		order = 40,
	},
})
]]

-- Example phone sound profile:
--[[
soundProfile = {
	soundPacks = { "my_mod_phone_pack", "my_mod_vibration_pack" },
	defaultRingtone = "my_mod_ring_soft",
	defaultNotification = "my_mod_ring_soft",
	defaultAlarm = "my_mod_alarm_beep",
	defaultNotificationVibration = "my_mod_vibrate_short",
	defaultCallVibration = "my_mod_vibrate_long",
	defaultAlarmVibration = "my_mod_vibrate_long",
	disabledSounds = { "my_mod_ring_hidden" },
	allowedSounds = {
		ringtone = { "my_mod_ring_soft" },
		notification = { "my_mod_ring_soft" },
		alarm = { "my_mod_alarm_beep" },
	},
	volume = 0.7,
}
]]

-- Example media/scripts/my_mod_sounds.txt:
--[[
module MyPhoneAddon
{
	sound my_mod_ring_soft
	{
		category = WorkingPhones,
		clip
		{
			file = media/sound/phones/my_phone/ringtones/my_mod_ring_soft.ogg,
			volume = 1.0,
		}
	}

	sound my_mod_alarm_beep
	{
		category = WorkingPhones,
		clip
		{
			file = media/sound/phones/my_phone/alarms/my_mod_alarm_beep.ogg,
			volume = 1.0,
		}
	}
}
]]

-- API controls:
-- SoundRegistry.remove("my_mod_ring_soft")
-- SoundRegistry.setEnabled("my_mod_alarm_beep", false)

return SoundRegistry
