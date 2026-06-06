-- Template only. Copy this file into your own mod before editing it.
--
-- Suggested location in your addon:
--   media/lua/client/MyPhoneAddon/Apps/Games/MyGameApp.lua
--
-- Games are normal apps with extra metadata:
--   game = true
--   showInGamesHub = true
--   gameOrder = number
--
-- Scores should be submitted through PhoneNetworking. The server stores the
-- world top scores; the phone item may keep only tiny per-phone score state if
-- the game needs it for display.

local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local Networking = require("WorkingPhones/Core/PhoneNetworking")
local I18N = require("WorkingPhones/Core/PhoneI18N")

local App = setmetatable({}, { __index = Base })
App.__index = App

local MENU_ROWS = { "New Game", "High Scores" }

local function playerName(os)
	local player = os.instance and os.instance.playerObj
	if player and player.getDisplayName then
		local name = player:getDisplayName()
		if name and name ~= "" then return tostring(name) end
	end
	if player and player.getUsername then
		local name = player:getUsername()
		if name and name ~= "" then return tostring(name) end
	end
	return I18N.get("Player")
end

local function worldScores(gameId, os)
	local scores = WorkingPhones and WorkingPhones.WorldGameScores or nil
	if scores and scores[gameId] then return scores[gameId] end
	return os.instance.data.worldGameScores and os.instance.data.worldGameScores[gameId] or {}
end

function App:new(os)
	local o = Base.new(self, os)
	o.id = "my_mod_game"
	o.name = "My Game"
	o.mode = "menu"
	o.selected = 1
	o.score = 0
	o.running = false
	Networking.requestWorldGameScores()
	return o
end

function App:startGame()
	self.mode = "play"
	self.score = 0
	self.running = true
end

function App:finishGame()
	if not self.running then return end
	self.running = false
	if (tonumber(self.score) or 0) > 0 then
		Networking.submitGameScore(self.id, self.score, playerName(self.os), self.os.instance.number)
	end
end

function App:onClose()
	self:finishGame()
end

function App:renderMenu(display)
	display:clear()
	display:drawHeader(self.name)
	for i = 1, #MENU_ROWS do
		local y = display.contentY + (i - 1) * 24
		local selected = i == self.selected
		if selected then
			display:fillRect(display.x + 6, y - 2, display.width - 12, 20, display.colors.accent)
		end
		display:drawText(MENU_ROWS[i], display.x + 10, y, selected and display.colors.bg or display.colors.fg)
	end
	display:drawFooter("Select", "Back")
end

function App:renderScores(display)
	display:clear()
	display:drawHeader("High Scores")
	local scores = worldScores(self.id, self.os)
	if #scores == 0 then
		display:drawText(I18N.get("NoScores"), display.x + 10, display.contentY, display.colors.dim)
	else
		for i = 1, math.min(#scores, 10) do
			local row = scores[i]
			local y = display.contentY + (i - 1) * 18
			display:drawText(tostring(i) .. ". " .. tostring(row.name or "?"), display.x + 10, y, display.colors.fg)
			display:drawTextRight(tostring(row.score or 0), display.x + display.width - 10, y, display.colors.fg)
		end
	end
	display:drawFooter("New", "Back")
end

function App:renderPlay(display)
	display:clear()
	display:drawHeader(self.name)
	display:drawText("Score: " .. tostring(self.score), display.x + 10, display.contentY, display.colors.fg)
	display:drawText("Replace this with your game board.", display.x + 10, display.contentY + 22, display.colors.dim)
	display:drawFooter("End", "Back")
end

function App:render(display)
	if self.mode == "scores" then return self:renderScores(display) end
	if self.mode == "play" then return self:renderPlay(display) end
	return self:renderMenu(display)
end

function App:onMouseDown(x, y, display)
	if self.mode ~= "menu" then return false end
	for i = 1, #MENU_ROWS do
		local rowY = display.contentY + (i - 1) * 24
		if y >= rowY - 2 and y <= rowY + 20 then
			self.selected = i
			return self:handleInput({ action = "SELECT" })
		end
	end
	return false
end

function App:handleInput(event)
	if self.mode == "menu" then
		if event.action == "UP" then
			self.selected = math.max(1, self.selected - 1)
			return true
		elseif event.action == "DOWN" then
			self.selected = math.min(#MENU_ROWS, self.selected + 1)
			return true
		elseif event.action == "SELECT" then
			if self.selected == 1 then self:startGame() else self.mode = "scores" end
			return true
		elseif event.action == "BACK" then
			return self.os:back()
		end
	elseif self.mode == "scores" then
		if event.action == "MENU" then
			self:startGame()
			return true
		elseif event.action == "BACK" then
			self.mode = "menu"
			return true
		end
	elseif self.mode == "play" then
		if event.action == "MENU" then
			self:finishGame()
			self.mode = "menu"
			return true
		elseif event.action == "BACK" then
			self:finishGame()
			self.mode = "menu"
			return true
		elseif event.action == "SELECT" then
			self.score = self.score + 1
			return true
		end
	end
	return false
end

-- Registration example. Put this in your addon's client registration file.
--[[
local AppRegistry = require("WorkingPhones/Core/PhoneAppRegistry")
local MyGame = require("MyPhoneAddon/Apps/Games/MyGameApp")

AppRegistry.register("my_mod_game", MyGame, {
	name = "My Game",
	nameKey = "App_my_mod_game",
	smartphoneIcon = "media/ui/MyPhoneAddon/games/my_mod_game.png",
	game = true,
	showInGamesHub = true,
	gameOrder = 100,
	autoInstall = true,
	hardwareTypes = { "smartphone" },
})
]]

return App
