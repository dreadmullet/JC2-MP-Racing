parachuteActions = {}
parachuteActions[Action.ActivateParachuteThrusters] = true
parachuteActions[Action.ExitToStuntposParachute] = true
parachuteActions[Action.ParachuteOpenClose] = true
parachuteActions[Action.ParachuteLandOnVehicle] = true
parachuteActions[Action.StuntposToParachute] = true
parachuteActions[Action.DeployParachuteWhileReelingAction] = true

-- When this is 0, input is normal. When it's above 0, input is suspended.
-- * It is up to implementations of input to abide by the value.
-- * Any text boxes should increment it on focus and decrement it on blur.
inputSuspensionValue = 0

-- Events

ModuleLoad = function()
	RaceMenu()
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

-- Network events

Network:Subscribe(
	"InitializeClass" ,
	function(args)
		_G[args.className](args)
	end
)
