require("Items/ProceduralDistributions")
require("Items/SuburbsDistributions")
require("WorkingPhones/Registration/RegisterPhoneItems")

local Common = require("WorkingPhones/Common/PhoneCommon")
local PhoneItemRegistry = require("WorkingPhones/Registries/PhoneItemRegistry")

local DUMMY_ITEM = "WorkingPhones.PhoneSpawnDummy"
local DISTRIBUTION_POINT_SCALE = 0.01

local PROCEDURAL_TARGETS = {
	{ name = "GigamartHouseElectronics",    points = 300 },
	{ name = "ElectronicStoreMisc",         points = 300 },
	{ name = "StoreShelfElectronics",       points = 300 },
	{ name = "CrateElectronics",            points = 100 },
	{ name = "BedroomSideTable",            points = 35 },
	{ name = "LivingRoomSideTable",         points = 35 },
	{ name = "LivingRoomSideTableNoRemote", points = 35 },
	{ name = "OfficeDeskHome",              points = 25 },
	{ name = "OfficeDesk",                  points = 20 },
	{ name = "OfficeDrawers",               points = 20 },
	{ name = "OfficeCounter",               points = 15 },
	{ name = "DeskGeneric",                 points = 15 },
	{ name = "PoliceDesk",                  points = 15 },
	{ name = "ClassroomDesk",               points = 10 },
	{ name = "DaycareDesk",                 points = 10 },
	{ name = "CrateComputer",               points = 50 },
	{ name = "CrateRandomJunk",             points = 25 },
	{ name = "PawnShopCases",               points = 25 },
	{ name = "ArmyStorageElectronics",      points = 15 },
	{ name = "MechanicShelfElectric",       points = 15 },
	{ name = "ControlRoomCounter",          points = 15 },
	{ name = "Locker",                      points = 10 },
	{ name = "LockerClassy",                points = 10 },
	{ name = "SchoolLockers",               points = 10 },
	{ name = "GymLockers",                  points = 10 },
	{ name = "PostOfficeSupplies",          points = 5 },
	{ name = "ShelfGeneric",                points = 5 },
}

local ZOMBIE_TARGETS = {
	{ gender = "inventorymale",   points = 20 },
	{ gender = "inventoryfemale", points = 20 },
}

local function lootMultiplier()
	return Common.sandboxPercent("PhoneLootSpawnRate", 100, 0, 500)
end

local function zombieMultiplier()
	return Common.sandboxPercent("PhoneZombieSpawnRate", 25, 0, 500)
end

local function groupEnabled(group)
	if group.sandboxEnabled and not Common.sandboxBool(group.sandboxEnabled, true) then
		return false
	end
	return true
end

local function groupWeight(group)
	if not groupEnabled(group) or #group.items == 0 then
		return 0
	end
	return tonumber(group.weight) or 0
end

local function itemWeight(item)
	return tonumber(item.weight) or 0
end

local function chooseWeighted(items, weightFunction)
	local total = 0
	for i = 1, #items do
		total = total + weightFunction(items[i])
	end
	if total <= 0 then
		return nil
	end
	local roll = ZombRandFloat(0, total)
	local cursor = 0
	local fallback = nil
	for i = 1, #items do
		local weight = weightFunction(items[i])
		if weight > 0 then
			fallback = items[i]
			cursor = cursor + weight
			if roll <= cursor then
				return items[i]
			end
		end
	end
	return fallback
end

local function chooseSpawnItem()
	local group = chooseWeighted(PhoneItemRegistry.getSpawnGroups(), groupWeight)
	if not group then
		return nil
	end
	local item = chooseWeighted(group.items, itemWeight)
	return item and item.fullType or nil
end

local function replaceDummies(container)
	if not container then
		return
	end
	local dummies = container:getAllType(DUMMY_ITEM)
	for i = 0, dummies:size() - 1 do
		container:Remove(dummies:get(i))
		local fullType = chooseSpawnItem()
		if fullType then
			local item = container:AddItem(fullType)
			if item then
				container:addItemOnServer(item)
			end
		end
	end
end

local function pointsToWeight(points)
	return (tonumber(points) or 0) * DISTRIBUTION_POINT_SCALE
end

local function addProceduralDummy(listName, points)
	local list = ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list[listName]
	if not list or not list.items then
		return
	end
	local adjusted = pointsToWeight(points) * lootMultiplier()
	if adjusted <= 0 then
		return
	end
	table.insert(list.items, DUMMY_ITEM)
	table.insert(list.items, adjusted)
end

local function addZombieDummy(gender, points)
	local distribution = SuburbsDistributions and SuburbsDistributions.all and SuburbsDistributions.all[gender]
	if not distribution or not distribution.items then
		return
	end
	local adjusted = pointsToWeight(points) * zombieMultiplier()
	if adjusted <= 0 then
		return
	end
	table.insert(distribution.items, DUMMY_ITEM)
	table.insert(distribution.items, adjusted)
end

local function addDistributions()
	for i = 1, #PROCEDURAL_TARGETS do
		addProceduralDummy(PROCEDURAL_TARGETS[i].name, PROCEDURAL_TARGETS[i].points)
	end
	for i = 1, #ZOMBIE_TARGETS do
		addZombieDummy(ZOMBIE_TARGETS[i].gender, ZOMBIE_TARGETS[i].points)
	end
end

local function onFillContainer(_roomName, _containerType, container)
	replaceDummies(container)
end

local function onRefreshInventoryWindowContainers(inventoryPage)
	if not inventoryPage.inventory or not instanceof(inventoryPage.inventory:getParent(), "IsoDeadBody") then
		return
	end
	replaceDummies(inventoryPage.inventory)
end

addDistributions()
Events.OnFillContainer.Add(onFillContainer)
Events.OnRefreshInventoryWindowContainers.Add(onRefreshInventoryWindowContainers)

return true
