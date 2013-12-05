RaceManagerMode.settings = {}
RaceManagerMode.settings.initialiseDelay = 1

function RaceManagerMode:__init() ; RaceManagerBase.__init(self)
	self.isInitialised = false
	self.courseManager = CourseManager("CourseManifest.txt")
	self.race = nil
	
	self.timer = Timer()
	
	self:EventSubscribe("ClientModuleLoad")
	-- This is unsubscribed after a delay.
	self:EventSubscribe("PreTick")
end

-- Adds all players in the server to a new Race.
function RaceManagerMode:CreateRace(playerArray)
	local course = self.courseManager:LoadCourseRandom()
	local playerArray = {}
	for player in Server:GetPlayers() do
		table.insert(playerArray , player)
	end
	self.race = Race(self , playerArray , course)
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
			self.race:AddPlayer(player , "You have joined a race that is already in progress.")
		end
	end
end

function RaceManagerMode:ManagedPlayerLeave(player)
	self.race:RemovePlayer(player)
end

-- Race callbacks

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
	if self.timer:GetSeconds() > RaceManagerMode.settings.initialiseDelay then
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
		
		self:EventUnsubscribe("PreTick")
	end
end
