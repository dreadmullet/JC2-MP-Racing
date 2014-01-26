RaceManagerJoinable.command = "/race"
RaceManagerJoinable.startDelay = 120

function RaceManagerJoinable:__init() ; RaceManagerBase.__init(self)
	self.courseManager = CourseManager("CourseManifest.txt")
	self.raceIdToRace = {}
	-- Array of Players.
	self.playerQueue = {}
	self.nextCourse = nil
	self.nextCourseCollisions = true
	-- Helps with storing position, model id, and inventory and restoring them when they leave.
	self.playerIdToRacerInfo = {}
	self.startTimer = Timer()
	
	self:SetupNextRace()
	
	self:EventSubscribe("RacerFinish")
	self:EventSubscribe("RaceEnd")
	self:EventSubscribe("PlayerChat")
	self:EventSubscribe("PreTick")
end

function RaceManagerJoinable:SetupNextRace()
	self.playerQueue = {}
	self.nextCourse = self.courseManager:LoadCourseRandom()
	self.nextCourseCollisions = math.random() > 0.55
	
	local collisionsString = "off"
	if self.nextCourseCollisions then
		collisionsString = "on"
	end
	
	self:Message(
		"A race is about to start, use "..RaceManagerJoinable.command.." to join! "..
		"("..self.nextCourse.name..", collisions "..collisionsString..")"
	)
end

function RaceManagerJoinable:CreateRace()
	self:Message("Starting race with "..#self.playerQueue.." players")
	
	-- Store everyone's position, inventory, and model.
	self:IteratePlayers(
		function(player)
			local info = {}
			info.position = player:GetPosition()
			info.modelId = player:GetModelId()
			info.inventory = player:GetInventory()
			player:ClearInventory()
			self.playerIdToRacerInfo[player:GetId()] = info
		end
	)
	
	local race = Race(self.playerQueue , self.nextCourse , self.nextCourseCollisions)
	self.raceIdToRace[race.id] = race
	self:SetupNextRace()
end

-- PlayerManager callbacks

function RaceManagerJoinable:ManagedPlayerJoin(player)
	-- Add this player to playerQueue.
	table.insert(self.playerQueue , player)
	-- If the queue becomes full or all players have joined, start a race.
	if
		#self.playerQueue == #self.nextCourse.spawns or
		#self.playerQueue == Server:GetPlayerCount()
	then
		self:CreateRace()
	end
end

function RaceManagerJoinable:ManagedPlayerLeave(player)
	-- Search playerQueue for this player and remove them.
	for index , player in ipairs(self.playerQueue) do
		if player == player then
			table.remove(self.playerQueue , index)
			return
		end
	end
	-- Search all Races for this player and remove them.
	for raceId , race in pairs(self.raceIdToRace) do
		race:RemovePlayer(player)
	end
	-- Give them back their position, model, and inventory, if applicable.
	local racerInfo = self.playerIdToRacerInfo[player:GetId()]
	if racerInfo then
		player:SetPosition(racerInfo.position)
		player:SetModelId(racerInfo.modelId)
		for index , weapon in pairs(racerInfo.inventory) do
			player:GiveWeapon(index , weapon)
		end
	end
end

function RaceManagerJoinable:PlayerManagerTerminate()
	if EGUSM.debug then
		EGUSM.Print("PlayerManagerTerminate")
	end
	-- Terminate all Races.
	for raceId , race in pairs(self.raceIdToRace) do
		race:Terminate()
	end
end

-- Race events

function RaceManagerJoinable:RacerFinish(args)
	-- Attempt to find the race.
	local race = self.raceIdToRace[args.id]
	-- Make sure this is one of our races.
	if race == nil then
		return
	end
	
	local racer = race:GetRacerFromPlayerId(args.playerId)
	racer:Message("Use "..RaceManagerJoinable.command.." to leave the race")
end

function RaceManagerJoinable:RaceEnd(args)
	-- Attempt to find the race.
	local race = self.raceIdToRace[args.id]
	-- Make sure this is one of our races.
	if race == nil then
		return
	end
	
	-- Remove this race from self.raceIdToRace.
	for raceId , race in pairs(self.raceIdToRace) do
		if race == raceThatEnded then
			raceIdToRace[raceId] = nil
			break
		end
	end
end

-- Events

function RaceManagerJoinable:PlayerChat(args)
	if args.text == RaceManagerJoinable.command then
		if self:HasPlayer(args.player) then
			self:RemovePlayer(args.player)
		else
			self:AddPlayer(args.player)
		end
		return false
	end
	
	return true
end

function RaceManagerJoinable:PreTick()
	if #self.playerQueue > 0 then
		if self.startTimer:GetSeconds() > RaceManagerJoinable.startDelay then
			self:CreateRace()
		end
	else
		self.startTimer = Timer()
	end
end
