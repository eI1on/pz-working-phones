require "ISUI/ISTextEntryBox"

local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local Networking = require("WorkingPhones/Core/PhoneNetworking")
local AppRegistry = require("WorkingPhones/Core/PhoneAppRegistry")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local App = setmetatable({}, { __index = Base })
App.__index = App

function App:new(os)
	local o = Base.new(self, os)
	o.id = "games"
	o.name = I18N.app("games")
	o.games = AppRegistry.getGamesForPhone(os.definition)
	o.scores = os.instance.data.gameScores or {}
	os.instance.data.gameScores = o.scores
	o.playerName = os.instance.data.gamePlayerName or ""
	o.mode = "list"
	o.selected = 1
	o.cursorTick = 0
	o.acceptsTextInput = false
	o.nameEntry = nil
	Networking.requestWorldGameScores()
	return o
end

function App:onClose()
	self:removeNameEntry()
end

function App:removeNameEntry()
	if self.nameEntry then
		if self.os.instance.os and self.os.instance.os.displayPanel then
			self.os.instance.os.displayPanel:removeChild(self.nameEntry)
		else
			self.nameEntry:removeFromUIManager()
		end
		self.nameEntry = nil
	end
end

function App:isTextEntryFocused()
	return self.nameEntry and self.nameEntry.isFocused and self.nameEntry:isFocused()
end

function App:handleInput(event)
	if self.mode == "name" then
		if event.action == "MOUSE_DOWN" and self.nameEntry then self.nameEntry:focus(); return true end
		if event.action == "LEFT_SOFT" or event.action == "OK" then
			if self.nameEntry then self.playerName = self.nameEntry:getText() end
			if not self:isNameTaken() then
				self.mode = "list"
				self.os.instance.data.gamePlayerName = self.playerName
				self:removeNameEntry()
			end
			return true
		end
		if event.action == "RIGHT_SOFT" then self.mode = "list"; self:removeNameEntry(); return true end
		return Base.handleInput(self, event)
	end
	self:removeNameEntry()
	if event.action == "UP" then
		self.selected = math.max(1, self.selected - 1)
		return true
	elseif event.action == "DOWN" then
		self.selected = math.min(#self.games, self.selected + 1)
		return true
	elseif event.action == "OK" or event.action == "LEFT_SOFT" then
		return self.games[self.selected] and self.os:openApp(self.games[self.selected].id) or true
	elseif event.action == "MENU" then
		self.mode = "name"
		return true
	elseif event.action == "RIGHT_SOFT" then
		return Base.handleInput(self, event)
	elseif event.action == "MOUSE_DOWN" and event.displayY then
		if self.os.definition.hardwareType == "smartphone" and self.smartGameRects then
			for i = 1, #self.smartGameRects do
				local rect = self.smartGameRects[i]
				if event.displayX >= rect.x and event.displayX <= rect.x + rect.w
					and event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
					self.selected = rect.index
					return self.os:openApp(self.games[self.selected].id)
				end
			end
		end
		local row = math.floor((event.displayY - (self.listTop or 58)) / 24) + 1
		if self.games[row] then
			self.selected = row
			return self.os:openApp(self.games[row].id)
		end
	end
	return Base.handleInput(self, event)
end

function App:update(deltaTime) self.cursorTick = (self.cursorTick + (deltaTime or 0)) % 1000 end

function App:isNameTaken()
	if self.nameEntry then self.playerName = self.nameEntry:getText() end
	local wanted = tostring(self.playerName or "")
	if wanted == "" then return false end
	local world = (WorkingPhones and WorkingPhones.WorldGameScores) or self.os.instance.data.worldGameScores or {}
	for i = 1, #self.games do
		local gameId = self.games[i].id
		local rows = world[gameId]
		if type(rows) == "table" then
			for r = 1, #rows do
				local row = rows[r]
				if tostring(row.name or "") == wanted and tostring(row.phoneNumber or "") ~= tostring(self.os.instance.number) then
					return true
				end
			end
		end
	end
	return false
end

function App:ensureNameEntry(display)
	local x, y = display.x + 10, display.contentY + 18
	local w, h = display.width - 20, 22
	if not self.nameEntry then
		self.nameEntry = ISTextEntryBox:new(self.playerName or "", x, y, w, h)
		self.nameEntry:initialise()
		self.nameEntry:instantiate()
		self.nameEntry:setMaxTextLength(14)
		self.nameEntry.backgroundColor = { r = 0.05, g = 0.08, b = 0.05, a = 1 }
		self.nameEntry.borderColor = { r = 0.55, g = 0.75, b = 0.45, a = 1 }
		self.nameEntry.font = UIFont.Small
		display.panel:addChild(self.nameEntry)
		self.nameEntry:focus()
	else
		self.nameEntry:setX(x); self.nameEntry:setY(y); self.nameEntry:setWidth(w); self.nameEntry:setHeight(h)
	end
	self.nameEntry:setVisible(true)
end

function App:drawNameEntry(display)
	if not self.nameEntry then return end
	local x, y = display.x + 10, display.contentY + 18
	local w, h = display.width - 20, 22
	display:fillRect(x, y, w, h, display.colors.bg)
	display:drawBorder(x, y, w, h, self.nameEntry:isFocused() and display.colors.fg or display.colors.dim)
	local text = tostring(self.nameEntry:getText() or "")
	if self.nameEntry:isFocused() and (not getTimestampMs or math.floor(getTimestampMs() / 500) % 2 == 0) then
		text = text .. "|"
	end
	display:drawText(display:ellipsize(text, w - 8), x + 4, y + 4, display.colors.fg)
end

function App:renderSmartphone(display)
	self:removeNameEntry()
	display:clear()
	display:drawText(I18N.app("games"), display.x + 14, display.y + 34, display.colors.fg, UIFont.Medium)
	display:drawText(I18N.get("ScoreName") .. ": " .. tostring(self.playerName ~= "" and self.playerName or I18N.get("Player")),
		display.x + 14, display.y + 58, display.colors.dim)
	local cols = 2
	local cellW = math.floor((display.width - 30) / cols)
	local cellH = 104
	local startX = display.x + 10
	local startY = display.y + 90
	self.smartGameRects = {}
	if #self.games == 0 then
		display:drawText(I18N.get("NoGames"), display.x + 14, startY, display.colors.dim)
	end
	for i = 1, #self.games do
		local game = self.games[i]
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		local x = startX + col * cellW
		local y = startY + row * cellH
		local selected = i == self.selected
		display:fillRect(x, y, cellW - 8, cellH - 10, selected and display.colors.accent or display.colors.bg)
		display:drawBorder(x, y, cellW - 8, cellH - 10, selected and display.colors.fg or display.colors.border)
		local tex = getTexture(game.smartphoneIcon)
		if tex then display.panel:drawTextureScaledAspect(tex, x + math.floor((cellW - 8 - 44) / 2), y + 10, 44, 44, 1, 1, 1, 1) end
		display:drawTextCentered(game.name or I18N.app(game.id), y + 60, selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.fg,
			UIFont.Small, x, x + cellW - 8)
		local score = self.scores[game.id] and self.scores[game.id].score or 0
		display:drawTextCentered(I18N.get("ScoreLabel", tostring(score)), y + 76,
			selected and { r = 0.9, g = 0.94, b = 1, a = 1 } or display.colors.dim, UIFont.Small, x, x + cellW - 8)
		table.insert(self.smartGameRects, { x = x - display.x, y = y - display.y, w = cellW - 8, h = cellH - 10, index = i })
	end
	display:drawFooter(I18N.get("Play"), I18N.get("Back"))
end

function App:render(display)
	if self.mode == "name" then
		display:clear()
		display:drawHeader(I18N.get("ScoreName"))
		display:drawText(I18N.get("Name"), display.x + 10, display.contentY, display.colors.dim)
		self:ensureNameEntry(display)
		self:drawNameEntry(display)
		local taken = self:isNameTaken()
		display:drawText(taken and I18N.get("NameAlreadyUsed") or I18N.get("UsedForHighs"), display.x + 10, display.contentY + 52, taken and display.colors.accent or display.colors.dim)
		display:drawFooter(I18N.get("Save"), I18N.get("Back"))
		return
	end
	if self.os.definition.hardwareType == "smartphone" then
		return self:renderSmartphone(display)
	end
	self:removeNameEntry()
	display:clear()
	display:drawHeader(I18N.app("games"))
	self.listTop = display.y + 58 - display.y
	if #self.games == 0 then
		display:drawText(I18N.get("NoGames"), display.x + 12, display.y + 58, display.colors.dim)
	end
	for i = 1, #self.games do
		local game = self.games[i]
		local y = display.y + 58 + (i - 1) * 24
		if i == self.selected then
			display:fillRect(display.x + 8, y - 2, display.width - 16, 20, display.colors.accent)
		end
		local score = self.scores[game.id] and self.scores[game.id].score or 0
		display:drawText(game.name or I18N.app(game.id), display.x + 18, y, i == self.selected and display.colors.bg or display.colors.fg)
		display:drawTextRight(tostring(score), display.x + display.width - 12, y, i == self.selected and display.colors.bg or display.colors.dim)
	end
	display:drawFooter(I18N.get("Play"), I18N.get("Back"))
end

return App
