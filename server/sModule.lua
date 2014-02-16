Events:Subscribe(
	"ModuleLoad" ,
	function()
		Chat:Broadcast(
			"JC2-MP-Racing "..settings.version.." loaded." ,
			settings.textColor
		)
		
		Stats.Init()
		
		if settings.raceManager then
			raceManager = settings.raceManager()
		end
	end
)
