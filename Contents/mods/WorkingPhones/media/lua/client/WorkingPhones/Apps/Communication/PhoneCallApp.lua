local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local Networking = require("WorkingPhones/Core/PhoneNetworking")
local Persistence = require("WorkingPhones/Core/PhonePersistence")
local PhoneUtils = require("WorkingPhones/Core/PhoneUtils")
local I18N = require("WorkingPhones/Core/PhoneI18N")
local Common = require("WorkingPhones/Common/PhoneCommon")
local Assets = require("WorkingPhones/Assets/PhoneAssets")
local App = setmetatable({}, { __index = Base })
App.__index = App
local AVATAR_TEXTURE = Assets.SMARTPHONE_AVATARS .. "ui_working_smartphone_avatar_default.png"

local function tr(key, ...)
	return I18N.get(key, ...)
end

local function reasonText(reason)
	reason = tostring(reason or "CallEnded")
	if reason == "Hung up" then
		reason = "HungUp"
	end
	return tr(reason)
end

function App:new(os)
	local o = Base.new(self, os)
	o.id = "phone"
	o.name = I18N.app("phone")
	o.status = tr("Ready")
	o.selected = 1
	o.scrollOffset = 0
	o.calling = nil
	o.activeCall = os.instance.data.activeCall
	o.mode = "contacts"
	o.confirmContact = nil
	o.hangRect = nil
	o.confirmCallRect = nil
	o.confirmCancelRect = nil
	o.history = os.instance.data.callHistory or {}
	return o
end

local function gameDateTime()
	return PhoneUtils.gameDateTime()
end

function App:contactLabel(number)
	local contacts = Persistence.getContacts(self.os.instance.item, self.os.instance.definition.id)
	for i = 1, #contacts do
		local contact = contacts[i]
		if tostring(contact.number) == tostring(number) then
			return tostring(contact.name or number) .. " (" .. tostring(number) .. ")"
		end
	end
	return tostring(number or tr("Unknown"))
end

function App:save()
	self.os.instance.data.callHistory = self.history
end

function App:addHistory(contact, callType, result)
	table.insert(self.history, 1, {
		name = contact and contact.name or tr("Unknown"),
		number = contact and contact.number or tr("Unknown"),
		type = callType or tr("Outgoing"),
		result = result or tr("Ringing"),
		date = gameDateTime(),
	})
	Common.trimList(self.history, Common.callHistoryLimit())
	self:save()
end

function App:call(contact)
	if not contact then
		self.status = tr("NoContactSelected")
		return
	end
	self.calling = contact
	self.confirmContact = nil
	self.mode = "contacts"
	self.status = tr("CallingContact", tostring(contact.name or contact.number or tr("Unknown")))
	self:addHistory(contact, tr("Outgoing"), tr("Ringing"))
	Networking.requestCall(contact.number, self.os.instance.number)
end

function App:hangup()
	local active = self.os.instance.data.activeCall
	if active and active.callId then
		Networking.hangupCall(active.callId, self.os.instance.number, "HungUp")
	elseif self.calling then
		Networking.hangupCall(nil, self.os.instance.number, "HungUp")
	end
	if self.calling and self.history[1] then
		self.history[1].result = tr("HungUp")
		self.history[1].date = gameDateTime()
		self:save()
	end
	self.calling = nil
	self.os.instance.data.activeCall = nil
	self.activeCall = nil
	self.status = tr("Ready")
end

function App:showIncoming(fromNumber)
	self.mode = "history"
	self.status = tr("IncomingContact", tostring(fromNumber or tr("Unknown")))
	self.selected = 1
end

function App:onCallRinging(args)
	self.os.instance.data.activeCall = {
		callId = args.callId,
		targetNumber = tostring(args.targetNumber or ""),
		state = "ringing",
	}
	self.status = tr("RingingContact", self:contactLabel(args.targetNumber))
end

function App:onCallAnswered(args)
	self.os.instance.data.activeCall = {
		callId = args.callId,
		targetNumber = tostring(args.targetNumber or ""),
		state = "connected",
	}
	if self.history[1] then
		self.history[1].result = tr("Answered")
		self.history[1].date = gameDateTime()
		self:save()
	end
	self.status = tr("OnCallWith", self:contactLabel(args.targetNumber))
end

function App:onCallConnected(args)
	self.os.instance.data.activeCall = {
		callId = args.callId,
		fromNumber = tostring(args.fromNumber or ""),
		state = "connected",
	}
	self.status = tr("OnCallWith", self:contactLabel(args.fromNumber))
end

function App:onCallRejected(args)
	if self.history[1] then
		self.history[1].result = reasonText(args.reason or "Declined")
		self.history[1].date = gameDateTime()
		self:save()
	end
	self.calling = nil
	self.status = reasonText(args.reason or "CallEnded")
end

function App:onCallEnded(args)
	if self.history[1] then
		self.history[1].result = reasonText(args.reason or "Ended")
		self.history[1].date = gameDateTime()
		self:save()
	end
	self.calling = nil
	self.status = reasonText(args.reason or "CallEnded")
end

function App:handleInput(event)
	local contacts = Persistence.getContacts(self.os.instance.item, self.os.instance.definition.id)
	if self.calling or (self.os.instance.data.activeCall and self.os.instance.data.activeCall.state == "connected") then
		if event.action == "MOUSE_DOWN" and self.hangRect and event.displayX and event.displayY
			and event.displayX >= self.hangRect.x and event.displayX <= self.hangRect.x + self.hangRect.w
			and event.displayY >= self.hangRect.y and event.displayY <= self.hangRect.y + self.hangRect.h then
			self:hangup()
			return true
		end
		if event.action == "LEFT_SOFT" or event.action == "RIGHT_SOFT" or event.action == "OK" then self:hangup(); return true end
		return Base.handleInput(self, event)
	end
	if self.mode == "confirm" then
		if event.action == "MOUSE_DOWN" and event.displayX and event.displayY then
			if self.confirmCallRect and event.displayX >= self.confirmCallRect.x and event.displayX <= self.confirmCallRect.x + self.confirmCallRect.w
				and event.displayY >= self.confirmCallRect.y and event.displayY <= self.confirmCallRect.y + self.confirmCallRect.h then
				self:call(self.confirmContact)
				return true
			end
			if self.confirmCancelRect and event.displayX >= self.confirmCancelRect.x and event.displayX <= self.confirmCancelRect.x + self.confirmCancelRect.w
				and event.displayY >= self.confirmCancelRect.y and event.displayY <= self.confirmCancelRect.y + self.confirmCancelRect.h then
				self.confirmContact = nil
				self.mode = "contacts"
				return true
			end
		end
		if event.action == "LEFT_SOFT" or event.action == "OK" then
			self:call(self.confirmContact)
			return true
		end
		if event.action == "RIGHT_SOFT" or event.action == "BACK" then
			self.confirmContact = nil
			self.mode = "contacts"
			return true
		end
		return true
	end
	if event.action == "LEFT_SOFT" then self.mode = self.mode == "contacts" and "history" or "contacts"; self.selected = 1; return true end
	local list = self.mode == "history" and self.history or contacts
	if event.action == "UP" then self.selected = math.max(1, self.selected - 1); return true end
	if event.action == "DOWN" then self.selected = math.min(math.max(1, #list), self.selected + 1); return true end
	if event.action == "MOUSE_DOWN" and event.displayY then
		if self.os.definition.hardwareType == "smartphone" and self.smartRowRects then
			for i = 1, #self.smartRowRects do
				local rect = self.smartRowRects[i]
				if event.displayX >= rect.x and event.displayX <= rect.x + rect.w
					and event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
					self.selected = rect.index
					if self.mode == "contacts" then self.confirmContact = list[rect.index]; self.mode = "confirm" end
					return true
				end
			end
		end
		local rowTop = self.lastRowTop or 0
		local row = self.scrollOffset + math.floor((event.displayY - rowTop) / 20) + 1
		if list[row] then
			self.selected = row
			if self.mode == "contacts" then self.confirmContact = list[row]; self.mode = "confirm" end
			return true
		end
	end
	if event.action == "OK" and self.mode == "contacts" then
		local contact = contacts[self.selected]
		if contact then self.confirmContact = contact; self.mode = "confirm" else self.status = tr("NoContactSelected") end
		return true
	end
	return Base.handleInput(self, event)
end

function App:renderSmartphone(display)
	display:clear()
	local avatar = getTexture(AVATAR_TEXTURE)
	display:drawText(tr("Phone"), display.x + 14, display.y + 34, display.colors.fg, UIFont.Medium)
	display:drawText(display:ellipsize(self.status, display.width - 28), display.x + 14, display.y + 58, display.colors.dim)
	local active = self.os.instance.data.activeCall
	if self.calling or active then
		local other = self.calling and self.calling.number or active.targetNumber or active.fromNumber or tr("Unknown")
		other = self:contactLabel(other)
		if avatar then display.panel:drawTextureScaledAspect(avatar, display.x + math.floor(display.width / 2) - 38, display.y + 110, 76, 76, 1, 1, 1, 1) end
		display:drawTextCentered(display:ellipsize(other, display.width - 32), display.y + 202, display.colors.fg, UIFont.Medium)
		display:drawTextCentered(active and active.state == "connected" and tr("Connected") or tr("RingingDots"), display.y + 228, display.colors.dim)
		local hangX = display.x + 84
		local hangY = display.contentBottom - 56
		local hangW = display.width - 168
		local hangH = 34
		self.hangRect = { x = hangX - display.x, y = hangY - display.y, w = hangW, h = hangH }
		display:fillRect(hangX, hangY, hangW, hangH, display.colors.accent)
		display:drawTextCentered(tr("Hang"), display.contentBottom - 48, { r = 1, g = 1, b = 1, a = 1 }, UIFont.Medium)
		return
	end
	self.hangRect = nil
	if self.mode == "confirm" then
		local contact = self.confirmContact or {}
		if avatar then display.panel:drawTextureScaledAspect(avatar, display.x + math.floor(display.width / 2) - 42, display.y + 84, 84, 84, 1, 1, 1, 1) end
		display:drawTextCentered(tr("ConfirmCall"), display.y + 184, display.colors.fg, UIFont.Medium)
		display:drawTextCentered(display:ellipsize(tostring(contact.name or contact.number or tr("Unknown")), display.width - 36),
			display.y + 214, display.colors.fg)
		display:drawTextCentered(tostring(contact.number or ""), display.y + 234, display.colors.dim)
		local buttonY = display.contentBottom - 62
		local buttonW = 92
		local gap = 18
		local totalW = buttonW * 2 + gap
		local callX = display.x + math.floor((display.width - totalW) / 2)
		local cancelX = callX + buttonW + gap
		self.confirmCallRect = { x = callX - display.x, y = buttonY - display.y, w = buttonW, h = 42 }
		self.confirmCancelRect = { x = cancelX - display.x, y = buttonY - display.y, w = buttonW, h = 42 }
		display:fillRect(callX, buttonY, buttonW, 42, { r = 0.08, g = 0.66, b = 0.24, a = 1 })
		display:drawTextCentered(tr("Call"), buttonY + 13, { r = 1, g = 1, b = 1, a = 1 }, UIFont.Medium, callX, callX + buttonW)
		display:fillRect(cancelX, buttonY, buttonW, 42, { r = 0.82, g = 0.12, b = 0.12, a = 1 })
		display:drawTextCentered(tr("Cancel"), buttonY + 13, { r = 1, g = 1, b = 1, a = 1 }, UIFont.Medium, cancelX, cancelX + buttonW)
		display:drawFooter(tr("Call"), tr("Cancel"))
		return
	end
	local contacts = Persistence.getContacts(self.os.instance.item, self.os.instance.definition.id)
	local list = self.mode == "history" and self.history or contacts
	local rowTop = display.y + 88
	local rowH = 54
	self.lastRowTop = rowTop - display.y
	local visibleRows = math.max(1, math.floor((display.contentBottom - rowTop - 4) / rowH))
	local hasScrollbar = #list > visibleRows
	if self.selected < self.scrollOffset + 1 then self.scrollOffset = self.selected - 1
	elseif self.selected > self.scrollOffset + visibleRows then self.scrollOffset = self.selected - visibleRows end
	self.scrollOffset = math.max(0, math.min(self.scrollOffset, math.max(0, #list - visibleRows)))
	self.smartRowRects = {}
	for i = self.scrollOffset + 1, math.min(#list, self.scrollOffset + visibleRows) do
		local contact = list[i]
		local y = rowTop + (i - self.scrollOffset - 1) * rowH
		local selected = i == self.selected
		display:fillRect(display.x + 10, y, display.width - 20, rowH - 7, selected and display.colors.accent or display.colors.bg)
		display:drawBorder(display.x + 10, y, display.width - 20, rowH - 7, selected and display.colors.fg or display.colors.border)
		if avatar then display.panel:drawTextureScaledAspect(avatar, display.x + 18, y + 8, 34, 34, 1, 1, 1, 1) end
		local label = self.mode == "history"
			and tostring(contact.name or contact.number or tr("Unknown"))
			or tostring(contact.name or contact.number or tr("Unknown"))
		local detail = self.mode == "history"
			and ((contact.date or tr("UnknownDate")) .. "  " .. (contact.type or "") .. "  " .. (contact.result or ""))
			or tostring(contact.number or "")
		display:drawText(display:ellipsize(label, display.width - 92), display.x + 60, y + 8,
			selected and { r = 1, g = 1, b = 1, a = 1 } or display.colors.fg)
		display:drawText(display:ellipsize(detail, display.width - 92), display.x + 60, y + 27,
			selected and { r = 0.9, g = 0.94, b = 1, a = 1 } or display.colors.dim)
		table.insert(self.smartRowRects, { x = 10, y = y - display.y, w = display.width - 20, h = rowH - 7, index = i })
	end
	if #list == 0 then display:drawText(self.mode == "history" and tr("NoCalls") or tr("NoContacts"), display.x + 14, rowTop + 20, display.colors.dim) end
	if hasScrollbar then display:drawScrollbar(#list, visibleRows, self.scrollOffset, rowTop, display.contentBottom) end
	display:drawFooter(self.mode == "history" and tr("Contacts") or tr("History"), tr("Back"))
end

function App:render(display)
	if self.os.definition.hardwareType == "smartphone" then
		return self:renderSmartphone(display)
	end
	display:clear()
	display:drawHeader(tr("Phone"))
	display:drawText(self.status, display.x + 10, display.contentY, display.colors.fg)
	local active = self.os.instance.data.activeCall
	if self.calling or active then
		local other = self.calling and self.calling.number or active.targetNumber or active.fromNumber or tr("Unknown")
		other = self:contactLabel(other)
		display:drawTextCentered(other, display.contentY + 38, display.colors.fg)
		display:drawTextCentered(active and active.state == "connected" and tr("Connected") or tr("RingingDots"), display.contentY + 64, display.colors.dim)
		display:drawFooter(tr("Hang"), tr("Back"))
		return
	end
	if self.mode == "confirm" then
		local contact = self.confirmContact or {}
		display:drawTextCentered(tr("ConfirmCall"), display.contentY + 36, display.colors.fg)
		display:drawTextCentered(tostring(contact.name or contact.number or tr("Unknown")), display.contentY + 58, display.colors.fg)
		display:drawTextCentered(tostring(contact.number or ""), display.contentY + 76, display.colors.dim)
		display:drawFooter(tr("Call"), tr("Cancel"))
		return
	end
	local contacts = Persistence.getContacts(self.os.instance.item, self.os.instance.definition.id)
	local list = self.mode == "history" and self.history or contacts
	local rowTop = display.contentY + 24
	self.lastRowTop = rowTop - display.y
	local visibleRows = math.max(1, math.floor((display.contentBottom - rowTop) / 20))
	local hasScrollbar = #list > visibleRows
	local contentRight = hasScrollbar and (display.contentRight - display.scrollbarWidth - 3) or display.contentRight
	if self.selected < self.scrollOffset + 1 then self.scrollOffset = self.selected - 1
	elseif self.selected > self.scrollOffset + visibleRows then self.scrollOffset = self.selected - visibleRows end
	self.scrollOffset = math.max(0, math.min(self.scrollOffset, math.max(0, #list - visibleRows)))
	for i = self.scrollOffset + 1, math.min(#list, self.scrollOffset + visibleRows) do
		local contact = list[i]
		local y = rowTop + (i - self.scrollOffset - 1) * 20
		if i == self.selected then display:fillRect(display.x + 4, y - 1, contentRight - display.x - 4, 18, display.colors.accent) end
		local label = self.mode == "history"
			and ((contact.date or "") .. " " .. (contact.type or "") .. " " .. (contact.result or ""))
			or contact.name
		display:drawText(display:ellipsize(label, contentRight - display.x - 12), display.x + 10, y, i == self.selected and display.colors.bg or display.colors.fg)
	end
	if #list == 0 then display:drawText(self.mode == "history" and tr("NoCalls") or tr("NoContacts"), display.x + 10, rowTop, display.colors.dim) end
	if hasScrollbar then display:drawScrollbar(#list, visibleRows, self.scrollOffset, rowTop, display.contentBottom) end
	display:drawFooter(self.mode == "history" and tr("Contacts") or tr("History"), tr("Back"))
end

return App
