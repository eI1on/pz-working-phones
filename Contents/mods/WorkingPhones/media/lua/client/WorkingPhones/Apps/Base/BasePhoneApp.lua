local BasePhoneApp = {}
BasePhoneApp.__index = BasePhoneApp
local I18N = require("WorkingPhones/Core/PhoneI18N")

function BasePhoneApp:new(phoneOS)
	local o = setmetatable({}, self)
	o.os = phoneOS
	o.id = "base"
	o.name = I18N.get("App")
	return o
end

function BasePhoneApp:handleInput(event)
	if event.action == "BACK" or event.action == "RIGHT_SOFT" then
		return self.os:back()
	elseif event.action == "LEFT_SOFT" then
		self.os:menu()
		return true
	end
	return false
end

function BasePhoneApp:render(display)
	display:clear()
	display:drawHeader(self.name)
	display:drawText(I18N.get("Scaffold"), display.x + 10, display.y + 36, display.colors.fg)
	display:drawFooter(I18N.get("Menu"), I18N.get("Back"))
end

return BasePhoneApp
