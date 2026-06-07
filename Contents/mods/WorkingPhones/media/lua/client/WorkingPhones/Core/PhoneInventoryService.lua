require("WorkingPhones/Registration/RegisterPhoneItems")
require("WorkingPhones/Core/WorkingPhonesGlobals")

local PhoneItemRegistry = require("WorkingPhones/Registries/PhoneItemRegistry")
local PhoneRegistry = require("WorkingPhones/Core/PhoneRegistry")
local Persistence = require("WorkingPhones/Core/PhonePersistence")
local I18N = require("WorkingPhones/Core/PhoneI18N")

local Service = {
	lastScan = 0,
	phonesByNumber = {},
	phonesByKey = {},
	registeredKeys = {},
}

local function addInventoryItems(container, out)
	if not container or not container.getItems then return end
	local items = container:getItems()
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		table.insert(out, item)
		if item and item.getInventory then
			addInventoryItems(item:getInventory(), out)
		end
	end
end

local function send(command, args, playerObj)
	playerObj = playerObj or getPlayer()
	if playerObj then
		sendClientCommand(playerObj, WorkingPhones.NET_MODULE, command, args or {})
	end
end

function Service.collect(playerObj)
	local out = {}
	if playerObj and playerObj.getInventory then
		addInventoryItems(playerObj:getInventory(), out)
	end
	return out
end

function Service.findByNumber(number)
	return Service.phonesByNumber[tostring(number or "")]
end

function Service.findByKey(phoneKey)
	return Service.phonesByKey[tostring(phoneKey or "")]
end

function Service.scan(playerObj, force)
	local now = getTimestampMs()
	if not force and now - Service.lastScan < 5000 then return end
	Service.lastScan = now
	Service.phonesByNumber = {}
	Service.phonesByKey = {}
	local seenKeys = {}

	local items = Service.collect(playerObj)
	for i = 1, #items do
		local item = items[i]
		local mapping = PhoneItemRegistry.getByItem(item)
		if mapping then
			local definition = PhoneRegistry.get(mapping.phoneId)
			if definition then
				local variant = PhoneItemRegistry.getVariant(definition.id, mapping.variantId or "default")
				local fallbackName = variant and I18N.translatedName(variant.displayNameKey, variant.displayName) or
					I18N.translatedName(definition.displayNameKey, definition.displayName)
				local number = Persistence.getPhoneNumber(item, definition.id)
				local displayName = Persistence.getDisplayName(item, fallbackName, definition.id)
				local phoneKey = Persistence.getPhoneKey(item, definition.id)
				local data = Persistence.getPhoneData(item, definition.id)
				data.phoneKey = phoneKey
				Service.phonesByNumber[tostring(number)] = {
					item = item,
					mapping = mapping,
					definition = definition,
					number = number,
					phoneKey = phoneKey,
					displayName = displayName,
				}
				Service.phonesByKey[tostring(phoneKey)] = Service.phonesByNumber[tostring(number)]
				seenKeys[phoneKey] = true
				send("RegisterPhone", {
					phoneKey = phoneKey,
					requestedNumber = number,
					displayName = displayName,
					x = playerObj and playerObj.getX and playerObj:getX() or nil,
					y = playerObj and playerObj.getY and playerObj:getY() or nil,
					z = playerObj and playerObj.getZ and playerObj:getZ() or nil,
				}, playerObj)
			end
		end
	end
	for phoneKey in pairs(Service.registeredKeys) do
		if not seenKeys[phoneKey] then
			send("UnregisterPhone", { phoneKey = phoneKey }, playerObj)
		end
	end
	Service.registeredKeys = seenKeys
end

local function onPlayerUpdate(playerObj)
	Service.scan(playerObj, false)
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)

return Service
