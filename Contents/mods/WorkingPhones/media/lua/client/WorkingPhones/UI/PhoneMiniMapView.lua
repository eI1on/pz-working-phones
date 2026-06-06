require "ISUI/ISUIElement"
require "ISUI/Maps/ISMapDefinitions"
local I18N = require("WorkingPhones/Core/PhoneI18N")

local PhoneMiniMapView = ISUIElement:derive("WorkingPhones_PhoneMiniMapView")

function PhoneMiniMapView:initialise()
	ISUIElement.initialise(self)
end

function PhoneMiniMapView:instantiate()
	if not UIWorldMap or not MapItem then
		self.unavailable = true
		return
	end

	self.javaObject = UIWorldMap.new(self)
	self.mapAPI = self.javaObject:getAPIv1()
	self.mapAPI:setMapItem(MapItem.getSingleton())
	self.javaObject:setX(self.x)
	self.javaObject:setY(self.y)
	self.javaObject:setWidth(self.width)
	self.javaObject:setHeight(self.height)
	self.javaObject:setAnchorLeft(self.anchorLeft)
	self.javaObject:setAnchorRight(self.anchorRight)
	self.javaObject:setAnchorTop(self.anchorTop)
	self.javaObject:setAnchorBottom(self.anchorBottom)
	self:loadMapData()
	self:applyMiniMapOptions()
	self:centerOnPlayer()
end

function PhoneMiniMapView:loadMapData()
	local dirs = getLotDirectories()
	for i = 1, dirs:size() do
		local dir = dirs:get(i - 1)
		local dataFile = "media/maps/" .. dir .. "/worldmap.xml"
		if fileExists(dataFile) then
			self.mapAPI:addData(dataFile)
		end
		self.mapAPI:endDirectoryData()
		self.mapAPI:addImages("media/maps/" .. dir)
	end
	self.mapAPI:setBoundsFromWorld()
	MapUtils.initDefaultStyleV1(self)
end

function PhoneMiniMapView:applyMiniMapOptions()
	if not self.mapAPI then
		return
	end
	self.mapAPI:setBoolean("HideUnvisited", self.hideUnvisited)
	self.mapAPI:setBoolean("Players", true)
	self.mapAPI:setBoolean("RemotePlayers", true)
	self.mapAPI:setBoolean("PlayerNames", false)
	self.mapAPI:setBoolean("Symbols", self.showSymbols)
	self.mapAPI:setBoolean("MiniMapSymbols", true)
	self.mapAPI:setBoolean("Isometric", self.isometric)
	self.mapAPI:setZoom(self.zoom)
end

function PhoneMiniMapView:setGeometry(x, y, width, height)
	self:setX(x)
	self:setY(y)
	self:setWidth(width)
	self:setHeight(height)
	if self.javaObject then
		self.javaObject:setX(x)
		self.javaObject:setY(y)
		self.javaObject:setWidth(width)
		self.javaObject:setHeight(height)
	end
end

function PhoneMiniMapView:getPlayer()
	return getSpecificPlayer(self.playerNum or 0)
end

function PhoneMiniMapView:centerOnPlayer()
	if not self.mapAPI then
		return
	end
	local playerObj = self:getPlayer()
	if not playerObj then
		return
	end
	local vehicle = playerObj:getVehicle()
	if vehicle then
		self.mapAPI:centerOn(vehicle:getX(), vehicle:getY())
	else
		self.mapAPI:centerOn(playerObj:getX(), playerObj:getY())
	end
end

function PhoneMiniMapView:prerender()
	if self.followPlayer and not self.dragging then
		self:centerOnPlayer()
	end
end

function PhoneMiniMapView:render()
	if self.unavailable then
		self:drawRect(0, 0, self.width, self.height, 1, self.colors.bg.r, self.colors.bg.g, self.colors.bg.b)
		self:drawRectBorder(0, 0, self.width, self.height, 1, self.colors.fg.r, self.colors.fg.g, self.colors.fg.b)
		self:drawText(I18N.get("MapUnavailable"), 8, 8, self.colors.fg.r, self.colors.fg.g, self.colors.fg.b, 1, UIFont.Small)
		return
	end

	ISUIElement.render(self)

	if self.monochromeOverlay then
		self:drawRect(0, 0, self.width, self.height, 0.24, self.colors.bg.r, self.colors.bg.g, self.colors.bg.b)
		self:drawRect(0, 0, self.width, self.height, 0.22, self.colors.fg.r, self.colors.fg.g, self.colors.fg.b)
		for y = 0, self.height, 2 do
			self:drawRect(0, y, self.width, 1, 0.10, self.colors.bg.r, self.colors.bg.g, self.colors.bg.b)
		end
	end

	local cx = math.floor(self.width / 2)
	local cy = math.floor(self.height / 2)
	self:drawRect(cx - 4, cy, 9, 1, 1, self.colors.accent.r, self.colors.accent.g, self.colors.accent.b)
	self:drawRect(cx, cy - 4, 1, 9, 1, self.colors.accent.r, self.colors.accent.g, self.colors.accent.b)
end

function PhoneMiniMapView:zoomBy(delta)
	if not self.mapAPI then
		return
	end
	local factor = delta > 0 and 1.08 or 0.925
	self.zoom = math.max(1, math.min(24, math.floor(self.zoom * factor + 0.5)))
	self.mapAPI:setZoom(self.zoom)
	if self.ownerApp then
		self.ownerApp.zoom = self.zoom
		self.ownerApp:saveOptions()
	end
end

function PhoneMiniMapView:pan(dx, dy)
	if not self.mapAPI then
		return
	end
	self.followPlayer = false
	local scale = self.mapAPI:getWorldScale()
	local step = 90 / math.max(0.1, scale)
	self.mapAPI:centerOn(self.mapAPI:getCenterWorldX() + dx * step, self.mapAPI:getCenterWorldY() + dy * step)
end

function PhoneMiniMapView:onMouseDown(x, y)
	self.dragging = true
	self.dragMoved = false
	self.dragStartX = x
	self.dragStartY = y
	if self.mapAPI then
		self.dragStartCX = self.mapAPI:getCenterWorldX()
		self.dragStartCY = self.mapAPI:getCenterWorldY()
		self.dragStartZoomF = self.mapAPI:getZoomF()
		self.dragStartWorldX = self.mapAPI:uiToWorldX(x, y)
		self.dragStartWorldY = self.mapAPI:uiToWorldY(x, y)
	end
	return true
end

function PhoneMiniMapView:onMouseMove(dx, dy)
	if not self.dragging or not self.mapAPI then
		return false
	end
	local mouseX = self:getMouseX()
	local mouseY = self:getMouseY()
	if not self.dragMoved and math.abs(mouseX - self.dragStartX) <= 4 and math.abs(mouseY - self.dragStartY) <= 4 then
		return true
	end
	self.dragMoved = true
	self.followPlayer = false
	local worldX = self.mapAPI:uiToWorldX(mouseX, mouseY, self.dragStartZoomF, self.dragStartCX, self.dragStartCY)
	local worldY = self.mapAPI:uiToWorldY(mouseX, mouseY, self.dragStartZoomF, self.dragStartCX, self.dragStartCY)
	self.mapAPI:centerOn(self.dragStartCX + self.dragStartWorldX - worldX,
		self.dragStartCY + self.dragStartWorldY - worldY)
	return true
end

function PhoneMiniMapView:onMouseMoveOutside(dx, dy)
	return self:onMouseMove(dx, dy)
end

function PhoneMiniMapView:onMouseUp(x, y)
	self.dragging = false
	return true
end

function PhoneMiniMapView:onMouseUpOutside(x, y)
	self.dragging = false
	return true
end

function PhoneMiniMapView:onMouseWheel(delta)
	self:zoomBy(delta < 0 and 1 or -1)
	return true
end

function PhoneMiniMapView:new(x, y, width, height, playerNum, colors, options)
	local o = ISUIElement.new(self, x, y, width, height)
	o.playerNum = playerNum or 0
	o.colors = colors
	o.zoom = options and options.zoom or 18
	o.followPlayer = options and options.followPlayer ~= false
	o.showSymbols = options and options.showSymbols == true
	o.hideUnvisited = not options or options.hideUnvisited ~= false
	o.isometric = options and options.isometric == true
	o.monochromeOverlay = not options or options.monochromeOverlay ~= false
	o.dragging = false
	return o
end

return PhoneMiniMapView
