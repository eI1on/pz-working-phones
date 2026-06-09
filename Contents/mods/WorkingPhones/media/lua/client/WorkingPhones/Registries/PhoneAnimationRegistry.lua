require("WorkingPhones/Core/WorkingPhonesGlobals")

local AnimationRegistry = {
	profiles = {},
	defaultProfileId = "default_phone_side",
}

local DEFAULT_PROFILE = {
	id = "default_phone_side",
	startMode = "idle",
	stopMode = "idle",
	phonePropSlot = "secondary",
	-- phonePropModel = "CordlessPhone",
	defaultStartTicks = 22,
	defaultFinishTicks = 18,
	defaultEndTicks = 20,
	modes = {
		idle = {
			start = "PhonePull",
			loop = "PhonePullLoop",
			finish = "PhoneEnd",
		},
		text = {
			start = "PhoneTextStart",
			loop = "PhoneTextLoop",
			finish = "PhoneTextEnd",
		},
		call = {
			start = "PhoneCallStart",
			loop = "PhoneCallLoop",
			finish = "PhoneCallEnd",
		},
	},
}

local function copyMode(mode)
	if type(mode) ~= "table" then
		return nil
	end
	return {
		start = mode.start,
		loop = mode.loop,
		finish = mode.finish,
		startTicks = tonumber(mode.startTicks),
		finishTicks = tonumber(mode.finishTicks),
		endTicks = tonumber(mode.endTicks),
	}
end

local function copyProfile(profile)
	local source = profile or DEFAULT_PROFILE
	local copy = {
		id = source.id or AnimationRegistry.defaultProfileId,
		startMode = source.startMode or DEFAULT_PROFILE.startMode,
		stopMode = source.stopMode or DEFAULT_PROFILE.stopMode,
		phonePropSlot = source.phonePropSlot or DEFAULT_PROFILE.phonePropSlot,
		phonePropModel = source.phonePropModel or DEFAULT_PROFILE.phonePropModel,
		defaultStartTicks = tonumber(source.defaultStartTicks) or DEFAULT_PROFILE.defaultStartTicks,
		defaultFinishTicks = tonumber(source.defaultFinishTicks) or DEFAULT_PROFILE.defaultFinishTicks,
		defaultEndTicks = tonumber(source.defaultEndTicks) or DEFAULT_PROFILE.defaultEndTicks,
		modes = {},
	}
	copy.modes.idle = copyMode(source.modes and source.modes.idle) or copyMode(DEFAULT_PROFILE.modes.idle)
	copy.modes.text = copyMode(source.modes and source.modes.text) or copyMode(DEFAULT_PROFILE.modes.text)
	copy.modes.call = copyMode(source.modes and source.modes.call) or copyMode(DEFAULT_PROFILE.modes.call)
	if source.modes then
		for modeId, mode in pairs(source.modes) do
			if not copy.modes[modeId] then
				copy.modes[modeId] = copyMode(mode)
			end
		end
	end
	return copy
end

function AnimationRegistry.registerProfile(id, profile)
	if type(id) ~= "string" or id == "" then
		return nil
	end
	local copy = copyProfile(profile)
	copy.id = id
	AnimationRegistry.profiles[id] = copy
	return copy
end

function AnimationRegistry.getProfile(id)
	return AnimationRegistry.profiles[id or AnimationRegistry.defaultProfileId] or
	AnimationRegistry.profiles[AnimationRegistry.defaultProfileId]
end

function AnimationRegistry.resolve(definition)
	local animationProfile = definition and definition.animationProfile or nil
	if type(animationProfile) == "table" then
		return copyProfile(animationProfile)
	end
	return AnimationRegistry.getProfile(animationProfile)
end

function AnimationRegistry.mode(profile, modeId)
	local resolvedProfile = profile or AnimationRegistry.getProfile()
	return resolvedProfile.modes[modeId] or resolvedProfile.modes[resolvedProfile.startMode] or
	resolvedProfile.modes.idle
end

function AnimationRegistry.modeExists(profile, modeId)
	local resolvedProfile = profile or AnimationRegistry.getProfile()
	return resolvedProfile.modes[modeId] ~= nil
end

AnimationRegistry.registerProfile(DEFAULT_PROFILE.id, DEFAULT_PROFILE)

WorkingPhones = WorkingPhones or {}
WorkingPhones.PhoneAnimationRegistry = AnimationRegistry

return AnimationRegistry
