local Settings = {
	uiScale = 1,
	showInputHints = true,
}

local SCALE_BY_INDEX = {
	[1] = 0.75,
	[2] = 0.9,
	[3] = 1,
	[4] = 1.1,
	[5] = 1.25,
	[6] = 1.5,
}

function Settings.apply(options)
	options = options or {}
	Settings.uiScale = SCALE_BY_INDEX[tonumber(options.ui_scale) or 3] or 1
	Settings.showInputHints = options.show_input_hints ~= false
end

function Settings.options()
	WorkingPhones = WorkingPhones or {}
	WorkingPhones.Options = WorkingPhones.Options or {}
	return WorkingPhones.Options
end

function Settings.reload()
	Settings.apply(Settings.options())
end

return Settings
