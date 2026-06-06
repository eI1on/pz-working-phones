local Assets = require("WorkingPhones/Assets/PhoneAssets")
local PhoneRegistry = require("WorkingPhones/Core/PhoneRegistry")

return PhoneRegistry.register({
	id = "generic_smartphone",
	displayName = "Generic Smartphone",
	displayNameKey = "PhoneGenericSmartphone",
	texture = Assets.SMARTPHONE_BODY .. "ui_working_phones_smartphone_front_black.png",
	screenRect = { x = 40, y = 108, width = 539, height = 985 },
	theme = "smartphone_light",
	hardwareType = "smartphone",
	supportedApps = {
		"calculator",
		"calendar",
		"clock",
		"contacts",
		"games",
		"journal",
		"map",
		"messages",
		"phone",
		"settings",
		"sounds",
	},
	defaultApps = {
		"phone",
		"messages",
		"contacts",
		"clock",
		"calendar",
		"calculator",
		"games",
		"journal",
		"map",
		"sounds",
		"settings",
	},
	inputMode = "touch",
	soundProfile = {
		soundPacks = { "generic_smartphone", "shared_vibration" },
		defaultRingtone = "smartphone_ring_1",
		defaultNotification = "smartphone_ring_2",
		defaultAlarm = "smartphone_alarm_1",
		defaultNotificationVibration = "phone_vibrate_short",
		defaultCallVibration = "phone_vibrate_long",
		defaultAlarmVibration = "phone_vibrate_long",
		volume = 0.7,
	},
	osProfile = {
		id = "wp_smart_os",
		colorMode = "rgb",
	},
	hardware = {
		displayMode = "color",
		touch = true,
		battery = 1.0,
		startsPowered = true,
	},
	panel = {
		scale = 1.1,
	},
	buttons = {
	},
})
