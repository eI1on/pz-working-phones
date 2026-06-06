local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local Networking = require("WorkingPhones/Core/PhoneNetworking")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local Assets = require("WorkingPhones/Assets/PhoneAssets")

local App = setmetatable({}, { __index = Base })
App.__index = App

local PIECE_ROOT = Assets.CHESS_PIECES .. "default/"

local BOARDS = {
	{ id = "blue",   nameKey = "ChessBoardBlue",   texture = Assets.CHESS_BOARDS .. "blue.png" },
	{ id = "brown",  nameKey = "ChessBoardBrown",  texture = Assets.CHESS_BOARDS .. "brown.png" },
	{ id = "green",  nameKey = "ChessBoardGreen",  texture = Assets.CHESS_BOARDS .. "green.png" },
	{ id = "ic",     nameKey = "ChessBoardIce",    texture = Assets.CHESS_BOARDS .. "ic.png" },
	{ id = "purple", nameKey = "ChessBoardPurple", texture = Assets.CHESS_BOARDS .. "purple.png" },
}

local DIFFICULTIES = {
	{ id = "casual", nameKey = "ChessLevelCasual", depth = 1, moveLimit = 10 },
	{ id = "normal", nameKey = "ChessLevelNormal", depth = 2, moveLimit = 14 },
	{ id = "sharp",  nameKey = "ChessLevelSharp",  depth = 3, moveLimit = 18 },
}

local MENU_ROWS = {
	{ id = "new",        labelKey = "ChessNewGame" },
	{ id = "difficulty", labelKey = "ChessDifficulty" },
	{ id = "board",      labelKey = "ChessBoard" },
}

local START = {
	{ "bR", "bN", "bB", "bQ", "bK", "bB", "bN", "bR" },
	{ "bP", "bP", "bP", "bP", "bP", "bP", "bP", "bP" },
	{ "",   "",   "",   "",   "",   "",   "",   "" },
	{ "",   "",   "",   "",   "",   "",   "",   "" },
	{ "",   "",   "",   "",   "",   "",   "",   "" },
	{ "",   "",   "",   "",   "",   "",   "",   "" },
	{ "wP", "wP", "wP", "wP", "wP", "wP", "wP", "wP" },
	{ "wR", "wN", "wB", "wQ", "wK", "wB", "wN", "wR" },
}

local VALUES = {
	P = 100,
	N = 320,
	B = 330,
	R = 500,
	Q = 900,
	K = 20000,
}

local PIECE_NAMES = {
	P = "",
	N = "N",
	B = "B",
	R = "R",
	Q = "Q",
	K = "K",
}

local function clamp(value, minValue, maxValue)
	return math.max(minValue, math.min(maxValue, value))
end

local function sideOf(piece)
	return string.sub(piece or "", 1, 1)
end

local function kindOf(piece)
	return string.sub(piece or "", 2, 2)
end

local function inBoard(x, y)
	return x >= 1 and x <= 8 and y >= 1 and y <= 8
end

local function cloneBoard(source)
	local board = {}
	for y = 1, 8 do
		board[y] = {}
		for x = 1, 8 do
			board[y][x] = source[y][x]
		end
	end
	return board
end

local function squareName(x, y)
	return string.char(96 + x) .. tostring(9 - y)
end

local function randomIndex(maxValue)
	if maxValue <= 1 then
		return 1
	end
	return ZombRand(1, maxValue + 1)
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

local function moveScore(board, move)
	local piece = board[move.fromY][move.fromX]
	local captured = board[move.toY][move.toX]
	local score = captured ~= "" and (VALUES[kindOf(captured)] or 0) * 10 - (VALUES[kindOf(piece)] or 0) or 0
	local center = (4 - math.abs(4.5 - move.toX)) + (4 - math.abs(4.5 - move.toY))
	return score + center
end

local function addMove(moves, board, sideId, fromX, fromY, toX, toY)
	if not inBoard(toX, toY) then
		return false
	end
	local target = board[toY][toX]
	if target ~= "" and sideOf(target) == sideId then
		return false
	end
	table.insert(moves, { fromX = fromX, fromY = fromY, toX = toX, toY = toY })
	return target == ""
end

local function slideMoves(moves, board, sideId, x, y, vectors)
	for i = 1, #vectors do
		local vector = vectors[i]
		local tx = x + vector[1]
		local ty = y + vector[2]
		while inBoard(tx, ty) do
			if not addMove(moves, board, sideId, x, y, tx, ty) then
				break
			end
			tx = tx + vector[1]
			ty = ty + vector[2]
		end
	end
end

local function movesForPiece(board, x, y)
	local piece = board[y][x]
	local moves = {}
	if piece == "" then
		return moves
	end
	local sideId = sideOf(piece)
	local kind = kindOf(piece)
	if kind == "P" then
		local dir = sideId == "w" and -1 or 1
		local startY = sideId == "w" and 7 or 2
		if inBoard(x, y + dir) and board[y + dir][x] == "" then
			table.insert(moves, { fromX = x, fromY = y, toX = x, toY = y + dir })
			if y == startY and board[y + dir * 2][x] == "" then
				table.insert(moves, { fromX = x, fromY = y, toX = x, toY = y + dir * 2 })
			end
		end
		for dx = -1, 1, 2 do
			local tx = x + dx
			local ty = y + dir
			if inBoard(tx, ty) and board[ty][tx] ~= "" and sideOf(board[ty][tx]) ~= sideId then
				table.insert(moves, { fromX = x, fromY = y, toX = tx, toY = ty })
			end
		end
	elseif kind == "N" then
		local jumps = { { 1, 2 }, { 2, 1 }, { 2, -1 }, { 1, -2 }, { -1, -2 }, { -2, -1 }, { -2, 1 }, { -1, 2 } }
		for i = 1, #jumps do
			addMove(moves, board, sideId, x, y, x + jumps[i][1], y + jumps[i][2])
		end
	elseif kind == "B" then
		slideMoves(moves, board, sideId, x, y, { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } })
	elseif kind == "R" then
		slideMoves(moves, board, sideId, x, y, { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } })
	elseif kind == "Q" then
		slideMoves(moves, board, sideId, x, y,
			{ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } })
	elseif kind == "K" then
		for dx = -1, 1 do
			for dy = -1, 1 do
				if dx ~= 0 or dy ~= 0 then
					addMove(moves, board, sideId, x, y, x + dx, y + dy)
				end
			end
		end
	end
	return moves
end

local applyMoveToBoard

local function pseudoMovesForSide(board, sideId)
	local moves = {}
	for y = 1, 8 do
		for x = 1, 8 do
			local piece = board[y][x]
			if piece ~= "" and sideOf(piece) == sideId then
				local pieceMoves = movesForPiece(board, x, y)
				for i = 1, #pieceMoves do
					table.insert(moves, pieceMoves[i])
				end
			end
		end
	end
	table.sort(moves, function(a, b)
		return moveScore(board, a) > moveScore(board, b)
	end)
	return moves
end

function applyMoveToBoard(board, move)
	local nextBoard = cloneBoard(board)
	local piece = nextBoard[move.fromY][move.fromX]
	nextBoard[move.fromY][move.fromX] = ""
	if kindOf(piece) == "P" and (move.toY == 1 or move.toY == 8) then
		piece = sideOf(piece) .. "Q"
	end
	nextBoard[move.toY][move.toX] = piece
	return nextBoard
end

local function findKing(board, sideId)
	local wanted = sideId .. "K"
	for y = 1, 8 do
		for x = 1, 8 do
			if board[y][x] == wanted then
				return { x = x, y = y }
			end
		end
	end
	return nil
end

local function squareAttackedBy(board, x, y, attacker)
	for by = 1, 8 do
		for bx = 1, 8 do
			local piece = board[by][bx]
			if piece ~= "" and sideOf(piece) == attacker then
				local kind = kindOf(piece)
				if kind == "P" then
					local dir = attacker == "w" and -1 or 1
					if by + dir == y and (bx - 1 == x or bx + 1 == x) then
						return true
					end
				else
					local moves = movesForPiece(board, bx, by)
					for i = 1, #moves do
						if moves[i].toX == x and moves[i].toY == y then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

local function kingSafeAfter(board, sideId, move)
	local nextBoard = applyMoveToBoard(board, move)
	local king = findKing(nextBoard, sideId)
	if not king then
		return false
	end
	local opponent = sideId == "w" and "b" or "w"
	return not squareAttackedBy(nextBoard, king.x, king.y, opponent)
end

local function allMovesForSide(board, sideId)
	local moves = pseudoMovesForSide(board, sideId)
	local legal = {}
	for i = 1, #moves do
		if kingSafeAfter(board, sideId, moves[i]) then
			table.insert(legal, moves[i])
		end
	end
	table.sort(legal, function(a, b)
		return moveScore(board, a) > moveScore(board, b)
	end)
	return legal
end

local function hasKing(board, sideId)
	local wanted = sideId .. "K"
	for y = 1, 8 do
		for x = 1, 8 do
			if board[y][x] == wanted then
				return true
			end
		end
	end
	return false
end

local function evaluateBoard(board)
	local score = 0
	for y = 1, 8 do
		for x = 1, 8 do
			local piece = board[y][x]
			if piece ~= "" then
				local value = VALUES[kindOf(piece)] or 0
				local center = (4 - math.abs(4.5 - x)) + (4 - math.abs(4.5 - y))
				local signed = sideOf(piece) == "b" and 1 or -1
				score = score + signed * (value + center * 4)
			end
		end
	end
	if not hasKing(board, "w") then
		return 999999
	end
	if not hasKing(board, "b") then
		return -999999
	end
	return score
end

local function search(board, depth, sideId, alpha, beta, moveLimit)
	if depth <= 0 or not hasKing(board, "w") or not hasKing(board, "b") then
		return evaluateBoard(board)
	end
	local moves = allMovesForSide(board, sideId)
	if #moves == 0 then
		return evaluateBoard(board)
	end
	local limit = math.min(#moves, moveLimit)
	if sideId == "b" then
		local best = -999999
		for i = 1, limit do
			local score = search(applyMoveToBoard(board, moves[i]), depth - 1, "w", alpha, beta, moveLimit)
			if score > best then
				best = score
			end
			alpha = math.max(alpha, best)
			if beta <= alpha then
				break
			end
		end
		return best
	end
	local best = 999999
	for i = 1, limit do
		local score = search(applyMoveToBoard(board, moves[i]), depth - 1, "b", alpha, beta, moveLimit)
		if score < best then
			best = score
		end
		beta = math.min(beta, best)
		if beta <= alpha then
			break
		end
	end
	return best
end

function App:new(os)
	local o = Base.new(self, os)
	o.id = "chess"
	o.name = I18N.app("chess")
	o.mode = "menu"
	o.menuIndex = 1
	o.cursor = { x = 5, y = 7 }
	o.selected = nil
	o.board = cloneBoard(START)
	o.turn = "w"
	o.statusKey = "ChessYourMove"
	o.historyScroll = 0
	o.aiDelay = 0
	o.animation = nil
	o.lastBoardRect = nil
	o.settings = os.instance.data.chessSettings or { difficulty = 2, board = 3 }
	o.settings.difficulty = clamp(o.settings.difficulty or 2, 1, #DIFFICULTIES)
	o.settings.board = clamp(o.settings.board or 3, 1, #BOARDS)
	os.instance.data.chessSettings = o.settings
	o.capturedByWhite = {}
	o.capturedByBlack = {}
	o.moveHistory = {}
	Networking.requestWorldGameScores()
	return o
end

function App:save()
	self.os.instance.data.chessSettings = self.settings
end

function App:recordWin()
	self.os.instance.data.gameScores = self.os.instance.data.gameScores or {}
	local current = self.os.instance.data.gameScores.chess and tonumber(self.os.instance.data.gameScores.chess.score) or 0
	local wins = current + 1
	local name = playerName(self.os)
	self.os.instance.data.gameScores.chess = { score = wins, name = name }
	Networking.submitGameScore("chess", wins, name, self.os.instance.number)
end

function App:newGame()
	self.board = cloneBoard(START)
	self.turn = "w"
	self.cursor = { x = 5, y = 7 }
	self.selected = nil
	self.statusKey = "ChessYourMove"
	self.capturedByWhite = {}
	self.capturedByBlack = {}
	self.moveHistory = {}
	self.animation = nil
	self.aiDelay = 0
	self.mode = "game"
	self:save()
end

function App:currentDifficulty()
	return DIFFICULTIES[self.settings.difficulty]
end

function App:currentBoard()
	return BOARDS[self.settings.board]
end

function App:menuValue(rowId)
	if rowId == "difficulty" then
		return I18N.get(self:currentDifficulty().nameKey)
	end
	if rowId == "board" then
		return I18N.get(self:currentBoard().nameKey)
	end
	return ""
end

function App:adjustMenu(delta)
	local row = MENU_ROWS[self.menuIndex]
	if not row then
		return
	end
	if row.id == "difficulty" then
		self.settings.difficulty = clamp(self.settings.difficulty + delta, 1, #DIFFICULTIES)
		self:save()
	elseif row.id == "board" then
		self.settings.board = clamp(self.settings.board + delta, 1, #BOARDS)
		self:save()
	end
end

function App:activateMenu()
	local row = MENU_ROWS[self.menuIndex]
	if not row then
		return true
	end
	if row.id == "new" then
		self:newGame()
	elseif row.id == "difficulty" then
		self:adjustMenu(1)
	elseif row.id == "board" then
		self:adjustMenu(1)
	end
	return true
end

function App:moveLabel(move, piece, captured)
	local name = PIECE_NAMES[kindOf(piece)] or ""
	local sep = captured ~= "" and "x" or "-"
	return name .. squareName(move.fromX, move.fromY) .. sep .. squareName(move.toX, move.toY)
end

function App:pushHistory(piece, move, captured)
	local sideLabel = sideOf(piece) == "w" and I18N.get("ChessWhite") or I18N.get("ChessBlack")
	table.insert(self.moveHistory, sideLabel .. " " .. self:moveLabel(move, piece, captured))
end

function App:startAnimation(piece, move)
	self.animation = {
		piece = piece,
		fromX = move.fromX,
		fromY = move.fromY,
		toX = move.toX,
		toY = move.toY,
		elapsed = 0,
		duration = 240,
	}
end

function App:finishIfGameOver()
	if not hasKing(self.board, "w") then
		self.statusKey = "ChessBlackWins"
		self.turn = "done"
		return true
	end
	if not hasKing(self.board, "b") then
		self.statusKey = "ChessWhiteWins"
		self.turn = "done"
		self:recordWin()
		return true
	end
	return false
end

function App:applyRealMove(move)
	local piece = self.board[move.fromY][move.fromX]
	local captured = self.board[move.toY][move.toX]
	if captured ~= "" then
		if sideOf(piece) == "w" then
			table.insert(self.capturedByWhite, captured)
		else
			table.insert(self.capturedByBlack, captured)
		end
	end
	self.board[move.fromY][move.fromX] = ""
	if kindOf(piece) == "P" and (move.toY == 1 or move.toY == 8) then
		piece = sideOf(piece) .. "Q"
	end
	self.board[move.toY][move.toX] = piece
	self:pushHistory(piece, move, captured)
	self:startAnimation(piece, move)
	if self:finishIfGameOver() then
		self:save()
		return
	end
	if sideOf(piece) == "w" then
		self.turn = "b"
		self.statusKey = "ChessThinking"
		self.aiDelay = 320
	else
		self.turn = "w"
		self.statusKey = "ChessYourMove"
	end
	self:save()
end

function App:isLegalMove(fromX, fromY, toX, toY)
	local moves = movesForPiece(self.board, fromX, fromY)
	local piece = self.board[fromY][fromX]
	local sideId = sideOf(piece)
	for i = 1, #moves do
		local move = moves[i]
		if move.toX == toX and move.toY == toY and kingSafeAfter(self.board, sideId, move) then
			return { fromX = fromX, fromY = fromY, toX = toX, toY = toY }
		end
	end
	return nil
end

function App:selectSquare(x, y)
	if self.turn ~= "w" then
		return true
	end
	local piece = self.board[y][x]
	if self.selected then
		local move = self:isLegalMove(self.selected.x, self.selected.y, x, y)
		if move then
			self.selected = nil
			self:applyRealMove(move)
			return true
		end
		self.selected = nil
	end
	if piece ~= "" and sideOf(piece) == "w" then
		self.selected = { x = x, y = y }
	end
	return true
end

function App:chooseAIMove()
	local moves = allMovesForSide(self.board, "b")
	if #moves == 0 then
		self.statusKey = "ChessNoMoves"
		self.turn = "done"
		return nil
	end
	local difficulty = self:currentDifficulty()
	local depth = difficulty.depth
	local moveLimit = difficulty.moveLimit
	local bestScore = -999999
	local bestMoves = {}
	for i = 1, #moves do
		local score = search(applyMoveToBoard(self.board, moves[i]), depth - 1, "w", -999999, 999999, moveLimit)
		if score > bestScore then
			bestScore = score
			bestMoves = { moves[i] }
		elseif score == bestScore then
			table.insert(bestMoves, moves[i])
		end
	end
	return bestMoves[randomIndex(#bestMoves)]
end

function App:update(deltaTime)
	deltaTime = deltaTime or 0
	if self.animation then
		self.animation.elapsed = self.animation.elapsed + deltaTime
		if self.animation.elapsed >= self.animation.duration then
			self.animation = nil
		end
	end
	if self.turn == "b" and not self.animation then
		self.aiDelay = math.max(0, self.aiDelay - deltaTime)
		if self.aiDelay <= 0 then
			local move = self:chooseAIMove()
			if move then
				self:applyRealMove(move)
			end
		end
	end
end

function App:handleMenuInput(event)
	if event.action == "UP" then
		self.menuIndex = math.max(1, self.menuIndex - 1)
		return true
	elseif event.action == "DOWN" then
		self.menuIndex = math.min(#MENU_ROWS, self.menuIndex + 1)
		return true
	elseif event.action == "LEFT" then
		self:adjustMenu(-1)
		return true
	elseif event.action == "RIGHT" then
		self:adjustMenu(1)
		return true
	elseif event.action == "OK" or event.action == "LEFT_SOFT" then
		return self:activateMenu()
	elseif event.action == "RIGHT_SOFT" or event.action == "BACK" then
		return Base.handleInput(self, event)
	elseif event.action == "MOUSE_DOWN" and event.displayY then
		local row = math.floor((event.displayY - (self.menuTop or 78)) / 30) + 1
		if MENU_ROWS[row] then
			self.menuIndex = row
			return self:activateMenu()
		end
	end
	return true
end

function App:handleHistoryInput(event)
	if event.action == "UP" then
		self.historyScroll = math.max(0, self.historyScroll - 1)
		return true
	elseif event.action == "DOWN" then
		self.historyScroll = math.min(math.max(0, #self.moveHistory - 8), self.historyScroll + 1)
		return true
	elseif event.action == "RIGHT_SOFT" or event.action == "BACK" or event.action == "LEFT_SOFT" then
		self.mode = "game"
		return true
	end
	return true
end

function App:handleGameInput(event)
	if event.action == "MENU" or event.action == "RIGHT_SOFT" or event.action == "BACK" then
		self.mode = "menu"
		return true
	elseif event.action == "LEFT_SOFT" then
		self.mode = "history"
		return true
	elseif event.action == "UP" then
		self.cursor.y = math.max(1, self.cursor.y - 1)
		return true
	elseif event.action == "DOWN" then
		self.cursor.y = math.min(8, self.cursor.y + 1)
		return true
	elseif event.action == "LEFT" then
		self.cursor.x = math.max(1, self.cursor.x - 1)
		return true
	elseif event.action == "RIGHT" then
		self.cursor.x = math.min(8, self.cursor.x + 1)
		return true
	elseif event.action == "OK" then
		return self:selectSquare(self.cursor.x, self.cursor.y)
	elseif event.action == "MOUSE_DOWN" and event.displayX and event.displayY and self.lastBoardRect then
		local rect = self.lastBoardRect
		if event.displayX >= rect.x and event.displayX <= rect.x + rect.size
			and event.displayY >= rect.y and event.displayY <= rect.y + rect.size then
			local x = clamp(math.floor((event.displayX - rect.x) / rect.cell) + 1, 1, 8)
			local y = clamp(math.floor((event.displayY - rect.y) / rect.cell) + 1, 1, 8)
			self.cursor = { x = x, y = y }
			return self:selectSquare(x, y)
		end
	end
	return true
end

function App:handleInput(event)
	if self.mode == "menu" then
		return self:handleMenuInput(event)
	elseif self.mode == "history" then
		return self:handleHistoryInput(event)
	end
	return self:handleGameInput(event)
end

function App:drawPiece(display, piece, x, y, size, alpha)
	if piece == "" then
		return
	end
	local texture = getTexture(PIECE_ROOT .. piece .. ".png")
	if texture then
		display.panel:drawTextureScaledAspect(texture, x, y, size, size, alpha or 1, 1, 1, 1)
	else
		display:drawTextCentered(piece, y + math.floor(size / 2) - 6, display.colors.fg, UIFont.Small, x, x + size)
	end
end

function App:drawCapturedRow(display, pieces, label, x, y, width)
	display:drawText(label, x, y + 2, display.colors.dim)
	local icon = 14
	local startX = x + 42
	for i = 1, math.min(#pieces, 10) do
		self:drawPiece(display, pieces[i], startX + (i - 1) * (icon + 1), y, icon, 0.95)
	end
	if #pieces > 10 then
		display:drawText("+" .. tostring(#pieces - 10), x + width - 20, y + 2, display.colors.dim)
	end
end

function App:drawBoard(display, x, y, size, cell)
	local boardInfo = self:currentBoard()
	local texture = getTexture(boardInfo.texture)
	if texture then
		display.panel:drawTextureScaled(texture, x, y, size, size, 1, 1, 1, 1)
	else
		for by = 1, 8 do
			for bx = 1, 8 do
				local color = ((bx + by) % 2 == 0) and display.colors.bg or display.colors.border
				display:fillRect(x + (bx - 1) * cell, y + (by - 1) * cell, cell, cell, color)
			end
		end
	end

	if self.selected then
		local moves = movesForPiece(self.board, self.selected.x, self.selected.y)
		for i = 1, #moves do
			local move = moves[i]
			display:fillRect(x + (move.toX - 1) * cell + math.floor(cell / 2) - 2,
				y + (move.toY - 1) * cell + math.floor(cell / 2) - 2, 4, 4, display.colors.accent)
		end
		display:drawBorder(x + (self.selected.x - 1) * cell + 1, y + (self.selected.y - 1) * cell + 1, cell - 2, cell - 2,
			display.colors.accent)
	end

	display:drawBorder(x + (self.cursor.x - 1) * cell + 1, y + (self.cursor.y - 1) * cell + 1, cell - 2, cell - 2,
		display.colors.fg)

	for by = 1, 8 do
		for bx = 1, 8 do
			local skip = self.animation and self.animation.toX == bx and self.animation.toY == by
			if not skip then
				self:drawPiece(display, self.board[by][bx], x + (bx - 1) * cell + 2, y + (by - 1) * cell + 2, cell - 4, 1)
			end
		end
	end

	if self.animation then
		local progress = clamp(self.animation.elapsed / self.animation.duration, 0, 1)
		local eased = 1 - (1 - progress) * (1 - progress)
		local fx = x + (self.animation.fromX - 1) * cell + 2
		local fy = y + (self.animation.fromY - 1) * cell + 2
		local tx = x + (self.animation.toX - 1) * cell + 2
		local ty = y + (self.animation.toY - 1) * cell + 2
		self:drawPiece(display, self.animation.piece, fx + (tx - fx) * eased, fy + (ty - fy) * eased, cell - 4, 1)
	end
end

function App:renderMenu(display)
	display:clear()
	display:drawText(I18N.app("chess"), display.x + 16, display.y + 34, display.colors.fg, UIFont.Medium)
	display:drawText(I18N.get("ChessMenuHint"), display.x + 16, display.y + 58, display.colors.dim)
	self.menuTop = 82
	for i = 1, #MENU_ROWS do
		local row = MENU_ROWS[i]
		local y = display.y + self.menuTop + (i - 1) * 30
		local selected = i == self.menuIndex
		display:fillRect(display.x + 12, y - 3, display.width - 24, 26,
			selected and display.colors.accent or display.colors.bg)
		display:drawBorder(display.x + 12, y - 3, display.width - 24, 26,
			selected and display.colors.fg or display.colors.border)
		local color = selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.fg
		display:drawText(I18N.get(row.labelKey), display.x + 20, y + 3, color)
		local value = self:menuValue(row.id)
		if value ~= "" then
			display:drawTextRight(display:ellipsize(value, 86), display.x + display.width - 22, y + 3, color)
		end
	end
	display:drawFooter(I18N.get("Select"), I18N.get("Back"))
end

function App:renderHistory(display)
	display:clear()
	display:drawText(I18N.get("ChessMoveHistory"), display.x + 16, display.y + 34, display.colors.fg, UIFont.Medium)
	local top = display.y + 66
	local rowH = 20
	local visible = math.max(1, math.floor((display.contentBottom - top) / rowH))
	self.historyScroll = clamp(self.historyScroll, 0, math.max(0, #self.moveHistory - visible))
	for i = 1, visible do
		local index = self.historyScroll + i
		local text = self.moveHistory[index]
		if text then
			display:drawText(display:ellipsize(tostring(index) .. ". " .. text, display.width - 34), display.x + 16,
				top + (i - 1) * rowH, display.colors.fg)
		end
	end
	if #self.moveHistory == 0 then
		display:drawText(I18N.get("ChessNoMoves"), display.x + 16, top, display.colors.dim)
	end
	if #self.moveHistory > visible then
		display:drawScrollbar(#self.moveHistory, visible, self.historyScroll, top, display.contentBottom)
	end
	display:drawFooter(I18N.get("Done"), I18N.get("Back"))
end

function App:renderGame(display)
	display:clear()
	display:drawText(I18N.app("chess"), display.x + 14, display.y + 32, display.colors.fg, UIFont.Medium)
	display:drawText(I18N.get(self.statusKey), display.x + 14, display.y + 55, display.colors.dim)
	local usableH = display.contentBottom - (display.y + 76) - 72
	local boardSize = math.min(display.width - 28, usableH)
	local cell = math.max(18, math.floor(boardSize / 8))
	boardSize = cell * 8
	local bx = display.x + math.floor((display.width - boardSize) / 2)
	local by = display.y + 78
	self.lastBoardRect = { x = bx - display.x, y = by - display.y, size = boardSize, cell = cell }
	self:drawBoard(display, bx, by, boardSize, cell)

	local trayY = by + boardSize + 8
	self:drawCapturedRow(display, self.capturedByWhite, I18N.get("ChessWhite"), display.x + 14, trayY, display.width - 28)
	self:drawCapturedRow(display, self.capturedByBlack, I18N.get("ChessBlack"), display.x + 14, trayY + 18,
		display.width - 28)

	local historyY = trayY + 40
	local start = math.max(1, #self.moveHistory - 2)
	for i = start, #self.moveHistory do
		display:drawText(display:ellipsize(tostring(i) .. ". " .. self.moveHistory[i], display.width - 28),
			display.x + 14, historyY + (i - start) * 14, display.colors.dim)
	end
	display:drawFooter(I18N.get("History"), I18N.get("Menu"))
end

function App:render(display)
	if self.mode == "menu" then
		return self:renderMenu(display)
	elseif self.mode == "history" then
		return self:renderHistory(display)
	end
	return self:renderGame(display)
end

return App
