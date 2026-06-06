require("WorkingPhones/Core/WorkingPhonesGlobals")
require("WorkingPhones/Registration/RegisterPhoneSounds")
require("WorkingPhones/Registration/RegisterSmartphoneWallpapers")
require("WorkingPhones/Core/PhoneNetworking")
require("WorkingPhones/Core/PhoneInventoryService")
require("WorkingPhones/Registration/RegisterPhoneItems")
require("WorkingPhones/Apps/RegisterApps")
require("WorkingPhones/WorkingPhonesModOptions")

local PhoneRegistry = require("WorkingPhones/Core/PhoneRegistry")
local PhonePanel = require("WorkingPhones/UI/PhonePanel")
local I18N = require("WorkingPhones/Core/PhoneI18N")

require("WorkingPhones/Phones/ClassicPhone2110")
require("WorkingPhones/Phones/GenericSmartphone")
require("WorkingPhones/Inventory/PhoneInventoryContext")

function WorkingPhones.openPhone(phoneId, playerNum, item, variantId)
	local definition = PhoneRegistry.get(phoneId or "classic_2110")
	if not definition then
		WorkingPhones.log("Unknown phone id: " .. tostring(phoneId))
		return nil
	end
	return PhonePanel.open(definition, playerNum or 0, item, variantId)
end

function WorkingPhones.openClassicPhone(playerNum)
	return WorkingPhones.openPhone("classic_2110", playerNum)
end

function WorkingPhones.openSmartphone(playerNum)
	return WorkingPhones.openPhone("generic_smartphone", playerNum)
end

local function addDebugContext(playerNum, context)
	if not isDebugEnabled or not isDebugEnabled() then
		return
	end
	local submenu = context:getNew(context)
	context:addSubMenu(context:addOption(I18N.get("DebugMenu")), submenu)
	submenu:addOption(I18N.get("DebugOpenClassic"), nil, function()
		WorkingPhones.openClassicPhone(playerNum)
	end)
	submenu:addOption(I18N.get("DebugOpenSmartphone"), nil, function()
		WorkingPhones.openSmartphone(playerNum)
	end)
end

Events.OnFillWorldObjectContextMenu.Add(addDebugContext)

return WorkingPhones
