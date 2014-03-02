RaceManagerMode.initialiseDelay = 1

class("RaceInfo")
function RaceInfo:__init(race)
	self.id = race.id
	self.hasWinner = false
	self.timer = Timer()
	self.raceEndTime = -1
end

function RaceManagerMode:__init() ; RaceManagerBase.__init(self)
	self.isInitialised = false
	self.courseManager = CourseManager("CourseManifest.txt")
	self.race = nil
	self.raceInfo = nil
	-- Helps with delaying the first race.
	self.initialiseTimer = Timer()
	
	self:EventSubscribe("RacerFinish")
	self:EventSubscribe("RaceEnd")
	self:EventSubscribe("ClientModuleLoad")
	self:EventSubscribe("PreTick")
end

-- Adds all players in the server to a new Race.
function RaceManagerMode:CreateRace()
	self:Message("Starting race with "..Server:GetPlayerCount().." players")
	
	local playerArray = {}
	for player in Server:GetPlayers() do
		table.insert(playerArray , player)
	end
	
	local course = self.courseManager:LoadCourseRandom()
	if #playerArray > course:GetMaxPlayers() then
		error("Too many players for course, "..course.name.." can only fit "..course:GetMaxPlayers())
	end
	
	local args = {
		players = playerArray ,
		course = course ,
		collisions = true -- temporary
	}
	self.race = Race(args)
	
	self.raceInfo = RaceInfo(self.race)
end

-- PlayerManager callbacks

function RaceManagerMode:ManagedPlayerJoin(player)
	player:ClearInventory()
	
	if self.isInitialised then
		-- If this is the first person to join the server, create the race.
		if self:GetPlayerCount() == 1 then
			self:CreateRace()
		-- Otherwise, add them to the current race.
		else
			self.race:AddSpectator(player)
		end
	end
end

function RaceManagerMode:ManagedPlayerLeave(player)
	self.race:RemovePlayer(player)
end

-- Race events

function RaceManagerMode:RacerFinish(args)
	-- Make sure a race is running and this is our race.
	if self.raceInfo == nil or args.id ~= self.raceInfo.id then
		return
	end
	
	-- If this is the first finisher, set the race end time.
	if self.raceInfo.hasWinner == false then
		self.raceInfo.hasWinner = true
		self.raceInfo.raceEndTime = self.raceInfo.timer:GetSeconds() * 1.06 + 12
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
	-- We will not be initialised when the module is first loaded.
	if self.isInitialised == false then
		-- Delay the first race to make sure everyone's client has loaded.
		if self.initialiseTimer:GetSeconds() > RaceManagerMode.initialiseDelay then
			-- Add all players to us.
			for player in Server:GetPlayers() do
				self:AddPlayer(player)
			end
			-- Create a race if there are any players.
			local playerCount = Server:GetPlayerCount()
			if playerCount ~= 0 then
				self:CreateRace()
			end
			
			self.isInitialised = true
		end
	else
		-- If someone has finished and it's time to end the race, end it.
		if
			self.raceInfo and
			self.raceInfo.hasWinner and
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
end
