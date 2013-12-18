----------------------------------------------------------------------------------------------------
-- Event to create the race manager, as well as misc stuff like global functions.
----------------------------------------------------------------------------------------------------

Events:Subscribe(
	"ModuleLoad" ,
	function()
		Chat:Broadcast(
			settings.name.." "..settings.version.." loaded." ,
			settings.textColor
		)
		
		Stats.Init()
		raceManager = _G[settings.raceManager]()
	end
)

math.randomseed(os.time())
math.tau = math.pi * 2
