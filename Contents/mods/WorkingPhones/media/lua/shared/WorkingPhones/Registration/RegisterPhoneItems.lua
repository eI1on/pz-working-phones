local Assets = require("WorkingPhones/Assets/PhoneAssets")
local PhoneItemRegistry = require("WorkingPhones/Registries/PhoneItemRegistry")

PhoneItemRegistry.registerVariant("classic_2110", "black", {
	displayName = "Classic 2210 Phone",
	displayNameKey = "PhoneClassic2210",
	texture = Assets.CLASSIC_2210_BODY .. "ui_working_phones_classic_phone_front_black.png",
})
PhoneItemRegistry.registerVariant("classic_2110", "blue", {
	displayName = "Blue Classic 2210 Phone",
	displayNameKey = "PhoneClassic2210Blue",
	texture = Assets.CLASSIC_2210_BODY .. "ui_working_phones_classic_phone_front_blue.png",
})
PhoneItemRegistry.registerVariant("classic_2110", "red", {
	displayName = "Red Classic 2210 Phone",
	displayNameKey = "PhoneClassic2210Red",
	texture = Assets.CLASSIC_2210_BODY .. "ui_working_phones_classic_phone_front_red.png",
})
PhoneItemRegistry.registerVariant("generic_smartphone", "black", {
	displayName = "Black Smartphone",
	displayNameKey = "PhoneSmartphoneBlack",
	texture = Assets.SMARTPHONE_BODY .. "ui_working_phones_smartphone_front_black.png",
})
PhoneItemRegistry.registerVariant("generic_smartphone", "white", {
	displayName = "White Smartphone",
	displayNameKey = "PhoneSmartphoneWhite",
	texture = Assets.SMARTPHONE_BODY .. "ui_working_phones_smartphone_front_white.png",
})
PhoneItemRegistry.registerVariant("generic_smartphone", "blue", {
	displayName = "Blue Smartphone",
	displayNameKey = "PhoneSmartphoneBlue",
	texture = Assets.SMARTPHONE_BODY .. "ui_working_phones_smartphone_front_blue.png",
})

PhoneItemRegistry.registerSpawnGroup("classic_2110", {
	weight = 100,
	sandboxEnabled = "SpawnClassicPhones",
	hardwareType = "classic",
})

PhoneItemRegistry.registerSpawnGroup("generic_smartphone", {
	weight = 25,
	sandboxEnabled = "SpawnSmartphones",
	hardwareType = "smartphone",
})

PhoneItemRegistry.registerItem("Classic2210Phone", "classic_2110", "black", {
	spawnWeight = 60,
	hardwareType = "classic",
})
PhoneItemRegistry.registerItem("Classic2210PhoneBlue", "classic_2110", "blue", {
	spawnWeight = 25,
	hardwareType = "classic",
})
PhoneItemRegistry.registerItem("Classic2210PhoneRed", "classic_2110", "red", {
	spawnWeight = 15,
	hardwareType = "classic",
})

PhoneItemRegistry.registerItem("SmartphoneBlack", "generic_smartphone", "black", {
	spawnWeight = 60,
	hardwareType = "smartphone",
})
PhoneItemRegistry.registerItem("SmartphoneWhite", "generic_smartphone", "white", {
	spawnWeight = 25,
	hardwareType = "smartphone",
})
PhoneItemRegistry.registerItem("SmartphoneBlue", "generic_smartphone", "blue", {
	spawnWeight = 15,
	hardwareType = "smartphone",
})

return PhoneItemRegistry
