local PhoneHardware = require("WorkingPhones/Core/PhoneHardware")
local PhoneOS = require("WorkingPhones/Core/PhoneOS")
local Persistence = require("WorkingPhones/Core/PhonePersistence")
local Networking = require("WorkingPhones/Core/PhoneNetworking")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local SoundRegistry = require("WorkingPhones/Registries/PhoneSoundRegistry")

local PhoneInstance = {}
PhoneInstance.__index = PhoneInstance

function PhoneInstance:new(definition, playerObj, item)
	local o = setmetatable({}, self)
	o.definition = definition
	o.playerObj = playerObj
	o.item = item
	o.hardware = PhoneHardware:new(definition.hardware)
	o.phoneKey = Persistence.getPhoneKey(item, definition.id)
	o.data = Persistence.getPhoneData(item, definition.id)
	SoundRegistry.applyDefaults(o.data, definition)
	o.number = Persistence.getPhoneNumber(item, definition.id)
	o.displayName = Persistence.getDisplayName(item, definition.displayNameKey and I18N.get(definition.displayNameKey) or definition.displayName, definition.id)
	Networking.registerPhone(o.phoneKey, o.number, o.displayName)
	o.signalStrength = o.data.signalStrength or 4
	o.os = PhoneOS:new(o)
	return o
end

return PhoneInstance
