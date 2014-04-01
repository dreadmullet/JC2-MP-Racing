ModuleLoad = function()
	Chat:Broadcast(
		"JC2-MP-Racing "..statics.version.." loaded." ,
		settings.textColor
	)
	
	Stats.Init()
	
	if settings.raceManager then
		raceManager = settings.raceManager()
	end
end

Events:Subscribe("ModuleLoad" , ModuleLoad)

math.randomseed(os.time())
math.tau = math.pi * 2
