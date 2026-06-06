WorkingPhones = WorkingPhones or {}

local PhoneItemRegistry = {
	items = {},
	variants = {},
}

local function normalizeFullType(fullType)
	if string.find(fullType, "%.") then
		return fullType
	end
	return "WorkingPhones." .. fullType
end

function PhoneItemRegistry.registerItem(fullType, phoneId, variantId)
	fullType = normalizeFullType(fullType)
	PhoneItemRegistry.items[fullType] = {
		fullType = fullType,
		phoneId = phoneId,
		variantId = variantId or "default",
	}
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

WorkingPhones.PhoneItemRegistry = PhoneItemRegistry
return PhoneItemRegistry
