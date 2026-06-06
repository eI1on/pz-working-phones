local Assets = require("WorkingPhones/Assets/PhoneAssets")
local WallpaperRegistry = require("WorkingPhones/Registries/SmartphoneWallpaperRegistry")

WallpaperRegistry.registerMany({
	{ id = "midnight",  nameKey = "SmartWallpaperMidnight", kind = "color",   r = 0.05, g = 0.06, b = 0.09, order = 10 },
	{ id = "forest",    nameKey = "SmartWallpaperForest",   kind = "color",   r = 0.08, g = 0.16, b = 0.11, order = 20 },
	{ id = "burgundy",  nameKey = "SmartWallpaperBurgundy", kind = "color",   r = 0.22, g = 0.06, b = 0.09, order = 30 },
	{ id = "steel",     nameKey = "SmartWallpaperSteel",    kind = "color",   r = 0.13, g = 0.16, b = 0.19, order = 40 },
	{ id = "amber",     nameKey = "SmartWallpaperAmber",    kind = "color",   r = 0.2,  g = 0.14, b = 0.05, order = 50 },
	{ id = "violet",    nameKey = "SmartWallpaperViolet",   kind = "color",   r = 0.13, g = 0.08, b = 0.2,  order = 60 },
	{ id = "texture_1", nameKey = "SmartWallpaperTexture1", kind = "texture", texture = Assets.SMARTPHONE_WALLPAPERS .. "bg_1.png", r = 0.12, g = 0.12, b = 0.14, order = 110 },
	{ id = "texture_2", nameKey = "SmartWallpaperTexture2", kind = "texture", texture = Assets.SMARTPHONE_WALLPAPERS .. "bg_2.png", r = 0.18, g = 0.18, b = 0.18, order = 120 },
	{ id = "texture_3", nameKey = "SmartWallpaperTexture3", kind = "texture", texture = Assets.SMARTPHONE_WALLPAPERS .. "bg_3.png", r = 0.1,  g = 0.12, b = 0.15, order = 130 },
	{ id = "texture_4", nameKey = "SmartWallpaperTexture4", kind = "texture", texture = Assets.SMARTPHONE_WALLPAPERS .. "bg_4.png", r = 0.17, g = 0.14, b = 0.12, order = 140 },
	{ id = "texture_5", nameKey = "SmartWallpaperTexture5", kind = "texture", texture = Assets.SMARTPHONE_WALLPAPERS .. "bg_5.png", r = 0.12, g = 0.16, b = 0.18, order = 150 },
	{ id = "texture_6", nameKey = "SmartWallpaperTexture6", kind = "texture", texture = Assets.SMARTPHONE_WALLPAPERS .. "bg_6.png", r = 0.16, g = 0.13, b = 0.2,  order = 160 },
})

return WallpaperRegistry
