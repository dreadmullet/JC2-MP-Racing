function RaceManagerJoinable:__init() ; EGUSM.PlayerManager.__init(self)
	self.courseManager = CourseManager("CourseManifest.txt")
	-- Array of Races.
	self.races = {}
	-- Array of Players.
	self.playerQueue = {}
	self.nextCourse = nil
	
	self:SetupNextRace()
	
	self:EventSubscribe("PlayerChat")
end

function RaceManagerJoinable:SetupNextRace()
	self.playerQueue = {}
	self.nextCourse = self.courseManager:LoadCourseRandom()
end

function RaceManagerJoinable:StartRace()
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
		self:StartRace()
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
end

function RaceManagerJoinable:PlayerManagerTerminate()
	EGUSM.Print("PlayerManagerTerminate")
	-- Terminate all Races.
	for index , race in ipairs(self.races) do
		race:Terminate()
	end
end

-- Race callbacks

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
	if args.text == settings.command then
		if self:HasPlayer(args.player) then
			self:RemovePlayer(args.player)
		else
			self:AddPlayer(args.player)
		end
		return false
	end
	
	return true
end
