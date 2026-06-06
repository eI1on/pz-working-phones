require("WorkingPhones/Core/WorkingPhonesGlobals")

local Networking = {
	listeners = {},
}
local I18N = require("WorkingPhones/Core/PhoneI18N")
local Service = require("WorkingPhones/Core/PhoneInventoryService")
local Persistence = require("WorkingPhones/Core/PhonePersistence")
local PhoneUtils = require("WorkingPhones/Core/PhoneUtils")
local PhoneAudioEngine = require("WorkingPhones/Audio/PhoneAudioEngine")
local Common = require("WorkingPhones/Common/PhoneCommon")
local SoundRegistry = require("WorkingPhones/Registries/PhoneSoundRegistry")

local function tr(key, ...)
	return I18N.get(key, ...)
end

local function reasonText(reason)
	return I18N.reason(reason, "Unavailable")
end

local WORLD_DATA_ID = "WorkingPhones.World"

local function scoreLimit()
	return 10
end

local function applyWorldScores(scores)
	WorkingPhones.WorldGameScores = scores or {}
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance and panel.instance.data then
		panel.instance.data.worldGameScores = WorkingPhones.WorldGameScores
	end
end

local function upsertScore(scores, gameId, score, name, phoneNumber)
	gameId = tostring(gameId or "")
	if gameId == "" then return scores end
	scores = scores or {}
	scores[gameId] = scores[gameId] or {}
	local rows = scores[gameId]
	local playerName = tostring(name or tr("Player"))
	local numericScore = tonumber(score) or 0
	local replaced = false
	for i = 1, #rows do
		if tostring(rows[i].name or "") == playerName then
			if numericScore > (tonumber(rows[i].score) or 0) then
				rows[i].score = numericScore
				rows[i].phoneNumber = tostring(phoneNumber or "")
			end
			replaced = true
			break
		end
	end
	if not replaced then
		rows[#rows + 1] = { name = playerName, score = numericScore, phoneNumber = tostring(phoneNumber or "") }
	end
	table.sort(rows, function(a, b) return (tonumber(a.score) or 0) > (tonumber(b.score) or 0) end)
	while #rows > scoreLimit() do table.remove(rows) end
	return scores
end

local function localWorldData()
	local data = ModData.getOrCreate(WORLD_DATA_ID)
	data.gameScores = type(data.gameScores) == "table" and data.gameScores or {}
	return data
end

function Networking.on(command, handler)
	Networking.listeners[command] = handler
end

function Networking.send(command, args)
	args = args or {}
	local player = getPlayer()
	if player then
		sendClientCommand(player, WorkingPhones.NET_MODULE, command, args)
		return true
	end
	return false
end

function Networking.requestCall(targetNumber, fromNumber)
	return Networking.send("CallRequest", {
		targetNumber = targetNumber,
		fromNumber = fromNumber,
	})
end

function Networking.answerCall(callId, targetNumber)
	return Networking.send("AnswerCall", {
		callId = callId,
		targetNumber = targetNumber,
	})
end

function Networking.declineCall(callId, number, reason)
	return Networking.send("DeclineCall", {
		callId = callId,
		number = number,
		reason = reason or "Declined",
	})
end

function Networking.hangupCall(callId, number, reason)
	return Networking.send("HangupCall", {
		callId = callId,
		number = number,
		reason = reason or "HungUp",
	})
end

function Networking.sendMessage(targetNumber, body, fromNumber)
	return Networking.send("SendMessage", {
		targetNumber = targetNumber,
		fromNumber = fromNumber,
		body = body,
		time = PhoneUtils.gameDateTime(),
	})
end

function Networking.fetchMessages(phoneNumber, peerNumber, includeConversations)
	return Networking.send("FetchMessages", {
		phoneNumber = phoneNumber,
		peerNumber = peerNumber,
		includeConversations = includeConversations == true,
	})
end

function Networking.deleteConversation(phoneNumber, peerNumber)
	return Networking.send("DeleteConversation", {
		phoneNumber = phoneNumber,
		peerNumber = peerNumber,
	})
end

function Networking.submitGameScore(gameId, score, name, phoneNumber)
	local scores = upsertScore(WorkingPhones.WorldGameScores, gameId, score, name, phoneNumber)
	applyWorldScores(scores)
	if not isClient() then
		local data = localWorldData()
		data.gameScores = upsertScore(data.gameScores, gameId, score, name, phoneNumber)
		applyWorldScores(data.gameScores)
	end
	return Networking.send("SubmitGameScore", {
		gameId = gameId,
		score = score,
		name = name,
		phoneNumber = phoneNumber,
	})
end

function Networking.requestWorldGameScores()
	if not isClient() then
		local data = localWorldData()
		applyWorldScores(data.gameScores)
	end
	return Networking.send("RequestWorldGameScores", {})
end

function Networking.registerPhone(phoneKey, requestedNumber, displayName, playerObj)
	playerObj = playerObj or getPlayer()
	return Networking.send("RegisterPhone", {
		phoneKey = phoneKey,
		requestedNumber = requestedNumber,
		displayName = displayName,
		x = playerObj and playerObj.getX and playerObj:getX() or nil,
		y = playerObj and playerObj.getY and playerObj:getY() or nil,
		z = playerObj and playerObj.getZ and playerObj:getZ() or nil,
	})
end

function Networking.requestOpenPhones(phoneKey)
	return Networking.send("RequestOpenPhones", {
		phoneKey = phoneKey,
	})
end

function Networking.unregisterPhone(phoneKey)
	return Networking.send("UnregisterPhone", {
		phoneKey = phoneKey,
	})
end

local function onServerCommand(module, command, args)
	if module ~= WorkingPhones.NET_MODULE then
		return
	end
	local handler = Networking.listeners[command]
	if handler then
		handler(args or {})
	end
end

Networking.on("IncomingCall", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance and tostring(panel.instance.number) == tostring(args.targetNumber or panel.instance.number) then
		local app = panel.instance.os and panel.instance.os.currentApp
		if app and app.isConversationOpen and app:isConversationOpen(args.fromNumber) then
			if app.onInlineIncomingCall then app:onInlineIncomingCall(args) end
			panel.instance.data.callHistory = panel.instance.data.callHistory or {}
			table.insert(panel.instance.data.callHistory, 1, {
				name = panel:contactLabel(args.fromNumber or tr("Unknown")),
				number = tostring(args.fromNumber or tr("Unknown")),
				type = tr("IncomingType"),
				result = tr("Ringing"),
				date = PhoneUtils.gameDateTime(),
			})
			Common.trimList(panel.instance.data.callHistory, Common.callHistoryLimit())
			PhoneUtils.playPhoneAlert(panel.playerObj, panel.instance.data.ringtoneEvent, panel.instance.data, true, "call")
			return
		end
		panel:showIncomingCall(args.fromNumber or tr("Unknown"), args.callId)
		return
	end
	Service.scan(getPlayer(), true)
	local phone = Service.findByNumber(args.targetNumber)
	if phone then
		local data = Persistence.getPhoneData(phone.item, phone.definition.id)
		SoundRegistry.applyDefaults(data, phone.definition)
		local fromLabel = tostring(args.fromNumber or tr("Unknown"))
		local contacts = Persistence.getContacts(phone.item, phone.definition.id)
		for i = 1, #contacts do
			local contact = contacts[i]
			if tostring(contact.number) == fromLabel then
				fromLabel = tostring(contact.name or fromLabel) .. " (" .. fromLabel .. ")"
				break
			end
		end
		data.callHistory = data.callHistory or {}
		table.insert(data.callHistory, 1, {
			name = fromLabel,
			number = tostring(args.fromNumber or tr("Unknown")),
			type = tr("IncomingType"),
			result = tr("Ringing"),
			date = PhoneUtils.gameDateTime(),
		})
		Common.trimList(data.callHistory, Common.callHistoryLimit())
		data.notifications = data.notifications or {}
		table.insert(data.notifications, {
			kind = "call",
			callId = args.callId,
			fromNumber = tostring(args.fromNumber or tr("Unknown")),
			title = tr("IncomingCall"),
			text = fromLabel,
			unread = true,
		})
		PhoneUtils.playPhoneAlert(getPlayer(), data.ringtoneEvent, data, true, "call")
		PhoneUtils.toast(tr("PhoneCallOn", tostring(phone.displayName or tr("UnknownPhone"))),
			tr("FromContact", fromLabel), "warning", nil, 8)
	end
end)

Networking.on("CallRinging", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance then
		panel.instance.data.activeCall = {
			callId = args.callId,
			targetNumber = tostring(args.targetNumber or ""),
			state = "ringing",
		}
		local app = panel.instance.os and panel.instance.os.currentApp
		if app and app.onCallRinging then app:onCallRinging(args) end
	end
end)

Networking.on("CallAnswered", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance then
		panel.instance.data.activeCall = {
			callId = args.callId,
			targetNumber = tostring(args.targetNumber or ""),
			state = "connected",
		}
		local app = panel.instance.os and panel.instance.os.currentApp
		if app and app.onCallAnswered then app:onCallAnswered(args) end
	end
end)

Networking.on("CallConnected", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance then
		panel.instance.data.activeCall = {
			callId = args.callId,
			fromNumber = tostring(args.fromNumber or ""),
			state = "connected",
		}
		local app = panel.instance.os and panel.instance.os.currentApp
		if app and app.onCallConnected then app:onCallConnected(args) end
	end
end)

Networking.on("CallRejected", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance then
		panel.instance.data.activeCall = nil
		local app = panel.instance.os and panel.instance.os.currentApp
		if app and app.onCallRejected then app:onCallRejected(args) end
		PhoneUtils.toast(tr("CallEnded"), reasonText(args.reason), "warning", nil, 6)
	end
end)

Networking.on("CallEnded", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance then
		panel.instance.data.activeCall = nil
		if panel.instance.os and panel.instance.os.notification and panel.instance.os.notification.callId == args.callId then
			panel.instance.os:dismissNotification(panel.instance.os.notification)
		end
		local app = panel.instance.os and panel.instance.os.currentApp
		if app and app.onCallEnded then app:onCallEnded(args) end
	end
end)

Networking.on("PlayPhoneSound", function(args)
	local eventName = tostring(args.event or "")
	if eventName == "" then return end
	PhoneAudioEngine.play({
		sound = eventName,
		volume = tonumber(args.volume) or 0.7,
		x = tonumber(args.x),
		y = tonumber(args.y),
		z = tonumber(args.z),
		radius = tonumber(args.radius) or 0,
		playerObj = getPlayer(),
	})
end)

Networking.on("IncomingMessage", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	local targetNumber = tostring(args.targetNumber or args.to or "")
	local fromNumber = tostring(args.fromNumber or args.from or tr("Unknown"))
	local body = tostring(args.body or args.text or "")
	local message = args.message or {
		from = fromNumber,
		to = targetNumber,
		body = body,
		time = PhoneUtils.gameDateTime(),
	}
	if panel and panel.instance and tostring(panel.instance.number) == targetNumber then
		local app = panel.instance.os and panel.instance.os.currentApp
		if app and app.onPhoneMessageReceived then
			app:onPhoneMessageReceived(message)
		end
		if app and app.isConversationOpen and app:isConversationOpen(fromNumber) then
			return
		end
		panel:showIncomingMessage(fromNumber, body)
		return
	end
	Service.scan(getPlayer(), true)
	local phone = Service.findByNumber(targetNumber)
	if phone then
		local data = Persistence.getPhoneData(phone.item, phone.definition.id)
		SoundRegistry.applyDefaults(data, phone.definition)
		local fromLabel = fromNumber
		local contacts = Persistence.getContacts(phone.item, phone.definition.id)
		for i = 1, #contacts do
			local contact = contacts[i]
			if tostring(contact.number) == fromNumber then
				fromLabel = tostring(contact.name or fromNumber) .. " (" .. fromNumber .. ")"
				break
			end
		end
		data.notifications = data.notifications or {}
		table.insert(data.notifications, {
			kind = "message",
			fromNumber = fromNumber,
			title = tr("IncomingMessage"),
			text = fromLabel,
			unread = true,
		})
		PhoneUtils.playPhoneAlert(getPlayer(),
			data.notificationEvent or data.ringtoneEvent, data, true, "notification")
		PhoneUtils.toast(tr("PhoneMessageOn", tostring(phone.displayName or tr("UnknownPhone"))),
			tr("FromContactWithBody", fromLabel, body), "info", nil, 8)
	end
end)

Networking.on("PhoneMessageSent", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance and tostring(panel.instance.number) == tostring(args.fromNumber or "") then
		local app = panel.instance.os and panel.instance.os.currentApp
		if app and app.onPhoneMessageReceived then
			app:onPhoneMessageReceived(args.message)
		end
	end
end)

Networking.on("PhoneMessages", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance and tostring(panel.instance.number) == tostring(args.phoneNumber or "") then
		local app = panel.instance.os and panel.instance.os.currentApp
		if app and app.onPhoneMessages then
			app:onPhoneMessages(args)
		end
	end
end)

Networking.on("WorldGameScores", function(args)
	applyWorldScores(args.scores or {})
end)

Networking.on("PhoneRegistered", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance and args and args.number then
		panel.instance.number = Persistence.setPhoneNumber(panel.instance.item, args.number, panel.instance.definition
		.id)
	end
	if args and args.phoneKey and args.number then
		local phone = Service.findByKey(args.phoneKey)
		if phone then
			Persistence.setPhoneNumber(phone.item, args.number, phone.definition.id)
			phone.number = args.number
		end
	end
end)

Networking.on("OpenPhonesList", function(args)
	local panel = WorkingPhones.PhonePanel and WorkingPhones.PhonePanel.activePanel
	if panel and panel.instance and panel.instance.data then
		panel.instance.data.openPhonesCache = args.phones or {}
		local app = panel.instance.os and panel.instance.os.currentApp
		if app and app.onOpenPhonesList then
			app:onOpenPhonesList(panel.instance.data.openPhonesCache)
		end
	end
end)

Events.OnServerCommand.Add(onServerCommand)

return Networking
