class("StateRacing")

function StateRacing:__init(race , args) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	self.racePosition = -1
	self.currentLap = 1
	self.targetCheckpoint = 1
	self.targetArrowValue = 1
	self.timer = Timer()
	self.numTicks = 0
	self.sendCheckpointTimer = Timer()
	self.respawnState = "None"
	self.exitVehicleCoroutine = nil
	
	LargeMessage("GO!" , 2)
	
	Events:Fire("RaceStart")
	
	self:EventSubscribe("Render")
	self:EventSubscribe("PostTick")
	self:EventSubscribe("LocalPlayerEnterVehicle")
	self:EventSubscribe("LocalPlayerInput")
	self:EventSubscribe("ControlDown")
	
	self:NetworkSubscribe("SetTargetCheckpoint")
	self:NetworkSubscribe("UpdateRacePositions")
	self:NetworkSubscribe("RaceTimePersonal")
	self:NetworkSubscribe("NewRecordTime")
	self:NetworkSubscribe("Respawned")
	self:NetworkSubscribe("RespawnAcknowledged")
	self:NetworkSubscribe("RacerFinish")
end

function StateRacing:End()
	self:Destroy()
end

function StateRacing:GetTargetCheckpointDistanceSqr()
	local targetCheckpointPos = self.race.course.checkpoints[self.targetCheckpoint][1]
	return (targetCheckpointPos - LocalPlayer:GetPosition()):LengthSqr()
end

function StateRacing:ExitVehicleCoroutineFunction()
	local timer = Timer()
	
	while timer:GetSeconds() <= 1.25 do
		coroutine.yield()
	end
	
	while timer:GetSeconds() <= 7 do
		DrawText(
			Vector2(Render.Width * 0.5 , Render.Height * 0.29) ,
			"Press "..Controls.GetInputNameByControl("Respawn").." to respawn" ,
			settings.textColor ,
			24 ,
			"center"
		)
		
		coroutine.yield()
	end
	
	while(true) do
		coroutine.yield()
	end
end

-- Events

function StateRacing:Render()
	self.numTicks = self.numTicks + 1
	
	-- Checkpoint arrow value.
	local maxValue = settings.targetArrowFlashNum * settings.targetArrowFlashInterval * 2
	-- Always try to increment the value.
	self.targetArrowValue = self.targetArrowValue + 1
	-- Always clamp, too.
	if self.targetArrowValue > maxValue then
		self.targetArrowValue = maxValue
	end
	
	-- Extract our race position from the leaderboard.
	for index , playerId in ipairs(self.race.leaderboard) do
		if playerId == LocalPlayer:GetId() then
			self.racePosition = index
		end
	end
	
	-- Draw GUI.
	if Game:GetState() == GUIState.Game then
		RaceGUI.DrawVersion()
		
		RaceGUI.DrawCourseName(self.race.course.name)
		
		RaceGUI.DrawTargetArrow{
			targetArrowValue = self.targetArrowValue ,
			numTicks = self.numTicks ,
			checkpointPosition = self.race.course.checkpoints[self.targetCheckpoint][1] ,
			model = Race.instance.targetArrowModel ,
		}
		
		RaceGUI.DrawLapCounter{
			courseType = self.race.course.type ,
			currentLap = self.currentLap ,
			totalLaps = self.race.numLaps ,
			numCheckpoints = #self.race.course.checkpoints ,
			targetCheckpoint = self.targetCheckpoint ,
			isFinished = false ,
		}
		
		RaceGUI.DrawRacePosition{
			position = self.racePosition ,
			numPlayers = self.race.numPlayers ,
		}
		
		RaceGUI.DrawTimers{
			recordTime = self.race.recordTime ,
			recordTimePlayerName = self.race.recordTimePlayerName ,
			courseType = self.race.course.type ,
			previousTime = self.race.lapTimes[#self.race.lapTimes] ,
			currentTime = self.timer:GetSeconds() ,
		}
		
		RaceGUI.DrawLeaderboard{
			leaderboard = self.race.leaderboard ,
			playerIdToInfo = self.race.playerIdToInfo ,
		}
		
		RaceGUI.DrawPositionTags{
			leaderboard = self.race.leaderboard ,
		}
		
		RaceGUI.DrawMinimapIcons{
			targetCheckpoint = self.targetCheckpoint ,
			checkpoints = self.race.course.checkpoints ,
			courseType = self.race.course.type ,
			currentLap = self.currentLap ,
			numLaps = self.race.numLaps ,
		}
		
		RaceGUI.DrawNextCheckpointArrow{
			targetCheckpoint = self.targetCheckpoint ,
			checkpoints = self.race.course.checkpoints ,
			courseType = self.race.course.type ,
			currentLap = self.currentLap ,
			numLaps = self.race.numLaps ,
		}
		
		if self.respawnState == "Waiting" then
			self.exitVehicleCoroutine = nil
			
			DrawText(
				Vector2(Render.Width * 0.5 , Render.Height * 0.29) ,
				" Respawning..." ,
				settings.textColor ,
				24 ,
				"center"
			)
		elseif self.respawnState == "None" and self.exitVehicleCoroutine then
			local success , returnValue = coroutine.resume(self.exitVehicleCoroutine , self)
			if success == false then
				error(returnValue)
			end
		end
	end
end

function StateRacing:PostTick(args)
	-- Send checkpoint distance every interval.
	if self.sendCheckpointTimer:GetSeconds() >= settings.sendCheckpointDistanceInterval then
		self.sendCheckpointTimer:Restart()
		Network:Send(
			"ReceiveCheckpointDistanceSqr" ,
			{LocalPlayer:GetId() , self:GetTargetCheckpointDistanceSqr() , self.targetCheckpoint}
		)
	end
	-- Manage the exit vehicle coroutine.
	if
		self.race.assignedVehicleId == -1 or
		LocalPlayer:InVehicle() or
		LocalPlayer:GetHealth() == 0
	then
		self.exitVehicleCoroutine = nil
	elseif self.exitVehicleCoroutine == nil then
		self.exitVehicleCoroutine = coroutine.create(self.ExitVehicleCoroutineFunction)
	end
end

function StateRacing:LocalPlayerEnterVehicle(args)
	if self.respawnState == "Spawned" and args.vehicle:GetId() == self.race.assignedVehicleId then
		self.respawnState = "None"
	end
end

function StateRacing:LocalPlayerInput(args)
	-- Block actions.
	if args.state ~= 0 then
		-- Block racing actions.
		for index , input in ipairs(settings.blockedInputsRacing) do
			if args.input == input then
				return false
			end
		end
		-- Block parachuting if the course disabled it.
		if
			self.race.course.parachuteEnabled == false and
			parachuteActions[args.input]
		then
			return false
		end
		-- Block grappling if the course disabled it or if we're aiming at someone else's vehicle.
		if args.input == Action.FireGrapple then
			local targetEntity = LocalPlayer:GetAimTarget().entity
			local targetEntityType
			if targetEntity then
				targetEntityType = targetEntity.__type
			end
			if
				self.race.course.grappleEnabled == false or
				targetEntityType == "Player" or
				(targetEntityType == "Vehicle" and targetEntity:GetId() ~= self.race.assignedVehicleId)
			then
				return false
			end
		end
		-- If we're in a vehicle, block some vehicle actions.
		if LocalPlayer:InVehicle() then
			for index , input in ipairs(settings.blockedInputsInVehicle) do
				if args.input == input then
					return false
				end
			end
		end
	end
	
	return true
end

function StateRacing:ControlDown(control)
	if control.name == "Respawn" then
		Network:Send("RequestRespawn" , ".")
	end
end

-- Network events

function StateRacing:SetTargetCheckpoint(targetCheckpoint)
	self.targetCheckpoint = targetCheckpoint
	
	-- If we started a new lap.
	if self.targetCheckpoint == 1 then
		self.currentLap = self.currentLap + 1
		self.targetArrowValue = -1
		self.timer:Restart()
	else
		self.targetArrowValue = 0
	end
end

function StateRacing:UpdateRacePositions(racePosInfo)
	self.race:UpdateLeaderboard(racePosInfo)
end

function StateRacing:RaceTimePersonal(time)
	table.insert(self.race.lapTimes , time)
end

function StateRacing:NewRecordTime(args)
	self.race.recordTime = args[1]
	self.race.recordTimePlayerName = args[2]
end

function StateRacing:Respawned(assignedVehicleId)
	self.race.assignedVehicleId = assignedVehicleId
	
	self.respawnState = "Spawned"
end

function StateRacing:RespawnAcknowledged()
	self.respawnState = "Waiting"
end

function StateRacing:RacerFinish(args)
	local playerId = args[1]
	local place = args[2]
	
	local player = Player.GetById(playerId)
	if player then
		Game:ShowPopup(
			player:GetName().." finishes "..Utility.NumberToPlaceString(place) ,
			place == 1
		)
	end
end
