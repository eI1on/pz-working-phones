local Persistence = {}
Persistence.localNumberRegistry = Persistence.localNumberRegistry or {}

local function simpleHash(text)
	local hash = 0
	for i = 1, #text do
		hash = (hash * 31 + string.byte(text, i)) % 1000000
	end
	return hash
end

local function randomSeed()
	return tostring(ZombRand(100000, 999999)) .. tostring(ZombRand(100000, 999999))
end

local function itemId(item)
	if item and item.getID then
		return tostring(item:getID())
	end
	return randomSeed()
end

local function getItemRoot(item, phoneId)
	if not item or not item.getModData then
		return nil
	end

	local md = item:getModData()
	md.WorkingPhones = md.WorkingPhones or {}
	local root = md.WorkingPhones
	root.schemaVersion = 1
	root.phoneId = root.phoneId or tostring(phoneId or "unknown")
	root.phoneKey = root.phoneKey or (tostring(root.phoneId) .. ":" .. itemId(item) .. ":" .. randomSeed())
	root.identity = root.identity or nil
	root.displayName = root.displayName or nil
	root.data = root.data or {}
	root.contacts = root.contacts or {}
	root.registry = root.registry or {}

	return root
end

function Persistence.getPhoneRoot(item, phoneId)
	return getItemRoot(item, phoneId) or {
		schemaVersion = 1,
		phoneId = tostring(phoneId or "unknown"),
		phoneKey = tostring(phoneId or "unknown") .. ":transient:" .. randomSeed(),
		data = {},
		contacts = {},
		registry = {},
	}
end

function Persistence.getPhoneKey(item, phoneId)
	return Persistence.getPhoneRoot(item, phoneId).phoneKey
end

function Persistence.getPhoneData(item, phoneId)
	return Persistence.getPhoneRoot(item, phoneId).data
end

function Persistence.getDisplayName(item, fallback, phoneId)
	local root = Persistence.getPhoneRoot(item, phoneId)
	if root.displayName and tostring(root.displayName) ~= "" then
		return tostring(root.displayName)
	end
	return tostring(fallback or (item and item.getDisplayName and item:getDisplayName()) or "Phone")
end

function Persistence.setDisplayName(item, displayName, phoneId)
	local root = Persistence.getPhoneRoot(item, phoneId)
	root.displayName = tostring(displayName or "")
	return root.displayName
end

function Persistence.getPhoneNumber(item, phoneId)
	local root = Persistence.getPhoneRoot(item, phoneId)
	if not root.identity or tostring(root.identity) == "" then
		local number = string.format("555-%06d", simpleHash(tostring(root.phoneKey)))
		while Persistence.localNumberRegistry[number] and Persistence.localNumberRegistry[number] ~= root.phoneKey do
			number = string.format("555-%06d", simpleHash(number .. randomSeed()))
		end
		root.identity = number
	end
	Persistence.localNumberRegistry[root.identity] = root.phoneKey
	root.registry[root.identity] = true
	return root.identity
end

function Persistence.setPhoneNumber(item, number, phoneId)
	local root = Persistence.getPhoneRoot(item, phoneId)
	root.identity = tostring(number or "")
	if root.identity ~= "" then
		Persistence.localNumberRegistry[root.identity] = root.phoneKey
		root.registry[root.identity] = true
	end
	return root.identity
end

function Persistence.getContacts(item, phoneId)
	local root = Persistence.getPhoneRoot(item, phoneId)
	root.contacts = root.contacts or {}
	return root.contacts
end

function Persistence.addContact(item, name, number, phoneId)
	local contacts = Persistence.getContacts(item, phoneId)
	number = tostring(number or "")
	if number == "" then return nil end
	for i = 1, #contacts do
		local contact = contacts[i]
		if tostring(contact.number) == number then
			contact.name = name or contact.name or number
			return contact
		end
	end
	local contact = { name = name or number, number = number }
	table.insert(contacts, contact)
	return contact
end

return Persistence
