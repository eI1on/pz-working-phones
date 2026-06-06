local ClassicRenderer = {}

function ClassicRenderer.renderShell(panel, definition)
	if panel.phoneTexture then
		panel:drawTextureScaled(panel.phoneTexture, 0, 0, panel.phoneFrameWidth or panel.width,
			panel.phoneFrameHeight or panel.height, 1, 1, 1, 1)
	end
end

function ClassicRenderer.renderOverlay(panel, definition)
	local rect = panel.screenRect or definition.screenRect
	panel:drawRectBorder(rect.x - 2, rect.y - 2, rect.width + 4, rect.height + 4, 0.6, 0, 0, 0)
end

return ClassicRenderer
