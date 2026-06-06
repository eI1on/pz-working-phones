-- Template only. A full phone pack usually has both client and shared pieces.
--
-- Suggested addon files:
--   media/lua/client/MyPhoneAddon/Phones/MyPhone.lua
--   media/lua/shared/MyPhoneAddon/RegisterItems.lua
--   media/lua/shared/MyPhoneAddon/RegisterSounds.lua
--   media/lua/shared/MyPhoneAddon/RegisterWallpapers.lua
--
-- Phone definitions are client-side because they include UI layout and textures.
-- Item variants are shared because inventory item mapping is needed by client and server.

-- Client phone definition example:
--[[
local PhoneRegistry = require("WorkingPhones/Core/PhoneRegistry")

PhoneRegistry.register({
	id = "my_mod_phone",
	displayName = "My Phone",
	displayNameKey = "PhoneMyModPhone",
	texture = "media/ui/MyPhoneAddon/phones/my_phone/body/front.png",
	screenRect = { x = 48, y = 96, width = 240, height = 320 },
	theme = "smartphone_light",
	hardwareType = "smartphone",
	defaultApps = { "phone", "messages", "contacts", "clock", "settings", "sounds" },
	inputMode = "touch",
	soundProfile = {
		soundPacks = { "my_mod_phone_pack", "shared_vibration" },
		defaultRingtone = "my_mod_ring_soft",
		defaultNotification = "my_mod_ring_soft",
		defaultAlarm = "my_mod_alarm_beep",
		defaultNotificationVibration = "phone_vibrate_short",
		defaultCallVibration = "phone_vibrate_long",
		defaultAlarmVibration = "phone_vibrate_long",
		volume = 0.7,
	},
	hardware = {
		displayMode = "color",
		touch = true,
		battery = 1.0,
		startsPowered = true,
	},
	panel = {
		scale = 1,
		maxScreenHeightRatio = 0.9,
	},
})
]]

-- Shared item variant example:
--[[
local PhoneItemRegistry = require("WorkingPhones/Registries/PhoneItemRegistry")

PhoneItemRegistry.registerVariant("my_mod_phone", "black", {
	displayName = "Black My Phone",
	displayNameKey = "PhoneMyModPhoneBlack",
	texture = "media/ui/MyPhoneAddon/phones/my_phone/body/front_black.png",
})

PhoneItemRegistry.registerSpawnGroup("my_mod_phone", {
	-- This is the phone family weight after a phone dummy has spawned.
	-- Keep this separate from the variant weights below.
	weight = 50,
	sandboxEnabled = "MyPhoneAddon.SpawnMyModPhones",
	hardwareType = "smartphone",
})

PhoneItemRegistry.registerItem("MyPhoneAddon.MyModPhoneBlack", "my_mod_phone", "black", {
	-- Optional world spawning support.
	-- Working Phones adds one hidden dummy item to selected loot tables, then replaces
	-- that dummy with one phone family, then one variant from that family.
	spawnWeight = 100,
	hardwareType = "smartphone",
})
]]

-- Optional addon sandbox-options.txt example:
--[[
VERSION = 1,

option MyPhoneAddon.SpawnMyModPhones
{
	type = boolean,
	default = true,
	page = MyPhoneAddon,
	translation = MyPhoneAddon_SpawnMyModPhones,
}

]]

-- Item script example:
--[[
module MyPhoneAddon
{
	item MyModPhoneBlack
	{
		DisplayCategory = Electronics,
		Type = Normal,
		DisplayName = My Phone,
		Icon = MyPhoneIcon,
		Weight = 0.3,
	}
}
]]

return true
