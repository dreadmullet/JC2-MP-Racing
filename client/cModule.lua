function ModulesLoad()
	-- Add us to the help menu.
	local args = {}
	args.name = settings.gamemodeName
	args.text = settings.gamemodeDescription
	Events:Fire("HelpAddItem" , args)
end

function ModuleUnload()
	-- Remove us from the help menu.
	local args = {}
	args.name = settings.gamemodeName
	Events:Fire("HelpRemoveItem" , args)
end

Events:Subscribe("ModulesLoad" , ModulesLoad)
Events:Subscribe("ModuleUnload" , ModuleUnload)

Network:Subscribe(
	"Initialise" ,
	function(args)
		race = Race(args)
	end
)

Network:Subscribe(
	"SpectateInitialise" ,
	function(args)
		spectate = Spectate(args)
	end
)
