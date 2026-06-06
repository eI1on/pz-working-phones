local PhoneHardware = {}
PhoneHardware.__index = PhoneHardware

function PhoneHardware:new(profile)
	local o = setmetatable({}, self)
	o.profile = profile or {}
	o.powered = o.profile.startsPowered ~= false
	o.battery = o.profile.battery or 1.0
	o.monochrome = o.profile.displayMode == "monochrome"
	o.touch = o.profile.touch == true
	return o
end

function PhoneHardware:isPowered()
	return self.powered
end

function PhoneHardware:togglePower()
	self.powered = not self.powered
end

function PhoneHardware:update(deltaTime)
	if self.powered and self.profile.batteryDrain then
		self.battery = math.max(0, self.battery - self.profile.batteryDrain * (deltaTime / 1000))
		if self.battery <= 0 then
			self.powered = false
		end
	end
end

return PhoneHardware
