----------------------------------------------------------------------------------------------------
-- Use /race to join a race. There is always a race running. When one starts, another begins.
----------------------------------------------------------------------------------------------------

function GMTestServer:__init()
	
	GMBase.__init(self)
	self.RaceStateChange = GMTestServer.RaceStateChange
	
	self.courseManagerAll = CourseManager("CourseManifest.txt")
	
	self.races = {}
	self.currentPublicRace = nil
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
	
end

function GMTestServer:CreateRace(name , isPublic , course , players)
	
	isPublic = isPublic or false
	players = players or {}
	course = course or self.courseManagerAll:LoadCourseRandom()
	
	-- Make sure race with this name doesn't already exist.
	for index , race in ipairs(self.races) do
		if race.name == name then
			return
		end
	end
	
	local race = Race(name , self , self:GetUnusedWorldId() , course)
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

function GMTestServer:CreateRacePublic()
	
	self.currentPublicRace = self:CreateRace(self:GenerateName() , true)
	
end

function GMTestServer:GetUnusedWorldId()
	
	local GetIsWorldUsed = function(id)
		for n , race in pairs(self.races) do
			if race.worldId == id then
				return true
			end
		end
		
		return false	
	end
	
	local newIndex = settings.worldIdBase
	while true do
		if GetIsWorldUsed(newIndex) == false then
			break
		end
		newIndex = newIndex + 1
	end
	
	return newIndex
	
end

function GMTestServer:RemoveRace(raceToRemove)
	
	for n , race in ipairs(self.races) do
		-- Can't compare races directly for some reason.
		if race.name == raceToRemove.name then
			table.remove(self.races , n)
			break
		end
	end
	
end

function GMTestServer:RemovePlayer(player)
	
	for index , race in ipairs(self.races) do
		if race.playerIdToRacer[player:GetId()] then
			race:RemovePlayer(player)
			break
		end
	end
	
end

function GMTestServer:GenerateName()
	
	return "Public"..string.format("%i" , self.numPublicRacesRan + 1)
	
end

function GMTestServer:RaceStateChange(race , stateName)
	
	-- Create another race when the current race starts.
	if stateName == "StateStartingGrid" then
		self:CreateRacePublic()
	end
	
end

--
-- Events
--

function GMTestServer:PlayerChat(args)
	
	if args.text:sub(1 , settings.command:len()) == settings.command then
		-- Split the message up into words (by spaces).
		local words = {}
		for word in string.gmatch(args.text , "[^%s]+") do
			table.insert(words , word)
		end
		
		if words[1] == settings.command and words[2] == nil then
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
			
			return true
		end
		
		return false
	end
	
	return true
	
end

function GMTestServer:ModuleUnload()
	
	-- Unsubscribe from all events.
	for n , event in ipairs(self.events) do
		Events:Unsubscribe(event)
	end
	
end
