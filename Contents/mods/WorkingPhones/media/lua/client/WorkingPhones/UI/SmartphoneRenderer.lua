local SmartphoneRenderer = {}

function SmartphoneRenderer.renderShell(panel, definition)
	local width = panel.phoneFrameWidth or panel.width
	local height = panel.phoneFrameHeight or panel.height
	if panel.phoneTexture then
		panel:drawTextureScaled(panel.phoneTexture, 0, 0, width, height, 1, 1, 1, 1)
		return
	end
	panel:drawRect(0, 0, width, height, 1, 0.02, 0.02, 0.025)
	panel:drawRectBorder(0, 0, width, height, 1, 0.12, 0.12, 0.13)
	panel:drawRect(width / 2 - 24, 14, 48, 5, 1, 0.1, 0.1, 0.11)
end

function SmartphoneRenderer.renderOverlay(panel, definition)
	if panel.phoneTexture then
		return
	end
	local rect = panel.screenRect or definition.screenRect
	panel:drawRectBorder(rect.x - 1, rect.y - 1, rect.width + 2, rect.height + 2, 1, 0.2, 0.2, 0.22)
end

return SmartphoneRenderer
