class("RaceManagerMode")

class("RaceInfo")
function RaceInfo:__init(race)
	self.id = race.id
	self.hasWinner = false
	self.timer = Timer()
	self.raceEndTime = nil
	-- Array of Players.
	self.skipVotes = {}
end

function RaceManagerMode:__init() ; RaceManagerBase.__init(self)
	self.courseManager = CourseManager("CourseManifest.txt")
	self.race = nil
	self.raceInfo = nil
	self.isInitialized = false
	
	-- Add all players in the server to us.
	for player in Server:GetPlayers() do
		self:AddPlayer(player)
	end
	-- Create a race if there are any players.
	if self:GetPlayerCount() ~= 0 then
		self:CreateRace()
	end
	
	self.isInitialized = true
	
	self:EventSubscribe("RacerFinish")
	self:EventSubscribe("RaceEnd")
	self:EventSubscribe("ClientModuleLoad")
	self:EventSubscribe("PreTick")
	self:NetworkSubscribe("VoteSkip")
end

-- Adds all players in the server to a new Race.
function RaceManagerMode:CreateRace()
	self:Message("Starting race with "..self:GetPlayerCount().." players")
	
	if self.race and self.race.isValid then
		error("RaceManagerMode is trying to create a race, but a race is still running!")
	end
	
	local playerArray = {}
	for player in Server:GetPlayers() do
		table.insert(playerArray , player)
	end
	
	local course = self.courseManager:LoadCourseRandom()
	if #playerArray > course:GetMaxPlayers() then
		self.courseManager:RemoveCourse(course.name)
		error("Too many players for course, "..course.name.." can only fit "..course:GetMaxPlayers())
	end
	
	local args = {
		players = playerArray ,
		course = course ,
		collisions = true , -- temporary
		modules = {"Mode"}
	}
	self.race = Race(args)
	
	self.raceInfo = RaceInfo(self.race)
	
	self:UpdateVoteSkipInfo()
end

function RaceManagerMode:UpdateVoteSkipInfo()
	local skipVotes = 0
	if self.raceInfo ~= nil then
		skipVotes = #self.raceInfo.skipVotes
	end
	
	local args = {
		skipVotes = skipVotes ,
		skipVotesRequired = self:GetRequiredSkipVotes() ,
	}
	self:NetworkSend("UpdateVoteSkipInfo" , args)
end

function RaceManagerMode:GetRequiredSkipVotes()
	return math.ceil(self:GetPlayerCount() * 0.475)
end

function RaceManagerMode:EndRaceIn(seconds)
	self.raceInfo.raceEndTime = self.raceInfo.timer:GetSeconds() + seconds
	
	if seconds ~= 0 then
		self:NetworkSend("RaceWillEndIn" , seconds)
	end
end

function RaceManagerMode:SkipRace()
	if self.race.stateName == "StateRacing" then
		self:EndRaceIn(8)
	else
		self:EndRaceIn(0)
	end
	
	self:NetworkSend("RaceSkipped")
end

-- PlayerManager callbacks

function RaceManagerMode:ManagedPlayerJoin(player)
	-- Initialize the RaceManagerMode class on the client.
	local constructorArgs = {
		className = "RaceManagerMode"
	}
	if self.raceInfo then
		-- constructorArgs.raceInfo = somethinghere
	end
	Network:Send(player , "InitializeClass" , constructorArgs)
	
	if self.isInitialized then
		-- If this is the first person to join the server, create the race.
		if self:GetPlayerCount() == 1 and self.raceInfo == nil then
			self:CreateRace()
		-- Otherwise, add them to the current race.
		else
			self.race:AddSpectator(player)
		end
	end
	
	self:UpdateVoteSkipInfo()
end

function RaceManagerMode:ManagedPlayerLeave(player)
	self.race:RemovePlayer(player)
	
	if self.raceInfo then
		table.erase(self.raceInfo.skipVotes , player)
	end
end

-- Race events

function RaceManagerMode:RacerFinish(args)
	-- Make sure a race is running and this is our race.
	if self.raceInfo == nil or args.id ~= self.raceInfo.id then
		return
	end
	
	-- If this is the first finisher, set the race end time.
	if self.raceInfo.raceEndTime == nil then
		self:EndRaceIn(12 + self.raceInfo.timer:GetSeconds() * 0.16)
	end
end

function RaceManagerMode:RaceEnd(args)
	-- Make sure a race is running and this is our race.
	if self.raceInfo == nil or args.id ~= self.raceInfo.id then
		return
	end
	
	self.raceInfo = nil
end

-- Events

function RaceManagerMode:ClientModuleLoad(args)
	self:AddPlayer(args.player)
end

function RaceManagerMode:PreTick(args)
	-- If someone has finished and it's time to end the race, end it.
	if
		self.raceInfo and
		self.raceInfo.raceEndTime and
		self.raceInfo.timer:GetSeconds() > self.raceInfo.raceEndTime
	then
		self.raceInfo = nil
		self.race:Terminate()
		
		Stats.UpdateCache()
	elseif self.raceInfo == nil then
		-- If there isn't a race, and there are players, create a race.
		local playerCount = self:GetPlayerCount()
		if playerCount ~= 0 then
			self:CreateRace()
		end
	end
end

-- Network events

function RaceManagerMode:VoteSkip(vote , player)
	if
		type(vote) ~= "boolean" or
		self:HasPlayer(player) == false or
		self.raceInfo == nil or
		self.raceInfo.raceEndTime ~= nil
	then
		return
	end
	
	if vote == true then
		if table.find(self.raceInfo.skipVotes , player) == nil then
			table.insert(self.raceInfo.skipVotes , player)
		end
	else
		table.erase(self.raceInfo.skipVotes , player)
	end
	
	if #self.raceInfo.skipVotes >= self:GetRequiredSkipVotes() then
		self:SkipRace()
	else
		Network:Send(player , "AcknowledgeVoteSkip" , vote)
		self:UpdateVoteSkipInfo()
	end
end
