local PhoneSettings = require("WorkingPhones/Core/PhoneSettings")
require("WorkingPhones/Apps/RegisterApps")
require("WorkingPhones/Phones/ClassicPhone2110")
require("WorkingPhones/Phones/GenericSmartphone")
local Service = require("WorkingPhones/Core/PhoneInventoryService")
local PhonePanel = require("WorkingPhones/UI/PhonePanel")

WorkingPhones = WorkingPhones or {}

local KEYBINDINGS = {
	OPEN_PHONE = { name = "WorkingPhones_OpenPhone", key = Keyboard and Keyboard.KEY_NONE or 0 },
	POWER = { name = "WorkingPhones_PhonePower", key = Keyboard and Keyboard.KEY_P or 0 },
	UP = { name = "WorkingPhones_PhoneUp", key = Keyboard and Keyboard.KEY_UP or 0 },
	ALT_UP = { name = "WorkingPhones_PhoneAltUp", key = Keyboard and Keyboard.KEY_NONE or 0 },
	DOWN = { name = "WorkingPhones_PhoneDown", key = Keyboard and Keyboard.KEY_DOWN or 0 },
	ALT_DOWN = { name = "WorkingPhones_PhoneAltDown", key = Keyboard and Keyboard.KEY_NONE or 0 },
	LEFT = { name = "WorkingPhones_PhoneLeft", key = Keyboard and Keyboard.KEY_LEFT or 0 },
	ALT_LEFT = { name = "WorkingPhones_PhoneAltLeft", key = Keyboard and Keyboard.KEY_NONE or 0 },
	RIGHT = { name = "WorkingPhones_PhoneRight", key = Keyboard and Keyboard.KEY_RIGHT or 0 },
	ALT_RIGHT = { name = "WorkingPhones_PhoneAltRight", key = Keyboard and Keyboard.KEY_NONE or 0 },
	LEFT_SOFT = { name = "WorkingPhones_PhoneLeftSoft", key = Keyboard and Keyboard.KEY_Q or 0 },
	RIGHT_SOFT = { name = "WorkingPhones_PhoneRightSoft", key = Keyboard and Keyboard.KEY_E or 0 },
	CLEAR = { name = "WorkingPhones_PhoneClear", key = Keyboard and Keyboard.KEY_NONE or 0 },
	ABC = { name = "WorkingPhones_PhoneABC", key = Keyboard and Keyboard.KEY_NONE or 0 },
	OK = { name = "WorkingPhones_PhoneOK", key = Keyboard and Keyboard.KEY_RETURN or 0 },
	BACK = { name = "WorkingPhones_PhoneBack", key = Keyboard and Keyboard.KEY_BACK or 0 },
	MENU = { name = "WorkingPhones_PhoneMenu", key = Keyboard and Keyboard.KEY_TAB or 0 },
}

local KEYBINDING_ORDER = {
	"OPEN_PHONE",
	"POWER",
	"UP",
	"ALT_UP",
	"DOWN",
	"ALT_DOWN",
	"LEFT",
	"ALT_LEFT",
	"RIGHT",
	"ALT_RIGHT",
	"OK",
	"BACK",
	"LEFT_SOFT",
	"RIGHT_SOFT",
	"CLEAR",
	"ABC",
	"MENU",
}

WorkingPhones.PhoneKeyBindings = KEYBINDINGS

local SETTINGS = {
	options = {
		classic_phone_scale = 6,
		smartphone_scale = 6,
		show_input_hints = true,
	},
	options_data = {
		classic_phone_scale = {
			"0.50",
			"0.60",
			"0.70",
			"0.80",
			"0.90",
			"1.00",
			"1.10",
			"1.25",
			"1.50",
			name = "IGUI_WorkingPhones_ModOptions_ClassicScale",
			tooltip = "IGUI_WorkingPhones_ModOptions_ClassicScale_Tooltip",
			default = 3,
		},
		smartphone_scale = {
			"0.50",
			"0.60",
			"0.70",
			"0.80",
			"0.90",
			"1.00",
			"1.10",
			"1.25",
			"1.50",
			name = "IGUI_WorkingPhones_ModOptions_SmartphoneScale",
			tooltip = "IGUI_WorkingPhones_ModOptions_SmartphoneScale_Tooltip",
			default = 3,
		},
		show_input_hints = {
			name = "IGUI_WorkingPhones_ModOptions_ShowInputHints",
			tooltip = "IGUI_WorkingPhones_ModOptions_ShowInputHints_Tooltip",
			default = true,
		},
	},
	mod_id = "WorkingPhones",
	mod_shortname = "Working Phones",
	mod_fullname = "Working Phones",
}

local function applySettings(optionValues)
	local settings = optionValues and optionValues.settings or SETTINGS
	WorkingPhones.Options = settings.options or WorkingPhones.Options or {}
	PhoneSettings.apply(WorkingPhones.Options)
	if PhonePanel.activePanel and PhonePanel.activePanel.refreshLayout then
		PhonePanel.activePanel:refreshLayout()
	end
end

local SETTINGS_OPTION_IDS = { "classic_phone_scale", "smartphone_scale", "show_input_hints" }
for i = 1, #SETTINGS_OPTION_IDS do
	local option = SETTINGS.options_data[SETTINGS_OPTION_IDS[i]]
	if option then
		option.OnApplyMainMenu = applySettings
		option.OnApplyInGame = applySettings
	end
end

local function firstPhone(playerObj)
	Service.scan(playerObj, true)
	for phoneKey in pairs(Service.phonesByKey or {}) do
		return Service.phonesByKey[phoneKey]
	end
	return nil
end

local function togglePhone(playerNum)
	if PhonePanel.activePanel and PhonePanel.activePanel:isVisible() then
		PhonePanel.activePanel:close()
		return
	end

	playerNum = playerNum or 0
	local playerObj = getSpecificPlayer(playerNum)
	local phone = firstPhone(playerObj)
	if phone and phone.definition then
		PhonePanel.open(phone.definition, playerNum, phone.item, phone.mapping and phone.mapping.variantId)
	end
end

if ModOptions and ModOptions.getInstance then
	local instance = ModOptions:getInstance(SETTINGS)
	for i = 1, #KEYBINDING_ORDER do
		ModOptions:AddKeyBinding("[Working Phones]", KEYBINDINGS[KEYBINDING_ORDER[i]])
	end
	ModOptions:loadFile()
	if instance then
		WorkingPhones.Options = SETTINGS.options
		applySettings({ settings = SETTINGS })
	end
	Events.OnGameBoot.Add(function()
		applySettings({ settings = SETTINGS })
	end)
else
	WorkingPhones.Options = SETTINGS.options
	PhoneSettings.apply(WorkingPhones.Options)
end

local function onKeyPressed(keynum)
	local openKey = KEYBINDINGS.OPEN_PHONE.key or 0
	if openKey == 0 or keynum ~= openKey then
		return
	end
	if MainScreen.instance and (not MainScreen.instance.inGame or MainScreen.instance:getIsVisible()) then
		return
	end
	togglePhone(0)
end

Events.OnKeyPressed.Add(onKeyPressed)

WorkingPhones.ModOptions = SETTINGS
WorkingPhones.PhoneKeyBindings = KEYBINDINGS
WorkingPhones.TogglePhone = togglePhone

return SETTINGS
