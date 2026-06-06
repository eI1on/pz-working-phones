local WorkingPhones = require("WorkingPhones/Core/WorkingPhonesGlobals")

local PhoneDefinition = {}

local requiredFields = {
	"id",
	"displayName",
	"screenRect",
	"theme",
	"hardwareType",
	"defaultApps",
	"inputMode",
	"soundProfile",
	"osProfile",
}

function PhoneDefinition.normalize(definition)
	if type(definition) ~= "table" then
		error("Phone definition must be a table")
	end

	for i = 1, #requiredFields do
		local field = requiredFields[i]
		if definition[field] == nil then
			error("Phone definition '" .. tostring(definition.id) .. "' is missing field: " .. field)
		end
	end

	definition.supportedApps = definition.supportedApps or definition.defaultApps or {}
	definition.texture = definition.texture or nil
	definition.panel = definition.panel or {}
	definition.hardware = definition.hardware or {}
	definition.network = definition.network or {}
	definition.persistence = definition.persistence or {}

	return definition
end

WorkingPhones.PhoneDefinition = PhoneDefinition
return PhoneDefinition
