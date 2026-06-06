local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local Networking = require("WorkingPhones/Core/PhoneNetworking")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local App = setmetatable({}, { __index = Base })
App.__index = App

local MENU_ROWS = { "NewGame", "HighScores" }

local function worldScores(os)
	local scores = WorkingPhones and WorkingPhones.WorldGameScores or nil
	if scores and scores.snake then return scores.snake end
	return os.instance.data.worldGameScores and os.instance.data.worldGameScores.snake or {}
end

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

function App:new(os)
	local o = Base.new(self, os)
	o.id = "snake"
	o.name = I18N.app("snake")
	o.dir = { x = 1, y = 0 }
	o.pending = { x = 1, y = 0 }
	o.snake = {}
	o.food = { x = 5, y = 5 }
	o.score = 0
	o.highScore = (os.instance.data.gameScores and os.instance.data.gameScores.snake and os.instance.data.gameScores.snake.score) or 0
	o.gridW = 14
	o.gridH = 10
	o.elapsed = 0
	o.delay = 180
	o.gameOver = false
	o.paused = false
	o.mode = "menu"
	o.menuIndex = 1
	o:reset()
	o.paused = true
	Networking.requestWorldGameScores()
	return o
end

function App:onClose()
	self:saveHighScore()
end

function App:saveHighScore()
	if (tonumber(self.score) or 0) <= 0 then return end
	self.os.instance.data.gameScores = self.os.instance.data.gameScores or {}
	local name = playerName(self.os)
	if self.score > ((self.os.instance.data.gameScores.snake and self.os.instance.data.gameScores.snake.score) or 0) then
		self.os.instance.data.gameScores.snake = { score = self.score, name = name }
		self.highScore = self.score
	end
	Networking.submitGameScore("snake", self.score, name, self.os.instance.number)
end

function App:reset()
	self.snake = { { x = 5, y = 5 }, { x = 4, y = 5 }, { x = 3, y = 5 } }
	self.dir = { x = 1, y = 0 }
	self.pending = { x = 1, y = 0 }
	self.score = 0
	self.gameOver = false
	self.paused = false
	self:spawnFood()
end

function App:spawnFood()
	local gw, gh = self.gridW or 14, self.gridH or 10
	self.food = { x = ZombRand(0, gw), y = ZombRand(0, gh) }
end

function App:startGame()
	self:reset()
	self.mode = "play"
end

function App:handleInput(event)
	if self.mode == "menu" or self.mode == "scores" then
		if self.mode == "scores" and (event.action == "RIGHT_SOFT" or event.action == "BACK" or event.action == "LEFT_SOFT") then
			self.mode = "menu"
			return true
		end
		if event.action == "UP" then self.menuIndex = math.max(1, self.menuIndex - 1); return true end
		if event.action == "DOWN" then self.menuIndex = math.min(#MENU_ROWS, self.menuIndex + 1); return true end
		if event.action == "MOUSE_DOWN" and event.displayY then
			local row = math.floor((event.displayY - (self.menuTop or 82)) / 30) + 1
			if MENU_ROWS[row] then
				self.menuIndex = row
				if MENU_ROWS[self.menuIndex] == "NewGame" then self:startGame() else self.mode = "scores" end
				return true
			end
		end
		if event.action == "OK" or event.action == "LEFT_SOFT" then
			if MENU_ROWS[self.menuIndex] == "NewGame" then self:startGame() else self.mode = "scores" end
			return true
		end
		return Base.handleInput(self, event)
	end
	if (event.action == "OK" or event.action == "LEFT_SOFT") and self.gameOver then
		self:startGame()
		return true
	elseif event.action == "LEFT_SOFT" then
		self.paused = not self.paused
		return true
	elseif event.action == "RIGHT_SOFT" or event.action == "BACK" then
		self:saveHighScore()
		self.mode = "menu"
		self.paused = true
		return true
	elseif event.action == "UP" and self.dir.y ~= 1 then
		self.pending = { x = 0, y = -1 }
		return true
	elseif event.action == "DOWN" and self.dir.y ~= -1 then
		self.pending = { x = 0, y = 1 }
		return true
	elseif event.action == "LEFT" and self.dir.x ~= 1 then
		self.pending = { x = -1, y = 0 }
		return true
	elseif event.action == "RIGHT" and self.dir.x ~= -1 then
		self.pending = { x = 1, y = 0 }
		return true
	end
	return Base.handleInput(self, event)
end

function App:update(deltaTime)
	if self.mode ~= "play" then
		return
	end
	if self.gameOver or self.paused then
		return
	end
	self.elapsed = self.elapsed + deltaTime
	if self.elapsed < self.delay then
		return
	end
	self.elapsed = 0
	self.dir = self.pending
	local head = self.snake[1]
	local gw, gh = self.gridW or 14, self.gridH or 10
	local nextHead = { x = head.x + self.dir.x, y = head.y + self.dir.y }
	if nextHead.x < 0 or nextHead.x >= gw or nextHead.y < 0 or nextHead.y >= gh then
		self.gameOver = true
		self:saveHighScore()
		return
	end
	for i = 1, #self.snake do
		local segment = self.snake[i]
		if segment.x == nextHead.x and segment.y == nextHead.y then
			self.gameOver = true
			self:saveHighScore()
			return
		end
	end
	table.insert(self.snake, 1, nextHead)
	if nextHead.x == self.food.x and nextHead.y == self.food.y then
		self.score = self.score + 10
		self:spawnFood()
	else
		table.remove(self.snake)
	end
end

function App:pauseForNotification()
	self.paused = true
end

function App:render(display)
	if self.mode == "menu" then
		display:clear()
		display:drawText(I18N.app("snake"), display.x + 16, display.y + 34, display.colors.fg, UIFont.Medium)
		display:drawText(I18N.get("GameMenuHint"), display.x + 16, display.y + 58, display.colors.dim)
		self.menuTop = 82
		for i = 1, #MENU_ROWS do
			local y = display.y + self.menuTop + (i - 1) * 30
			local selected = i == self.menuIndex
			display:fillRect(display.x + 12, y - 3, display.width - 24, 26,
				selected and display.colors.accent or display.colors.bg)
			display:drawBorder(display.x + 12, y - 3, display.width - 24, 26,
				selected and display.colors.fg or display.colors.border)
			display:drawText(I18N.get(MENU_ROWS[i]), display.x + 20, y + 3,
				selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.fg)
		end
		display:drawFooter(I18N.get("Select"), I18N.get("Back"))
		return
	elseif self.mode == "scores" then
		display:clear()
		display:drawHeader(I18N.get("HighScores"))
		local world = worldScores(self.os)
		for i = 1, math.min(#world, 6) do
			local row = world[i]
			display:drawText(display:ellipsize(tostring(i) .. ". " .. tostring(row.name or I18N.get("Player")), display.width - 60),
				display.x + 12, display.contentY + (i - 1) * 18, display.colors.fg)
			display:drawTextRight(tostring(row.score or 0), display.contentRight - 2, display.contentY + (i - 1) * 18, display.colors.dim)
		end
		if #world == 0 then display:drawText(I18N.get("NoScores"), display.x + 12, display.contentY, display.colors.dim) end
		display:drawFooter(I18N.get("Menu"), I18N.get("Back"))
		return
	end
	display:clear()
	local world = worldScores(self.os)[1]
	local worldScore = world and world.score or 0
	display:drawHeader(I18N.app("snake"))
	display:drawText(I18N.get("ScoreHighLabel", tostring(self.score), tostring(self.highScore)), display.x + 8, display.contentY, display.colors.fg)
	display:drawText(I18N.get("WorldScoreLabel", tostring(worldScore)), display.x + 8, display.contentY + 12, display.colors.dim)
	local top = display.contentY + 28
	local availH = display.contentBottom - top - 2
	local availW = display.width - 20
	local cell = math.floor(math.min(availW / 14, availH / 10))
	local ox = display.x + math.floor((display.width - cell * self.gridW) / 2)
	local oy = top
	display:drawBorder(ox - 1, oy - 1, cell * self.gridW + 2, cell * self.gridH + 2, display.colors.fg)
	local smart = self.os.definition.hardwareType == "smartphone"
	display:fillRect(ox + self.food.x * cell + 1, oy + self.food.y * cell + 1, cell - 2, cell - 2,
		smart and { r = 1, g = 0.24, b = 0.22, a = 1 } or display.colors.accent)
	for i = 1, #self.snake do
		local segment = self.snake[i]
		local pad = i == 1 and 0 or 1
		local color = smart and (i == 1 and { r = 0.14, g = 0.72, b = 0.32, a = 1 } or { r = 0.26, g = 0.86, b = 0.45, a = 1 }) or display.colors.fg
		display:fillRect(ox + segment.x * cell + pad, oy + segment.y * cell + pad, cell - pad * 2, cell - pad * 2, color)
	end
	if self.gameOver or self.paused then
		display:drawTextCentered(self.gameOver and I18N.get("GameOver") or I18N.get("Paused"), oy + math.floor((cell * self.gridH) / 2) - 6, display.colors.fg)
	end
	display:drawFooter(self.gameOver and I18N.get("Retry") or (self.paused and I18N.get("Resume") or I18N.get("Pause")), I18N.get("Back"))
end

return App
