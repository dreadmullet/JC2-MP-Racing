
function Racer:__init(race , player , updateOffset)
	
	self.race = race
	self.player = player
	-- This helps with calling Racer:Update only one player per tick.
	self.updateOffset = updateOffset
	
	self.playerId = player:GetId()
	self.name = player:GetName()
	self.steamId = player:GetSteamId().id
	-- Pulled from database, and used to update database on our removal.
	self.playTime = -1
	self.targetCheckpoint = 1
	self.numLapsCompleted = 0
	self.numCheckpointsHit = 0
	self.hasFinished = false
	self.assignedVehicleId = -1
	-- Used with racePosTracker and helps with NetworkSend parameters.
	self.targetCheckpointDistanceSqr = {[1] = 0}
	-- Begins at starting grid, used to update playTime.
	self.raceTimer = nil
	-- Procs at end of lap for circuits, or end of race for linear courses.
	self.bestTimeTimer = nil
	-- Used for both circuits and linear courses.
	self.bestTime = -1
	-- Position in leaderboard.
	self.startPosition = -1
	self.courseSpawn = nil
	-- Helps with preventing respawning the player every tick.
	self.respawnTimer = nil
	
	-- if race.raceManager:GetIsAdmin(player) then
		-- player:SetModelId(settings.playerModelIdAdmin)
	-- else
		-- player:SetModelId(table.randomvalue(settings.playerModelIds))
	-- end
	
	-- Disable collisions, if applicable.
	if self.race.vehicleCollisions == false then
		self.player:DisableCollision(CollisionGroup.Vehicle)
	end
	-- Always disable player collisions.
	self.player:DisableCollision(CollisionGroup.Player)
	
	local args = {}
	args.version = settings.version
	Network:Send(self.player , "Initialise" , args)
	
end

function Racer:Update()
	
	-- TODO: The actual fuck
	local finishedPlayerIds = {}
	for index , racer in ipairs(self.race.finishedRacers) do
		table.insert(finishedPlayerIds , racer.playerId)
	end
	
	if self.respawnTimer and self.respawnTimer:GetSeconds() < 7 then
		-- Do nothing, we recently respawned, and we're likely in the enter vehicle animation.
	else
		local isVehicleAlive = true
		if self.assignedVehicleId >= 0 then
			local vehicle = Vehicle.GetById(self.assignedVehicleId)
			if IsValid(vehicle) then
				isVehicleAlive = vehicle:GetHealth() > 0
			end
		end
		-- If they're out of their vehicle, respawn them and create the respawn timer.
		if
			isVehicleAlive and
			self.player:GetHealth() > 0 and
			self.assignedVehicleId >= 0 and
			self.player:InVehicle() == false
		then
			self:Respawn()
			self.respawnTimer = Timer()
		end
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
	
	-- Remove our vehicle.
	local vehicle = Vehicle.GetById(self.assignedVehicleId)
	if vehicle then
		vehicle:Remove()
	end
	
	-- Reenable collisions.
	if self.vehicleCollisions == false then
		self.player:EnableCollision(CollisionGroup.Vehicle)
	end
	self.player:EnableCollision(CollisionGroup.Player)
	
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
	
	local args = {}
	args.stateName = "StateFinished"
	args.place = #self.race.finishedRacers
	Network:Send(self.player , "SetState" , args)
	
end

function Racer:Respawn()
	
	if settings.debugLevel >= 2 then
		print(self.name.." is respawning.")
	end
	
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
			Vector3(0 , 0 , 1) ,
			spawnDirection
		)
		spawnAngle.roll = 0
	end
	
	-- If the spawn position isn't clear, spawn the vehicle a little above. Terrible solution, I know.
	if IsSpawnPositionClear(spawnPosition) == false then
		spawnPosition = spawnPosition + Vector3(0 , 2.75 , 0)
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
			spawnArgs.world = oldVehicle:GetWorld()
			spawnArgs.enabled = true
			spawnArgs.tone1 = color1
			spawnArgs.tone2 = color2
			spawnArgs.template = oldVehicle:GetTemplate()
			spawnArgs.decal = oldVehicle:GetDecal()
			
			oldVehicle:Remove()
			
			local newVehicle = Vehicle.Create(spawnArgs)
			newVehicle:SetDeathRemove(true)
			newVehicle:SetUnoccupiedRemove(true)
			
			local dirToPlayerSpawn = spawnAngle * Vector3(-1 , 0 , 0)
			local playerSpawnPosition = spawnPosition + dirToPlayerSpawn * 2
			self.player:Teleport(playerSpawnPosition , spawnAngle)
			self.player:EnterVehicle(newVehicle , VehicleSeat.Driver)
			
			self.assignedVehicleId = newVehicle:GetId()
		end
	else
		-- On-foot, just teleport.
		self.player:Teleport(spawnPosition , spawnAngle)
	end
	
	Network:Send(self.player , "Respawn" , self.assignedVehicleId)
	
end

function Racer:Message(message)
	self.player:SendChatMessage("[Racing] "..message , settings.textColor)
end

-- Event callbacks

function Racer:EnterVehicle(args)
	
	self.respawnTimer = nil
	
	-- If someone enters the wrong car, boot them out.
	if self.assignedVehicleId >= 0 and self.assignedVehicleId ~= args.vehicle:GetId() then
		if not debug.dontRestrictVehicle then
			args.player:Teleport(
				args.player:GetPosition() + Vector3(0 , 2 , 0) ,
				args.player:GetAngle()
			)
			self:Message("This is not your car!")
		end
	end
	
end
