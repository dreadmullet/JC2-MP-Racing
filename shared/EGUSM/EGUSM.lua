
EGUSM.debug = false

EGUSM.Print = function(message)
	message = tostring(message)
	print(message)
	message = "["..module_name.."] "..message
	if Server then
		Chat:Broadcast(message , Color(64 , 107 , 128))
	else
		Chat:Print(message , Color(85 , 128 , 64))
	end
end
