# Working Phones

Working Phones is a Project Zomboid framework mod that adds usable inventory phones and a modular base for future phone addons.

The current built-in phones are:

- Classic 2210 Phone: a monochrome keypad phone with a classic launcher and compact apps.
- Generic Smartphone: a touch-style graphical phone with lock screen, home screen, app drawer, wallpapers, themes, and modern app layouts.

## Core Features

- Inventory context option to open supported phones.
- Lightweight dummy-item world spawning with weighted phone variants.
- Per-phone persistent data stored on the phone item.
- Unique phone numbers per physical phone.
- Phone-to-phone messages through the KnoxNet object messaging layer.
- Phone-to-phone call state and ringing notifications.
- Contacts, call history, journal entries, alarms, settings, sounds, games, map, calendar, calculator, and messages.
- Classic monochrome UI and smartphone color UI.
- Keyboard, mouse, and controller-compatible navigation.
- Sound, vibrate, and silent alert modes.
- Multiplayer-aware sound playback and zombie attraction for audible phone alerts.

## World Spawning

Phones spawn through a hidden dummy item that is replaced with a weighted registered phone variant when loot is generated. Classic 2210 variants are enabled by default. Smartphones are registered for spawning, but disabled by default through sandbox options.

To make more phones appear, increase `Phone container spawns (%)` for containers and `Phone zombie spawns (%)` for zombies. `Spawn classic phones` and `Spawn smartphones` only decide which built-in phone families are allowed to replace a spawned dummy item.

## Sound Behavior

Phones have sound profiles. The player can choose ringtone, notification tone, alert mode, and volume. Vibration patterns are not player-selectable.

Built-in vibration behavior:

- Messages and other notification alerts use short buzz.
- Incoming calls use long buzz.
- Alarms use long buzz.

These can replace those defaults per phone through the sound API.

## Smartphone Features

The smartphone opens to a lock screen. Swipe up or press the configured select/up input to unlock it.

The home screen supports:

- 4x5 or 5x5 app grid.
- Multiple home pages.
- App rearranging.
- App drawer.
- Clock and phone info panels.
- Light and dark theme.
- Color and texture wallpapers.

## Classic Phone Features

The classic phone renders the full phone texture and draws the monochrome UI only inside the configured screen rectangle. It uses keypad-style soft keys, a main launcher, and app list navigation.

## Dependencies

- KnoxNet for phone-to-phone messages.
- ElyonLib for notification/toast integration.
