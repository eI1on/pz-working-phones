local Registry = {}

Registry._wallpapers = {}
Registry._order = {}

local function contains(list, value)
	if type(list) ~= "table" then return false end
	value = tostring(value or "")
	for i = 1, #list do
		if tostring(list[i]) == value then return true end
	end
	return false
end

local function matchesPhone(wallpaper, definition)
	if type(definition) ~= "table" then return true end
	if type(wallpaper.phones) == "table" and not contains(wallpaper.phones, definition.id) then return false end
	if type(wallpaper.hardwareTypes) == "table" and not contains(wallpaper.hardwareTypes, definition.hardwareType) then return false end
	return true
end

local function normalize(definition)
	local wallpaper = definition
	wallpaper.id = tostring(wallpaper.id or "")
	if wallpaper.id == "" then return nil end
	wallpaper.kind = tostring(wallpaper.kind or (wallpaper.texture and "texture" or "color"))
	wallpaper.r = tonumber(wallpaper.r) or 0.05
	wallpaper.g = tonumber(wallpaper.g) or 0.06
	wallpaper.b = tonumber(wallpaper.b) or 0.09
	wallpaper.order = tonumber(wallpaper.order) or 1000
	return wallpaper
end

function Registry.register(id, definition)
	if type(definition) ~= "table" then return nil end
	definition.id = tostring(id or definition.id or "")
	local wallpaper = normalize(definition)
	if not wallpaper then return nil end
	if Registry._wallpapers[wallpaper.id] == nil then
		table.insert(Registry._order, wallpaper.id)
	end
	Registry._wallpapers[wallpaper.id] = wallpaper
	return wallpaper
end

function Registry.registerMany(list)
	if type(list) ~= "table" then return end
	for i = 1, #list do
		Registry.register(list[i].id, list[i])
	end
end

function Registry.remove(id)
	id = tostring(id or "")
	if Registry._wallpapers[id] == nil then return false end
	Registry._wallpapers[id] = nil
	for i = #Registry._order, 1, -1 do
		if Registry._order[i] == id then table.remove(Registry._order, i) end
	end
	return true
end

function Registry.setEnabled(id, enabled)
	local wallpaper = Registry._wallpapers[tostring(id or "")]
	if not wallpaper then return false end
	wallpaper.enabled = enabled ~= false
	return true
end

function Registry.get(id, definition)
	local wallpaper = Registry._wallpapers[tostring(id or "")]
	if wallpaper and wallpaper.enabled ~= false and matchesPhone(wallpaper, definition) then
		return wallpaper
	end
	return nil
end

function Registry.list(definition)
	local out = {}
	for i = 1, #Registry._order do
		local wallpaper = Registry._wallpapers[Registry._order[i]]
		if wallpaper and wallpaper.enabled ~= false and matchesPhone(wallpaper, definition) then
			table.insert(out, wallpaper)
		end
	end
	table.sort(out, function(a, b)
		if a.order == b.order then return a.id < b.id end
		return a.order < b.order
	end)
	return out
end

function Registry.first(definition)
	local list = Registry.list(definition)
	return list[1]
end

function Registry.label(wallpaper)
	if type(wallpaper) ~= "table" then return "" end
	if wallpaper.nameKey and getText then
		return getText("IGUI_WorkingPhones_" .. tostring(wallpaper.nameKey))
	end
	return tostring(wallpaper.label or wallpaper.id or "")
end

return Registry
