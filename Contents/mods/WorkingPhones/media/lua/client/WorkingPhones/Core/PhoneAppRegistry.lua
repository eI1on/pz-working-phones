local AppRegistry = {
	apps = {},
	order = {},
}
local I18N = require("WorkingPhones/Core/PhoneI18N")

function AppRegistry.register(appId, appClass, metadata)
	if not AppRegistry.apps[appId] then
		table.insert(AppRegistry.order, appId)
	end
	AppRegistry.apps[appId] = {
		class = appClass,
		metadata = metadata or {},
	}
end

function AppRegistry.create(appId, phoneOS)
	local entry = AppRegistry.apps[appId]
	if not entry then
		return nil
	end
	local app = entry.class:new(phoneOS)
	app.id = app.id or appId
	local meta = entry.metadata or {}
	app.name = meta.nameKey and I18N.get(meta.nameKey) or meta.name or I18N.app(app.id or appId)
	app.smartphoneIcon = meta.smartphoneIcon
	app.metadata = meta
	return app
end

function AppRegistry.getMetadata(appId)
	local entry = AppRegistry.apps[appId]
	return entry and entry.metadata or nil
end

local function listHas(list, value)
	if type(list) ~= "table" then return false end
	for i = 1, #list do
		if tostring(list[i]) == tostring(value) then return true end
	end
	return false
end

local function supportsPhone(meta, definition)
	if type(meta) ~= "table" then return false end
	if meta.hidden == true then return false end
	if type(meta.phones) == "table" and not listHas(meta.phones, definition.id) then return false end
	if type(meta.hardwareTypes) == "table" and not listHas(meta.hardwareTypes, definition.hardwareType) then return false end
	if type(meta.excludePhones) == "table" and listHas(meta.excludePhones, definition.id) then return false end
	return true
end

local function shouldInstallOnPhone(meta, definition)
	if not supportsPhone(meta, definition) then return false end
	if meta.autoInstall == true then return true end
	if type(meta.installOnPhones) == "table" and listHas(meta.installOnPhones, definition.id) then return true end
	if type(meta.installOnHardware) == "table" and listHas(meta.installOnHardware, definition.hardwareType) then return true end
	return false
end

local function appInfo(appId, meta)
	return {
		id = appId,
		name = meta.nameKey and I18N.get(meta.nameKey) or meta.name or I18N.app(appId),
		smartphoneIcon = meta.smartphoneIcon,
		metadata = meta,
	}
end

function AppRegistry.getApps(appIds)
	local apps = {}
	appIds = appIds or AppRegistry.order
	for i = 1, #appIds do
		local appId = appIds[i]
		local meta = AppRegistry.getMetadata(appId)
		if meta then
			table.insert(apps, appInfo(appId, meta))
		end
	end
	return apps
end

function AppRegistry.getAppsForPhone(definition)
	local ids, seen = {}, {}
	local defaultApps = definition.defaultApps or {}
	for i = 1, #defaultApps do
		local appId = defaultApps[i]
		if AppRegistry.apps[appId] and not seen[appId] then
			ids[#ids + 1] = appId
			seen[appId] = true
		end
	end
	for i = 1, #AppRegistry.order do
		local appId = AppRegistry.order[i]
		local meta = AppRegistry.getMetadata(appId)
		if not seen[appId] and shouldInstallOnPhone(meta, definition) then
			ids[#ids + 1] = appId
			seen[appId] = true
		end
	end
	return AppRegistry.getApps(ids)
end

function AppRegistry.getGamesForPhone(definition)
	local games = {}
	for i = 1, #AppRegistry.order do
		local appId = AppRegistry.order[i]
		local meta = AppRegistry.getMetadata(appId)
		if meta and meta.game == true and meta.showInGamesHub ~= false and supportsPhone(meta, definition) then
			games[#games + 1] = appInfo(appId, meta)
		end
	end
	table.sort(games, function(a, b)
		local ao = tonumber(a.metadata and a.metadata.gameOrder) or 1000
		local bo = tonumber(b.metadata and b.metadata.gameOrder) or 1000
		if ao == bo then return tostring(a.id) < tostring(b.id) end
		return ao < bo
	end)
	return games
end

return AppRegistry
