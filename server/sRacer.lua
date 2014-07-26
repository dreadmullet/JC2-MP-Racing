class("Racer")

function Racer:__init(race , player) ; RacerBase.__init(self , race , player)
	self.Update = Racer.Update
	self.Remove = Racer.Remove
	
	-- Pulled from database, and used to update database on our removal.
	self.playTime = -1
	self.targetCheckpoint = 1
	self.numLapsCompleted = 0
	self.numCheckpointsHit = 0
	self.hasFinished = false
	self.assignedVehicleId = -1
	-- Table containing modelId, template, color1, color2
	self.assignedVehicleInfo = nil
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
	-- Helps with limiting the rate of respawning.
	self.respawnLimiterTimer = Timer()
	-- Works with settings.respawnDelay to delay the respawn when it's requested.
	self.respawnDelayTimer = Timer()
	self.isRespawning = false
	
	-- Add ourselves to Stats.
	Stats.AddPlayer(self)
	
	-- Send info to client.
	local args = {
		className = "Race" ,
		raceInfo = self.race.info
	}
	Network:Send(self.player , "InitializeClass" , args)
end

function Racer:Update(racePosInfo)
	RacerBase.Update(self , racePosInfo)
	
	-- If we're stunt jumped on someone else's vehicle, teleport us off.
	local vehicle = self.player:GetVehicle()
	if
		self.player:GetState() == PlayerState.StuntPos and
		vehicle and
		vehicle:GetId() ~= self.assignedVehicleId
	then
		self:Message("Get off, you freeloader!")
		self.player:SetPosition(self.player:GetPosition() + Vector3(0 , 0.5 , 0))
	end
	
	-- If we're respawning, and the timer is elapsed, respawn us.
	if self.isRespawning and self.respawnDelayTimer:GetSeconds() >= settings.respawnDelay then
		self.isRespawning = false
		self:Respawn()
	end
end

function Racer:Remove()
	RacerBase.Remove(self)
	
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
	
	Network:Send(self.player , "Terminate")
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
	
	-- If this is a new record, send every racer the new time/player.
	if lapTime < self.race.info.topRecordTime then
		self.race:NetworkSendRace("NewRecordTime" , {lapTime , self.name})
		self.race.info.topRecordTime = lapTime
		self.race.topRecordPlayerName = self.name
	end
	
	self.bestTimeTimer:Restart()
	
	-- Finish the race if we've completed all laps.
	if self.numLapsCompleted >= self.race.numLaps and self.hasFinished == false then
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
		if raceTime < self.race.info.topRecordTime then
			self.race:NetworkSendRace("NewRecordTime" , {raceTime , self.name})
			self.race.info.topRecordTime = raceTime
			self.race.topRecordPlayerName = self.name
		end
	end
	
	self.race:RacerFinish(self)
	
	local args = {}
	args.stateName = "StateFinished"
	args.place = #self.race.finishedRacers
	Network:Send(self.player , "RaceSetState" , args)
end

function Racer:RequestRespawn()
	if self.isRespawning == false then
		self.isRespawning = true
		self.respawnDelayTimer = Timer()
		Network:Send(self.player , "RespawnAcknowledged")
	end
end

function Racer:Respawn()
	-- Make sure that we're alive.
	if self.player:GetHealth() == 0 then
		return
	end
	
	if settings.debugLevel >= 2 then
		print(self.name.." is respawning.")
	end
	
	self.respawnLimiterTimer = Timer()
	
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
	-- TODO: Some logic should probably be in Course/CourseCheckpoint.
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
	
	-- Handle checkpoints that are not respawnable.
	while checkpointIndex > 0 do
		if self.race.course.checkpoints[checkpointIndex].isRespawnable then
			break
		end
		
		previousCheckpointIndex = previousCheckpointIndex - 1
		checkpointIndex = checkpointIndex - 1
		nextCheckpointIndex = nextCheckpointIndex - 1
	end
	
	-- Fix for courses with two checkpoints.
	if #self.race.course.checkpoints == 2 then
		previousCheckpointIndex = -1
	end
	
	-- Get spawn position, angle, and speed.
	local spawnPosition
	local spawnAngle
	local spawnSpeed = 5
	if checkpointIndex <= 0 then
		-- Respawn at our start position.
		spawnPosition = self.courseSpawn.position
		spawnAngle = self.courseSpawn.angle
	else
		local previousCheckpoint = self.race.course.checkpoints[previousCheckpointIndex]
		local checkpoint = self.race.course.checkpoints[checkpointIndex]
		local nextCheckpoint = self.race.course.checkpoints[nextCheckpointIndex]
		-- If the checkpoint has usable respawn points, use them.
		local usedRespawnPoint = false
		if #checkpoint.respawnPoints > 0 then
			local respawnPointToUse
			for index , respawnPoint in ipairs(checkpoint.respawnPoints) do
				if
					respawnPoint.modelId == 0 or
					respawnPoint.modelId == self.assignedVehicleInfo.modelId
				then
					if respawnPointToUse == nil or respawnPoint.counter < respawnPointToUse.counter then
						respawnPointToUse = respawnPoint
					end
				end
			end
			if respawnPointToUse ~= nil then
				spawnPosition = respawnPointToUse.position
				spawnAngle = respawnPointToUse.angle
				spawnSpeed = respawnPointToUse.speed
				
				respawnPointToUse.counter = respawnPointToUse.counter + 1
				usedRespawnPoint = true
			end
		end
		-- Otherwise, calculate spawnAngle from the surrounding checkpoints and, if our assigned
		-- vehicle is a plane, set spawnSpeed to a reasonable amount so we don't immediately crash
		-- into the ground.
		if usedRespawnPoint == false then
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
				spawnDirection = nextCheckpoint.position - checkpoint.position
			end
			spawnDirection = spawnDirection:Normalized()
			
			spawnAngle = Angle.FromVectors(
				Vector3.Forward ,
				spawnDirection
			)
			spawnAngle.roll = 0
			
			local vehicleListEntry = VehicleList[self.assignedVehicleInfo.modelId]
			if vehicleListEntry.type == "Air" then
				spawnSpeed = 32
			end
		end
	end
	
	-- If the spawn position isn't clear, spawn the vehicle a little above. Terrible solution, I know.
	if IsSpawnPositionClear(spawnPosition) == false then
		spawnPosition = spawnPosition + Vector3(0 , 2.75 , 0)
	end
	
	if self.assignedVehicleId >= 0 then
		-- Remove last vehicle.
		local oldVehicle = Vehicle.GetById(self.assignedVehicleId)
		if oldVehicle then
			oldVehicle:Remove()
		end
		-- Respawn with vehicle.
		local spawnArgs = {}
		spawnArgs.model_id = self.assignedVehicleInfo.modelId
		spawnArgs.position = spawnPosition
		spawnArgs.angle = spawnAngle
		spawnArgs.world = self.race.world
		spawnArgs.enabled = true
		spawnArgs.tone1 = self.assignedVehicleInfo.color1
		spawnArgs.tone2 = self.assignedVehicleInfo.color2
		spawnArgs.template = self.assignedVehicleInfo.template
		spawnArgs.decal = "."
		spawnArgs.linear_velocity = spawnAngle * Vector3.Forward * spawnSpeed
		
		local newVehicle = Vehicle.Create(spawnArgs)
		newVehicle:SetDeathRemove(true)
		newVehicle:SetUnoccupiedRemove(true)
		
		local dirToPlayerSpawn = spawnAngle * Vector3(-1 , 0 , 0)
		local playerSpawnPosition = spawnPosition + dirToPlayerSpawn * 2
		self.player:Teleport(playerSpawnPosition , spawnAngle)
		self.player:EnterVehicle(newVehicle , VehicleSeat.Driver)
		
		self.assignedVehicleId = newVehicle:GetId()
	else
		-- On-foot, just teleport.
		self.player:Teleport(spawnPosition , spawnAngle)
	end
	
	Network:Send(self.player , "Respawned" , self.assignedVehicleId)
end

function Racer:Message(message)
	self.player:SendChatMessage("[Racing] "..message , settings.textColor)
end

-- Event callbacks

function Racer:EnterVehicle(args)
	-- If someone enters the wrong car, boot them out and replace the original driver.
	if self.assignedVehicleId >= 0 and self.assignedVehicleId ~= args.vehicle:GetId() then
		self.player:SetPosition(self.player:GetPosition() + Vector3(0 , 0.5 , 0))
		self:Message("Get your own car, you thief!")
		
		if args.old_driver then
			args.old_driver:EnterVehicle(args.vehicle , VehicleSeat.Driver)
		end
	end
end
