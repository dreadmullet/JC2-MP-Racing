Events:Subscribe(
	"ModuleLoad" ,
	function()
		Chat:Broadcast(
			"JC2-MP-Racing "..settings.version.." loaded." ,
			settings.textColor
		)
		
		raceManager = settings.raceManager()
		
		Stats.Init()
	end
)
