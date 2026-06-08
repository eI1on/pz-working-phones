local PhoneCommon = {}

function PhoneCommon.clamp(value, minValue, maxValue)
	value = tonumber(value) or minValue
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

function PhoneCommon.clamp01(value, fallback)
	value = tonumber(value) or fallback or 0
	if value < 0 then return 0 end
	if value > 1 then return 1 end
	return value
end

function PhoneCommon.phoneSoundRadius(volume)
	volume = PhoneCommon.clamp01(volume, 0.7)
	if volume <= 0 then return 0 end
	return math.max(4, math.floor(4 + volume * 22))
end

function PhoneCommon.phoneVibrationRadius(volume)
	volume = PhoneCommon.clamp01(volume, 0.4)
	if volume <= 0 then return 0 end
	return math.max(1, math.floor(1 + volume * 4))
end

function PhoneCommon.soundMode(data)
	local mode = data and tostring(data.soundMode or "")
	if mode == "vibrate" or mode == "silent" then
		return mode
	end
	return "sound"
end

function PhoneCommon.sandboxValue(key)
	local vars = SandboxVars
	if not vars then
		return nil
	end
	local dot = string.find(key, "%.")
	if dot then
		local page = string.sub(key, 1, dot - 1)
		local option = string.sub(key, dot + 1)
		local pageVars = vars[page]
		return pageVars and pageVars[option] or nil
	end
	local pageVars = vars.WorkingPhones
	return pageVars and pageVars[key] or nil
end

function PhoneCommon.sandboxInt(key, fallback, minValue, maxValue)
	local value = PhoneCommon.sandboxValue(key) or fallback
	value = math.floor(tonumber(value) or fallback or minValue or 0)
	if minValue and value < minValue then return minValue end
	if maxValue and value > maxValue then return maxValue end
	return value
end

function PhoneCommon.sandboxBool(key, fallback)
	local value = PhoneCommon.sandboxValue(key)
	if value == nil then
		return fallback == true
	end
	return value == true
end

function PhoneCommon.sandboxPercent(key, fallback, minValue, maxValue)
	return PhoneCommon.sandboxInt(key, fallback, minValue or 0, maxValue or 10000) / 100
end

function PhoneCommon.messageHistoryLimit()
	return PhoneCommon.sandboxInt("MessageHistoryPerContact", 100, 1, 500)
end

function PhoneCommon.callHistoryLimit()
	return PhoneCommon.sandboxInt("CallHistoryLimit", 10, 1, 100)
end

function PhoneCommon.trimList(list, limit)
	if type(list) ~= "table" then return end
	limit = math.max(0, math.floor(tonumber(limit) or 0))
	while #list > limit do
		table.remove(list)
	end
end

function PhoneCommon.copyTable(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = PhoneCommon.copyTable(v)
	end
	return out
end

function PhoneCommon.scaledRect(rect, scale)
	return {
		x = math.floor(rect.x * scale),
		y = math.floor(rect.y * scale),
		width = math.floor(rect.width * scale),
		height = math.floor(rect.height * scale),
		action = rect.action,
		value = rect.value,
		letters = rect.letters,
		label = rect.label,
		labelKey = rect.labelKey,
	}
end

function PhoneCommon.textureSize(texture)
	if not texture then
		return nil, nil
	end
	return tonumber(texture:getWidthOrig()), tonumber(texture:getHeightOrig())
end

function PhoneCommon.wrapTextToWidth(text, font, maxWidth, maxLines)
	local lines, line = {}, ""
	for word in string.gmatch(tostring(text or "") .. " ", "([^ ]*) ") do
		local candidate = line == "" and word or (line .. " " .. word)
		if getTextManager():MeasureStringX(font, candidate) > maxWidth and line ~= "" then
			table.insert(lines, line)
			line = word
			if maxLines and #lines >= maxLines then break end
		else
			line = candidate
		end
	end
	if line ~= "" and (not maxLines or #lines < maxLines) then
		table.insert(lines, line)
	end
	return lines
end

return PhoneCommon
