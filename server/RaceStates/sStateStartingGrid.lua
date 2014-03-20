class("StateStartingGrid")

function StateStartingGrid:__init(race) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	self.eventSubs = {}
	
	race.course:AssignRacers(self.race.playerIdToRacer)
	race.course:SpawnVehicles()
	race.course:SpawnRacers()
	race.course:SpawnCheckpoints()
	
	self.startTimer = Timer()
	
	-- Loop through all racers and create their raceTimer.
	for playerId , racer in pairs(self.race.playerIdToRacer) do
		racer.raceTimer = Timer()
	end
	
	-- Update database.
	-- TODO: why is this here
	Stats.RaceStart(self.race)
	
	-- TODO: This is completely broken.
	self.startPositions = {}
	for playerId , racer in pairs(self.race.playerIdToRacer) do
		self.startPositions[racer.playerId] = racer.startPosition
	end
	
	-- Send info to clients.
	
	local args = {
		stateName = "StateStartingGrid" ,
		delay = settings.startingGridWaitSeconds ,
		startPositions = self.startPositions
	}
	for id , racer in pairs(self.race.playerIdToRacer) do
		args.assignedVehicleId = racer.assignedVehicleId
		Network:Send(racer.player , "RaceSetState" , args)
	end
	
	self:EventSubscribe("PostTick")
	self:EventSubscribe("PlayerEnterVehicle")
	self:EventSubscribe("PlayerSpawn")
end

function StateStartingGrid:PostTick()
	if self.startTimer:GetSeconds() >= settings.startingGridWaitSeconds then
		self.race:SetState("StateRacing")
	end
end

function StateStartingGrid:End()
	self:Destroy()
end

function StateStartingGrid:RacerLeave(racer)
	for playerId , startPosition in pairs(self.startPositions) do
		if playerId == racer.playerId then
			self.startPositions[playerId] = nil
			break
		end
	end
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
