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

AdminManager.Kick = function(playerName , player)
	if not player:GetValue("isRaceAdmin") then
		return
	end
	
	local player = Player.Match(playerName)[1]
	if player then
		player:Kick()
	else
		player:SendChatMessage(playerName.." not found!" , Color.Red)
	end
end

AdminManager.Ban = function(playerName , player)
	if not player:GetValue("isRaceAdmin") then
		return
	end
	
	local player = Player.Match(playerName)[1]
	if player then
		player:Ban()
	else
		player:SendChatMessage(playerName.." not found!" , Color.Red)
	end
end

Network:Subscribe("AdminSetMOTD" , AdminManager.SetMOTD)
Network:Subscribe("AdminKick" , AdminManager.Kick)
Network:Subscribe("AdminBan" , AdminManager.Ban)

-- Console events

AdminManager.ConsoleSetMOTD = function(args)
	-- Replace "\n" with actual newlines.
	local text = args.text:gsub("\\n" , "\n")
	
	Network:Broadcast("SetMOTD" , text)
end

Console:Subscribe("setmotd" , AdminManager.ConsoleSetMOTD)
