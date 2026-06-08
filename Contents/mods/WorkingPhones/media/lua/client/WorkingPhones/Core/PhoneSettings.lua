local Settings = {
	classicScale = 1,
	smartphoneScale = 1,
	showInputHints = true,
}

local SCALE_BY_INDEX = {
	[1] = 0.5,
	[2] = 0.6,
	[3] = 0.7,
	[4] = 0.8,
	[5] = 0.9,
	[6] = 1,
	[7] = 1.1,
	[8] = 1.25,
	[9] = 1.5,
}

function Settings.apply(options)
	options = options or {}
	Settings.classicScale = SCALE_BY_INDEX[tonumber(options.classic_phone_scale) or 3] or 1
	Settings.smartphoneScale = SCALE_BY_INDEX[tonumber(options.smartphone_scale) or 3] or 1
	Settings.showInputHints = options.show_input_hints ~= false
end

function Settings.scaleForHardware(hardwareType)
	hardwareType = tostring(hardwareType or "")
	if hardwareType == "classic" then return Settings.classicScale end
	if hardwareType == "smartphone" then return Settings.smartphoneScale end
	return 1
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
