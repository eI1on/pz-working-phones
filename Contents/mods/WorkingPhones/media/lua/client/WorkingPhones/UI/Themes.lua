local Themes = {}

Themes.classic_green = {
	mode = "monochrome",
	bg = { r = 0.55, g = 0.67, b = 0.42, a = 1 },
	fg = { r = 0.05, g = 0.13, b = 0.08, a = 1 },
	dim = { r = 0.18, g = 0.26, b = 0.14, a = 1 },
	accent = { r = 0.12, g = 0.2, b = 0.1, a = 1 },
	border = { r = 0.04, g = 0.1, b = 0.05, a = 1 },
}

Themes.smartphone_light = {
	mode = "color",
	bg = { r = 0.06, g = 0.07, b = 0.08, a = 1 },
	fg = { r = 0.94, g = 0.96, b = 0.98, a = 1 },
	dim = { r = 0.5, g = 0.56, b = 0.62, a = 1 },
	accent = { r = 0.16, g = 0.5, b = 0.88, a = 1 },
	border = { r = 0.02, g = 0.02, b = 0.03, a = 1 },
}

function Themes.get(id)
	return Themes[id] or Themes.classic_green
end

return Themes
