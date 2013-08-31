
function Racer:__init(race , player)
	
	self.race = race
	self.player = player
	self.playerId = player:GetId()
	self.name = player:GetName()
	self.steamId = player:GetSteamId().Id
	-- Pulled from database, and used to update database on our removal.
	self.playTime = -1
	self.originalPosition = player:GetPosition()
	self.originalModelId = player:GetModelId()
	self.targetCheckpoint = 1
	self.numLapsCompleted = 0
	self.numCheckpointsHit = 0
	self.hasFinished = false
	self.assignedVehicleId = -1
	self.outOfVehicleTimer = nil
	self.storedInventory = nil
	-- Used with racePosTracker and helps with NetworkSend parameters.
	self.targetCheckpointDistanceSqr = {[1] = 0}
	self.updateTick = race.numPlayers
	-- Begins at starting grid, used to update playTime.
	self.raceTimer = nil
	-- Procs at end of lap for circuits, or end of race for linear courses.
	self.bestTimeTimer = nil
	-- Used for both circuits and linear courses.
	self.bestTime = -1
	-- Position in leaderboard.
	self.startPosition = -1
	self.courseSpawn = nil
	
	if race.raceManager:GetIsAdmin(player) then
		player:SetModelId(settings.playerModelIdAdmin)
	else
		player:SetModelId(table.randomvalue(settings.playerModelIds))
	end
	
	local args = {}
	args.version = settings.version
	args.stateName = self.race.stateName
	args.maxPlayers = self.race.maxPlayers
	Network:Send(self.player , "Initialize" , args)
	
end

function Racer:RaceStart()
	
	self.outOfVehicleTimer = Timer()
	self.race.playersOutOfVehicle[self.playerId] = true
	
	self.bestTimeTimer = Timer()
	
	-- Disable collisions, if applicable.
	if self.race.vehicleCollisions == false then
		self.player:DisableCollision(CollisionGroup.Vehicle)
	end
	
	-- Store our inventory.
	self.storedInventory = self.player:GetInventory()
	self.player:ClearInventory()
	
end

function Racer:Update()
	
	local finishedPlayerIds = {}
	for index , racer in ipairs(self.race.finishedRacers) do
		table.insert(finishedPlayerIds , racer.playerId)
	end
	
	Network:Send(
		self.player ,
		"UpdateRacePositions" ,
		{
			self.race.state.racePosTracker ,
			self.race.state.currentCheckpoint ,
			finishedPlayerIds
		}
	)
	
end

function Racer:Remove()
	
	-- Update database with our new playtime, if the timer is running.
	if self.raceTimer then
		self.playTime = self.playTime + self.raceTimer:GetSeconds()
		Stats.PlayerExit(self)
	end
	
	self.player:SetPosition(self.originalPosition)
	self.player:SetModelId(self.originalModelId)
	self.player:SetWorldId(-1)
	
	-- Restore our inventory if it exists.
	if self.storedInventory then
		for index , weapon in pairs(self.storedInventory) do
			self.player:GiveWeapon(index , weapon)
		end
	end
	
	-- Remove our vehicle.
	local vehicle = Vehicle.GetById(self.assignedVehicleId)
	if vehicle then
		vehicle:Remove()
	end
	
	self.race.playersOutOfVehicle[self.player:GetId()] = nil
	
	local args = {}
	args.stateName = "StateTerminate"
	Network:Send(self.player , "SetState" , args)
	
end

function Racer:AdvanceCheckpoint(index)
	
	self.targetCheckpoint = self.targetCheckpoint + 1
	if self.targetCheckpoint > #self.race.course.checkpoints then
		self.targetCheckpoint = 1
	end
	self.numCheckpointsHit = self.numCheckpointsHit + 1
	
	-- If this is not set to a large value, it will contain the previous value, which is small.
	self.targetCheckpointDistanceSqr[1] = 1000000000
	
	-- racePosTracker: Remove us from table containing racers with previous number of checkpoints hit.
	self.race.state.racePosTracker[self.numCheckpointsHit - 1][self.player:GetId()] = nil
	-- Initialize the table in racePosTracker if it doesn't exist yet. Also, since we are the first 
	-- racer to hit this checkpoint, increase currentCheckpoint.
	if self.race.state.racePosTracker[self.numCheckpointsHit] == nil then
		self.race.state.racePosTracker[self.numCheckpointsHit] = {}
		self.race.state.currentCheckpoint = self.race.state.currentCheckpoint + 1
	end
	
	-- If this is the final checkpoint, advance lap if it's a circuit, or finish the race if it's
	-- linear. Also get best lap time here.
	if index == #self.race.course.checkpoints then
		if self.race.course.type == "Circuit" then
			self:AdvanceLap()
		elseif self.race.course.type == "Linear" then
			self:Finish()
		end
	end
	
	-- Add racer to table that contains racers who have hit the current number of checkpoints. Only
	-- add it if they're still racing.
	if self.hasFinished == false then
		self.race.state.racePosTracker[self.numCheckpointsHit][self.player:GetId()] = (
			self.targetCheckpointDistanceSqr
		)
	end
	
	Network:Send(self.player , "SetTargetCheckpoint" , self.targetCheckpoint)
	
end

function Racer:AdvanceLap()
	
	self.targetCheckpoint = 1
	self.numLapsCompleted = self.numLapsCompleted + 1
	
	local lapTime = self.bestTimeTimer:GetSeconds()
	
	-- If we don't have a best lap time yet, just set it.
	if self.bestTime == -1 then
		self.bestTime = lapTime
	-- Otherwise, only set our best lap time if this lap was faster.
	else
		if lapTime < self.bestTime then
			self.bestTime = lapTime
		end
	end
	
	Network:Send(self.player , "RaceTimePersonal" , lapTime)
	
	-- If this is a new record, send every racer the new time/player and store the new time in the
	-- database.
	-- TODO: Change topRecords if we make it into the top x, not just the very top.
	if lapTime < self.race.course.topRecords[1].time then
		self.race:NetworkSendRace("NewRecordTime" , {lapTime , self.name})
		self.race.course.topRecords[1].time = lapTime
		self.race.course.topRecords[1].playerName = self.name
	end
	
	self.bestTimeTimer:Restart()
	
	-- Finish the race if we've completed all laps.
	if self.numLapsCompleted >= self.race.course.numLaps and self.hasFinished == false then
		self:Finish()
	end
	
end

-- TODO: This and Race.RacerFinish are too similar.
function Racer:Finish()
	
	self.hasFinished = true
	
	-- Handle Linear course records. Circuit records are handled in AdvanceLap, above.
	if self.race.course.type == "Linear" then
		local raceTime = self.race.state.timer:GetSeconds()
		
		self.bestTime = raceTime
		
		Network:Send(self.player , "RaceTimePersonal" , raceTime)
		
		-- If this is a new record, send every racer the new time/player and store the new time in the
		-- database.
		if raceTime < self.race.course.topRecords[1].time then
			self.race:NetworkSendRace("NewRecordTime" , {raceTime , self.name})
			self.race.course.topRecords[1].time = raceTime
			self.race.course.topRecords[1].playerName = self.name
		end
	end
	
	self.race:RacerFinish(self)
	
	DelayedFunction(
		settings.playerFinishRemoveDelay ,
		function(racer)
			if racer.race:HasPlayer(racer.player) then
				racer.race:RemovePlayer(racer.player)
			end
		end ,
		self
	)
	
	local args = {}
	args.stateName = "StateFinished"
	args.place = #self.race.finishedRacers
	Network:Send(self.player , "SetState" , args)
	
end

function Racer:Respawn()
	
	local IsSpawnPositionClear = function(position)
		if self.race.vehicleCollisions == false then
			return true
		end
		
		local checkRadiusSquared = 4 * 4
		
		for id , racer in pairs(self.race.playerIdToRacer) do
			local vehicle = Vehicle.GetById(racer.assignedVehicleId)
			if IsValid(vehicle) then
				local distanceSquared = (position - vehicle:GetPosition()):LengthSqr()
				if distanceSquared <= checkRadiusSquared then
					return false
				end
			end
		end
		
		return true
	end
	
	self.outOfVehicleTimer = nil
	self.race.playersOutOfVehicle[self.playerId] = nil
	
	-- Get 2 extra indices of checkpoints around our current one.
	local previousCheckpointIndex = self.targetCheckpoint - 2
	local checkpointIndex = self.targetCheckpoint - 1
	local nextCheckpointIndex = self.targetCheckpoint
	if checkpointIndex <= 0 and self.race.course.type == "Circuit" and self.numLapsCompleted > 0 then
		previousCheckpointIndex = #self.race.course.checkpoints - 1
		checkpointIndex = #self.race.course.checkpoints
		nextCheckpointIndex = 1
	end
	if previousCheckpointIndex <= 0 and self.race.course.type == "Circuit" then
		previousCheckpointIndex = #self.race.course.checkpoints
	end
	
	-- Get spawn position and angle.
	local spawnPosition
	local spawnAngle
	if checkpointIndex <= 0 then
		-- Respawn at our spawn position.
		spawnPosition = self.courseSpawn.position
		spawnAngle = self.courseSpawn.angle
	else
		local previousCheckpoint = self.race.course.checkpoints[previousCheckpointIndex]
		local checkpoint = self.race.course.checkpoints[checkpointIndex]
		local nextCheckpoint = self.race.course.checkpoints[nextCheckpointIndex]
		spawnPosition = checkpoint.position
		
		local spawnDirection
		if previousCheckpoint then
			spawnDirection = (previousCheckpoint.position - checkpoint.position)
			if nextCheckpoint then
				spawnDirection = (
					spawnDirection +
					(checkpoint.position - nextCheckpoint.position)
				) * 0.5
			end
		elseif nextCheckpoint then
			spawnDirection = checkpoint.position - nextCheckpoint.position
		end
		spawnDirection = spawnDirection:Normalized()
		
		spawnAngle = Angle.FromVectors(
			Vector(0 , 0 , 1) ,
			spawnDirection
		)
		spawnAngle.roll = 0
	end
	
	-- If the spawn position isn't clear, spawn the vehicle a little above. Terrible solution, I know.
	if IsSpawnPositionClear(spawnPosition) == false then
		spawnPosition = spawnPosition + Vector(0 , 2.75 , 0)
	end
	
	if self.assignedVehicleId >= 0 then
		-- Respawn with vehicle.
		local oldVehicle = Vehicle.GetById(self.assignedVehicleId)
		if IsValid(oldVehicle) then
			local color1 , color2 = oldVehicle:GetColors()
			
			local spawnArgs = {}
			spawnArgs.model_id = oldVehicle:GetModelId()
			spawnArgs.position = spawnPosition
			spawnArgs.angle = spawnAngle
			spawnArgs.world = oldVehicle:GetWorldId()
			spawnArgs.enabled = true
			spawnArgs.tone1 = color1
			spawnArgs.tone2 = color2
			-- TODO: Currently not implemented by the API.
			-- spawnArgs.template = oldVehicle:GetTemplate()
			-- spawnArgs.decal = oldVehicle:GetDecal()
			
			oldVehicle:Remove()
			
			local newVehicle = Vehicle.Create(spawnArgs)
			newVehicle:SetDeathRemove(true)
			newVehicle:SetUnoccupiedRemove(true)
			
			local dirToPlayerSpawn = spawnAngle * Vector(-1 , 0 , 0)
			local playerSpawnPosition = spawnPosition + dirToPlayerSpawn * 2
			self.player:Teleport(playerSpawnPosition , spawnAngle)
			
			self.assignedVehicleId = newVehicle:GetId()
		end
	else
		-- On-foot, just teleport.
		self.player:Teleport(spawnPosition , spawnAngle)
	end
	
	Network:Send(self.player , "Respawn" , self.assignedVehicleId)
	
end

function Racer:EnterVehicle(args)
	
	-- -1 is on-foot, -2 is no vehicle.
	if self.assignedVehicleId >= 0 then
		if self.assignedVehicleId == args.vehicle:GetId() then
			self.outOfVehicleTimer = nil
			self.race.playersOutOfVehicle[self.player:GetId()] = nil
		elseif self.race.stateName ~= "StateAddPlayers" and not debug.dontRestrictVehicle then
			-- Remove player from race if they steal a vehicle.
			if args.is_driver and args.old_driver then
				self.race:MessageRace(
					args.player:GetName().." has been removed for vehicle theft."
				)
				self.race:RemovePlayer(args.player)
			else -- Otherwise, just remove them from the car.
				args.player:Teleport(
					args.player:GetPosition() + Vector(0 , 2 , 0) ,
					args.player:GetAngle()
				)
				self.race:MessagePlayer(args.player , "This is not your car!")
			end
		end
	end
	
end

function Racer:ExitVehicle(args)
	
	self.outOfVehicleTimer = Timer()
	
	self.race.playersOutOfVehicle[self.player:GetId()] = true
	
end
