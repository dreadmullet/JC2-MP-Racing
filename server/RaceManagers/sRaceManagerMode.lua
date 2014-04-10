class("RaceManagerMode")

RaceManagerMode.initializeDelay = 1.5

function RaceManagerMode:__init() ; RaceManagerBase.__init(self)
	self.courseManager = CourseManager("CourseManifest.txt")
	self.race = nil
	self.raceInfo = nil
	self.nextRaceInfo = nil
	self.isInitialized = false
	
	self:UpdateNextRaceInfo()
	
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
	self:NetworkSubscribe("AdminSkip")
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
	
	local course = self.courseManager:LoadCourseSequential()
	
	local args = {
		players = playerArray ,
		course = course ,
		collisions = self.nextRaceInfo.collisions ,
		modules = {"Mode"}
	}
	self.race = Race(args)
	
	self:UpdateRaceInfo()
	self:UpdateNextRaceInfo()
	self:UpdateVoteSkipInfo()
	
	local args = {
		raceInfo = self:MarshalCurrentRace() ,
		nextRaceInfo = self.nextRaceInfo ,
	}
	Network:Broadcast("RaceInfoChanged" , args)
end

function RaceManagerMode:UpdateRaceInfo()
	self.raceInfo = {
		id = self.race.id ,
		hasWinner = false ,
		timer = Timer() ,
		raceEndTime = nil ,
		-- Array of Players.
		skipVotes = {} ,
	}
end

function RaceManagerMode:MarshalCurrentRace()
	return {
		currentPlayers = self.race.numPlayers ,
		course = self.race.course:MarshalInfo() ,
		-- TODO: Shouldn't this be part of course?
		numCheckpoints = #self.race.course.checkpoints ,
		collisions = self.race.vehicleCollisions ,
	}
end

function RaceManagerMode:UpdateNextRaceInfo()
	self.nextRaceInfo = {
		courseName = self.courseManager:GetNextCourseName() ,
		collisions = math.random() >= 0.5 ,
	}
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
	
	self:Message("Race skipped")
	
	self:NetworkSend("RaceSkipped")
end

-- PlayerManager callbacks

function RaceManagerMode:ManagedPlayerJoin(player)
	-- Initialize the RaceManagerMode class on the client.
	local args = {
		className = "RaceManagerMode" ,
		nextRaceInfo = self.nextRaceInfo ,
	}
	if self.raceInfo then
		args.raceInfo = self:MarshalCurrentRace()
	end
	Network:Send(player , "InitializeClass" , args)
	
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
	-- The end time starts at 12 seconds and is proportional to:
	-- * the race time of the finisher
	-- ** If their time is 60 seconds, 7 seconds is added.
	-- ** If their time is 15 minutes, 1:48 is added.
	-- * the player count
	-- ** If there are 10 players, it is multiplied by 1.1
	-- ** If there are 100 players, it is multiplied by 2
	-- So, Endless Coast with 100 players may take 4:15 to end.
	if self.raceInfo.raceEndTime == nil then
		local seconds = 12
		seconds = seconds + self.raceInfo.timer:GetSeconds() * 0.12
		seconds = seconds * 1 + (self:GetPlayerCount() * 0.01)
		self:EndRaceIn(seconds)
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

function RaceManagerMode:AdminSkip(unused , player)
	if player:GetValue("isRaceAdmin") == true then
		self:SkipRace()
		Network:Send(player , "AcknowledgeAdminSkip")
	end
end
