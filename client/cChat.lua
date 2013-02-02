
OnLocalPlayerChat = function(args)
	
	if Settings.guiQuality ~= 0 and args.text == "/race quality high" then
		Settings.guiQuality = 0
		Client:ChatMessage("Race GUI quality changed to high." , Settings.textColor)
		return false
	elseif Settings.guiQuality ~= -1 and args.text == "/race quality low" then
		Settings.guiQuality = -1
		Client:ChatMessage("Race GUI quality changed to low." , Settings.textColor)
		return false
	end
	
	return true
	
end

Events:Subscribe("LocalPlayerChat" , OnLocalPlayerChat)
