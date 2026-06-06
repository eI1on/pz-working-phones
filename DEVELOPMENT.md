# Working Phones Development Guide

This guide explains how addon mods can extend Working Phones without editing its core files. The framework is meant to let modders add phones, item variants, apps, games, sound packs, wallpapers, and UI assets through registration APIs.

## Mental Model

Working Phones separates the physical item, phone definition, phone data, and apps:

- The inventory item is an item script entry.
- The item registry maps that item type to a Working Phones phone id and variant id.
- The phone definition describes hardware, screen rectangle, theme, apps, texture, and sound profile.
- Phone data is stored on the physical item mod data, not on the player.
- Server/global data is used for phone number uniqueness, calls, messages, and world high scores.
- Apps are client-side UI modules registered with `PhoneAppRegistry`.

## Folder Recommendations

For addon mods, a clean layout usually looks like this:

```text
media/lua/client/MyPhoneAddon/
  Apps/
  Apps/Games/
  Phones/
  RegisterApps.lua

media/lua/shared/MyPhoneAddon/
  RegisterItems.lua
  RegisterSounds.lua
  RegisterWallpapers.lua

media/scripts/
  my_phone_items.txt
  my_phone_sounds.txt

media/ui/MyPhoneAddon/
  phones/<phone_id>/apps/icons/
  phones/<phone_id>/body/
  phones/<phone_id>/wallpapers/
  apps/<app_id>/

media/sound/
  phones/<phone_id>/ringtones/
  phones/<phone_id>/alarms/
  shared/vibration/
```

Built-in Working Phones assets use the same idea:

- `media/ui/WorkingPhones/phones/classic_2210/body/`
- `media/ui/WorkingPhones/phones/smartphone/apps/icons/`
- `media/ui/WorkingPhones/apps/messages/emojis/`
- `media/ui/WorkingPhones/apps/games/chess/`
- `media/sound/phones/classic_2210/ringtones/`
- `media/sound/phones/smartphone/alarms/`
- `media/sound/shared/vibration/`

The built-in code uses `WorkingPhones/Assets/PhoneAssets` for its own asset roots. Addons can use their own paths directly.

## Load Order

Shared registrations can be loaded by both client and server. Client registrations are only for UI and phone definitions.

Core APIs:

- `WorkingPhones/Core/PhoneRegistry`: register phone definitions.
- `WorkingPhones/Core/PhoneAppRegistry`: register apps and games.
- `WorkingPhones/Registries/PhoneItemRegistry`: map item types and variants to phone definitions.
- `WorkingPhones/Registries/PhoneSoundRegistry`: register sound choices and vibration events.
- `WorkingPhones/Registries/SmartphoneWallpaperRegistry`: register smartphone wallpapers.

Templates live in:

- `media/lua/shared/WorkingPhones/Templates/TemplatePhonePack.lua`
- `media/lua/shared/WorkingPhones/Templates/TemplateApp.lua`
- `media/lua/shared/WorkingPhones/Templates/TemplateGameApp.lua`
- `media/lua/shared/WorkingPhones/Templates/TemplateSoundPack.lua`
- `media/lua/shared/WorkingPhones/Templates/TemplateWallpaperPack.lua`

## Adding A New Phone

A phone needs at least one client phone definition and one shared item mapping.

Client phone definition example:

```lua
local PhoneRegistry = require("WorkingPhones/Core/PhoneRegistry")

PhoneRegistry.register({
	id = "my_mod_phone",
	displayName = "My Phone",
	displayNameKey = "PhoneMyModPhone",
	texture = "media/ui/MyPhoneAddon/phones/my_mod_phone/body/front.png",
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
```

Important phone fields:

- `id`: stable id used by registries and saves.
- `texture`: full phone front texture. Smartphones can set this to `nil` if drawn with UI primitives.
- `screenRect`: screen area inside the texture, in source texture pixels.
- `hardwareType`: usually `classic` or `smartphone`.
- `defaultApps`: apps installed on a new phone.
- `soundProfile`: allowed sound packs and defaults.
- `panel.scale`: default phone UI scale for this phone.

Shared item mapping example:

```lua
local PhoneItemRegistry = require("WorkingPhones/Registries/PhoneItemRegistry")

PhoneItemRegistry.registerVariant("my_mod_phone", "black", {
	displayName = "Black My Phone",
	displayNameKey = "PhoneMyModPhoneBlack",
	texture = "media/ui/MyPhoneAddon/phones/my_mod_phone/body/front_black.png",
})

PhoneItemRegistry.registerItem("MyPhoneAddon.MyModPhoneBlack", "my_mod_phone", "black")
```

Optional world spawning:

```lua
PhoneItemRegistry.registerSpawnGroup("my_mod_phone", {
	weight = 50,
	sandboxEnabled = "MyPhoneAddon.SpawnMyModPhones",
	hardwareType = "smartphone",
})

PhoneItemRegistry.registerItem("MyPhoneAddon.MyModPhoneBlack", "my_mod_phone", "black", {
	spawnWeight = 100,
	hardwareType = "smartphone",
})
```

Working Phones does not add every real phone to loot tables. It adds one hidden dummy item to a curated set of likely phone containers, then replaces each dummy in two stages:

- Choose a phone family/spawn group, such as `classic_2110`.
- Choose one variant inside that family, such as black, blue, red, or gray.

This keeps loot tables compact while still allowing many phone families and variants.

Spawn fields:

- `registerSpawnGroup(id, ...)`: defines a phone family that can be chosen after dummy loot spawns.
- `weight`: relative family weight. If classic has `100` and smartphone has `25`, smartphones are rarer when enabled.
- `sandboxEnabled`: optional boolean sandbox option for enabling or disabling the whole family. Use `SpawnClassicPhones` for this mod's `WorkingPhones` page or `MyAddon.SomeOption` for another sandbox page.
- `spawnWeight`: relative weight for this exact item variant inside its family. Omit it or set it to `0` if the item should never replace dummy loot.
- `hardwareType`: optional metadata for tooling and debugging.

Built-in spawning:

- Classic 2210 variants spawn by default.
- Smartphone variants are registered as a rarer phone family, but `SpawnSmartphones` defaults to `false`.
- `PhoneLootSpawnRate` scales world container dummy spawns.
- `PhoneZombieSpawnRate` scales zombie inventory dummy spawns.
- To increase the total amount of phones, raise `PhoneLootSpawnRate` or `PhoneZombieSpawnRate`.
- To change which kind of phone appears, adjust family `weight` values in `registerSpawnGroup(...)`.
- To change color/variant ratios, adjust `spawnWeight` values in `registerItem(...)`.
- Built-in distribution targets use readable `points` in `PhoneDistribution.lua`; `100` points becomes a `1.00` PZ procedural weight before sandbox multipliers.

Addon sandbox example:

```txt
VERSION = 1,

option MyPhoneAddon.SpawnMyModPhones
{
	type = boolean,
	default = true,
	page = MyPhoneAddon,
	translation = MyPhoneAddon_SpawnMyModPhones,
}

```

Item script example:

```txt
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
```

## Adding Apps

Apps are client-side Lua classes. Extend `WorkingPhones/Apps/Base/BasePhoneApp`, then register the app.

Minimal app registration:

```lua
local AppRegistry = require("WorkingPhones/Core/PhoneAppRegistry")
local MyApp = require("MyPhoneAddon/Apps/MyApp")

AppRegistry.register("my_mod_app", MyApp, {
	name = "My App",
	nameKey = "App_my_mod_app",
	smartphoneIcon = "media/ui/MyPhoneAddon/smartphone/my_mod_app.png",
	autoInstall = true,
	hardwareTypes = { "classic", "smartphone" },
})
```

Useful metadata:

- `name`: fallback display name.
- `nameKey`: translated app name suffix. `App_my_mod_app` becomes `IGUI_WorkingPhones_App_my_mod_app`.
- `smartphoneIcon`: smartphone app grid icon. Classic monochrome phones do not use app icons.
- `autoInstall = true`: install automatically where filters match.
- `hardwareTypes = { "smartphone" }`: only install on matching hardware.
- `phones = { "generic_smartphone" }`: only install on specific phones.
- `excludePhones = { "classic_2110" }`: keep off specific phones.
- `hidden = true`: register but hide from normal app lists.

App methods commonly used:

- `new(os)`: initialize app state.
- `onOpen()`: refresh when opened.
- `onClose()`: stop previews or save small local state.
- `render(display)`: draw inside the phone display.
- `handleInput(event)`: keyboard/controller/soft-key input.
- `onMouseDown(x, y, display)`: mouse/touch interaction.
- `onMouseWheel(delta, x, y, display)`: scrolling or sliders.

Use `display:getVisibleListMetrics(...)` and `display:drawScrollbar(...)` for scrollable lists so content does not draw under footers or scrollbars.

## Adding Games

Games are apps with game metadata. If `showInGamesHub` is true, the Games app can list them automatically.

```lua
AppRegistry.register("my_mod_game", MyGameApp, {
	name = "My Game",
	nameKey = "App_my_mod_game",
	smartphoneIcon = "media/ui/MyPhoneAddon/games/my_mod_game.png",
	game = true,
	showInGamesHub = true,
	gameOrder = 100,
	autoInstall = true,
	hardwareTypes = { "smartphone" },
})
```

Submit scores through networking:

```lua
local Networking = require("WorkingPhones/Core/PhoneNetworking")

Networking.submitGameScore("my_mod_game", score, playerDisplayName, phoneNumber)
```

Use server/world high scores for shared leaderboards. Keep phone item data small: local best score is fine; storing long match histories on a phone item is not.

## Adding Sounds

Sound registration is two-part:

1. Add `.ogg` files and define Project Zomboid sound events in `media/scripts`.
2. Register those sound events with `PhoneSoundRegistry`.

Lua registration:

```lua
local SoundRegistry = require("WorkingPhones/Registries/PhoneSoundRegistry")

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
})
```

Sound script:

```txt
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
}
```

Sound kinds:

- `ringtone`: selectable for calls.
- `notification`: selectable for messages and notifications.
- `alarm`: selectable for alarms.
- `vibration`: not player-selectable; used by phone definitions.

Vibration policy:

- Short vibration is for messages/notifications.
- Long vibration is for calls and alarms.
- Players choose sound/vibrate/silent mode, but vibration pattern selection is controlled by phone definitions and sound packs.

Useful controls:

```lua
SoundRegistry.remove("my_mod_ring_soft")
SoundRegistry.setEnabled("my_mod_alarm_beep", false)
```

## Adding Wallpapers

Register smartphone wallpapers with `SmartphoneWallpaperRegistry`.

```lua
local WallpaperRegistry = require("WorkingPhones/Registries/SmartphoneWallpaperRegistry")

WallpaperRegistry.register({
	id = "my_mod_wallpaper",
	label = "My Wallpaper",
	kind = "texture",
	texture = "media/ui/MyPhoneAddon/wallpapers/my_wallpaper.png",
	r = 0.1,
	g = 0.1,
	b = 0.12,
	order = 50,
	hardwareTypes = { "smartphone" },
})
```

Color wallpaper:

```lua
WallpaperRegistry.register({
	id = "my_mod_color",
	label = "My Color",
	kind = "color",
	r = 0.08,
	g = 0.14,
	b = 0.2,
	order = 40,
})
```

The `r/g/b` values should describe the wallpaper’s dominant color. The smartphone OS uses them for preview/fallback drawing and readable text decisions.

## Persistence Rules

Phone data belongs to the physical phone item. Do not store phone numbers, alarms, contacts, notes, or phone settings on player mod data.

Phone item mod data is used for:

- Phone display name.
- Assigned phone number reference.
- Contacts.
- Journal entries.
- Alarms.
- Local settings.
- Small local histories and notifications.

Server/global data is used for:

- Phone number registry.
- Created phone registry references.
- KnoxNet object messages.
- Calls and call state.
- World high scores.
- Nearby open-phone discovery.

## Multiplayer Rules

Keep the server authoritative for shared state:

- Unique phone numbers.
- Phone-to-phone messages.
- Call state and busy/unavailable checks.
- World high scores.
- Sound broadcasts that other players/zombies should hear.

Client code should handle:

- Rendering UI.
- Input.
- Local previews.
- Reading and updating the opened phone’s item data.

When in doubt, do not trust the client for anything that affects another player.

## Translations

Use translation keys for release-facing text.

For app names, use `nameKey`:

```lua
AppRegistry.register("my_mod_app", MyApp, {
	name = "My App",
	nameKey = "App_my_mod_app",
})
```

Then add:

```lua
IGUI_EN = {
	IGUI_WorkingPhones_App_my_mod_app = "My App",
}
```

For phone item names, use `displayNameKey`:

```lua
PhoneItemRegistry.registerVariant("my_mod_phone", "black", {
	displayName = "Black My Phone",
	displayNameKey = "PhoneMyModPhoneBlack",
})
```

## Final Checklist

Before releasing an addon:

- All app `require(...)` paths resolve.
- Item script full types match `PhoneItemRegistry.registerItem(...)`; add-on items should use full types such as `MyPhoneAddon.MyModPhoneBlack`.
- Phone definition id matches item registry phone id.
- Spawnable phone packs have a sensible `registerSpawnGroup(...)` and variant `spawnWeight` values.
- Sound registry `event` values exist in `media/scripts`.
- Texture paths start with `media/ui/...` and load in game.
- Apps handle `BACK`, `SELECT`, mouse click, and scrolling where needed.
- Lists use scrollbars when content can overflow.
- Data that belongs to a phone is saved on the phone item, not the player.
