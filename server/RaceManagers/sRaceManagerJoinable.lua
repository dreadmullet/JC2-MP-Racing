RaceManagerJoinable.command = "/race"
RaceManagerJoinable.startDelay = 120

function RaceManagerJoinable:__init() ; RaceManagerBase.__init(self)
	self.courseManager = CourseManager("CourseManifest.txt")
	-- Array of Races.
	self.races = {}
	-- Array of Players.
	self.playerQueue = {}
	self.nextCourse = nil
	-- Helps with storing position, model id, and inventory and restoring them when they leave.
	self.playerIdToRacerInfo = {}
	self.startTimer = Timer()
	
	self:SetupNextRace()
	
	self:EventSubscribe("PlayerChat")
	self:EventSubscribe("PreTick")
end

function RaceManagerJoinable:SetupNextRace()
	self.playerQueue = {}
	self.nextCourse = self.courseManager:LoadCourseRandom()
	
	self:Message("A race is about to start, use "..RaceManagerJoinable.command.." to join!")
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
	
	local race = Race(self , self.playerQueue , self.nextCourse)
	table.insert(self.races , race)
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
	for index , race in ipairs(self.races) do
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
	EGUSM.Print("PlayerManagerTerminate")
	-- Terminate all Races.
	for index , race in ipairs(self.races) do
		race:Terminate()
	end
end

-- Race callbacks

function RaceManagerJoinable:RacerFinish(racer)
	racer:Message("Use "..RaceManagerJoinable.command.." to leave the race")
end

function RaceManagerJoinable:RaceEnd(raceThatEnded)
	-- Remove this race from self.races.
	for index , race in ipairs(self.races) do
		if race == raceThatEnded then
			table.remove(self.races , index)
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
