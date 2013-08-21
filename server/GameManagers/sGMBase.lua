
function GMBase:__init()
	
	-- Key = player id
	-- Value = true
	self.playerIds = {}
	
	self.baseEvents = {}
	table.insert(
		self.baseEvents ,
		Events:Subscribe("PlayerChat" , self , GMBase.BasePlayerChat)
	)
	table.insert(
		self.baseEvents ,
		Events:Subscribe("ModuleUnload" , self , GMBase.BaseModuleUnload)
	)
	
	-- Expose our functions to inheritors. It's like public/private functions. Lua is awesoem.
	self.HasPlayer = GMBase.HasPlayer
	self.GetIsAdmin = GMBase.GetIsAdmin
	self.MessagePlayer = GMBase.MessagePlayer
	self.AdminChangeSetting = GMBase.AdminChangeSetting
	self.AdminPrintSetting = GMBase.AdminPrintSetting
	
end

function GMBase:HasPlayer(player)
	
	local playerId = Racing.PlayerId(player)
	
	return self.playerIds[playerId]
	
end

function GMBase:GetIsAdmin(player)
	
	local playerSteamId = player:GetSteamId()
	for index , steamId in ipairs(settings.admins) do
		if playerSteamId == steamId then
			return true
		end
	end
	
	return false
	
end

function GMBase:MessagePlayer(player , message)
	
	player:SendChatMessage("[Racing] "..message , settings.textColorLocal)
	
end

function GMBase:AdminChangeSetting(player , settingName , value)
	
	-- Argument checking.
	if settingName == nil then
		self:MessagePlayer(player , "Error: setting name required")
		return
	elseif settings[settingName] == nil then
		self:MessagePlayer(player , "Error: invalid setting")
		return
	elseif value == nil then
		self:MessagePlayer(player , "Error: value required")
		return
	end
	
	value = Utility.CastFromString(value , type(settings[settingName]))
	
	if value == nil then
		self:MessagePlayer(player , "Error: invalid value")
		return
	end
	
	settings[settingName] = value
	
	self:MessagePlayer(player , "Set settings."..settingName.." to "..tostring(value))
	
end

function GMBase:AdminPrintSetting(player , settingName)
	
	-- Argument checking.
	if settingName == nil then
		self:MessagePlayer(player , "Error: setting name required")
		return
	elseif settings[settingName] == nil then
		self:MessagePlayer(player , "Error: invalid setting")
		return
	end
	
	self:MessagePlayer(player , "settings."..settingName.." is "..tostring(settings[settingName]))
	
end

--
-- Events
--

function GMBase:BasePlayerChat(args)
	
	if
		self:GetIsAdmin(args.player) and
		args.text:sub(1 , settings.command:len()) == settings.command
	then
		-- Split the message up into words (by spaces).
		local words = {}
		for word in string.gmatch(args.text , "[^%s]+") do
			table.insert(words , word)
		end
		
		if words[2] == "create" and words[3] then
			self:CreateRace(words[3])
		elseif words[2] == "set" then
			self:AdminChangeSetting(args.player , words[3] , words[4])
		elseif words[2] == "get" then
			self:AdminPrintSetting(args.player , words[3])
		end
		
		return false
	end
	
	return true
	
end

function GMBase:BaseModuleUnload(args)
	
	for index , event in ipairs(self.baseEvents) do
		Events:Unsubscribe(event)
	end
	
end
