local I18N = {}

local PREFIX = "IGUI_WorkingPhones_"

function I18N.get(key, ...)
	return getText(PREFIX .. tostring(key), ...)
end

function I18N.app(appId)
	return I18N.get("App_" .. tostring(appId))
end

function I18N.monthShort(month)
	return I18N.get("MonthShort_" .. tostring(month))
end

function I18N.dayShort(day)
	return I18N.get("DayShort_" .. tostring(day))
end

function I18N.reason(reason, fallback)
	reason = tostring(reason or fallback or "Unavailable")
	if reason == "Hung up" then
		reason = "HungUp"
	end
	return I18N.get(reason)
end

function I18N.translatedName(key, fallback)
	return key and I18N.get(key) or fallback
end

return I18N
