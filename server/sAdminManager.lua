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
