WorkingPhones = WorkingPhones or {}

local PhoneItemRegistry = {
	items = {},
	variants = {},
	spawnGroups = {},
	spawnGroupOrder = {},
}

local function normalizeFullType(fullType)
	if string.find(fullType, "%.") then
		return fullType
	end
	return "WorkingPhones." .. fullType
end

function PhoneItemRegistry.registerSpawnGroup(groupId, options)
	options = options or {}
	local group = PhoneItemRegistry.spawnGroups[groupId]
	if not group then
		group = {
			id = groupId,
			weight = tonumber(options.weight) or 100,
			sandboxEnabled = options.sandboxEnabled,
			hardwareType = options.hardwareType,
			items = {},
		}
		PhoneItemRegistry.spawnGroups[groupId] = group
		table.insert(PhoneItemRegistry.spawnGroupOrder, group)
		return group
	end
	group.weight = tonumber(options.weight) or group.weight
	group.sandboxEnabled = options.sandboxEnabled or group.sandboxEnabled
	group.hardwareType = options.hardwareType or group.hardwareType
	return group
end

function PhoneItemRegistry.registerItem(fullType, phoneId, variantId, options)
	fullType = normalizeFullType(fullType)
	PhoneItemRegistry.items[fullType] = {
		fullType = fullType,
		phoneId = phoneId,
		variantId = variantId or "default",
	}
	options = options or {}
	local spawnWeight = tonumber(options.spawnWeight) or 0
	if spawnWeight > 0 then
		local groupId = options.spawnGroup or phoneId
		local group = PhoneItemRegistry.registerSpawnGroup(groupId, {
			weight = options.spawnGroupWeight,
			sandboxEnabled = options.sandboxEnabled,
			hardwareType = options.hardwareType,
		})
		table.insert(group.items, {
			fullType = fullType,
			phoneId = phoneId,
			variantId = variantId or "default",
			weight = spawnWeight,
			hardwareType = options.hardwareType,
		})
	end
end

function PhoneItemRegistry.getByFullType(fullType)
	return PhoneItemRegistry.items[normalizeFullType(fullType)]
end

function PhoneItemRegistry.getByItem(item)
	if not item or not item.getFullType then
		return nil
	end
	return PhoneItemRegistry.getByFullType(item:getFullType())
end

function PhoneItemRegistry.registerVariant(phoneId, variantId, data)
	PhoneItemRegistry.variants[phoneId] = PhoneItemRegistry.variants[phoneId] or {}
	PhoneItemRegistry.variants[phoneId][variantId] = data or {}
end

function PhoneItemRegistry.getVariant(phoneId, variantId)
	local phoneVariants = PhoneItemRegistry.variants[phoneId]
	return phoneVariants and phoneVariants[variantId] or nil
end

function PhoneItemRegistry.getSpawnGroups()
	return PhoneItemRegistry.spawnGroupOrder
end

WorkingPhones.PhoneItemRegistry = PhoneItemRegistry
return PhoneItemRegistry
