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
		
		raceManager = settings.raceManager()
		
		Stats.Init()
	end
)

math.randomseed(os.time())
math.tau = math.pi * 2
