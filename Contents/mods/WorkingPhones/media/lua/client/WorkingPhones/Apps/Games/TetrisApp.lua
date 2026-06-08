local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local Networking = require("WorkingPhones/Core/PhoneNetworking")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local App = setmetatable({}, { __index = Base })
App.__index = App

local MENU_ROWS = { "NewGame", "HighScores" }
local COLORS = {
	{ r = 0.1, g = 0.56, b = 0.95, a = 1 },
	{ r = 0.95, g = 0.34, b = 0.24, a = 1 },
	{ r = 0.24, g = 0.74, b = 0.38, a = 1 },
	{ r = 0.9, g = 0.72, b = 0.18, a = 1 },
	{ r = 0.58, g = 0.35, b = 0.92, a = 1 },
}

local function worldScores(os)
	local scores = WorkingPhones and WorkingPhones.WorldGameScores or nil
	if scores and scores.tetris then return scores.tetris end
	return os.instance.data.worldGameScores and os.instance.data.worldGameScores.tetris or {}
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

local SHAPES = {
	{ { 0, 0 },  { 1, 0 }, { 0, 1 }, { 1, 1 } },
	{ { -1, 0 }, { 0, 0 }, { 1, 0 }, { 2, 0 } },
	{ { -1, 0 }, { 0, 0 }, { 1, 0 }, { 1, 1 } },
	{ { -1, 1 }, { 0, 1 }, { 0, 0 }, { 1, 0 } },
	{ { -1, 0 }, { 0, 0 }, { 0, 1 }, { 1, 1 } },
	{ { -1, 0 }, { 0, 0 }, { 1, 0 }, { 0, 1 } },
}

function App:new(os)
	local o = Base.new(self, os)
	o.id = "tetris"
	o.name = I18N.app("tetris")
	o.w, o.h = 10, 16
	o.board = {}
	o.elapsed = 0
	o.delay = 650
	o.score = 0
	o.highScore = (os.instance.data.gameScores and os.instance.data.gameScores.tetris and os.instance.data.gameScores.tetris.score) or
	0
	o.gameOver = false
	o.paused = false
	o.mode = "menu"
	o.menuIndex = 1
	o.nextShape = SHAPES[ZombRand(1, #SHAPES + 1)]
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
	if self.score > ((self.os.instance.data.gameScores.tetris and self.os.instance.data.gameScores.tetris.score) or 0) then
		self.os.instance.data.gameScores.tetris = { score = self.score, name = name }
		self.highScore = self.score
	end
	Networking.submitGameScore("tetris", self.score, name, self.os.instance.number)
end

function App:reset()
	self.board = {}
	for y = 1, self.h do self.board[y] = {} end
	self.score = 0
	self.gameOver = false
	self.paused = false
	self:spawn()
end

function App:startGame()
	self:reset()
	self.mode = "play"
end

function App:spawn()
	self.piece = { shape = self.nextShape or SHAPES[1], x = 5, y = 1, r = 0 }
	self.nextShape = SHAPES[ZombRand(1, #SHAPES + 1)]
	if self:collides(self.piece.x, self.piece.y, self.piece.shape) then
		self.gameOver = true; self:saveHighScore()
	end
end

function App:rotated(shape)
	local out = {}
	for i = 1, #shape do
		local c = shape[i]
		table.insert(out, { -c[2], c[1] })
	end
	return out
end

function App:collides(px, py, shape)
	for i = 1, #shape do
		local c = shape[i]
		local x, y = px + c[1], py + c[2]
		if x < 1 or x > self.w or y > self.h then return true end
		if y >= 1 and self.board[y][x] then return true end
	end
	return false
end

function App:lockPiece()
	for i = 1, #self.piece.shape do
		local c = self.piece.shape[i]
		local x, y = self.piece.x + c[1], self.piece.y + c[2]
		if y >= 1 and y <= self.h then self.board[y][x] = true end
	end
	self:clearLines()
	self:spawn()
end

function App:clearLines()
	local y = self.h
	while y >= 1 do
		local full = true
		for x = 1, self.w do if not self.board[y][x] then
				full = false; break
			end end
		if full then
			table.remove(self.board, y)
			table.insert(self.board, 1, {})
			self.score = self.score + 100
		else
			y = y - 1
		end
	end
end

function App:move(dx, dy)
	if self.gameOver or self.paused then return end
	if not self:collides(self.piece.x + dx, self.piece.y + dy, self.piece.shape) then
		self.piece.x = self.piece.x + dx
		self.piece.y = self.piece.y + dy
	elseif dy > 0 then
		self:lockPiece()
	end
end

function App:rotate()
	local shape = self:rotated(self.piece.shape)
	if not self:collides(self.piece.x, self.piece.y, shape) then self.piece.shape = shape end
end

function App:handleInput(event)
	if event.action == "KEYPAD" then
		local value = tostring(event.value or "")
		if value == "2" or value == "5" then event = { action = "OK" }
		elseif value == "4" then event = { action = "LEFT" }
		elseif value == "6" then event = { action = "RIGHT" }
		elseif value == "8" then event = { action = "DOWN" }
		end
	end
	if self.mode == "menu" or self.mode == "scores" then
		if self.mode == "scores" and (event.action == "RIGHT_SOFT" or event.action == "BACK" or event.action == "LEFT_SOFT") then
			self.mode = "menu"; return true
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
	if self.gameOver and (event.action == "OK" or event.action == "LEFT_SOFT") then
		self:startGame(); return true
	end
	if event.action == "LEFT_SOFT" and not self.gameOver then
		self.paused = not self.paused; return true
	end
	if event.action == "LEFT" then
		self:move(-1, 0); return true
	end
	if event.action == "RIGHT" then
		self:move(1, 0); return true
	end
	if event.action == "DOWN" then
		self:move(0, 1); return true
	end
	if event.action == "UP" or event.action == "OK" then
		self:rotate(); return true
	end
	if event.action == "RIGHT_SOFT" or event.action == "BACK" then
		self:saveHighScore()
		self.mode = "menu"
		self.paused = true
		return true
	end
	return Base.handleInput(self, event)
end

function App:update(deltaTime)
	if self.mode ~= "play" then return end
	if self.gameOver or self.paused then return end
	self.elapsed = self.elapsed + deltaTime
	if self.elapsed >= self.delay then
		self.elapsed = 0
		self:move(0, 1)
	end
end

function App:pauseForNotification()
	self.paused = true
end

function App:render(display)
	if self.mode == "menu" then
		display:clear()
		display:drawText(I18N.app("tetris"), display.x + 16, display.y + 34, display.colors.fg, UIFont.Medium)
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
	display:drawHeader(I18N.app("tetris"))
	display:drawText(I18N.get("ScoreLabel", tostring(self.score)), display.x + 8, display.contentY, display.colors.fg)
	display:drawText(I18N.get("HighWorldLabel", tostring(self.highScore), tostring(worldScore)), display.x + 8,
		display.contentY + 12, display.colors.dim)
	local top = display.contentY + 26
	local cell = math.floor(math.min((display.width - 70) / self.w, (display.contentBottom - top - 2) / self.h))
	local ox = display.x + 8
	display:drawBorder(ox - 1, top - 1, self.w * cell + 2, self.h * cell + 2, display.colors.fg)
	for y = 1, self.h do
		for x = 1, self.w do
			if self.board[y][x] then
				local color = self.os.definition.hardwareType == "smartphone" and COLORS[((x + y) % #COLORS) + 1] or display.colors.fg
				display:fillRect(ox + (x - 1) * cell + 1, top + (y - 1) * cell + 1, cell - 2, cell - 2, color)
			end
		end
	end
	if self.piece then
		for i = 1, #self.piece.shape do
			local c = self.piece.shape[i]
			local x, y = self.piece.x + c[1], self.piece.y + c[2]
			if y >= 1 then
				local color = self.os.definition.hardwareType == "smartphone" and COLORS[((i + self.score) % #COLORS) + 1] or display.colors.accent
				display:fillRect(ox + (x - 1) * cell + 1, top + (y - 1) * cell + 1, cell - 2, cell - 2, color)
			end
		end
	end
	if self.gameOver or self.paused then display:drawTextCentered(
		self.gameOver and I18N.get("GameOver") or I18N.get("Paused"), top + 70, display.colors.fg) end
	local infoX = ox + self.w * cell + 8
	display:drawText(I18N.get("Next"), infoX, top, display.colors.dim)
	if self.nextShape then
		for i = 1, #self.nextShape do
			local c = self.nextShape[i]
			display:fillRect(infoX + 12 + c[1] * 5, top + 22 + c[2] * 5, 4, 4, display.colors.fg)
		end
	end
	display:drawText(I18N.get("TetrisTipMove"), infoX, top + 52, display.colors.dim)
	display:drawText(I18N.get("TetrisTipDrop"), infoX, top + 66, display.colors.dim)
	display:drawText(I18N.get("TetrisTipRotate"), infoX, top + 80, display.colors.dim)
	display:drawText(I18N.get("TetrisTipPause"), infoX, top + 94, display.colors.dim)
	display:drawFooter(self.gameOver and I18N.get("Retry") or (self.paused and I18N.get("Resume") or I18N.get("Pause")),
		I18N.get("Back"))
end

return App
