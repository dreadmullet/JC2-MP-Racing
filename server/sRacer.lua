
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
	self.deathTimer = nil
	-- Used with racePosTracker and helps with NetworkSend parameters.
	self.targetCheckpointDistanceSqr = {[1] = 0}
	self.updateTick = race.numPlayers
	-- Begins at starting grid, used to update playTime.
	self.raceTimer = nil
	-- Procs at end of lap for circuits, or end of race for linear courses.
	self.bestTimeTimer = nil
	-- Used for both circuits and linear courses.
	self.bestTime = -1
	
	race.playersOutOfVehicle[player:GetId()] = true
	
	if race.raceManager:GetIsAdmin(player) then
		player:SetModelId(settings.playerModelIdAdmin)
	else
		player:SetModelId(table.randomvalue(settings.playerModelIds))
	end
	
end

function Racer:RaceStart()
	
	self.outOfVehicleTimer = Timer()
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
	
	Network:Send(self.player , "Finish")
	local message = Utility.NumberToPlaceString(#self.race.finishedRacers).." place!"
	Network:Send(
		self.player ,
		"ShowLargeMessage" ,
		{message , 7.5}
	)
	
end

function Racer:EnterVehicle(args)
	
	if self.assignedVehicleId == args.vehicle:GetId() then
		self.outOfVehicleTimer = nil
		self.race.playersOutOfVehicle[self.player:GetId()] = nil
	else
		if self.race.stateName ~= "StateAddPlayers" and not debug.dontRestrictVehicle then
			-- Remove player from race if they steal a vehicle.
			if args.isdriver and args.olddriver then
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
