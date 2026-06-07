local Service = require("WorkingPhones/Core/PhoneInventoryService")
local Common = require("WorkingPhones/Common/PhoneCommon")
local Persistence = require("WorkingPhones/Core/PhonePersistence")
require("TimedActions/ISInventoryTransferAction")

local VoiceBridge = {
	active = nil,
}

local PROXY_ITEM_TYPE = "WorkingPhones.PhoneVoiceProxy"

local function isProxyItem(item)
	return item and item.getFullType and item:getFullType() == PROXY_ITEM_TYPE
end

local function installTransferGuard()
	if VoiceBridge.transferGuardInstalled then return end
	if not ISInventoryTransferAction or not ISInventoryTransferAction.isValid then return end
	if ISInventoryTransferAction.WorkingPhonesVoiceProxyGuard then
		VoiceBridge.transferGuardInstalled = true
		return
	end

	local originalIsValid = ISInventoryTransferAction.isValid
	function ISInventoryTransferAction:isValid()
		if isProxyItem(self.item) then return false end
		return originalIsValid(self)
	end

	ISInventoryTransferAction.WorkingPhonesVoiceProxyGuard = true
	VoiceBridge.transferGuardInstalled = true
end

local function rootInventory()
	local player = getPlayer()
	return player and player.getInventory and player:getInventory() or nil
end

local function itemContainer(item)
	return item and item.getContainer and item:getContainer() or nil
end

local function deviceDataFor(item)
	if item and item.getDeviceData then
		return item:getDeviceData()
	end
	return nil
end

local function readState(deviceData)
	local noTransmit = true
	if deviceData.isNoTransmit then
		noTransmit = deviceData:isNoTransmit()
	end
	return {
		channel = deviceData:getChannel(),
		turnedOn = deviceData:getIsTurnedOn(),
		micMuted = deviceData:getMicIsMuted(),
		volume = deviceData:getDeviceVolume(),
		noTransmit = noTransmit,
	}
end

local function writeState(deviceData, state)
	if not deviceData or not state then return end
	if deviceData.setNoTransmit then deviceData:setNoTransmit(state.noTransmit ~= false) end
	deviceData:setMicIsMuted(state.micMuted == true)
	deviceData:setDeviceVolume(tonumber(state.volume) or 0.0)
	deviceData:setChannel(tonumber(state.channel) or deviceData:getChannel())
	deviceData:setIsTurnedOn(state.turnedOn == true)
end

local function phoneVolume(data)
	return Common.clamp01(data and data.volume, 0.75)
end

local function configureDevice(deviceData, channel, data)
	deviceData:setIsTwoWay(true)
	deviceData:setTransmitRange(1000000)
	deviceData:setMicRange(5)
	deviceData:setBaseVolumeRange(10)
	deviceData:setDeviceVolume(phoneVolume(data))
	deviceData:setPower(1.0)
	if deviceData.setNoTransmit then deviceData:setNoTransmit(false) end
	deviceData:setMicIsMuted(false)
	deviceData:setChannel(tonumber(channel) or 88000)
	deviceData:setIsTurnedOn(true)
end

local function removeItem(container, item)
	if container and item and container.Remove then
		container:Remove(item)
	end
end

local function removeStaleProxies(container)
	if not container or not container.getItems then return end
	local items = container:getItems()
	for i = items:size() - 1, 0, -1 do
		local item = items:get(i)
		if isProxyItem(item) then
			removeItem(container, item)
		end
	end
end

local function createProxy()
	local container = rootInventory()
	if not container or not container.AddItem then return nil end
	removeStaleProxies(container)
	local item = container:AddItem(PROXY_ITEM_TYPE)
	if item and item.getModData then
		item:getModData().WorkingPhonesVoiceProxy = true
	end
	if item and item.setFavorite then
		item:setFavorite(true)
	end
	return item
end

function VoiceBridge.start(args)
	args = args or {}
	local channel = tonumber(args.voiceChannel)
	local phoneNumber = tostring(args.phoneNumber or args.targetNumber or args.fromNumber or "")
	if not channel or phoneNumber == "" then return false end
	VoiceBridge.stop()

	Service.scan(getPlayer(), true)
	local phone = Service.findByNumber(phoneNumber)
	if not phone then return false end
	local proxy = createProxy()
	local proxyContainer = rootInventory()
	local deviceData = deviceDataFor(proxy)
	if not deviceData then
		removeItem(proxyContainer, proxy)
		return false
	end
	local data = args.data or Persistence.getPhoneData(phone.item, phone.definition.id)

	VoiceBridge.active = {
		callId = tostring(args.callId or ""),
		phoneNumber = phoneNumber,
		phoneKey = phone.phoneKey,
		phoneItem = phone.item,
		item = proxy,
		deviceData = deviceData,
		voiceChannel = channel,
		data = data,
		previous = readState(deviceData),
		proxyContainer = proxyContainer,
	}
	configureDevice(deviceData, channel, data)
	return true
end

function VoiceBridge.stop(callId)
	local active = VoiceBridge.active
	if not active then return end
	if callId and tostring(callId) ~= "" and tostring(callId) ~= tostring(active.callId or "") then return end
	local phoneNumber = active.phoneNumber
	writeState(active.deviceData, active.previous)
	removeItem(itemContainer(active.item) or active.proxyContainer or rootInventory(), active.item)
	VoiceBridge.active = nil
	return phoneNumber
end

function VoiceBridge.stopForPhoneNumber(number)
	local active = VoiceBridge.active
	if active and tostring(active.phoneNumber or "") == tostring(number or "") then
		VoiceBridge.stop(active.callId)
	end
end

function VoiceBridge.refreshVolume(data)
	local active = VoiceBridge.active
	if active and active.deviceData then
		active.data = data or active.data
		active.deviceData:setDeviceVolume(phoneVolume(data))
	end
end

function VoiceBridge.update()
	local active = VoiceBridge.active
	if not active or not active.item then return end

	local root = rootInventory()
	if not root then return end
	if itemContainer(active.item) == root then return end

	removeItem(itemContainer(active.item), active.item)
	local proxy = createProxy()
	local deviceData = deviceDataFor(proxy)
	if not deviceData then
		removeItem(root, proxy)
		VoiceBridge.active = nil
		return
	end

	active.item = proxy
	active.deviceData = deviceData
	active.previous = readState(deviceData)
	active.proxyContainer = root
	configureDevice(deviceData, active.voiceChannel, active.data)
end

function VoiceBridge.isActive(callId)
	local active = VoiceBridge.active
	if not active then return false end
	return not callId or tostring(callId) == tostring(active.callId or "")
end

installTransferGuard()

Events.OnCreatePlayer.Add(function()
	VoiceBridge.stop()
	removeStaleProxies(rootInventory())
end)

Events.OnTick.Add(VoiceBridge.update)

return VoiceBridge
