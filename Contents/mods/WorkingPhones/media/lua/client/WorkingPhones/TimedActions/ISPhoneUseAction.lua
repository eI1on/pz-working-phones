require "TimedActions/ISBaseTimedAction"

local ISPhoneUseAction = ISBaseTimedAction:derive("WorkingPhones_ISPhoneUseAction")

local function inventoryContains(character, item)
	if not character or not item then
		return false
	end
	return character:getInventory():contains(item, true)
end

local function phoneHandModel(item, profile)
	if profile and profile.phonePropModel and profile.phonePropModel ~= "" then
		return profile.phonePropModel
	end
	if item and item.getStaticModel then
		local model = item:getStaticModel()
		if model and model ~= "" then
			return model
		end
	end
	return "CordlessPhone"
end

local function phoneHandModels(item, profile)
	local model = phoneHandModel(item, profile)
	if profile and profile.phonePropSlot == "primary" then
		return model, nil
	end
	return nil, model
end

local function defaultPhoneAction(profile, preferStart)
	local startMode = profile and profile.startMode or "idle"
	local mode = profile and profile.modes and profile.modes[startMode] or nil
	if preferStart and mode and mode.start then
		return mode.start
	end
	if mode and mode.loop then
		return mode.loop
	end
	if mode and mode.start then
		return mode.start
	end
	return nil
end

function ISPhoneUseAction:isValid()
	return inventoryContains(self.character, self.item)
end

function ISPhoneUseAction:applyPhoneAction(actionName)
	self.phoneAction = actionName or self.phoneAction or defaultPhoneAction(self.animationProfile, false)
	if not self.action then
		return
	end
	if not self.phoneAction then
		return
	end
	self:setActionAnim(self.phoneAction)
	local primaryModel, secondaryModel = phoneHandModels(self.item, self.animationProfile)
	self:setOverrideHandModelsString(primaryModel, secondaryModel)
end

function ISPhoneUseAction:start()
	self.item:setJobDelta(0.0)
	self.item:setJobType(self.item:getName())
	self.action:setLoopedAction(true)
	self.action:setUseProgressBar(false)
	self.useProgressBar = false
	self:applyPhoneAction(self.phoneAction)
	self.character:reportEvent("EventAttachItem")
end

function ISPhoneUseAction:update()
	if self.item then
		self.item:setJobDelta(0.0)
	end
	if self.action then
		local primaryModel, secondaryModel = phoneHandModels(self.item, self.animationProfile)
		self:setOverrideHandModelsString(primaryModel, secondaryModel)
	end
end

function ISPhoneUseAction:stop()
	if self.item then
		self.item:setJobDelta(0.0)
	end
	ISBaseTimedAction.stop(self)
end

function ISPhoneUseAction:perform()
	if self.item then
		self.item:setJobDelta(0.0)
	end
	ISBaseTimedAction.perform(self)
end

function ISPhoneUseAction:new(character, item, actionName, animationProfile)
	local o = ISBaseTimedAction.new(self, character)
	o.item = item
	o.animationProfile = animationProfile
	o.phoneAction = actionName or defaultPhoneAction(animationProfile, true)
	o.stopOnWalk = false
	o.stopOnRun = false
	o.stopOnAim = false
	o.ignoreHandsWounds = true
	o.maxTime = -1
	o.useProgressBar = false
	return o
end

return ISPhoneUseAction
