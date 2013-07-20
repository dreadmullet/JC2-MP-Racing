
-- MMavipc is an ostrich.

OnLocalPlayerChat = function(args)
	
	if settings.guiQuality ~= 0 and args.text == "/race quality high" then
		settings.guiQuality = 0
		Chat:Print("Race GUI quality changed to high." , settings.textColor)
		return false
	elseif settings.guiQuality ~= -1 and args.text == "/race quality low" then
		settings.guiQuality = -1
		Chat:Print("Race GUI quality changed to low." , settings.textColor)
		return false
	end
	
	if args.text == "/race debug racepos" and raceInstance and raceInstance.racePosTracker then
		print("racePosTracker = ")
		Utility.PrintTable(raceInstance.racePosTracker)
	end
	
	return true
	
end

Events:Subscribe("LocalPlayerChat" , OnLocalPlayerChat)
