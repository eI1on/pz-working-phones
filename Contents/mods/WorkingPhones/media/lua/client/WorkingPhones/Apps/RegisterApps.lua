local AppRegistry = require("WorkingPhones/Core/PhoneAppRegistry")
local Assets = require("WorkingPhones/Assets/PhoneAssets")
local CalculatorApp = require("WorkingPhones/Apps/Tools/CalculatorApp")
local CalendarApp = require("WorkingPhones/Apps/Tools/CalendarApp")
local ClockApp = require("WorkingPhones/Apps/Tools/ClockApp")
local ContactsApp = require("WorkingPhones/Apps/Communication/ContactsApp")
local GamesApp = require("WorkingPhones/Apps/Games/GamesApp")
local SnakeApp = require("WorkingPhones/Apps/Games/SnakeApp")
local TetrisApp = require("WorkingPhones/Apps/Games/TetrisApp")
local ChessApp = require("WorkingPhones/Apps/Games/ChessApp")
local JournalApp = require("WorkingPhones/Apps/Tools/JournalApp")
local MapApp = require("WorkingPhones/Apps/Tools/MapApp")
local MessagesApp = require("WorkingPhones/Apps/Communication/MessagesApp")
local PhoneCallApp = require("WorkingPhones/Apps/Communication/PhoneCallApp")
local SettingsApp = require("WorkingPhones/Apps/Tools/SettingsApp")
local SoundsApp = require("WorkingPhones/Apps/Tools/SoundsApp")

local SMARTPHONE_ICON_ROOT = Assets.SMARTPHONE_APP_ICONS

AppRegistry.register("calculator", CalculatorApp, {
	nameKey = "App_calculator",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_calculator.png",
})
AppRegistry.register("calendar", CalendarApp, {
	nameKey = "App_calendar",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_calendar.png",
})
AppRegistry.register("clock", ClockApp, {
	nameKey = "App_clock",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_clock.png",
})
AppRegistry.register("contacts", ContactsApp, {
	nameKey = "App_contacts",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_contacts.png",
})
AppRegistry.register("games", GamesApp, {
	nameKey = "App_games",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_games.png",
})
AppRegistry.register("snake", SnakeApp, {
	nameKey = "App_snake",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_games_snake.png",
	game = true,
	gameOrder = 10,
	showInGamesHub = true,
	autoInstall = true,
	hardwareTypes = { "smartphone" },
})
AppRegistry.register("tetris", TetrisApp, {
	nameKey = "App_tetris",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_games_tetris.png",
	game = true,
	gameOrder = 20,
	showInGamesHub = true,
	autoInstall = true,
	hardwareTypes = { "smartphone" },
})
AppRegistry.register("chess", ChessApp, {
	nameKey = "App_chess",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_games_chess.png",
	game = true,
	gameOrder = 30,
	showInGamesHub = true,
	autoInstall = true,
	hardwareTypes = { "smartphone" },
})
AppRegistry.register("journal", JournalApp, {
	nameKey = "App_journal",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_journal.png",
})
AppRegistry.register("map", MapApp, {
	nameKey = "App_map",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_map.png",
})
AppRegistry.register("messages", MessagesApp, {
	nameKey = "App_messages",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_messages.png",
})
AppRegistry.register("phone", PhoneCallApp, {
	nameKey = "App_phone",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_phone.png",
})
AppRegistry.register("settings", SettingsApp, {
	nameKey = "App_settings",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_settings.png",
})
AppRegistry.register("sounds", SoundsApp, {
	nameKey = "App_sounds",
	smartphoneIcon = SMARTPHONE_ICON_ROOT .. "ui_working_smartphone_app_sounds.png",
})

return AppRegistry
