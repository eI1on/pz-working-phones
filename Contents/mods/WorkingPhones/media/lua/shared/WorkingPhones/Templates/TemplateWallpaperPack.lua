-- Template only. Copy this into your addon if you want to register smartphone wallpapers.
--
-- Suggested location:
--   media/lua/shared/MyPhoneAddon/RegisterWallpapers.lua
--
-- Texture wallpapers should live under media/ui in your mod and be referenced
-- with a Project Zomboid texture path, for example:
--   media/ui/MyPhoneAddon/wallpapers/my_wallpaper.png

local WallpaperRegistry = require("WorkingPhones/Registries/SmartphoneWallpaperRegistry")

--[[
WallpaperRegistry.registerMany({
	{
		id = "my_mod_wallpaper_color",
		label = "My Color",
		kind = "color",
		r = 0.08,
		g = 0.12,
		b = 0.18,
		order = 10,
		hardwareTypes = { "smartphone" },
	},
	{
		id = "my_mod_wallpaper_texture",
		label = "My Texture",
		kind = "texture",
		texture = "media/ui/MyPhoneAddon/wallpapers/my_wallpaper.png",
		r = 0.1,
		g = 0.1,
		b = 0.12,
		order = 20,
		phones = { "generic_smartphone" },
	},
})
]]

-- Useful fields:
--
-- id:
--   Unique wallpaper id. Prefix it with your mod id.
--
-- label or nameKey:
--   Use label for quick prototypes. Use nameKey for translated release builds.
--
-- kind:
--   "color" or "texture".
--
-- r/g/b:
--   Approximate dominant color. The smartphone OS uses this for readable text
--   and fallback drawing.
--
-- order:
--   Lower values appear earlier in the Settings wallpaper carousel.
--
-- phones / hardwareTypes:
--   Optional filters. Leave unset to make the wallpaper available to all
--   smartphone hardware.

-- API controls:
-- WallpaperRegistry.remove("my_mod_wallpaper_color")
-- WallpaperRegistry.setEnabled("my_mod_wallpaper_texture", false)

return WallpaperRegistry
