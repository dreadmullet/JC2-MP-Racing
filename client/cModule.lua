ModuleLoad = function()
	raceMenu = RaceMenu()
end

ModulesLoad = function()
	-- Add us to the help menu.
	local args = {
		name = settings.gamemodeName ,
		text = settings.gamemodeDescription
	}
	Events:Fire("HelpAddItem" , args)
end

ModuleUnload = function()
	-- Remove us from the help menu.
	local args = {
		name = settings.gamemodeName
	}
	Events:Fire("HelpRemoveItem" , args)
end

Events:Subscribe("ModuleLoad" , ModuleLoad)
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
