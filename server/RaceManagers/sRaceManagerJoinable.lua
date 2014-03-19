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
	self:EventSubscribe("ClientModuleLoad")
	
	self:NetworkSubscribe("JoinRace")
	self:NetworkSubscribe("LeaveRace")
end

function RaceManagerJoinable:SetupNextRace()
	Stats.UpdateCache()
	
	self.playerQueue = {}
	self.nextCourse = self.courseManager:LoadCourseRandom()
	self.nextCourseCollisions = math.random() > 0.55
	
	local collisionsString = "off"
	if self.nextCourseCollisions then
		collisionsString = "on"
	end
	
	self:Message(
		"A race has started queueing, use /"..settings.command.." to open the race menu! "..
		"("..self.nextCourse.name..")"
	)
	
	Network:Broadcast("QueuedRaceCreate" , self:MarshalNextRace())
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
	
	local args = {
		players = self.playerQueue ,
		course = self.nextCourse ,
		collisions = self.nextCourseCollisions ,
		modules = {"Joinable"}
	}
	local race = Race(args)
	self.raceIdToRace[race.id] = race
	self:SetupNextRace()
end

function RaceManagerJoinable:MarshalNextRace()
	return {
		currentPlayers = #self.playerQueue ,
		maxPlayers = self.nextCourse:GetMaxPlayers() ,
		course = self.nextCourse:MarshalInfo() ,
		numCheckpoints = #self.nextCourse.checkpoints ,
		collisions = self.nextCourseCollisions ,
	}
end

-- PlayerManager callbacks

function RaceManagerJoinable:ManagedPlayerJoin(player)
	-- Add this player to playerQueue.
	table.insert(self.playerQueue , player)
	Network:Send(player , "JoinQueue")
	-- If the queue becomes full or all players have joined, start a race.
	if
		#self.playerQueue == #self.nextCourse.spawns or
		#self.playerQueue == Server:GetPlayerCount()
	then
		self:CreateRace()
	-- Otherwise, update the player count for everyone.
	else
		Network:Broadcast("QueuedRacePlayersChange" , #self.playerQueue)
	end
end

function RaceManagerJoinable:ManagedPlayerLeave(player)
	-- Search playerQueue for this player and remove them.
	for index , playerToRemove in ipairs(self.playerQueue) do
		if playerToRemove == player then
			table.remove(self.playerQueue , index)
			Network:Send(player , "LeaveQueue")
			break
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
		for slot , weapon in pairs(racerInfo.inventory) do
			player:GiveWeapon(slot , weapon)
		end
	end
	-- Update the player count for everyone.
	Network:Broadcast("QueuedRacePlayersChange" , #self.playerQueue)
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

function RaceManagerJoinable:ClientModuleLoad(args)
	local constructorArgs = {
		className = "RaceManagerJoinable" ,
		raceInfo = self:MarshalNextRace()
	}
	Network:Send(args.player , "InitializeClass" , constructorArgs)
end

-- Network events

function RaceManagerJoinable:JoinRace(unused , player)
	self:AddPlayer(player)
end

function RaceManagerJoinable:LeaveRace(unused , player)
	self:RemovePlayer(player)
end
