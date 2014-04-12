AdminManager = {}

AdminManager.AttemptGivePlayerAdmin = function(player)
	if settings.GetIsAdmin(player) == true then
		player:SetValue("isRaceAdmin" , true)
		Network:Send(player , "AdminInitialize")
	end
end

-- Events

AdminManager.PlayerAuthenticate = function(args)
	AdminManager.AttemptGivePlayerAdmin(args.player)
end

AdminManager.ClientModuleLoad = function(args)
	if args.player:IsFullyAuthenticated() then
		AdminManager.AttemptGivePlayerAdmin(args.player)
	end
end

Events:Subscribe("PlayerAuthenticate" , AdminManager.PlayerAuthenticate)
Events:Subscribe("ClientModuleLoad" , AdminManager.ClientModuleLoad)

-- Network events

AdminManager.SetMOTD = function(text , player)
	if not player:GetValue("isRaceAdmin") then
		return
	end
	
	Network:Broadcast("SetMOTD" , text)
end

Network:Subscribe("AdminSetMOTD" , AdminManager.SetMOTD)

-- Console events

AdminManager.ConsoleSetMOTD = function(args)
	-- Replace "\n" with actual newlines.
	local text = args.text:gsub("\\n" , "\n")
	
	Network:Broadcast("SetMOTD" , text)
end

Console:Subscribe("setmotd" , AdminManager.ConsoleSetMOTD)
