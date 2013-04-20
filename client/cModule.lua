function ModulesLoad()
	
	-- Add us to the help menu.
	local args = {}
	args.name = Settings.gamemodeName
	args.text = Settings.gamemodeDescription
	Events:FireRegisteredEvent("HelpAddItem" , args)
	
end

function ModuleUnload()
	
	-- Remove us from the help menu.
	local args = {}
	args.name = Settings.gamemodeName
	Events:FireRegisteredEvent("HelpRemoveItem" , args)
	
end

Events:Subscribe("ModulesLoad" , ModulesLoad)
Events:Subscribe("ModuleUnload" , ModuleUnload)
