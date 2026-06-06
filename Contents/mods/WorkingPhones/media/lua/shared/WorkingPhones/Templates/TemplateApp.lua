-- Template only. Copy this file into your own mod before editing it.
--
-- Suggested location in your addon:
--   media/lua/client/MyPhoneAddon/Apps/MyApp.lua
--
-- Registration location in your addon:
--   media/lua/client/MyPhoneAddon/RegisterApps.lua
--
-- Working Phones loads apps from the client side because apps render UI and receive
-- player input. The template lives in shared so all examples are easy to find, but
-- your actual app class should normally be in your mod's client Lua folder.

local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local I18N = require("WorkingPhones/Core/PhoneI18N")

local App = setmetatable({}, { __index = Base })
App.__index = App

function App:new(os)
	local o = Base.new(self, os)
	o.id = "my_mod_app"
	o.name = "My App"
	o.selected = 1
	o.rows = {
		{ label = "First row", value = "Use arrow keys, controller d-pad, or mouse." },
		{ label = "Second row", value = "Return/Select activates the selected row." },
	}
	return o
end

function App:onOpen()
	-- Called when the app becomes active.
	-- Good place to refresh phone data or request server state.
end

function App:onClose()
	-- Called when the app is closed or another app replaces it.
	-- Good place to stop previews, save small phone-local settings, etc.
end

function App:activateSelected()
	local row = self.rows[self.selected]
	if not row then return false end
	-- Replace this with your app action.
	return true
end

function App:render(display)
	display:clear()
	display:drawHeader(self.name)

	local top, visibleRows, contentRight, hasScrollbar = display:getVisibleListMetrics(22, #self.rows)
	local offset = math.max(0, math.min(self.selected - visibleRows, math.max(0, #self.rows - visibleRows)))
	for i = offset + 1, math.min(#self.rows, offset + visibleRows) do
		local row = self.rows[i]
		local y = top + (i - offset - 1) * 22
		local selected = i == self.selected
		if selected then
			display:fillRect(display.x + 4, y - 2, contentRight - display.x - 6, 20, display.colors.accent)
		end
		local color = selected and display.colors.bg or display.colors.fg
		display:drawText(display:ellipsize(row.label, contentRight - display.x - 12), display.x + 8, y, color)
	end
	if hasScrollbar then
		display:drawScrollbar(#self.rows, visibleRows, offset, top, display.contentBottom)
	end

	display:drawFooter("Select", "Back")
end

function App:onMouseDown(x, y, display)
	local top, visibleRows, contentRight = display:getVisibleListMetrics(22, #self.rows)
	if x < display.x or x > contentRight or y < top or y > display.contentBottom then
		return false
	end
	local offset = math.max(0, math.min(self.selected - visibleRows, math.max(0, #self.rows - visibleRows)))
	local rowIndex = offset + math.floor((y - top) / 22) + 1
	if rowIndex >= 1 and rowIndex <= #self.rows then
		self.selected = rowIndex
		return self:activateSelected()
	end
	return false
end

function App:handleInput(event)
	if event.action == "UP" then
		self.selected = math.max(1, self.selected - 1)
		return true
	elseif event.action == "DOWN" then
		self.selected = math.min(#self.rows, self.selected + 1)
		return true
	elseif event.action == "SELECT" then
		return self:activateSelected()
	elseif event.action == "BACK" then
		return self.os:back()
	end
	return false
end

-- Registration example. Put this in your addon's client registration file.
--[[
local AppRegistry = require("WorkingPhones/Core/PhoneAppRegistry")
local MyApp = require("MyPhoneAddon/Apps/MyApp")

AppRegistry.register("my_mod_app", MyApp, {
	name = "My App",
	nameKey = "App_my_mod_app",
	smartphoneIcon = "media/ui/MyPhoneAddon/smartphone/my_mod_app.png",
	autoInstall = true,
	hardwareTypes = { "classic", "smartphone" },
	phones = { "classic_2110", "generic_smartphone" },
	excludePhones = {},
})
]]

-- Translation example for media/lua/shared/Translate/EN/IG_UI_EN.txt:
-- IGUI_EN = {
--   IGUI_WorkingPhones_App_my_mod_app = "My App",
-- }

return App
