WorkingPhones = WorkingPhones or {}

WorkingPhones.MOD_ID = "WorkingPhones"
WorkingPhones.NET_MODULE = "WorkingPhones"

function WorkingPhones.log(message)
	print("[WorkingPhones] " .. tostring(message))
end

return WorkingPhones
