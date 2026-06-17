require("WorkingPhones/Core/WorkingPhonesGlobals")
local PhoneDefinition = require("WorkingPhones/Core/PhoneDefinition")

local PhoneRegistry = {
	definitions = {},
	order = {},
}

function PhoneRegistry.register(definition)
	definition = PhoneDefinition.normalize(definition)

	if not PhoneRegistry.definitions[definition.id] then
		table.insert(PhoneRegistry.order, definition.id)
	end

	PhoneRegistry.definitions[definition.id] = definition
	return definition
end

function PhoneRegistry.get(phoneId)
	return PhoneRegistry.definitions[phoneId]
end

function PhoneRegistry.getAll()
	local phones = {}
	for i = 1, #PhoneRegistry.order do
		local id = PhoneRegistry.order[i]
		table.insert(phones, PhoneRegistry.definitions[id])
	end
	return phones
end

WorkingPhones.PhoneRegistry = PhoneRegistry
return PhoneRegistry
