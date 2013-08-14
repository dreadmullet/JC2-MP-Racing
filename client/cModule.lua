
function ModulesLoad()
	
	-- Add us to the help menu.
	local args = {}
	args.name = settings.gamemodeName
	args.text = settings.gamemodeDescription
	Events:FireRegisteredEvent("HelpAddItem" , args)
	
end

function ModuleUnload()
	
	-- Remove us from the help menu.
	local args = {}
	args.name = settings.gamemodeName
	Events:FireRegisteredEvent("HelpRemoveItem" , args)
	
end

Events:Subscribe("ModulesLoad" , ModulesLoad)
Events:Subscribe("ModuleUnload" , ModuleUnload)

Network:Subscribe(
	"Initialize" ,
	function(args)
		local race = Race(args)
	end
)
