----------------------------------------------------------------------------------------------------
-- Cars spawn, and players are teleported to their cars.
----------------------------------------------------------------------------------------------------

function StateStartingGrid:__init(race)
	
	self.race = race
	self.eventSubs = {}
	
	if settings.WTF then
		WTF.RandomiseCourseVehicles(race.course)
		WTF.RandomiseCheckpointActions(race.course)
	end
	race.course:AssignRacers(self.race.playerIdToRacer)
	race.course:SpawnVehicles()
	race.course:SpawnRacers()
	race.course:SpawnCheckpoints()
	race.course.numLaps = settings.numLapsFunc(race , race.course.numLaps)
	
	self.startTimer = Timer()
	
	Utility.EventSubscribe(self , "PlayerChat")
	Utility.EventSubscribe(self , "PlayerEnterVehicle")
	Utility.EventSubscribe(self , "PlayerExitVehicle")
	Utility.EventSubscribe(self , "PlayerDeath")
	
	-- If we somehow started without racers, end the race.
	if self.race.numPlayers == 0 then
		self.race:MessageServer("Race somehow started with no players! Ending race.")
		self.race:CleanUp()
	end
	
	-- Tell the race manager to create another public race.
	if settings.doPublicRaces then
		self.race.raceManager:CreateRacePublic()
	end
	
	--
	-- Send info to clients.
	--
	
	-- Set up a new checkpoints table, containing only the data to send out.
	local checkpointData = {} -- [1] = {1}
	for n = 1 , #race.course.checkpoints do
		table.insert(checkpointData , race.course.checkpoints[n].position)
	end
	
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
		args.checkpointData = checkpointData
		-- Player-specific.
		args.assignedVehicleId = racer.assignedVehicleId
		Network:Send(racer.player , "SetState" , args)
	end
	
end

function StateStartingGrid:Run()
	
	if self.startTimer:GetSeconds() >= settings.startingGridWaitSeconds then
		self.race:SetState("StateRacing")
	end
	
end

function StateStartingGrid:End()
	
	Utility.NetUnsubscribeAll(self)
	
end

function StateStartingGrid:PlayerChat(args)
	
	-- If the race is public, it's not our hands; it's handled by the RaceManager.
	if self.race.isPublic then
		return
	end
	
	if args.text == settings.command then
		if self.race:HasPlayer(args.player) then
			self.race:RemovePlayer(
				args.player ,
				"You have exited the race."
			)
			
			return false
		end
	end
	
	return true
	
end

function StateStartingGrid:PlayerEnterVehicle(args)
	
	local racer = self.race.playerIdToRacer[args.player:GetId()]
	if racer then
		racer:EnterVehicle(args)
	end
	
end

function StateStartingGrid:PlayerExitVehicle(args)
	
	local racer = self.race.playerIdToRacer[args.player:GetId()]
	if racer then
		racer:ExitVehicle(args)
	end
	
end

function StateStartingGrid:PlayerDeath(args)
	
	local racer = self.race.playerIdToRacer[args.player:GetId()]
	if racer then
		racer.deathTimer = Timer()
		self.race.playersDead[racer.player:GetId()] = true
		
		self.race:MessageRace(args.player:GetName().." has died!")
	end
	
end
