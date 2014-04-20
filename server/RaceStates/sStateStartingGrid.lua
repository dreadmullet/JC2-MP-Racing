class("StateStartingGrid")

function StateStartingGrid:__init(race) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	-- Number of times PostTick has been called.
	self.numTicks = 0
	
	-- Array of Racers. This is used to call UpdateRacer on us once per tick.
	self.updateList = {}
	for id , racer in pairs(self.race.playerIdToRacer) do
		table.insert(self.updateList , racer)
	end
	
	race.course:AssignRacers(self.race.playerIdToRacer)
	race.course:SpawnVehicles()
	race.course:SpawnRacers()
	race.course:SpawnCheckpoints()
	
	self.startTimer = Timer()
	
	-- Loop through all racers
	-- * Set their world.
	-- * Create their raceTimer.
	for playerId , racer in pairs(self.race.playerIdToRacer) do
		racer.raceTimer = Timer()
		racer.player:SetWorld(self.race.world)
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
		startPositions = self.startPositions
	}
	for id , racer in pairs(self.race.playerIdToRacer) do
		args.assignedVehicleId = racer.assignedVehicleId
		Network:Send(racer.player , "RaceSetState" , args)
	end
	args.assignedVehicleId = nil
	for id , spectator in pairs(self.race.playerIdToSpectator) do
		Network:Send(spectator.player , "RaceSetState" , args)
	end
	
	self:EventSubscribe("PostTick")
	self:EventSubscribe("PlayerEnterVehicle")
	self:EventSubscribe("PlayerSpawn")
end

function StateStartingGrid:End()
	self:Destroy()
end

function StateStartingGrid:UpdateRacer(racer)
	-- If they travel too far from their starting slot, respawn them.
	local shouldRespawn = false
	if racer.assignedVehicleId == -1 then
		local distance = Vector3.Distance2D(racer.courseSpawn.position , racer.player:GetPosition())
		if distance >= 1.2 and distance < 150 then
			shouldRespawn = true
		end
	else
		local vehicle = Vehicle.GetById(racer.assignedVehicleId)
		if vehicle then
			local distance = Vector3.Distance2D(racer.courseSpawn.position , vehicle:GetPosition())
			if distance >= 2 then
				shouldRespawn = true
			end
			
			if vehicle:GetHealth() < 0.75 then
				shouldRespawn = true
			end
		end
	end
	
	if shouldRespawn then
		if settings.debugLevel >= 2 then
			print("Respawning player because they're out of their starting slot")
		end
		racer:Respawn()
	end
end

-- Race callbacks

function StateStartingGrid:RacerLeave(racer)
	-- Remove them from self.startPositions.
	for playerId , startPosition in pairs(self.startPositions) do
		if playerId == racer.playerId then
			self.startPositions[playerId] = nil
			break
		end
	end
	
	-- Remove them from self.updateList.
	for index , racer in ipairs(self.updateList) do
		if racer.player == racer.player then
			table.remove(self.updateList , index)
			break
		end
	end
end

-- Events

function StateStartingGrid:PostTick()
	if self.startTimer:GetSeconds() >= settings.startingGridSeconds then
		self.race:SetState("StateRacing")
	end
	
	-- Call UpdateRacer on one racer. If the list is less than 50, then sometimes skip.
	local index = (self.numTicks % math.max(50 , #self.updateList)) + 1
	if index <= #self.updateList then
		local racer = self.updateList[index]
		if IsValid(racer.player) then
			self:UpdateRacer(racer)
		end
	end
	
	self.numTicks = self.numTicks + 1
end

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
