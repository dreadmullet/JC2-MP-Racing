BindMenu = {}
-- Minimum interval in seconds that clients are allowed to request, to prevent spam.
BindMenu.networkLimit = 2
-- Map that helps with preventing request spam.
-- Key: player id
-- Value: timer
BindMenu.requests = {}

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

BindMenu.SaveSettings = function(newSettings , player)
	-- Make sure the client can request.
	if BindMenu.CheckSpam(player) == false then
		return
	end
	
	-- Check client arguments.
	if type(newSettings) ~= "table" then
		return
	end
	
	local settings = {}
	local query = SQL:Query("select Settings from BindMenuClientSettings where SteamId = (?)")
	query:Bind(1 , player:GetSteamId().string)
	results = query:Execute()
	
	if #results > 0 and results[1].Settings ~= "Empty" then
		local marshalledControls = string.split(results[1].Settings , "\n")
		for index , marshalledControl in ipairs(marshalledControls) do
			if marshalledControl:len() > 10 then
				local args = string.split(marshalledControl , "|")
				settings[args[2]] = {
					module = args[1] ,
					name = args[2] ,
					type = args[3] ,
					value = args[4] ,
				}
			end
		end
	end
	
	for index , newSetting in ipairs(newSettings) do
		settings[newSetting.name] = newSetting
	end
	
	local settingsString = ""
	for name , setting in pairs(settings) do
		settingsString = (
			settingsString..
			setting.module.."|"..
			setting.name.."|"..
			setting.type.."|"..
			setting.value.."\n"
		)
	end
	
	local command = SQL:Command(
		"insert or replace into BindMenuClientSettings(SteamId , Settings) values(?,?)"
	)
	command:Bind(1 , player:GetSteamId().string)
	command:Bind(2 , settingsString)
	command:Execute()
end

-- Returns false if they are spamming, and thus should be refused.
BindMenu.CheckSpam = function(player)
	local timer = BindMenu.requests[player:GetId()]
	if timer ~= nil and timer:GetSeconds() < BindMenu.networkLimit then
		warn(player:GetName().." is requesting or saving bind menu settings too quickly!")
		return false
	end
	
	BindMenu.requests[player:GetId()] = Timer()
	
	return true
end

Events:Subscribe("ModuleLoad" , BindMenu.Init)

Network:Subscribe("BindMenuRequestSettings" , BindMenu.RequestSettings)
Network:Subscribe("BindMenuSaveSettings" , BindMenu.SaveSettings)
