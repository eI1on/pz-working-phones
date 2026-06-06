local Assets = require("WorkingPhones/Assets/PhoneAssets")
local PhoneItemRegistry = require("WorkingPhones/Registries/PhoneItemRegistry")

PhoneItemRegistry.registerVariant("classic_2110", "black", {
	displayName = "Classic 2210 Phone",
	displayNameKey = "PhoneClassic2210",
	texture = Assets.CLASSIC_2210_BODY .. "ui_working_phones_classic_phone_front.png",
})
PhoneItemRegistry.registerVariant("classic_2110", "blue", {
	displayName = "Blue Classic 2210 Phone",
	displayNameKey = "PhoneClassic2210Blue",
	texture = Assets.CLASSIC_2210_BODY .. "ui_working_phones_classic_phone_front.png",
})
PhoneItemRegistry.registerVariant("classic_2110", "red", {
	displayName = "Red Classic 2210 Phone",
	displayNameKey = "PhoneClassic2210Red",
	texture = Assets.CLASSIC_2210_BODY .. "ui_working_phones_classic_phone_front.png",
})
PhoneItemRegistry.registerVariant("classic_2110", "gray", {
	displayName = "Gray Classic 2210 Phone",
	displayNameKey = "PhoneClassic2210Gray",
	texture = Assets.CLASSIC_2210_BODY .. "ui_working_phones_classic_phone_front.png",
})
PhoneItemRegistry.registerVariant("generic_smartphone", "black", {
	displayName = "Black Smartphone",
	displayNameKey = "PhoneSmartphoneBlack",
})
PhoneItemRegistry.registerVariant("generic_smartphone", "white", {
	displayName = "White Smartphone",
	displayNameKey = "PhoneSmartphoneWhite",
})
PhoneItemRegistry.registerVariant("generic_smartphone", "blue", {
	displayName = "Blue Smartphone",
	displayNameKey = "PhoneSmartphoneBlue",
})

PhoneItemRegistry.registerItem("Classic2210Phone", "classic_2110", "black")
PhoneItemRegistry.registerItem("Classic2210PhoneBlue", "classic_2110", "blue")
PhoneItemRegistry.registerItem("Classic2210PhoneRed", "classic_2110", "red")
PhoneItemRegistry.registerItem("Classic2210PhoneGray", "classic_2110", "gray")

PhoneItemRegistry.registerItem("Smartphone", "generic_smartphone", "black")
PhoneItemRegistry.registerItem("SmartphoneWhite", "generic_smartphone", "white")
PhoneItemRegistry.registerItem("SmartphoneBlue", "generic_smartphone", "blue")

return PhoneItemRegistry
