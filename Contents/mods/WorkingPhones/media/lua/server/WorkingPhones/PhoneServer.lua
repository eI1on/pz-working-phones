local MODULE = "WorkingPhones"
local Common = require("WorkingPhones/Common/PhoneCommon")
local ObjectMessages = require("KnoxNet/ObjectMessages")

local Commands = {}
local WORLD_DATA_ID = "WorkingPhones.World"
local PHONE_MESSAGE_NAMESPACE = "working_phones"
local EMERGENCY_NUMBER = "555-000000"
local WorldData
local WorldGameScores = {}
local PhoneRegistryByKey = {}
local PhoneKeyByNumber = {}
local PhonePlayerByNumber = {}
local PhoneInfoByKey = {}
local ActiveCallByNumber = {}
local ActiveCallByPlayer = {}
local ActiveVoiceChannel = {}
local CallsById = {}

local function worldData()
	if WorldData then return WorldData end
	WorldData = ModData.getOrCreate(WORLD_DATA_ID)
	WorldData.phoneRegistryByKey = type(WorldData.phoneRegistryByKey) == "table" and WorldData.phoneRegistryByKey or {}
	WorldData.phoneKeyByNumber = type(WorldData.phoneKeyByNumber) == "table" and WorldData.phoneKeyByNumber or {}
	WorldData.phoneInfoByKey = type(WorldData.phoneInfoByKey) == "table" and WorldData.phoneInfoByKey or {}
	WorldData.gameScores = type(WorldData.gameScores) == "table" and WorldData.gameScores or {}
	PhoneRegistryByKey = WorldData.phoneRegistryByKey
	PhoneKeyByNumber = WorldData.phoneKeyByNumber
	PhoneInfoByKey = WorldData.phoneInfoByKey
	WorldGameScores = WorldData.gameScores
	return WorldData
end

local function transmitWorldData()
	ModData.transmit(WORLD_DATA_ID)
end

local function messageCap()
	return Common.messageHistoryLimit()
end

local function scoreLimit()
	return 10
end

local function broadcastWorldScores(playerObj)
	local payload = { scores = WorldGameScores }
	sendServerCommand(MODULE, "WorldGameScores", payload)
	if playerObj then
		sendServerCommand(playerObj, MODULE, "WorldGameScores", payload)
	end
end

local function uniqueNumber(requestedNumber, phoneKey)
	worldData()
	local number = tostring(requestedNumber or "")
	if number == "" then
		number = "555-" .. tostring(ZombRand(100000, 999999))
	end
	while PhoneKeyByNumber[number] and PhoneKeyByNumber[number] ~= phoneKey do
		number = "555-" .. tostring(ZombRand(100000, 999999))
	end
	return number
end

local function nearbyRadius()
	return tonumber(SandboxVars and SandboxVars.WorkingPhones and SandboxVars.WorkingPhones.NearbyPhonesRadius) or 25
end

local function phoneInfoByNumber(number)
	worldData()
	local phoneKey = PhoneKeyByNumber[tostring(number or "")]
	return phoneKey and PhoneInfoByKey[phoneKey] or nil
end

local function playerKey(playerObj)
	return playerObj and playerObj.getUsername and tostring(playerObj:getUsername()) or nil
end

local function sendToPhoneNumber(number, command, args)
	local playerObj = PhonePlayerByNumber[tostring(number or "")]
	if playerObj then
		sendServerCommand(playerObj, MODULE, command, args)
		return true
	end
	return false
end

local function phoneSoundAlertKey(args)
	local sourceKey = tostring(args and args.sourceKey or "")
	local alertKind = tostring(args and args.alertKind or "notification")
	if sourceKey == "" then
		sourceKey = tostring(args and args.event or "phone")
	end
	return sourceKey .. ":" .. alertKind
end

local function broadcastStopPhoneSound(number, alertKind)
	local info = phoneInfoByNumber(number)
	if not info then return end
	local alertKey = tostring(info.phoneKey or "") .. ":" .. tostring(alertKind or "call")
	local players = getOnlinePlayers()
	for i = 0, players:size() - 1 do
		local target = players:get(i)
		if target then
			sendServerCommand(target, MODULE, "StopPhoneSound", {
				alertKey = alertKey,
				alertKind = tostring(alertKind or "call"),
			})
		end
	end
end

local function clearCall(call)
	if not call then return end
	CallsById[call.id] = nil
	if call.voiceChannel then ActiveVoiceChannel[tonumber(call.voiceChannel)] = nil end
	if call.fromNumber then ActiveCallByNumber[tostring(call.fromNumber)] = nil end
	if call.targetNumber then ActiveCallByNumber[tostring(call.targetNumber)] = nil end
	if call.fromPlayerKey then ActiveCallByPlayer[call.fromPlayerKey] = nil end
	if call.targetPlayerKey then ActiveCallByPlayer[call.targetPlayerKey] = nil end
end

local function voiceChannelSeed(call)
	local text = tostring(call and call.id or getTimestampMs())
	local seed = 0
	for i = 1, #text do
		seed = (seed * 33 + string.byte(text, i)) % 90000
	end
	return 900000 + seed
end

local function allocateVoiceChannel(call)
	if call.voiceChannel then return call.voiceChannel end
	local channel = voiceChannelSeed(call)
	while ActiveVoiceChannel[channel] do
		channel = channel + 200
		if channel > 999800 then channel = 900000 end
	end
	ActiveVoiceChannel[channel] = call.id
	call.voiceChannel = channel
	return channel
end

local function sendToMatchingNumber(targetNumber, command, args)
	local normalizedTarget = targetNumber and tostring(targetNumber) or nil
	if normalizedTarget and PhonePlayerByNumber[normalizedTarget] then
		sendServerCommand(PhonePlayerByNumber[normalizedTarget], MODULE, command, args)
		return true
	end

	if normalizedTarget then
		return false
	end

	local sent = false
	for number in pairs(PhonePlayerByNumber) do
		local playerObj = PhonePlayerByNumber[number]
		sendServerCommand(playerObj, MODULE, command, args)
		sent = true
	end
	return sent
end

function Commands.RegisterPhone(playerObj, args)
	worldData()
	args = args or {}
	local phoneKey = tostring(args.phoneKey or "")
	if phoneKey == "" then return end

	local oldNumber = PhoneRegistryByKey[phoneKey]
	local number = uniqueNumber(oldNumber or args.requestedNumber, phoneKey)
	if oldNumber and oldNumber ~= number then
		PhoneKeyByNumber[oldNumber] = nil
		PhonePlayerByNumber[oldNumber] = nil
	end

	PhoneRegistryByKey[phoneKey] = number
	PhoneKeyByNumber[number] = phoneKey
	PhonePlayerByNumber[number] = playerObj
	PhoneInfoByKey[phoneKey] = {
		phoneKey = phoneKey,
		number = number,
		displayName = tostring(args.displayName or number),
		x = tonumber(args.x),
		y = tonumber(args.y),
		z = tonumber(args.z),
		open = true,
	}

	transmitWorldData()
	sendServerCommand(playerObj, MODULE, "PhoneRegistered", { phoneKey = phoneKey, number = number })
end

function Commands.RequestOpenPhones(playerObj, args)
	worldData()
	args = args or {}
	local requesterKey = tostring(args.phoneKey or "")
	local requester = PhoneInfoByKey[requesterKey]
	local radius = nearbyRadius()
	local phones = {}
	for phoneKey, info in pairs(PhoneInfoByKey) do
		if phoneKey ~= requesterKey and info and info.number and PhonePlayerByNumber[tostring(info.number)] then
			local include = true
			if requester and requester.x and requester.y and info.x and info.y then
				local dx, dy = requester.x - info.x, requester.y - info.y
				include = (dx * dx + dy * dy) <= (radius * radius)
			end
			if include then
				table.insert(phones, {
					phoneKey = phoneKey,
					name = info.displayName or info.number,
					number = info.number,
				})
			end
		end
	end
	table.sort(phones, function(a, b) return tostring(a.name) < tostring(b.name) end)
	sendServerCommand(playerObj, MODULE, "OpenPhonesList", { phones = phones })
end

function Commands.UnregisterPhone(playerObj, args)
	worldData()
	args = args or {}
	local phoneKey = tostring(args.phoneKey or "")
	if phoneKey == "" then return end
	local number = PhoneRegistryByKey[phoneKey]
	if number then
		PhonePlayerByNumber[number] = nil
	end
	if PhoneInfoByKey[phoneKey] then
		PhoneInfoByKey[phoneKey].open = false
	end
	transmitWorldData()
end

function Commands.CallRequest(playerObj, args)
	args = args or {}
	local fromNumber = tostring(args.fromNumber or "")
	local targetNumber = tostring(args.targetNumber or "")
	if fromNumber == "" or targetNumber == "" then return end
	local targetInfo = phoneInfoByNumber(targetNumber)
	if not targetInfo or not PhonePlayerByNumber[targetNumber] then
		sendToPhoneNumber(fromNumber, "CallRejected", { targetNumber = targetNumber, reason = "Unavailable" })
		return
	end
	local fromPlayer = PhonePlayerByNumber[fromNumber] or playerObj
	local targetPlayer = PhonePlayerByNumber[targetNumber]
	local fromPlayerKey = playerKey(fromPlayer)
	local targetPlayerKey = playerKey(targetPlayer)
	if ActiveCallByNumber[fromNumber] or ActiveCallByNumber[targetNumber] or
		(fromPlayerKey and ActiveCallByPlayer[fromPlayerKey]) or
		(targetPlayerKey and ActiveCallByPlayer[targetPlayerKey]) then
		sendToPhoneNumber(fromNumber, "CallRejected", { targetNumber = targetNumber, reason = "Busy" })
		return
	end
	local callId = fromNumber .. ">" .. targetNumber .. "@" .. tostring(getTimestampMs())
	local call = {
		id = callId,
		fromNumber = fromNumber,
		targetNumber = targetNumber,
		fromPlayerKey = fromPlayerKey,
		targetPlayerKey = targetPlayerKey,
		state = "ringing",
	}
	CallsById[callId] = call
	ActiveCallByNumber[fromNumber] = callId
	ActiveCallByNumber[targetNumber] = callId
	if fromPlayerKey then ActiveCallByPlayer[fromPlayerKey] = callId end
	if targetPlayerKey then ActiveCallByPlayer[targetPlayerKey] = callId end
	sendToPhoneNumber(fromNumber, "CallRinging", { callId = callId, targetNumber = targetNumber })
	sendToPhoneNumber(targetNumber, "IncomingCall", {
		callId = callId,
		targetNumber = targetNumber,
		fromNumber = fromNumber,
	})
end

function Commands.AnswerCall(playerObj, args)
	args = args or {}
	local call = CallsById[tostring(args.callId or "")]
	if not call or call.targetNumber ~= tostring(args.targetNumber or "") then return end
	call.state = "connected"
	broadcastStopPhoneSound(call.targetNumber, "call")
	local voiceChannel = allocateVoiceChannel(call)
	sendToPhoneNumber(call.fromNumber, "CallAnswered", {
		callId = call.id,
		targetNumber = call.targetNumber,
		voiceChannel = voiceChannel,
	})
	sendToPhoneNumber(call.targetNumber, "CallConnected", {
		callId = call.id,
		fromNumber = call.fromNumber,
		voiceChannel = voiceChannel,
	})
end

function Commands.DeclineCall(playerObj, args)
	args = args or {}
	local call = CallsById[tostring(args.callId or "")]
	if not call then return end
	local declinedBy = tostring(args.number or "")
	local other = declinedBy == call.fromNumber and call.targetNumber or call.fromNumber
	broadcastStopPhoneSound(declinedBy, "call")
	sendToPhoneNumber(other, "CallRejected", { callId = call.id, targetNumber = declinedBy, reason = args.reason or "Declined" })
	clearCall(call)
end

function Commands.HangupCall(playerObj, args)
	args = args or {}
	local call = CallsById[tostring(args.callId or ActiveCallByNumber[tostring(args.number or "")] or "")]
	if not call then return end
	local hungBy = tostring(args.number or "")
	local other = hungBy == call.fromNumber and call.targetNumber or call.fromNumber
	broadcastStopPhoneSound(call.fromNumber, "call")
	broadcastStopPhoneSound(call.targetNumber, "call")
	sendToPhoneNumber(other, "CallEnded", { callId = call.id, number = hungBy, reason = args.reason or "HungUp" })
	clearCall(call)
end

function Commands.PhoneSound(playerObj, args)
	args = args or {}
	local eventName = tostring(args.event or "")
	if eventName == "" then return end
	local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z) or 0
	local volume = Common.clamp01(args.volume, 0.7)
	local radius = tonumber(args.radius) or Common.phoneSoundRadius(volume)
	if radius <= 0 then return end
	if args.audible ~= false and playerObj and playerObj.getX then
		addSound(playerObj, x or playerObj:getX(), y or playerObj:getY(), z or playerObj:getZ(), radius, math.max(1, math.floor(volume * 10)))
	end
	local players = getOnlinePlayers()
	if not x or not y then return end
	for i = 0, players:size() - 1 do
		local target = players:get(i)
		if target and target ~= playerObj and target.getX then
			local dx, dy = target:getX() - x, target:getY() - y
			if dx * dx + dy * dy <= radius * radius then
				sendServerCommand(target, MODULE, "PlayPhoneSound", {
					event = eventName,
					volume = volume,
					radius = radius,
					audible = args.audible ~= false,
					alertKey = phoneSoundAlertKey(args),
					alertKind = tostring(args.alertKind or "notification"),
					loop = args.loop == true,
					x = x,
					y = y,
					z = z,
				})
			end
		end
	end
end

function Commands.SendMessage(playerObj, args)
	args = args or {}
	worldData()
	local fromNumber = tostring(args.fromNumber or "")
	local targetNumber = tostring(args.targetNumber or "")
	local body = tostring(args.body or "")
	if fromNumber == "" or targetNumber == "" or body == "" then return end
	if targetNumber == EMERGENCY_NUMBER then return end
	local message = ObjectMessages.append(PHONE_MESSAGE_NAMESPACE, fromNumber, targetNumber, body, {
		sourceMod = MODULE,
		gameDate = tostring(args.time or ""),
	}, messageCap())
	if not message then return end
	sendToMatchingNumber(fromNumber, "PhoneMessageSent", {
		message = message,
		targetNumber = targetNumber,
		fromNumber = fromNumber,
	})
	sendToMatchingNumber(targetNumber, "IncomingMessage", {
		targetNumber = args.targetNumber,
		fromNumber = args.fromNumber,
		body = args.body,
		message = message,
	})
end

function Commands.FetchMessages(playerObj, args)
	args = args or {}
	local phoneNumber = tostring(args.phoneNumber or "")
	if phoneNumber == "" then return end
	local peerNumber = tostring(args.peerNumber or "")
	if peerNumber ~= "" then
		local payload = {
			phoneNumber = phoneNumber,
			peerNumber = peerNumber,
			messages = ObjectMessages.messages(PHONE_MESSAGE_NAMESPACE, phoneNumber, peerNumber, messageCap()),
		}
		if args.includeConversations == true then
			payload.conversations = ObjectMessages.conversations(PHONE_MESSAGE_NAMESPACE, phoneNumber)
		end
		sendServerCommand(playerObj, MODULE, "PhoneMessages", payload)
		return
	end
	sendServerCommand(playerObj, MODULE, "PhoneMessages", {
		phoneNumber = phoneNumber,
		conversations = ObjectMessages.conversations(PHONE_MESSAGE_NAMESPACE, phoneNumber),
		messages = {},
	})
end

function Commands.DeleteConversation(playerObj, args)
	args = args or {}
	local phoneNumber = tostring(args.phoneNumber or "")
	local peerNumber = tostring(args.peerNumber or "")
	if phoneNumber == "" or peerNumber == "" then return end
	ObjectMessages.deleteConversation(PHONE_MESSAGE_NAMESPACE, phoneNumber, peerNumber)
	sendServerCommand(playerObj, MODULE, "PhoneMessages", {
		phoneNumber = phoneNumber,
		conversations = ObjectMessages.conversations(PHONE_MESSAGE_NAMESPACE, phoneNumber),
		messages = {},
	})
end

function Commands.SubmitGameScore(playerObj, args)
	args = args or {}
	worldData()
	local gameId = tostring(args.gameId or "")
	if gameId == "" then return end
	WorldGameScores[gameId] = WorldGameScores[gameId] or {}
	local name = tostring(args.name or "Player")
	local score = tonumber(args.score) or 0
	local rows = WorldGameScores[gameId]
	local replaced = false
	for i = 1, #rows do
		local row = rows[i]
		if row.name == name then
			if score > (tonumber(row.score) or 0) then
				row.score = score
				row.phoneNumber = tostring(args.phoneNumber or "")
			end
			replaced = true
			break
		end
	end
	if not replaced then
		table.insert(rows, { name = name, score = score, phoneNumber = tostring(args.phoneNumber or "") })
	end
	table.sort(rows, function(a, b) return (tonumber(a.score) or 0) > (tonumber(b.score) or 0) end)
	while #rows > scoreLimit() do table.remove(rows) end
	transmitWorldData()
	broadcastWorldScores(playerObj)
end

function Commands.RequestWorldGameScores(playerObj, args)
	worldData()
	sendServerCommand(playerObj, MODULE, "WorldGameScores", { scores = WorldGameScores })
end

local function onClientCommand(module, command, playerObj, args)
	if module ~= MODULE then
		return
	end
	local handler = Commands[command]
	if handler then
		handler(playerObj, args or {})
	end
end

Events.OnClientCommand.Add(onClientCommand)

local function initWorldData()
	worldData()
end

Events.OnInitGlobalModData.Add(initWorldData)

return Commands
