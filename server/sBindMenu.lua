
BindMenu = {}
-- Minimum interval in seconds that clients are allowed to request, to prevent spam.
BindMenu.networkLimit = 5
-- Map that helps with preventing request spam.
-- Key: player id
-- Value: timer
BindMenu.requests = {}
-- Prevents clients from storing massive strings in the database.
BindMenu.maxSettingsLength = 5000

BindMenu.Init = function()
	SQL:Execute(
		"create table if not exists "..
		"BindMenuClientSettings("..
			"SteamId  text primary key ,"..
			"Settings text"..
		")"
	)
end

BindMenu.RequestSettings = function(unused , player)
	local playerId = player:GetId()
	local steamId = player:GetSteamId().string
	
	-- Make sure the client can request.
	if BindMenu.CheckSpam(player) == false then
		return
	end
	
	local query = SQL:Query("select Settings from BindMenuClientSettings where SteamId = (?)")
	query:Bind(1 , steamId)
	results = query:Execute()
	
	if #results == 0 then
		local command = SQL:Command(
			"insert into BindMenuClientSettings(SteamId , Settings) values(?,?)"
		)
		command:Bind(1 , steamId)
		command:Bind(2 , "Empty")
		command:Execute()
		
		Network:Send(player , "BindMenuReceiveSettings" , "Empty")
	else
		Network:Send(player , "BindMenuReceiveSettings" , results[1].Settings)
	end
end

BindMenu.SaveSettings = function(settings , player)
	-- Make sure the client can request.
	if BindMenu.CheckSpam(player) == false then
		return
	end
	
	if settings:len() > BindMenu.maxSettingsLength then
		warn(player:GetName().."'s bind menu settings are "..settings:len().." characters!")
		return
	end
	
	local command = SQL:Command(
		"insert or replace into BindMenuClientSettings(SteamId , Settings) values(?,?)"
	)
	command:Bind(1 , player:GetSteamId().string)
	command:Bind(2 , settings)
	command:Execute()
end

-- Returns false if they are spamming, and thus should be refused.
BindMenu.CheckSpam = function(player)
	local timer = BindMenu.requests[player:GetId()]
	if timer ~= nil and timer:GetSeconds() < BindMenu.networkLimit then
		warn(player:GetName().." is requesting bind menu settings too quickly!")
		return false
	end
	
	BindMenu.requests[player:GetId()] = Timer()
	
	return true
end

Events:Subscribe("ModuleLoad" , BindMenu.Init)

Network:Subscribe("BindMenuRequestSettings" , BindMenu.RequestSettings)
Network:Subscribe("BindMenuSaveSettings" , BindMenu.SaveSettings)
