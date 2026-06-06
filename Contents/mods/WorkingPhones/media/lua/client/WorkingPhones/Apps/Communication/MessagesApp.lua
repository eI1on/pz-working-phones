require "ISUI/ISTextEntryBox"

local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local Networking = require("WorkingPhones/Core/PhoneNetworking")
local Persistence = require("WorkingPhones/Core/PhonePersistence")
local EmojiRegistry = require("WorkingPhones/Assets/EmojiRegistry")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local Assets = require("WorkingPhones/Assets/PhoneAssets")

local App = setmetatable({}, { __index = Base })
App.__index = App
local AVATAR_TEXTURE = Assets.SMARTPHONE_AVATARS .. "ui_working_smartphone_avatar_default.png"
local SMART_BG_DARK = Assets.MESSAGE_BACKGROUNDS .. "messages_bg_dark_pattern.png"
local SMART_BG_LIGHT = Assets.MESSAGE_BACKGROUNDS .. "messages_bg_light_pattern.png"
local SMART_HEADER_H = 38
local SMART_MESSAGE_LINE_H = 18
local SMART_BG_TOP_CROP_RATIO = 0.09
local EMERGENCY_NUMBER = "555-000000"

local function color(r, g, b, a)
	return { r = r, g = g, b = b, a = a or 1 }
end

local function nextTextChunk(display, text, maxWidth)
	text = tostring(text or "")
	if text == "" then return "" end
	local chunk = ""
	for c = 1, #text do
		local candidate = chunk .. string.sub(text, c, c)
		if chunk ~= "" and display:measureText(candidate) > maxWidth then
			return chunk
		end
		chunk = candidate
	end
	return chunk
end

local function textureSize(tex)
	if not tex then return 1, 1 end
	local w = tex:getWidthOrig()
	local h = tex:getHeightOrig()
	return math.max(1, w), math.max(1, h)
end

local function isEmergencyNumber(number)
	return tostring(number or "") == EMERGENCY_NUMBER
end

local function smartHeaderY(display)
	return display.y + display.statusBarHeight
end

local function smartBodyY(display)
	return smartHeaderY(display) + SMART_HEADER_H
end

local function smartBackgroundTopCrop(display, drawH, bgH)
	local overflow = math.max(0, drawH - bgH)
	local preferred = math.max(SMART_HEADER_H, math.floor(drawH * SMART_BG_TOP_CROP_RATIO))
	return math.min(overflow, preferred)
end

local function normalizeMessage(message, ownNumber)
	if type(message) == "table" then
		return {
			id = tostring(message.id or ""),
			from = tostring(message.from or message.fromNumber or message.fromId or I18N.get("Unknown")),
			to = tostring(message.to or message.targetNumber or message.toId or ownNumber or I18N.get("Unknown")),
			body = tostring(message.body or message.text or ""),
			time = tostring(message.time or message.gameDate or message.createdAtTs or ""),
		}
	end
	return {
		from = I18N.get("Unknown"),
		to = tostring(ownNumber or I18N.get("Unknown")),
		body = tostring(message or ""),
		time = ""
	}
end

function App:new(os)
	local o = Base.new(self, os)
	o.id = "messages"
	o.name = I18N.app("messages")
	o.messages = {}
	o.conversations = {}
	o.mode = "threads"
	o.selected = 1
	o.messageIndex = 1
	o.target = nil
	o.targetIndex = 1
	o.composeEntry = nil
	o.bodyScroll = 0
	o.emojiOpen = false
	o.emojiCategoryIndex = 1
	o.emojiRects = {}
	o.emojiTabRects = {}
	o.emojiPrevRect = nil
	o.emojiNextRect = nil
	o.smartComposeRect = nil
	o.smartEmojiButtonRect = nil
	o.smartSendButtonRect = nil
	o.smartMessageScroll = nil
	o.smartMessageScrollTarget = nil
	o.smartMessageScrollMax = 0
	o.smartMessageScrollbarRect = nil
	o.smartScrollToBottom = true
	o.emojiScroll = {}
	Networking.fetchMessages(os.instance.number)
	return o
end

function App:onClose()
	self:removeComposeEntry()
end

function App:isTextEntryFocused()
	return self.composeEntry and self.composeEntry.isFocused and self.composeEntry:isFocused()
end

function App:removeComposeEntry()
	if self.composeEntry then
		if self.os.instance.os and self.os.instance.os.displayPanel then
			self.os.instance.os.displayPanel:removeChild(self.composeEntry)
		else
			self.composeEntry:removeFromUIManager()
		end
		self.composeEntry = nil
	end
end

function App:save()
end

function App:onPhoneMessages(args)
	if type(args.conversations) == "table" then
		self.conversations = args.conversations
	end
	if type(args.messages) == "table" and tostring(args.peerNumber or "") ~= "" then
		self.messages = {}
		for i = 1, #args.messages do
			self.messages[#self.messages + 1] = normalizeMessage(args.messages[i], self.os.instance.number)
		end
		self.smartScrollToBottom = true
	end
end

function App:onPhoneMessageReceived(message)
	local msg = normalizeMessage(message, self.os.instance.number)
	if self.target and self:threadNumber(msg) == tostring(self.target.number or "") then
		self.messages[#self.messages + 1] = msg
		self.smartScrollToBottom = true
	end
	Networking.fetchMessages(self.os.instance.number, self.target and self.target.number or nil)
end

function App:isConversationOpen(number)
	return self.mode == "view" and self.target and tostring(self.target.number or "") == tostring(number or "")
end

function App:onInlineIncomingCall(args)
	self.inlineCall = {
		callId = args and args.callId or nil,
		fromNumber = tostring(args and args.fromNumber or ""),
	}
end

function App:clearInlineCall(callId)
	if self.inlineCall and (not callId or self.inlineCall.callId == callId) then
		self.inlineCall = nil
	end
end

function App:onCallConnected(args) self:clearInlineCall(args and args.callId) end
function App:onCallRejected(args) self:clearInlineCall(args and args.callId) end
function App:onCallEnded(args) self:clearInlineCall(args and args.callId) end

function App:contactName(number)
	local contacts = Persistence.getContacts(self.os.instance.item, self.os.instance.definition.id)
	for i = 1, #contacts do
		local contact = contacts[i]
		if tostring(contact.number) == tostring(number) then return tostring(contact.name or number) end
	end
	return tostring(number or I18N.get("Unknown"))
end

function App:threadNumber(message)
	local own = tostring(self.os.instance.number)
	if tostring(message.from) == own then return tostring(message.to or I18N.get("Unknown")) end
	return tostring(message.from or I18N.get("Unknown"))
end

function App:threads()
	if self.conversations and #self.conversations > 0 then
		local out = {}
		for i = 1, #self.conversations do
			local row = self.conversations[i]
			local msg = normalizeMessage({
				fromId = row.lastFromId,
				toId = row.lastToId,
				body = row.lastBody,
				gameDate = row.lastGameDate,
				createdAtTs = row.updatedAtTs,
			}, self.os.instance.number)
			out[#out + 1] = {
				number = tostring(row.peerId or self:threadNumber(msg)),
				count = tonumber(row.count) or 0,
				last = msg,
			}
		end
		return out
	end
	local seen, out = {}, {}
	for i = 1, #self.messages do
		local raw = self.messages[i]
		local msg = normalizeMessage(raw, self.os.instance.number)
		local number = self:threadNumber(msg)
		if not seen[number] then
			seen[number] = { number = number, count = 0, last = msg }
			table.insert(out, seen[number])
		end
		seen[number].count = seen[number].count + 1
		seen[number].last = msg
	end
	return out
end

function App:threadMessages()
	local out = {}
	if not self.target then return out end
	for i = 1, #self.messages do
		local raw = self.messages[i]
		local msg = normalizeMessage(raw, self.os.instance.number)
		if self:threadNumber(msg) == self.target.number then table.insert(out, msg) end
	end
	return out
end

function App:openThreadForNumber(number)
	if isEmergencyNumber(number) then
		self.mode = "threads"
		return false
	end
	self.target = { number = tostring(number or I18N.get("Unknown")) }
	self.mode = "view"
	self.messages = {}
	self.messageIndex = math.max(1, #self:threadMessages())
	self.smartScrollToBottom = true
	Networking.fetchMessages(self.os.instance.number, self.target.number)
end

function App:messageTargets()
	local contacts = Persistence.getContacts(self.os.instance.item, self.os.instance.definition.id)
	local out = {}
	for i = 1, #contacts do
		local contact = contacts[i]
		if not isEmergencyNumber(contact.number) then
			out[#out + 1] = contact
		end
	end
	return out
end

function App:send(body)
	body = tostring(body or "")
	if body == "" then return false end
	local to = self.target and self.target.number or "broadcast"
	if isEmergencyNumber(to) then return false end
	Networking.sendMessage(to, body, self.os.instance.number)
	self.smartScrollToBottom = true
	return true
end

function App:appendEmojiToken(token)
	if not self.composeEntry then return end
	local text = tostring(self.composeEntry:getText() or "")
	self.composeEntry:setText(text .. tostring(token or "") .. " ")
	self.composeEntry:focus()
end

function App:drawSmartBackground(display)
	display:clear()
	local smart = self.os.instance.data and self.os.instance.data.smartphone or {}
	local path = smart.themeMode == "light" and SMART_BG_LIGHT or SMART_BG_DARK
	local tex = getTexture(path)
	local bgY = smartBodyY(display)
	local bgH = display.y + display.height - (display.navBarHeight or 0) - bgY
	display:fillRect(display.x, bgY, display.width, bgH, display.colors.bg)
	if tex then
		local tw, th = textureSize(tex)
		local drawAreaH = bgH
		local scale = math.max(display.width / tw, drawAreaH / th)
		local drawW = math.floor(tw * scale)
		local drawH = math.floor(th * scale)
		local drawX = display.x + math.floor((display.width - drawW) / 2)
		local drawY = bgY - smartBackgroundTopCrop(display, drawH, bgH)
		display.panel:drawTextureScaled(tex, drawX, drawY, drawW, drawH, 1, 1, 1, 1)
		if smart.themeMode == "light" then
			display:fillRect(display.x, bgY, display.width, bgH, color(1, 1, 1, 0.16))
		else
			display:fillRect(display.x, bgY, display.width, bgH, color(0, 0, 0, 0.2))
		end
	end
	display:drawStatusBar()
	self:drawSmartHeader(display, nil)
end

function App:drawSmartHeader(display, title)
	local headerY = smartHeaderY(display)
	display:fillRect(display.x, headerY, display.width, SMART_HEADER_H, display.colors.bg)
	display:drawBorder(display.x, headerY + SMART_HEADER_H - 1, display.width, 1, display.colors.border)
	if title then
		display:drawText(display:ellipsize(title, display.width - 28), display.x + 14, headerY + 9, display.colors.fg,
			UIFont.Medium)
	end
end

function App:deleteThread(number)
	number = tostring(number or "")
	if number == "" then return end
	for i = #self.conversations, 1, -1 do
		if tostring(self.conversations[i].peerId or "") == number then
			table.remove(self.conversations, i)
		end
	end
	if self.target and tostring(self.target.number or "") == number then
		self.messages = {}
	end
	Networking.deleteConversation(self.os.instance.number, number)
end

function App:setSmartMessageScroll(value)
	local maxScroll = math.max(0, self.smartMessageScrollMax or 0)
	self.smartMessageScrollTarget = math.max(0, math.min(maxScroll, value or 0))
	self.smartScrollToBottom = false
end

function App:scrollSmartMessages(delta)
	local base = self.smartMessageScrollTarget or self.smartMessageScroll or 0
	self:setSmartMessageScroll(base + delta)
	return true
end

function App:handleInput(event)
	if self.mode == "compose" then
		if event.action == "MOUSE_DOWN" and self.composeEntry then
			self.composeEntry:focus(); return true
		end
		if event.action == "LEFT_SOFT" or event.action == "OK" then
			local text = self.composeEntry and self.composeEntry:getText() or ""
			if self:send(text) then
				self:removeComposeEntry()
				self.mode = "view"
			end
			return true
		end
		if event.action == "RIGHT_SOFT" then
			self:removeComposeEntry(); self.mode = self.target and "view" or "threads"; return true
		end
	elseif self.mode == "view" then
		if self.os.definition.hardwareType ~= "smartphone" then
			self:removeComposeEntry()
		end
		local messages = self:threadMessages()
		if self.os.definition.hardwareType == "smartphone" then
			if event.action == "RIGHT_SOFT" or event.action == "BACK" then
				self:removeComposeEntry()
				self.emojiOpen = false
				self.mode = "threads"
				Networking.fetchMessages(self.os.instance.number)
				return true
			end
			if event.action == "UP" then
				return self:scrollSmartMessages(-30)
			end
			if event.action == "DOWN" then
				return self:scrollSmartMessages(30)
			end
			if event.action == "LEFT_SOFT" then
				local text = self.composeEntry and self.composeEntry:getText() or ""
				if self:send(text) then
					self.composeEntry:setText("")
					self.messageIndex = math.max(1, #self:threadMessages())
				end
				return true
			end
			if event.action == "OK" then
				if self.composeEntry then self.composeEntry:focus() end
				return true
			end
			if event.action == "MOUSE_DOWN" and event.displayX and event.displayY then
				if self.inlineAnswerRect and self.inlineCall
					and event.displayX >= self.inlineAnswerRect.x and event.displayX <= self.inlineAnswerRect.x + self.inlineAnswerRect.w
					and event.displayY >= self.inlineAnswerRect.y and event.displayY <= self.inlineAnswerRect.y + self.inlineAnswerRect.h then
					Networking.answerCall(self.inlineCall.callId, self.os.instance.number)
					self.inlineCall = nil
					return true
				end
				if self.inlineDeclineRect and self.inlineCall
					and event.displayX >= self.inlineDeclineRect.x and event.displayX <= self.inlineDeclineRect.x + self.inlineDeclineRect.w
					and event.displayY >= self.inlineDeclineRect.y and event.displayY <= self.inlineDeclineRect.y + self.inlineDeclineRect.h then
					Networking.declineCall(self.inlineCall.callId, self.os.instance.number, "Declined")
					self.inlineCall = nil
					return true
				end
				for i = 1, #(self.emojiTabRects or {}) do
					local rect = self.emojiTabRects[i]
					if event.displayX >= rect.x and event.displayX <= rect.x + rect.w and event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
						self.emojiCategoryIndex = i
						self.emojiOpen = true
						return true
					end
				end
				if self.emojiOpen and self.emojiPrevRect
					and event.displayX >= self.emojiPrevRect.x and event.displayX <= self.emojiPrevRect.x + self.emojiPrevRect.w
					and event.displayY >= self.emojiPrevRect.y and event.displayY <= self.emojiPrevRect.y + self.emojiPrevRect.h then
					local categories = EmojiRegistry.categories()
					local cat = categories[self.emojiCategoryIndex or 1]
					if cat then
						local perPage = math.max(1, self.emojiPerPage or 1)
						self.emojiScroll[cat.id] = math.max(0, (self.emojiScroll[cat.id] or 0) - perPage)
						return true
					end
				end
				if self.emojiOpen and self.emojiNextRect
					and event.displayX >= self.emojiNextRect.x and event.displayX <= self.emojiNextRect.x + self.emojiNextRect.w
					and event.displayY >= self.emojiNextRect.y and event.displayY <= self.emojiNextRect.y + self.emojiNextRect.h then
					local categories = EmojiRegistry.categories()
					local cat = categories[self.emojiCategoryIndex or 1]
					if cat then
						local perPage = math.max(1, self.emojiPerPage or 1)
						self.emojiScroll[cat.id] = math.min(math.max(0, #cat.files - perPage),
							(self.emojiScroll[cat.id] or 0) + perPage)
						return true
					end
				end
				for i = 1, #(self.emojiRects or {}) do
					local rect = self.emojiRects[i]
					if event.displayX >= rect.x and event.displayX <= rect.x + rect.w and event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
						self:appendEmojiToken(rect.token)
						return true
					end
				end
				if self.smartEmojiButtonRect and event.displayX >= self.smartEmojiButtonRect.x and event.displayX <= self.smartEmojiButtonRect.x + self.smartEmojiButtonRect.w
					and event.displayY >= self.smartEmojiButtonRect.y and event.displayY <= self.smartEmojiButtonRect.y + self.smartEmojiButtonRect.h then
					self.emojiOpen = not self.emojiOpen
					if self.composeEntry then self.composeEntry:focus() end
					return true
				end
				if self.smartSendButtonRect and event.displayX >= self.smartSendButtonRect.x and event.displayX <= self.smartSendButtonRect.x + self.smartSendButtonRect.w
					and event.displayY >= self.smartSendButtonRect.y and event.displayY <= self.smartSendButtonRect.y + self.smartSendButtonRect.h then
					local text = self.composeEntry and self.composeEntry:getText() or ""
					if self:send(text) then
						self.composeEntry:setText("")
						self.messageIndex = math.max(1, #self:threadMessages())
					end
					return true
				end
				if self.smartComposeRect and event.displayX >= self.smartComposeRect.x and event.displayX <= self.smartComposeRect.x + self.smartComposeRect.w
					and event.displayY >= self.smartComposeRect.y and event.displayY <= self.smartComposeRect.y + self.smartComposeRect.h then
					if self.composeEntry then self.composeEntry:focus() end
					return true
				end
				if self.smartMessageScrollbarRect and event.displayX >= self.smartMessageScrollbarRect.x
					and event.displayX <= self.smartMessageScrollbarRect.x + self.smartMessageScrollbarRect.w
					and event.displayY >= self.smartMessageScrollbarRect.y
					and event.displayY <= self.smartMessageScrollbarRect.y + self.smartMessageScrollbarRect.h then
					local rect = self.smartMessageScrollbarRect
					local ratio = (event.displayY - rect.y) / math.max(1, rect.h)
					self:setSmartMessageScroll((self.smartMessageScrollMax or 0) * ratio)
					return true
				end
			end
		end
		if event.action == "UP" then
			if (self.bodyScroll or 0) > 0 then
				self.bodyScroll = self.bodyScroll - 1
			else
				self.messageIndex = math.max(1, self.messageIndex - 1); self.bodyScroll = 0
			end
			return true
		end
		if event.action == "DOWN" then
			if self.bodyLines and self.bodyVisible and (self.bodyScroll or 0) < math.max(0, #self.bodyLines - self.bodyVisible) then
				self.bodyScroll = self.bodyScroll + 1
			else
				self.messageIndex = math.min(math.max(1, #messages), self.messageIndex + 1)
				self.bodyScroll = 0
			end
			return true
		end
		if event.action == "LEFT_SOFT" or event.action == "OK" then
			self.mode = "compose"; return true
		end
		if event.action == "RIGHT" and self.target then
			self:deleteThread(self.target.number); self.mode = "threads"; self.selected = 1; return true
		end
		if event.action == "RIGHT_SOFT" or event.action == "BACK" then
			self.mode = "threads"; Networking.fetchMessages(self.os.instance.number); return true
		end
	elseif self.mode == "target" then
		local contacts = self:messageTargets()
		if event.action == "UP" then
			self.targetIndex = math.max(1, self.targetIndex - 1); return true
		end
		if event.action == "DOWN" then
			self.targetIndex = math.min(math.max(1, #contacts), self.targetIndex + 1); return true
		end
		if event.action == "MOUSE_DOWN" and event.displayY then
			local row = self.targetOffset and
				(self.targetOffset + math.floor((event.displayY - (self.targetTop or 0)) / 20) + 1) or nil
			if row and contacts[row] then
				self.targetIndex = row
				self:openThreadForNumber(contacts[row].number)
				return true
			end
		end
		if (event.action == "LEFT_SOFT" or event.action == "OK") and contacts[self.targetIndex] then
			self:openThreadForNumber(contacts[self.targetIndex].number)
			return true
		end
		if event.action == "RIGHT_SOFT" then
			self.mode = "threads"; return true
		end
	else
		local threads = self:threads()
		self:removeComposeEntry()
		if event.action == "UP" then
			self.selected = math.max(1, self.selected - 1); return true
		end
		if event.action == "DOWN" then
			self.selected = math.min(math.max(1, #threads), self.selected + 1); return true
		end
		if event.action == "MOUSE_DOWN" and event.displayY then
			if self.os.definition.hardwareType == "smartphone" and self.smartThreadRects then
				for i = 1, #self.smartThreadRects do
					local rect = self.smartThreadRects[i]
					if event.displayX >= rect.x and event.displayX <= rect.x + rect.w
						and event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
						self.selected = rect.index
						self:openThreadForNumber(threads[rect.index].number)
						return true
					end
				end
			end
			local row = self.threadOffset and
				(self.threadOffset + math.floor((event.displayY - (self.threadTop or 0)) / 20) + 1) or nil
			if row and threads[row] then
				self.selected = row
				self:openThreadForNumber(threads[row].number)
				return true
			end
		end
		if event.action == "OK" and threads[self.selected] then
			self:openThreadForNumber(threads[self.selected].number); return true
		end
		if event.action == "LEFT_SOFT" then
			self.mode = "target"; self.targetIndex = 1; return true
		end
		if event.action == "RIGHT" and threads[self.selected] then
			self:deleteThread(threads[self.selected].number); self.selected = 1; return true
		end
	end
	return Base.handleInput(self, event)
end

function App:ensureComposeEntry(display, x, y, w, h)
	x = x or display.x + 8
	y = y or display.contentY + 22
	w = w or display.width - 16
	h = h or display.contentBottom - y
	if not self.composeEntry then
		self.composeEntry = ISTextEntryBox:new("", x, y, w, h)
		self.composeEntry:initialise()
		self.composeEntry:instantiate()
		self.composeEntry:setMultipleLine(true)
		self.composeEntry:setMaxTextLength(500)
		if self.os.definition.hardwareType == "smartphone" then
			self.composeEntry.backgroundColor = { r = 0.96, g = 0.97, b = 0.98, a = 1 }
			self.composeEntry.borderColor = { r = 0.18, g = 0.48, b = 0.86, a = 1 }
		else
			self.composeEntry.backgroundColor = { r = 0.05, g = 0.08, b = 0.05, a = 1 }
			self.composeEntry.borderColor = { r = 0.55, g = 0.75, b = 0.45, a = 1 }
		end
		self.composeEntry.font = UIFont.Small
		display.panel:addChild(self.composeEntry)
		self.composeEntry:focus()
	else
		self.composeEntry:setX(x); self.composeEntry:setY(y); self.composeEntry:setWidth(w); self.composeEntry:setHeight(
			h)
	end
	self.composeEntry:setVisible(true)
end

function App:ensureSmartComposeEntry(display)
	local h = 58
	local y = display.contentBottom - h - 8
	local emojiW = 34
	local sendW = 54
	local x = display.x + emojiW + 18
	local w = display.width - emojiW - sendW - 34
	self.smartComposeRect = { x = x - display.x, y = y - display.y, w = w, h = h }
	self.smartEmojiButtonRect = { x = 10, y = y - display.y, w = emojiW, h = h }
	self.smartSendButtonRect = { x = display.width - sendW - 10, y = y - display.y, w = sendW, h = h }
	self:ensureComposeEntry(display, x, y, w, h)
end

function App:wrapTextLines(display, text, maxWidth)
	local lines = {}
	local line = ""
	local raw = tostring(text or "")
	for word in string.gmatch(raw .. " ", "([^ ]*) ") do
		if word == "" then
			local candidate = line == "" and " " or (line .. " ")
			if display:measureText(candidate) <= maxWidth then
				line = candidate
			end
		else
			local part = word
			while display:measureText(part) > maxWidth and #part > 1 do
				local chunk = ""
				for c = 1, #part do
					local candidate = chunk .. string.sub(part, c, c)
					if display:measureText(candidate) > maxWidth then
						break
					end
					chunk = candidate
				end
				if line ~= "" then
					table.insert(lines, line)
					line = ""
				end
				table.insert(lines, chunk)
				part = string.sub(part, #chunk + 1)
			end
			local candidate = line == "" and part or (line .. " " .. part)
			if display:measureText(candidate) > maxWidth and line ~= "" then
				table.insert(lines, line)
				line = part
			else
				line = candidate
			end
		end
	end
	if line ~= "" then table.insert(lines, line) end
	if #lines == 0 then table.insert(lines, "") end
	return lines
end

function App:drawSmartComposeEntry(display)
	if not self.composeEntry or not self.smartComposeRect then return end
	local rect = self.smartComposeRect
	local x = display.x + rect.x
	local y = display.y + rect.y
	display:fillRect(x, y, rect.w, rect.h, display.colors.bg)
	display:drawBorder(x, y, rect.w, rect.h,
		self.composeEntry:isFocused() and display.colors.accent or display.colors.border)
	local text = tostring(self.composeEntry:getText() or "")
	if self.composeEntry:isFocused() and (not getTimestampMs or math.floor(getTimestampMs() / 500) % 2 == 0) then
		text = text .. "|"
	end
	local lines = self:wrapTextLines(display, text, rect.w - 10)
	local maxLines = math.max(1, math.floor((rect.h - 8) / 15))
	local first = math.max(1, #lines - maxLines + 1)
	local yy = y + 5
	for i = first, #lines do
		if yy <= y + rect.h - 13 then
			display:drawText(lines[i], x + 5, yy, display.colors.fg)
			yy = yy + 15
		end
	end
end

function App:drawComposeEntry(display)
	if not self.composeEntry then return end
	local x, y = display.x + 8, display.contentY + 22
	local w, h = display.width - 16, display.contentBottom - y
	display:fillRect(x, y, w, h, display.colors.bg)
	display:drawBorder(x, y, w, h, self.composeEntry:isFocused() and display.colors.fg or display.colors.dim)
	local yy, line = y + 4, ""
	local rawText = tostring(self.composeEntry:getText() or "")
	if self.composeEntry:isFocused() and (not getTimestampMs or math.floor(getTimestampMs() / 500) % 2 == 0) then
		rawText = rawText .. "|"
	end
	for word in string.gmatch(rawText .. " ", "([^ ]*) ") do
		local candidate = line == "" and word or (line .. " " .. word)
		if display:measureText(candidate) > w - 8 then
			display:drawText(line, x + 4, yy, display.colors.fg); yy = yy + 15; line = word
		else
			line = candidate
		end
		if yy > y + h - 15 then break end
	end
	if line ~= "" and yy <= y + h - 8 then display:drawText(line, x + 4, yy, display.colors.fg) end
end

function App:messageLines(display, body, maxWidth)
	local lines = { { runs = {}, width = 0 } }
	local function currentLine()
		return lines[#lines]
	end
	local function pushLine()
		if #currentLine().runs > 0 then
			table.insert(lines, { runs = {}, width = 0 })
		end
	end
	local function addRun(run)
		local line = currentLine()
		table.insert(line.runs, run)
		line.width = line.width + run.w
	end
	local function addTextToken(token)
		local remaining = tostring(token or "")
		while remaining ~= "" do
			local line = currentLine()
			local available = maxWidth - line.width
			if available <= 0 then
				pushLine()
				line = currentLine()
				available = maxWidth
			end
			local width = display:measureText(remaining)
			if width <= available then
				addRun({ kind = "text", text = remaining, w = width })
				remaining = ""
			elseif width <= maxWidth and line.width > 0 then
				pushLine()
			else
				local chunk = nextTextChunk(display, remaining, available)
				if chunk == "" then
					pushLine()
				else
					addRun({ kind = "text", text = chunk, w = display:measureText(chunk) })
					remaining = string.sub(remaining, #chunk + 1)
					if remaining ~= "" then pushLine() end
				end
			end
		end
	end
	local parts = EmojiRegistry.parts(body)
	for p = 1, #parts do
		local part = parts[p]
		if part.kind == "emoji" then
			if currentLine().width + 18 > maxWidth and currentLine().width > 0 then
				pushLine()
			end
			addRun({ kind = "emoji", path = part.path, w = 18 })
		else
			local text = tostring(part.text or "")
			for token in string.gmatch(text, "%S+%s*") do
				addTextToken(token)
			end
		end
	end
	if #lines > 1 and #currentLine().runs == 0 then
		table.remove(lines, #lines)
	end
	return lines
end

function App:maxLineWidth(lines)
	local width = 0
	for i = 1, #lines do
		width = math.max(width, lines[i].width or 0)
	end
	return width
end

function App:drawMessageLines(display, lines, x, y, color, clipTop, clipBottom)
	for i = 1, #lines do
		local lineY = y + (i - 1) * SMART_MESSAGE_LINE_H
		if lineY >= clipTop and lineY + SMART_MESSAGE_LINE_H <= clipBottom then
			local cursorX = x
			local runs = lines[i].runs
			for r = 1, #runs do
				local run = runs[r]
				if run.kind == "emoji" then
					local tex = getTexture(run.path)
					if tex then
						display.panel:drawTextureScaledAspect(tex, cursorX, lineY, 15, 15, 1, 1, 1, 1)
					else
						display:drawText("?", cursorX, lineY, color)
					end
				else
					display:drawText(run.text, cursorX, lineY, color)
				end
				cursorX = cursorX + run.w
			end
		end
	end
end

function App:drawClippedRect(display, x, y, w, h, rectColor, clipTop, clipBottom)
	local yy = math.max(y, clipTop)
	local bottom = math.min(y + h, clipBottom)
	if bottom > yy then
		display:fillRect(x, yy, w, bottom - yy, rectColor)
	end
end

function App:drawMessagePreview(display, body, x, y, maxWidth, color)
	local cursorX = x
	local right = x + maxWidth
	local ellipsisW = display:measureText("...")
	local parts = EmojiRegistry.parts(body)
	for p = 1, #parts do
		local part = parts[p]
		if part.kind == "emoji" then
			if cursorX + 18 > right then
				if cursorX + ellipsisW <= right then display:drawText("...", cursorX, y, color) end
				return
			end
			local tex = getTexture(part.path)
			if tex then
				display.panel:drawTextureScaledAspect(tex, cursorX, y - 1, 15, 15, 1, 1, 1, 1)
			else
				display:drawText("?", cursorX, y, color)
			end
			cursorX = cursorX + 18
		else
			local text = string.gsub(tostring(part.text or ""), "%s+", " ")
			if text ~= "" then
				local remainingW = right - cursorX
				if display:measureText(text) <= remainingW then
					display:drawText(text, cursorX, y, color)
					cursorX = cursorX + display:measureText(text)
				elseif remainingW > ellipsisW then
					display:drawText(display:ellipsize(text, remainingW), cursorX, y, color)
					return
				else
					return
				end
			end
		end
	end
end

function App:drawMessageContent(display, body, x, y, maxWidth, color)
	local cursorX = x
	local cursorY = y
	local lineH = 16
	local parts = EmojiRegistry.parts(body)
	for p = 1, #parts do
		local part = parts[p]
		if part.kind == "emoji" then
			if cursorX + 16 > x + maxWidth then
				cursorX = x
				cursorY = cursorY + lineH
			end
			local tex = getTexture(part.path)
			if tex then
				display.panel:drawTextureScaledAspect(tex, cursorX, cursorY - 1, 15, 15, 1, 1, 1, 1)
			else
				display:drawText("?", cursorX, cursorY, color)
			end
			cursorX = cursorX + 18
		else
			for word in string.gmatch(tostring(part.text or "") .. " ", "([^ ]*) ") do
				local text = word .. " "
				local tw = display:measureText(text)
				if tw > maxWidth then
					if cursorX > x then
						cursorX = x
						cursorY = cursorY + lineH
					end
					local remaining = text
					while remaining ~= "" do
						local chunk = nextTextChunk(display, remaining, maxWidth)
						display:drawText(chunk, cursorX, cursorY, color)
						remaining = string.sub(remaining, #chunk + 1)
						if remaining ~= "" then
							cursorX = x
							cursorY = cursorY + lineH
						else
							cursorX = cursorX + display:measureText(chunk)
						end
					end
				elseif cursorX + tw > x + maxWidth then
					cursorX = x
					cursorY = cursorY + lineH
					display:drawText(text, cursorX, cursorY, color)
					cursorX = cursorX + tw
				else
					display:drawText(text, cursorX, cursorY, color)
					cursorX = cursorX + tw
				end
			end
		end
	end
	return cursorY + lineH - y
end

function App:messageContentSize(display, body, maxWidth)
	local cursorX = 0
	local lines = 1
	local parts = EmojiRegistry.parts(body)
	for p = 1, #parts do
		local part = parts[p]
		if part.kind == "emoji" then
			if cursorX + 18 > maxWidth then
				cursorX = 0; lines = lines + 1
			end
			cursorX = cursorX + 18
		else
			for word in string.gmatch(tostring(part.text or "") .. " ", "([^ ]*) ") do
				local text = word .. " "
				local tw = display:measureText(text)
				if tw > maxWidth then
					if cursorX > 0 then
						cursorX = 0; lines = lines + 1
					end
					local remaining = text
					while remaining ~= "" do
						local chunk = nextTextChunk(display, remaining, maxWidth)
						remaining = string.sub(remaining, #chunk + 1)
						if remaining ~= "" then
							cursorX = 0
							lines = lines + 1
						else
							cursorX = display:measureText(chunk)
						end
					end
				else
					if cursorX + tw > maxWidth then
						cursorX = 0; lines = lines + 1
					end
					cursorX = cursorX + tw
				end
			end
		end
	end
	return lines * 16
end

function App:plainTextWidth(display, body)
	local width = 0
	local current = 0
	local parts = EmojiRegistry.parts(body)
	for p = 1, #parts do
		local part = parts[p]
		if part.kind == "emoji" then
			current = current + 18
		else
			local text = tostring(part.text or "")
			width = math.max(width, display:measureText(text))
			current = current + display:measureText(text)
		end
	end
	return math.max(width, current)
end

function App:renderEmojiPicker(display, bottomY)
	self.emojiRects = {}
	self.emojiTabRects = {}
	self.emojiPrevRect = nil
	self.emojiNextRect = nil
	if not self.emojiOpen then return bottomY end
	local categories = EmojiRegistry.categories()
	self.emojiCategoryIndex = math.max(1, math.min(#categories, self.emojiCategoryIndex or 1))
	local panelH = 102
	local panelY = bottomY - panelH - 6
	self.lastDisplayWidth = display.width
	local panelX = display.x + 8
	local panelW = display.width - 16
	display:fillRect(panelX, panelY, panelW, panelH, display.colors.bg)
	display:drawBorder(panelX, panelY, panelW, panelH, display.colors.border)
	local tabW = math.floor(panelW / #categories)
	for i = 1, #categories do
		local x = 8 + (i - 1) * tabW
		local selected = i == self.emojiCategoryIndex
		display:fillRect(display.x + x, panelY, tabW, 22, selected and display.colors.accent or display.colors.bg)
		display:drawBorder(display.x + x, panelY, tabW, 22, display.colors.border)
		local tabTex = getTexture(EmojiRegistry.path(categories[i].id, categories[i].icon))
		if tabTex then
			display.panel:drawTextureScaledAspect(tabTex, display.x + x + math.floor((tabW - 16) / 2), panelY + 3, 16, 16,
				1, 1, 1, 1)
		else
			display:drawTextCentered(string.sub(I18N.get(categories[i].labelKey), 1, 2), panelY + 4,
				selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.dim, UIFont.Small, display.x + x,
				display.x + x + tabW)
		end
		self.emojiTabRects[i] = { x = x, y = panelY - display.y, w = tabW, h = 22 }
	end
	local cat = categories[self.emojiCategoryIndex]
	local icon = 22
	local gap = 6
	local arrowW = 24
	local gridX = panelX + arrowW + 8
	local gridY = panelY + 32
	local gridW = panelW - arrowW * 2 - 16
	local cols = math.max(1, math.floor(gridW / (icon + gap)))
	local rows = 2
	local perPage = cols * rows
	self.emojiPerPage = perPage
	self.emojiScroll[cat.id] = self.emojiScroll[cat.id] or 0
	local offset = math.max(0, math.min(self.emojiScroll[cat.id], math.max(0, #cat.files - perPage)))
	local arrowY = panelY + 33
	local arrowH = panelH - 38
	self.emojiPrevRect = { x = 10, y = arrowY - display.y, w = arrowW, h = arrowH }
	self.emojiNextRect = { x = display.width - arrowW - 10, y = arrowY - display.y, w = arrowW, h = arrowH }
	display:drawBorder(display.x + self.emojiPrevRect.x, arrowY, arrowW, arrowH, display.colors.border)
	display:drawBorder(display.x + self.emojiNextRect.x, arrowY, arrowW, arrowH, display.colors.border)
	display:drawTextCentered("<", arrowY + math.floor((arrowH - 16) / 2),
		offset > 0 and display.colors.fg or display.colors.dim,
		UIFont.Medium, display.x + self.emojiPrevRect.x, display.x + self.emojiPrevRect.x + arrowW)
	display:drawTextCentered(">", arrowY + math.floor((arrowH - 16) / 2),
		offset + perPage < #cat.files and display.colors.fg or display.colors.dim,
		UIFont.Medium, display.x + self.emojiNextRect.x, display.x + self.emojiNextRect.x + arrowW)
	for i = offset + 1, math.min(#cat.files, offset + perPage) do
		local visible = i - offset
		local col = (visible - 1) % cols
		local row = math.floor((visible - 1) / cols)
		local x = gridX + col * (icon + gap)
		local y = gridY + row * (icon + gap)
		local path = EmojiRegistry.path(cat.id, cat.files[i])
		local tex = getTexture(path)
		if tex then display.panel:drawTextureScaledAspect(tex, x, y, icon, icon, 1, 1, 1, 1) end
		table.insert(self.emojiRects, {
			x = x - display.x,
			y = y - display.y,
			w = icon,
			h = icon,
			token = EmojiRegistry.token(cat.id, cat.files[i]),
		})
	end
	return panelY
end

function App:renderTargets(display)
	self:removeComposeEntry()
	display:clear()
	display:drawHeader(I18N.get("SendTo"))
	local contacts = self:messageTargets()
	self.targetIndex = math.max(1, math.min(math.max(1, #contacts), self.targetIndex or 1))
	local top, visibleRows, contentRight, hasScrollbar = display:getVisibleListMetrics(20, #contacts)
	local offset = math.max(0, math.min(self.targetIndex - visibleRows, math.max(0, #contacts - visibleRows)))
	self.targetTop = top - display.y
	self.targetOffset = offset
	for i = offset + 1, math.min(#contacts, offset + visibleRows) do
		local c = contacts[i]
		local y = top + (i - offset - 1) * 20
		if i == self.targetIndex then
			display:fillRect(display.x + 4, y - 1, contentRight - display.x - 4, 18,
				display.colors.accent)
		end
		display:drawText(display:ellipsize(tostring(c.name or c.number), contentRight - display.x - 12), display.x + 8, y,
			i == self.targetIndex and display.colors.bg or display.colors.fg)
	end
	if #contacts == 0 then display:drawText(I18N.get("NoContacts"), display.x + 12, top, display.colors.dim) end
	if hasScrollbar then display:drawScrollbar(#contacts, visibleRows, offset, top, display.contentBottom) end
	display:drawFooter(I18N.get("Select"), I18N.get("Back"))
end

function App:renderSmartThreads(display)
	self:removeComposeEntry()
	self:drawSmartBackground(display)
	self:drawSmartHeader(display, I18N.app("messages"))
	local threads = self:threads()
	local avatar = getTexture(AVATAR_TEXTURE)
	local rowTop = smartBodyY(display) + 6
	local rowH = 58
	local visibleRows = math.max(1, math.floor((display.contentBottom - rowTop - 4) / rowH))
	local offset = math.max(0, math.min(self.selected - visibleRows, math.max(0, #threads - visibleRows)))
	self.threadTop = rowTop - display.y
	self.threadOffset = offset
	self.smartThreadRects = {}
	for i = offset + 1, math.min(#threads, offset + visibleRows) do
		local thread = threads[i]
		local y = rowTop + (i - offset - 1) * rowH
		local selected = i == self.selected
		display:fillRect(display.x + 10, y, display.width - 20, rowH - 7,
			selected and display.colors.accent or display.colors.bg)
		display:drawBorder(display.x + 10, y, display.width - 20, rowH - 7,
			selected and display.colors.fg or display.colors.border)
		if avatar then
			display.panel:drawTextureScaledAspect(avatar, display.x + 18, y + 9, 34, 34, 1, 1, 1, 1)
		end
		local textColor = selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.fg
		display:drawText(display:ellipsize(self:contactName(thread.number), display.width - 100), display.x + 60, y + 8,
			textColor)
		self:drawMessagePreview(display, thread.last and thread.last.body or "", display.x + 60, y + 29,
			display.width - 118, selected and { r = 0.9, g = 0.94, b = 1, a = 1 } or display.colors.dim)
		display:drawTextRight(tostring(thread.count), display.x + display.width - 18, y + 8, textColor)
		table.insert(self.smartThreadRects,
			{ x = 10, y = y - display.y, w = display.width - 20, h = rowH - 7, index = i })
	end
	if #threads == 0 then display:drawText(I18N.get("NoMessages"), display.x + 14, rowTop + 20, display.colors.dim) end
	display:drawFooter(I18N.get("New"), I18N.get("Back"))
end

function App:smartMessageLayouts(display, messages, maxBubble)
	local layouts = {}
	local totalH = 0
	for i = 1, #messages do
		local msg = messages[i]
		local own = tostring(msg.from) == tostring(self.os.instance.number)
		local dateW = display:measureText(tostring(msg.time or ""), UIFont.Small) + 18
		local lines = self:messageLines(display, msg.body, maxBubble - 16)
		local contentH = #lines * SMART_MESSAGE_LINE_H
		local bubbleH = math.max(44, contentH + 28)
		local bubbleW = math.max(44, dateW)
		bubbleW = math.max(bubbleW, math.min(maxBubble, self:maxLineWidth(lines) + 16))
		bubbleW = math.min(maxBubble, bubbleW)
		table.insert(layouts, {
			msg = msg,
			own = own,
			w = bubbleW,
			h = bubbleH,
			lines = lines,
			y = totalH,
		})
		totalH = totalH + bubbleH + 8
	end
	return layouts, math.max(0, totalH - 8)
end

function App:renderThreads(display)
	if self.os.definition.hardwareType == "smartphone" then
		return self:renderSmartThreads(display)
	end
	self:removeComposeEntry()
	display:clear()
	display:drawHeader(I18N.app("messages"))
	local threads = self:threads()
	local top, visibleRows, contentRight, hasScrollbar = display:getVisibleListMetrics(20, #threads)
	local offset = math.max(0, math.min(self.selected - visibleRows, math.max(0, #threads - visibleRows)))
	self.threadTop = top - display.y
	self.threadOffset = offset
	for i = offset + 1, math.min(#threads, offset + visibleRows) do
		local thread = threads[i]
		local y = top + (i - offset - 1) * 20
		if i == self.selected then
			display:fillRect(display.x + 4, y - 1, contentRight - display.x - 4, 18,
				display.colors.accent)
		end
		local color = i == self.selected and display.colors.bg or display.colors.fg
		local label = self:contactName(thread.number) .. " (" .. tostring(thread.count) .. ")"
		display:drawText(display:ellipsize(label, contentRight - display.x - 12), display.x + 8, y, color)
	end
	if #threads == 0 then display:drawText(I18N.get("NoMessages"), display.x + 12, top, display.colors.dim) end
	if hasScrollbar then display:drawScrollbar(#threads, visibleRows, offset, top, display.contentBottom) end
	display:drawFooter(I18N.get("New"), I18N.get("Back"))
end

function App:renderSmartView(display)
	self:drawSmartBackground(display)
	local title = self:contactName(self.target and self.target.number)
	self:ensureSmartComposeEntry(display)
	local messages = self:threadMessages()
	local listTop = smartBodyY(display) + 5
	self.inlineAnswerRect = nil
	self.inlineDeclineRect = nil
	if self.inlineCall then
		local bannerX = display.x + 10
		local bannerY = listTop
		local bannerW = display.width - 20
		local bannerH = 42
		display:fillRect(bannerX, bannerY, bannerW, bannerH, display.colors.bg)
		display:drawBorder(bannerX, bannerY, bannerW, bannerH, display.colors.accent)
		display:drawText(display:ellipsize(I18N.get("IncomingContact", title), bannerW - 116), bannerX + 8, bannerY + 7,
			display.colors.fg)
		local buttonW = 48
		self.inlineAnswerRect = { x = bannerX + bannerW - buttonW * 2 - 12 - display.x, y = bannerY + 8 - display.y, w = buttonW, h = 26 }
		self.inlineDeclineRect = { x = bannerX + bannerW - buttonW - 6 - display.x, y = bannerY + 8 - display.y, w = buttonW, h = 26 }
		display:fillRect(display.x + self.inlineAnswerRect.x, display.y + self.inlineAnswerRect.y, buttonW, 26,
			color(0.15, 0.62, 0.28, 1))
		display:fillRect(display.x + self.inlineDeclineRect.x, display.y + self.inlineDeclineRect.y, buttonW, 26,
			color(0.75, 0.16, 0.14, 1))
		display:drawTextCentered(I18N.get("Answer"), display.y + self.inlineAnswerRect.y + 8,
			{ r = 1, g = 1, b = 1, a = 1 }, UIFont.Small, display.x + self.inlineAnswerRect.x,
			display.x + self.inlineAnswerRect.x + buttonW)
		display:drawTextCentered(I18N.get("Decline"), display.y + self.inlineDeclineRect.y + 8,
			{ r = 1, g = 1, b = 1, a = 1 }, UIFont.Small, display.x + self.inlineDeclineRect.x,
			display.x + self.inlineDeclineRect.x + buttonW)
		listTop = listTop + bannerH + 6
	end
	local listBottom = display.y + self.smartComposeRect.y - 8
	local listH = math.max(1, listBottom - listTop)
	local maxBubble = math.floor(display.width * 0.72)
	local layouts, totalH = self:smartMessageLayouts(display, messages, maxBubble)
	self.smartMessageScrollMax = math.max(0, totalH - listH)
	if self.smartScrollToBottom or self.smartMessageScrollTarget == nil or self.smartMessageScroll == nil then
		self.smartMessageScrollTarget = self.smartMessageScrollMax
		self.smartMessageScroll = self.smartMessageScrollMax
		self.smartScrollToBottom = false
	else
		self.smartMessageScrollTarget = math.max(0, math.min(self.smartMessageScrollMax, self.smartMessageScrollTarget))
		self.smartMessageScroll = math.max(0, math.min(self.smartMessageScrollMax, self.smartMessageScroll))
		local diff = self.smartMessageScrollTarget - self.smartMessageScroll
		if math.abs(diff) < 0.5 then
			self.smartMessageScroll = self.smartMessageScrollTarget
		else
			self.smartMessageScroll = self.smartMessageScroll + diff * 0.35
		end
	end
	local scrollY = math.floor((self.smartMessageScroll or 0) + 0.5)
	for i = 1, #layouts do
		local item = layouts[i]
		local y = listTop + item.y - scrollY
		if y + item.h >= listTop and y <= listBottom then
			local x = item.own and (display.x + display.width - item.w - 14) or (display.x + 14)
			self:drawClippedRect(display, x, y, item.w, item.h, item.own and display.colors.accent or display.colors.bg,
				listTop, listBottom)
			if y >= listTop and y + item.h <= listBottom then
				display:drawBorder(x, y, item.w, item.h, item.own and display.colors.accent or display.colors.border)
			end
			self:drawMessageLines(display, item.lines, x + 8, y + 7,
				item.own and { r = 1, g = 1, b = 1, a = 1 } or display.colors.fg, listTop, listBottom)
			local dateY = y + item.h - 15
			if dateY >= listTop and dateY + 12 <= listBottom then
				display:drawText(tostring(item.msg.time or ""), x + 8, dateY,
					item.own and { r = 0.9, g = 0.94, b = 1, a = 1 } or display.colors.dim)
			end
		end
	end
	self.smartMessageScrollbarRect = nil
	if self.smartMessageScrollMax > 0 then
		local trackX = display.width - 7
		local thumbH = math.max(18, math.floor(listH * (listH / math.max(listH, totalH))))
		local travel = math.max(1, listH - thumbH)
		local thumbY = listTop +
			math.floor(travel * (self.smartMessageScroll or 0) / math.max(1, self.smartMessageScrollMax))
		display:fillRect(display.x + trackX, listTop, 3, listH,
			color(display.colors.dim.r, display.colors.dim.g, display.colors.dim.b, 0.32))
		display:fillRect(display.x + trackX, thumbY, 3, thumbH, display.colors.accent)
		self.smartMessageScrollbarRect = { x = trackX - 4, y = listTop - display.y, w = 11, h = listH }
	end
	if #messages == 0 then display:drawText(I18N.get("NoMessages"), display.x + 14, listTop + 20, display.colors.dim) end
	self:drawSmartHeader(display, title)
	display:fillRect(display.x + self.smartEmojiButtonRect.x, display.y + self.smartEmojiButtonRect.y,
		self.smartEmojiButtonRect.w, self.smartEmojiButtonRect.h, display.colors.bg)
	display:drawBorder(display.x + self.smartEmojiButtonRect.x, display.y + self.smartEmojiButtonRect.y,
		self.smartEmojiButtonRect.w, self.smartEmojiButtonRect.h, display.colors.border)
	display:drawTextCentered(":)", display.y + self.smartEmojiButtonRect.y + 22, display.colors.accent, UIFont.Small,
		display.x + self.smartEmojiButtonRect.x, display.x + self.smartEmojiButtonRect.x + self.smartEmojiButtonRect.w)
	display:fillRect(display.x + self.smartSendButtonRect.x, display.y + self.smartSendButtonRect.y,
		self.smartSendButtonRect.w, self.smartSendButtonRect.h, display.colors.accent)
	display:drawTextCentered(I18N.get("Send"), display.y + self.smartSendButtonRect.y + 22,
		{ r = 1, g = 1, b = 1, a = 1 },
		UIFont.Small, display.x + self.smartSendButtonRect.x,
		display.x + self.smartSendButtonRect.x + self.smartSendButtonRect.w)
	self:drawSmartComposeEntry(display)
	self:renderEmojiPicker(display, display.y + self.smartComposeRect.y)
	display:drawFooter(I18N.get("Send"), I18N.get("Back"))
end

function App:renderView(display)
	if self.os.definition.hardwareType == "smartphone" then
		return self:renderSmartView(display)
	end
	self:removeComposeEntry()
	display:clear()
	display:drawHeader(self:contactName(self.target and self.target.number))
	local messages = self:threadMessages()
	local msg = messages[self.messageIndex]
	local top, right = display.contentY, display.contentRight
	if msg then
		local prefix = tostring(msg.from) == tostring(self.os.instance.number) and I18N.get("Me") or I18N.get("Them")
		display:drawText(prefix .. "  " .. tostring(msg.time or ""), display.x + 8, top, display.colors.dim)
		local lines, line = {}, ""
		for word in string.gmatch(tostring(msg.body or "") .. " ", "([^ ]*) ") do
			local candidate = line == "" and word or (line .. " " .. word)
			if display:measureText(candidate) > right - display.x - 16 then
				table.insert(lines, line)
				line = word
			else
				line = candidate
			end
		end
		if line ~= "" then table.insert(lines, line) end
		self.bodyLines = lines
		self.bodyVisible = math.max(1, math.floor((display.contentBottom - (top + 18)) / 15))
		self.bodyScroll = math.max(0, math.min(self.bodyScroll or 0, math.max(0, #lines - self.bodyVisible)))
		local y = top + 18
		for i = self.bodyScroll + 1, math.min(#lines, self.bodyScroll + self.bodyVisible) do
			display:drawText(lines[i], display.x + 8, y, display.colors.fg)
			y = y + 15
		end
		display:drawTextRight(tostring(self.messageIndex) .. "/" .. tostring(#messages), right - 2,
			display.contentBottom - 14, display.colors.dim)
	else
		display:drawText(I18N.get("NoMessages"), display.x + 12, top, display.colors.dim)
	end
	display:drawFooter(I18N.get("Reply"), I18N.get("Back"))
end

function App:renderCompose(display)
	display:clear()
	display:drawHeader(I18N.get("SendMessage"))
	display:drawText(I18N.get("ToLabel", self:contactName(self.target and self.target.number)), display.x + 8,
		display.contentY, display.colors.fg)
	self:ensureComposeEntry(display)
	self:drawComposeEntry(display)
	display:drawFooter(I18N.get("Send"), I18N.get("Cancel"))
end

function App:render(display)
	if self.mode == "compose" then return self:renderCompose(display) end
	if self.mode == "target" then return self:renderTargets(display) end
	if self.mode == "view" then return self:renderView(display) end
	return self:renderThreads(display)
end

return App
