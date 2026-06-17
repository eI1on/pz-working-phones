local Base = require("WorkingPhones/Apps/Base/BasePhoneApp")
local PhoneMiniMapView = require("WorkingPhones/UI/PhoneMiniMapView")
local I18N = require("WorkingPhones/Core/PhoneI18N")

local App = setmetatable({}, { __index = Base })
App.__index = App

function App:new(os)
	local o = Base.new(self, os)
	o.id = "map"
	o.name = I18N.app("map")
	o.mapView = nil
	o.optionsOpen = false
	o.optionIndex = 1
	o.options = { "Zoom", "Follow", "Symbols", "Iso", "Center" }
	o.optionRects = {}
	o.zoom = os.instance.data.mapZoom or 18
	o.followPlayer = os.instance.data.mapFollowPlayer ~= false
	o.showSymbols = os.instance.data.mapShowSymbols == true
	o.hideUnvisited = true
	o.isometric = os.instance.data.mapIsometric == true
	o.monochromeOverlay = true
	return o
end

function App:saveOptions()
	self.os.instance.data.mapZoom = self.zoom
	self.os.instance.data.mapFollowPlayer = self.followPlayer
	self.os.instance.data.mapShowSymbols = self.showSymbols
	self.os.instance.data.mapIsometric = self.isometric
end

function App:syncMapOptions()
	if not self.mapView then
		return
	end
	self.mapView.zoom = self.zoom
	self.mapView.followPlayer = self.followPlayer
	self.mapView.showSymbols = self.showSymbols
	self.mapView.hideUnvisited = true
	self.mapView.isometric = self.isometric
	self.mapView.monochromeOverlay = true
	self.mapView:applyMiniMapOptions()
end

function App:onClose()
	if self.mapView then
		self.mapView:setVisible(false)
		self.mapView:removeFromUIManager()
		self.mapView = nil
	end
end

function App:getMapLocalGeometry(display)
	local x = display.x + 1
	local y = display.contentY
	local w = display.width - 2
	local h = math.max(1, display.contentBottom - y)
	return x, y, w, h
end

function App:getMapGeometry(display)
	local panelX = display.panel.getAbsoluteX and display.panel:getAbsoluteX() or display.panel.x
	local panelY = display.panel.getAbsoluteY and display.panel:getAbsoluteY() or display.panel.y
	local x, y, w, h = self:getMapLocalGeometry(display)
	return panelX + x, panelY + y, w, h
end

function App:bringOverlayToTop()
	if not self.mapView then
		return
	end
	if self.mapView.setAlwaysOnTop then
		self.mapView:setAlwaysOnTop(true)
	end
	if self.mapView.bringToTop then
		self.mapView:bringToTop()
	end
end

function App:syncOverlayGeometry(display)
	if not self.mapView or self.optionsOpen then
		return
	end
	local x, y, w, h = self:getMapGeometry(display)
	self.mapView:setGeometry(x, y, w, h)
	self.mapView:setVisible(true)
end

function App:ensureMapView(display)
	local x, y, w, h = self:getMapGeometry(display)

	if self.mapView then
		self:syncOverlayGeometry(display)
		self:syncMapOptions()
		return
	end

	local playerNum = self.os.instance.playerObj and self.os.instance.playerObj:getPlayerNum() or 0
	self.mapView = PhoneMiniMapView:new(x, y, w, h, playerNum, display.colors, {
		zoom = self.zoom,
		followPlayer = self.followPlayer,
		showSymbols = self.showSymbols,
		hideUnvisited = true,
		isometric = self.isometric,
		monochromeOverlay = true,
	})
	self.mapView.ownerApp = self
	self.mapView:initialise()
	self.mapView:instantiate()
	if self.mapView.setAlwaysOnTop then
		self.mapView:setAlwaysOnTop(true)
	end
	self.mapView:addToUIManager()
	self:bringOverlayToTop()
end

function App:isMouseOverMap(display)
	local mouseX = display.panel:getMouseX()
	local mouseY = display.panel:getMouseY()
	local x, y, w, h = self:getMapLocalGeometry(display)
	return mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h
end

function App:selectedOptionName()
	return self.options[self.optionIndex]
end

function App:adjustOption(delta)
	local option = self:selectedOptionName()
	if option == "Zoom" then
		local factor = delta > 0 and 1.035 or (1 / 1.035)
		self.zoom = math.max(1, math.min(24, self.zoom * factor))
	elseif option == "Follow" then
		self.followPlayer = not self.followPlayer
	elseif option == "Symbols" then
		self.showSymbols = not self.showSymbols
	elseif option == "Iso" then
		self.isometric = not self.isometric
	elseif option == "Center" then
		self.followPlayer = true
		if self.mapView then
			self.mapView:centerOnPlayer()
		end
	end
	self:saveOptions()
	self:syncMapOptions()
end

function App:handleInput(event)
	if event.action == "LEFT_SOFT" then
		self.optionsOpen = not self.optionsOpen
		if not self.optionsOpen then
			self:bringOverlayToTop()
		end
		return true
	end

	if self.optionsOpen then
		if event.action == "MOUSE_DOWN" and event.displayX and event.displayY then
			for i = #self.optionRects, 1, -1 do
				local rect = self.optionRects[i]
				if event.displayX >= rect.x and event.displayX <= rect.x + rect.w
					and event.displayY >= rect.y and event.displayY <= rect.y + rect.h then
					self.optionIndex = rect.index
					if rect.delta then
						self:adjustOption(rect.delta)
					else
						self:adjustOption(1)
					end
					return true
				end
			end
			return true
		end
		if event.action == "UP" then
			self.optionIndex = math.max(1, self.optionIndex - 1)
			return true
		elseif event.action == "DOWN" then
			self.optionIndex = math.min(#self.options, self.optionIndex + 1)
			return true
		elseif event.action == "SCROLL_UP" then
			self.optionIndex = math.max(1, self.optionIndex - 1)
			return true
		elseif event.action == "SCROLL_DOWN" then
			self.optionIndex = math.min(#self.options, self.optionIndex + 1)
			return true
		elseif event.action == "LEFT" then
			self:adjustOption(-1)
			return true
		elseif event.action == "RIGHT" or event.action == "OK" then
			self:adjustOption(1)
			return true
		end
		return Base.handleInput(self, event)
	end

	if event.action == "SCROLL_UP" then
		self.zoom = math.min(24, self.zoom * 1.035)
		self:saveOptions()
		self:syncMapOptions()
		return true
	elseif event.action == "SCROLL_DOWN" then
		self.zoom = math.max(1, self.zoom / 1.035)
		self:saveOptions()
		self:syncMapOptions()
		return true
	end

	if event.action == "UP" then
		if self.mapView then self.mapView:pan(0, -1) end
		self.followPlayer = false
		self:saveOptions()
		return true
	elseif event.action == "DOWN" then
		if self.mapView then self.mapView:pan(0, 1) end
		self.followPlayer = false
		self:saveOptions()
		return true
	elseif event.action == "LEFT" then
		if self.mapView then self.mapView:pan(-1, 0) end
		self.followPlayer = false
		self:saveOptions()
		return true
	elseif event.action == "RIGHT" then
		if self.mapView then self.mapView:pan(1, 0) end
		self.followPlayer = false
		self:saveOptions()
		return true
	elseif event.action == "OK" then
		self.followPlayer = true
		if self.mapView then self.mapView:centerOnPlayer() end
		self:saveOptions()
		return true
	end

	return Base.handleInput(self, event)
end

function App:optionValue(option)
	if option == "Zoom" then
		return tostring(math.floor(self.zoom * 10 + 0.5) / 10)
	elseif option == "Follow" then
		return self.followPlayer and I18N.get("On") or I18N.get("Off")
	elseif option == "Symbols" then
		return self.showSymbols and I18N.get("On") or I18N.get("Off")
	elseif option == "Iso" then
		return self.isometric and I18N.get("On") or I18N.get("Off")
	end
	return ""
end

function App:renderOptions(display)
	display:clear()
	display:drawHeader(I18N.get("MapOptions"))
	self.optionRects = {}
	local top, visibleRows, contentRight, hasScrollbar = display:getVisibleListMetrics(20, #self.options)
	local offset = math.max(0, math.min(self.optionIndex - visibleRows, math.max(0, #self.options - visibleRows)))
	for i = offset + 1, math.min(#self.options, offset + visibleRows) do
		local row = i - offset
		local y = top + (row - 1) * 20
		local selected = i == self.optionIndex
		if selected then
			display:fillRect(display.x + 4, y - 1, contentRight - display.x - 4, 18, display.colors.accent)
		end
		local color = selected and display.colors.bg or display.colors.fg
		local option = self.options[i]
		local localY = y - display.y - 1
		self.optionRects[#self.optionRects + 1] = { x = 4, y = localY, w = contentRight - display.x - 4, h = 20, index = i }
		display:drawText(I18N.get("MapOption_" .. option), display.x + 10, y, color)
		local value = self:optionValue(option)
		if value ~= "" then
			local rightX = contentRight - 2
			display:drawText("<", rightX - 50, y, color)
			display:drawTextRight(value, rightX - 10, y, color)
			display:drawText(">", rightX - 6, y, color)
			self.optionRects[#self.optionRects + 1] = { x = rightX - 58 - display.x, y = localY, w = 22, h = 20, index = i, delta = -1 }
			self.optionRects[#self.optionRects + 1] = { x = rightX - 10 - display.x, y = localY, w = 22, h = 20, index = i, delta = 1 }
		end
	end
	if hasScrollbar then
		display:drawScrollbar(#self.options, visibleRows, offset, top, display.contentBottom)
	end
	display:drawFooter(I18N.app("map"), I18N.get("Back"))
end

function App:render(display)
	if self.optionsOpen then
		if self.mapView then
			self.mapView:setVisible(false)
		end
		self:renderOptions(display)
		return
	end

	display:clear()
	display:drawHeader(I18N.app("map"))
	self:ensureMapView(display)
	self.mapView:setVisible(true)
	display:drawFooter(I18N.get("Options"), I18N.get("Back"))
end

return App
