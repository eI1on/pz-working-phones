require("WorkingPhones/Registration/RegisterPhoneItems")
require("ISUI/ISTextBox")

local PhoneItemRegistry = require("WorkingPhones/Registries/PhoneItemRegistry")
local PhoneRegistry = require("WorkingPhones/Core/PhoneRegistry")
local PhonePanel = require("WorkingPhones/UI/PhonePanel")
local Persistence = require("WorkingPhones/Core/PhonePersistence")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local Service = require("WorkingPhones/Core/PhoneInventoryService")

local function getInventoryItem(entry)
	if not entry then
		return nil
	end
	if entry.getFullType then
		return entry
	end
	if type(entry) == "table" and entry.items then
		for i = 1, #entry.items do
			local nested = entry.items[i]
			local item = getInventoryItem(nested)
			if item then
				return item
			end
		end
	end
	return nil
end

local function collectPhoneItems(items)
	local phones = {}
	items = items or {}
	for i = 1, #items do
		local entry = items[i]
		local item = getInventoryItem(entry)
		local mapping = PhoneItemRegistry.getByItem(item)
		if item and mapping then
			table.insert(phones, { item = item, mapping = mapping })
		end
	end
	return phones
end

local function openPhone(playerNum, item, mapping)
	local definition = PhoneRegistry.get(mapping.phoneId)
	if definition then
		PhonePanel.open(definition, playerNum, item, mapping.variantId)
	end
end

local function renamePhone(target, button, item, mapping)
	if not button or button.internal ~= "OK" or not button.parent or not button.parent.entry then
		return
	end
	local definition = PhoneRegistry.get(mapping.phoneId)
	local name = button.parent.entry:getText()
	if definition and name and name ~= "" then
		Persistence.setDisplayName(item, name, definition.id)
		if item.setName then item:setName(name) end
		Service.scan(getSpecificPlayer(0), true)
	end
end

local function openRenameDialog(playerNum, item, mapping)
	local definition = PhoneRegistry.get(mapping.phoneId)
	if not definition then return end
	local fallbackName = definition.displayNameKey and I18N.get(definition.displayNameKey) or definition.displayName
	local current = Persistence.getDisplayName(item, fallbackName, definition.id)
	local modal = ISTextBox:new(0, 0, 320, 160, getText("IGUI_WorkingPhones_PhoneDisplayName"), current, nil, renamePhone, playerNum, item, mapping)
	modal:initialise()
	modal:addToUIManager()
	modal.moveWithMouse = true
end

local function onInventoryContextMenu(playerNum, context, items)
	local phones = collectPhoneItems(items)
	if #phones == 0 then
		return
	end

	if #phones == 1 then
		context:addOption(getText("ContextMenu_WorkingPhones_OpenPhone"), phones[1], function(phone)
			openPhone(playerNum, phone.item, phone.mapping)
		end)
		context:addOption(getText("ContextMenu_WorkingPhones_EditPhoneDisplayName"), phones[1], function(phone)
			openRenameDialog(playerNum, phone.item, phone.mapping)
		end)
		return
	end

	local parent = context:addOption(getText("ContextMenu_WorkingPhones_OpenPhone"))
	local submenu = context:getNew(context)
	context:addSubMenu(parent, submenu)
	for i = 1, #phones do
		local phone = phones[i]
		submenu:addOption(phone.item:getDisplayName(), phone, function(selectedPhone)
			openPhone(playerNum, selectedPhone.item, selectedPhone.mapping)
		end)
	end
	local renameParent = context:addOption(getText("ContextMenu_WorkingPhones_EditPhoneDisplayName"))
	local renameSubmenu = context:getNew(context)
	context:addSubMenu(renameParent, renameSubmenu)
	for i = 1, #phones do
		local phone = phones[i]
		renameSubmenu:addOption(phone.item:getDisplayName(), phone, function(selectedPhone)
			openRenameDialog(playerNum, selectedPhone.item, selectedPhone.mapping)
		end)
	end
end

Events.OnFillInventoryObjectContextMenu.Add(onInventoryContextMenu)
