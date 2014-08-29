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
	
	-- Assign racers
	
	local course = self.race.course
	
	local numRacers = table.count(self.race.playerIdToRacer)
	local maxRacers = course:GetMaxPlayers()
	if
		numRacers > maxRacers and
		self.race.overflowHandling ~= Race.OverflowHandling.StackSpawns
	then
		error("Too many racers for course! "..course.name..", "..numRacers.."/"..maxRacers)
	end
	
	local racers = {}
	for id , racer in pairs(self.race.playerIdToRacer) do
		table.insert(racers , racer)
	end
	-- Randomly sort the racers table. Otherwise, the starting grid is consistent; we want it to
	-- always be completely random.
	table.sortrandom(racers)
	-- Assign racers to spawns.
	local spawnIndex = 1
	for index , racer in ipairs(racers) do
		racer.startPosition = index -- TODO: Starting grid bug is here.
		
		local IsRacerCompatibleWithSpawn = function(spawn)
			-- This is WAY more complex than it should be. It should just be able to compare an index.
			for index , vehicleInfo in ipairs(spawn.vehicleInfos) do
				if vehicleInfo.modelId ~= racer.assignedVehicleInfo.modelId then
					goto continue
				end
				if #vehicleInfo.templates == 0 then
					goto continue
				end
				for index , template in ipairs(vehicleInfo.templates) do
					if racer.assignedVehicleInfo.template == template then
						return true
					end
				end
				
				::continue::
			end
			
			return false
		end
		
		local foundSpawn = false
		for index , spawn in ipairs(course.spawns) do
			if spawn.racer == nil and IsRacerCompatibleWithSpawn(spawn) == true then
				spawn.racer = racer
				foundSpawn = true
				break
			end
		end
		if foundSpawn == false then
			warn("Could not find appropriate spawn for "..tostring(racer.player))
			for index , spawn in ipairs(course.spawns) do
				if spawn.racer == nil then
					spawn.racer = racer
					break
				end
			end
		end
		
		spawnIndex = spawnIndex + 1
	end
	
	-- Spawn vehicles
	
	for n , spawn in ipairs(course.spawns) do
		if spawn.racer then
			spawn:SpawnVehicle()
		end
	end
	
	-- Spawn checkpoints
	
	for n, checkpoint in ipairs(course.checkpoints) do
		checkpoint:Spawn()
	end
	
	-- Spawn racers
	
	for n , spawn in ipairs(course.spawns) do
		spawn:SpawnRacer()
	end
	
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
			-- Dilute the effect of the Y axis on the resulting distance.
			local a = Copy(racer.courseSpawn.position)
			local b = Copy(vehicle:GetPosition())
			a.y = a.y * 0.4
			b.y = b.y * 0.4
			local distanceSquared = Vector3.DistanceSqr(a , b)
			if distanceSquared >= 4.2 then
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

function StateStartingGrid:RacerLeave(racerThatLeft)
	-- Remove them from self.startPositions.
	for playerId , startPosition in pairs(self.startPositions) do
		if playerId == racerThatLeft.playerId then
			self.startPositions[playerId] = nil
			break
		end
	end
	
	-- Remove them from self.updateList.
	for index , racer in ipairs(self.updateList) do
		if racer.player == racerThatLeft.player then
			table.remove(self.updateList , index)
			break
		end
	end
end

-- Events

function StateStartingGrid:PostTick()
	if self.startTimer:GetSeconds() >= self.race.startingGridSeconds then
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
