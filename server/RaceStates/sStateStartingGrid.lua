
function StateStartingGrid:__init(race) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	self.eventSubs = {}
	
	race.course:AssignRacers(self.race.playerIdToRacer)
	race.course:SpawnVehicles()
	race.course:SpawnRacers()
	race.course:SpawnCheckpoints()
	race.course.numLaps = settings.numLapsFunc(
		race.numPlayers ,
		#race.course.spawns ,
		race.course.numLaps
	)
	
	self.startTimer = Timer()
	
	-- Send info to clients.
	
	-- Loop through all racers:
	--    Create each racer's raceTimer.
	--    Add ourselves to the database.
	--    Get names of racers and whatnot, which will be sent to clients.
	local playerIdToInfo = {}
	for playerId , racer in pairs(self.race.playerIdToRacer) do
		racer.raceTimer = Timer()
		
		Stats.AddPlayer(racer)
		
		playerIdToInfo[playerId] = {["name"] = racer.name , ["color"] = racer.player:GetColor()}
	end
	
	-- Update database.
	Stats.RaceStart(self.race)
	
	local startPositions = {}
	for playerId , racer in pairs(self.race.playerIdToRacer) do
		startPositions[racer.playerId] = racer.startPosition
	end
	
	-- TODO: Why is args created every iteration
	for id , racer in pairs(self.race.playerIdToRacer) do
		local args = {}
		args.stateName = "StateStartingGrid"
		args.delay = settings.startingGridWaitSeconds
		args.numPlayers = self.race.numPlayers
		args.playerIdToInfo = playerIdToInfo
		args.startPositions = startPositions
		args.courseInfo = {
			race.course.name ,
			race.course.type ,
			race.course.numLaps ,
			race.course.weatherSeverity ,
			race.course.authors ,
			race.course.parachuteEnabled ,
			race.course.grappleEnabled ,
		}
		args.recordTime = race.course.topRecords[1].time
		args.recordTimePlayerName = race.course.topRecords[1].playerName
		args.checkpointPositions = self.race.checkpointPositions
		-- Player-specific.
		args.assignedVehicleId = racer.assignedVehicleId
		Network:Send(racer.player , "RaceSetState" , args)
	end
	
	self:EventSubscribe("PreTick")
	self:EventSubscribe("PlayerEnterVehicle")
	self:EventSubscribe("PlayerSpawn")
end

function StateStartingGrid:PreTick()
	if self.startTimer:GetSeconds() >= settings.startingGridWaitSeconds then
		self.race:SetState("StateRacing")
	end
end

function StateStartingGrid:End()
	self:Destroy()
end

-- Events

function StateStartingGrid:PlayerEnterVehicle(args)
	local racer = self.race.playerIdToRacer[args.player:GetId()]
	if racer then
		racer:EnterVehicle(args)
	end
end

function StateStartingGrid:PlayerSpawn(args)
	local racer = self.race.playerIdToRacer[args.player:GetId()]
	if racer then
		racer:Respawn()
	end
	
	return false
end
