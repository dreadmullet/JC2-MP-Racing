RaceManagerMode.settings = {}
RaceManagerMode.settings.initialiseDelay = 1

class("RaceInfo")
function RaceInfo:__init()
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
	
	self:EventSubscribe("ClientModuleLoad")
	self:EventSubscribe("PreTick")
end

-- Adds all players in the server to a new Race.
function RaceManagerMode:CreateRace(playerArray)
	self:Message("Starting race with "..Server:GetPlayerCount().." players")
	
	local course = self.courseManager:LoadCourseRandom()
	local playerArray = {}
	for player in Server:GetPlayers() do
		table.insert(playerArray , player)
	end
	local doCollisions = math.random() > 0.55
	
	self.race = Race(self , playerArray , course , doCollisions)
	
	self.raceInfo = RaceInfo()
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
			-- TODO: Add as spectator
			self.race:AddSpectator(player)
		end
	end
end

function RaceManagerMode:ManagedPlayerLeave(player)
	self.race:RemovePlayer(player)
end

-- Race callbacks

function RaceManagerMode:RacerFinish(racer)
	-- If this is the first finisher, set the race end time.
	if self.raceInfo.hasWinner == false then
		self.raceInfo.hasWinner = true
		self.raceInfo.raceEndTime = self.raceInfo.timer:GetSeconds() * 1.06 + 12
	end
end

function RaceManagerMode:RaceEnd(raceThatEnded)
	-- Create a race if there are any players left.
	local playerCount = self:GetPlayerCount()
	if playerCount ~= 0 then
		self:CreateRace()
	end
end

-- Events

function RaceManagerMode:ClientModuleLoad(args)
	self:AddPlayer(args.player)
end

function RaceManagerMode:PreTick(args)
	-- We will not be initialised when the module is first loaded.
	if self.isInitialised == false then
		-- Delay the first race to make sure everyone's client has loaded.
		if self.initialiseTimer:GetSeconds() > RaceManagerMode.settings.initialiseDelay then
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
		end
	end
end
