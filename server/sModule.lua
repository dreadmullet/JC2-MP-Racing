----------------------------------------------------------------------------------------------------
-- Event to create the race manager, as well as misc stuff like global functions.
----------------------------------------------------------------------------------------------------

Events:Subscribe(
	"ModuleLoad" ,
	function()
		Chat:Broadcast(
			"JC2-MP-Racing "..settings.version.." loaded." ,
			settings.textColor
		)
		
		Stats.Init()
		
		raceManager = settings.raceManager()
	end
)

math.randomseed(os.time())
math.tau = math.pi * 2
