----------------------------------------------------------------------------------------------------
-- There should only be one RaceManager; the single instance should contain everything.
----------------------------------------------------------------------------------------------------

function RaceManager:__init()
	
	Chat:Broadcast(
		settings.name.." "..settings.version.." loaded." ,
		settings.textColorGlobal
	)
	
	self.courseManagerAll = CourseManager("CourseManifest.txt")
	
	self.races = {}
	self.currentPublicRace = nil
	-- Key = player id
	-- Value = true
	self.playerIds = {}
	self.numPublicRacesRan = 0
	
	if settings.doPublicRaces then
		self:CreateRacePublic()
	end
	
	self.events = {}
	local EventSub = function(name)
		table.insert(
			self.events ,
			Events:Subscribe(name , self , self[name])
		)
	end
	EventSub("PlayerChat")
	EventSub("ModuleUnload")
	
	EventSub("JoinGamemode")
	
end

function RaceManager:CreateRace(name , isPublic , course , players)
	
	isPublic = isPublic or false
	players = players or {}
	-- This is so bad. Need a proper admin GUI.
	if settings.forceCourse ~= "" then
		-- Set forceCourse to an empty string, so if some knobhead gets the course name wrong the
		-- module won't explode.
		local temp = settings.forceCourse
		settings.forceCourse = ""
		course = Course.Load(temp)
	else
		course = course or self.courseManagerAll:LoadCourseRandom()
	end
	
	-- Make sure race with this name doesn't already exist.
	for index , race in ipairs(self.races) do
		if race.name == name then
			return
		end
	end
	
	local race = Race(name , self , World.Create() , course)
	race.isPublic = isPublic
	if math.random() >= 0.5 then
		race.vehicleCollisions = false
	end
	table.insert(self.races , race)
	
	race:SetState("StateAddPlayers")
	
	-- Add players.
	for index , player in ipairs(players) do
		race:JoinPlayer(player)
	end
	
	if isPublic then
		self.numPublicRacesRan = self.numPublicRacesRan + 1
	else
		race:SetState("StateStartingGrid")
	end
	
	return race
	
end

function RaceManager:CreateRacePublic()
	
	self.currentPublicRace = self:CreateRace(self:GenerateName() , true)
	
end

function RaceManager:RemoveRace(raceToRemove)
	
	for n , race in ipairs(self.races) do
		-- Can't compare races directly for some reason.
		if race.name == raceToRemove.name then
			table.remove(self.races , n)
			break
		end
	end
	
end

function RaceManager:GetIsAdmin(player)
	
	local playerSteamId = player:GetSteamId()
	for n , steamId in ipairs(settings.admins) do
		if playerSteamId == steamId then
			return true
		end
	end
	
	return false
	
end

function RaceManager:HasPlayer(player)
	
	local playerId = Racing.PlayerId(player)
	
	return self.playerIds[playerId]
	
end

function RaceManager:RemovePlayer(player)
	
	for index , race in ipairs(self.races) do
		if race.playerIdToRacer[player:GetId()] then
			race:RemovePlayer(player)
			break
		end
	end
	
end

function RaceManager:MessagePlayer(player , message)
	
	player:SendChatMessage("[Racing] "..message , settings.textColorLocal)
	
end

function RaceManager:GenerateName()
	
	return "Public"..string.format("%i" , self.numPublicRacesRan + 1)
	
end

function RaceManager:AdminChangeSetting(player , settingName , value)
	
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

function RaceManager:AdminPrintSetting(player , settingName)
	
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

function RaceManager:PlayerChat(args)
	
	-- Split the message up into words (by spaces).
	local words = {}
	for word in string.gmatch(args.text , "[^%s]+") do
		table.insert(words , word)
	end
	
	if words[1] == settings.command then
		if words[2] == nil then
			-- Join a public race.
			if self.currentPublicRace:HasPlayer(args.player) then
				self.currentPublicRace:RemovePlayer(
					args.player ,
					"You have been removed from the race."
				)
			else
				if self:HasPlayer(args.player) then
					self:RemovePlayer(args.player)
				else
					self.currentPublicRace:JoinPlayer(args.player)
				end
			end
		elseif self:GetIsAdmin(args.player) then
			if words[2] == "create" and words[3] then
				self:CreateRace(words[3])
			elseif words[2] == "set" then
				self:AdminChangeSetting(args.player , words[3] , words[4])
			elseif words[2] == "get" then
				self:AdminPrintSetting(args.player , words[3])
			end
		end
	end
	
end

function RaceManager:ModuleUnload()
	
	-- Unsubscribe from all events.
	for n , event in ipairs(self.events) do
		Events:Unsubscribe(event)
	end
	
end

function RaceManager:JoinGamemode(args)
	if args.name ~= "Racing" then
		self:RemovePlayer(args.player)
	end
end
