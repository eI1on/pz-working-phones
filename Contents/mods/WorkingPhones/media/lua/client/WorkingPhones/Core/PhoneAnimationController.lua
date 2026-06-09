require "TimedActions/ISTimedActionQueue"

local ISPhoneUseAction = require("WorkingPhones/TimedActions/ISPhoneUseAction")
local AnimationRegistry = require("WorkingPhones/Registries/PhoneAnimationRegistry")

local PhoneAnimationController = {}
PhoneAnimationController.__index = PhoneAnimationController

local ACTIVE_CONTROLLERS = {}

local function removeActive(controller)
	for i = #ACTIVE_CONTROLLERS, 1, -1 do
		if ACTIVE_CONTROLLERS[i] == controller then
			table.remove(ACTIVE_CONTROLLERS, i)
			return
		end
	end
end

local function addActive(controller)
	for i = 1, #ACTIVE_CONTROLLERS do
		if ACTIVE_CONTROLLERS[i] == controller then
			return
		end
	end
	ACTIVE_CONTROLLERS[#ACTIVE_CONTROLLERS + 1] = controller
end

local function removeActiveForPlayer(playerObj)
	if not playerObj then
		return
	end
	for i = #ACTIVE_CONTROLLERS, 1, -1 do
		local controller = ACTIVE_CONTROLLERS[i]
		if controller and controller.playerObj == playerObj then
			controller:stopPhoneUseAction()
			table.remove(ACTIVE_CONTROLLERS, i)
		end
	end
end

local function inventoryContains(playerObj, item)
	if not item then
		return true
	end
	if not playerObj then
		return false
	end
	return playerObj:getInventory():contains(item, true)
end

local function setAction(playerObj, actionName)
	if not playerObj or not actionName then
		return
	end
	local sameAction = tostring(playerObj:getVariableString("PerformingAction") or "") == tostring(actionName or "")
	local performing = playerObj:getVariableBoolean("IsPerformingAnAction")
	if sameAction and performing then
		return
	end
	playerObj:setVariable("PerformingAction", actionName)
	playerObj:setVariable("IsPerformingAnAction", true)
end

local function actionMatchesProfile(actionName, profile)
	if actionName == "" then
		return true
	end
	if not profile or not profile.modes then
		return string.sub(actionName, 1, 5) == "Phone"
	end
	for modeId, mode in pairs(profile.modes) do
		if mode and (actionName == mode.start or actionName == mode.loop or actionName == mode.finish) then
			return true
		end
	end
	return false
end

local function isPhoneAction(playerObj, profile)
	if not playerObj then
		return false
	end
	local actionName = tostring(playerObj:getVariableString("PerformingAction") or "")
	return actionMatchesProfile(actionName, profile)
end

local function clearAction(playerObj, profile)
	if not isPhoneAction(playerObj, profile) then
		return
	end
	playerObj:clearVariable("PerformingAction")
	playerObj:clearVariable("IsPerformingAnAction")
	playerObj:setVariable("IsPerformingAnAction", false)
end

local function modeStage(profile, mode)
	return AnimationRegistry.mode(profile, mode)
end

local function normalizedMode(profile, mode)
	if AnimationRegistry.modeExists(profile, mode) then
		return mode
	end
	return profile.startMode or "idle"
end

local function startTicks(profile, stage)
	return tonumber(stage and stage.startTicks) or tonumber(profile.defaultStartTicks) or 22
end

local function finishTicks(profile, stage)
	return tonumber(stage and stage.finishTicks) or tonumber(profile.defaultFinishTicks) or 18
end

local function endTicks(profile, stage)
	return tonumber(stage and stage.endTicks) or tonumber(profile.defaultEndTicks) or 20
end

function PhoneAnimationController:new(playerObj, phoneItem, definition)
	removeActiveForPlayer(playerObj)
	local o = setmetatable({}, self)
	o.playerObj = playerObj
	o.phoneItem = phoneItem
	o.profile = AnimationRegistry.resolve(definition)
	o.phoneUseAction = nil
	o.mode = nil
	o.pendingLoop = nil
	o.pendingTicks = 0
	o.stopping = false
	addActive(o)
	local stage = modeStage(o.profile, o.profile.startMode)
	o:startPhoneUseAction(stage and (stage.start or stage.loop))
	return o
end

function PhoneAnimationController:startPhoneUseAction(actionName)
	if not self.playerObj or not self.phoneItem or not inventoryContains(self.playerObj, self.phoneItem) then
		return
	end
	if self.phoneUseAction and ISTimedActionQueue.hasAction(self.phoneUseAction) then
		self.phoneUseAction:applyPhoneAction(actionName)
		return
	end
	self.phoneUseAction = ISPhoneUseAction:new(self.playerObj, self.phoneItem, actionName, self.profile)
	ISTimedActionQueue.add(self.phoneUseAction)
end

function PhoneAnimationController:stopPhoneUseAction()
	if not self.phoneUseAction then
		return
	end
	if ISTimedActionQueue.hasAction(self.phoneUseAction) then
		if self.phoneUseAction.action then
			self.phoneUseAction:forceStop()
		else
			ISTimedActionQueue.getTimedActionQueue(self.playerObj):removeFromQueue(self.phoneUseAction)
		end
	end
	self.phoneUseAction = nil
end

function PhoneAnimationController:playStage(actionName, loopName, ticks)
	self:startPhoneUseAction(actionName)
	setAction(self.playerObj, actionName)
	self.pendingLoop = loopName
	self.pendingTicks = ticks or 0
	self.stopping = false
end

function PhoneAnimationController:setMode(mode)
	mode = normalizedMode(self.profile, mode)
	local stage = modeStage(self.profile, mode)
	if not self.stopping and (not self.phoneUseAction or not ISTimedActionQueue.hasAction(self.phoneUseAction)) then
		self:startPhoneUseAction(stage and stage.loop)
	end
	if self.stopping then
		self.mode = nil
	end
	if self.mode == mode and not self.stopping then
		local currentAction = tostring(self.playerObj and self.playerObj:getVariableString("PerformingAction") or "")
		if self.pendingTicks <= 0 and isPhoneAction(self.playerObj, self.profile) and currentAction == "" then
			if self.phoneUseAction then
				self.phoneUseAction:applyPhoneAction(stage and stage.loop)
			end
			setAction(self.playerObj, stage and stage.loop)
		end
		return
	end

	local previous = self.mode
	self.mode = mode
	local previousStage = previous and modeStage(self.profile, previous) or nil
	local startMode = self.profile.startMode or "idle"
	if previous and previous ~= mode and previous ~= startMode and previousStage and previousStage.finish then
		if mode == startMode then
			self:playStage(previousStage.finish, stage and stage.loop, finishTicks(self.profile, previousStage))
			self.nextLoopAfterStart = nil
			self.nextStartTicks = nil
		else
			self:playStage(previousStage.finish, stage and stage.start, finishTicks(self.profile, previousStage))
			self.nextLoopAfterStart = stage and stage.loop
			self.nextStartTicks = startTicks(self.profile, stage)
		end
		return
	end
	self.nextLoopAfterStart = nil
	self.nextStartTicks = nil
	if mode == startMode and previous then
		if self.phoneUseAction then
			self.phoneUseAction:applyPhoneAction(stage and stage.loop)
		end
		setAction(self.playerObj, stage and stage.loop)
		self.pendingLoop = nil
		self.pendingTicks = 0
		return
	end
	self:playStage(stage and stage.start, stage and stage.loop, startTicks(self.profile, stage))
end

function PhoneAnimationController:update()
	if self.pendingTicks <= 0 then
		return
	end
	self.pendingTicks = self.pendingTicks - 1
	if self.pendingTicks > 0 then
		return
	end

	if self.nextLoopAfterStart and self.pendingLoop then
		local startAction = self.pendingLoop
		local loopAction = self.nextLoopAfterStart
		local ticks = self.nextStartTicks or tonumber(self.profile.defaultStartTicks) or 22
		self.nextLoopAfterStart = nil
		self.nextStartTicks = nil
		self:playStage(startAction, loopAction, ticks)
		return
	end

	if self.stopping and self.pendingLoop then
		if self.phoneUseAction then
			self.phoneUseAction:applyPhoneAction(self.pendingLoop)
		end
		setAction(self.playerObj, self.pendingLoop)
		self.pendingLoop = nil
		self.pendingTicks = endTicks(self.profile, modeStage(self.profile, self.profile.stopMode))
		return
	end

	if self.stopping then
		self:stopPhoneUseAction()
		clearAction(self.playerObj, self.profile)
		removeActive(self)
		return
	end

	if self.pendingLoop then
		if self.phoneUseAction then
			self.phoneUseAction:applyPhoneAction(self.pendingLoop)
		end
		setAction(self.playerObj, self.pendingLoop)
		self.pendingLoop = nil
	end
end

function PhoneAnimationController:stop()
	if self.stopping then
		return
	end
	local finishingStage = self.mode and modeStage(self.profile, self.mode) or nil
	local stopStage = modeStage(self.profile, self.profile.stopMode)
	self.mode = nil
	self.nextLoopAfterStart = nil
	self.nextStartTicks = nil
	self.stopping = true
	if finishingStage and finishingStage.finish and stopStage and finishingStage.finish ~= stopStage.finish then
		if self.phoneUseAction then
			self.phoneUseAction:applyPhoneAction(finishingStage.finish)
		end
		setAction(self.playerObj, finishingStage.finish)
		self.pendingLoop = stopStage.finish
		self.pendingTicks = finishTicks(self.profile, finishingStage)
	else
		if self.phoneUseAction then
			self.phoneUseAction:applyPhoneAction(stopStage and stopStage.finish)
		end
		setAction(self.playerObj, stopStage and stopStage.finish)
		self.pendingLoop = nil
		self.pendingTicks = endTicks(self.profile, stopStage)
	end
	addActive(self)
end

local function onTick()
	for i = #ACTIVE_CONTROLLERS, 1, -1 do
		local controller = ACTIVE_CONTROLLERS[i]
		if controller then
			controller:update()
		else
			table.remove(ACTIVE_CONTROLLERS, i)
		end
	end
end

Events.OnTick.Add(onTick)

return PhoneAnimationController
