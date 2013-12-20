
function StateRacing:__init(race , args) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	self.racePosition = -1
	self.currentLap = 1
	self.targetCheckpoint = 1
	self.targetArrowValue = 1
	self.timer = Timer()
	self.numTicks = 0
	self.sendCheckpointTimer = Timer()
	
	LargeMessage("GO!" , 2)
	
	self:EventSubscribe("Render")
	self:EventSubscribe("PostTick")
	self:EventSubscribe("LocalPlayerInput")
	
	self:NetworkSubscribe("SetTargetCheckpoint")
	self:NetworkSubscribe("UpdateRacePositions")
	self:NetworkSubscribe("RaceTimePersonal")
	self:NetworkSubscribe("NewRecordTime")
	self:NetworkSubscribe("Respawn")
end

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
		-- DrawVersion
		RaceGUI.DrawVersion(self.race.version)
		-- DrawCourseName
		RaceGUI.DrawCourseName(self.race.courseInfo.name)
		-- DrawTargetArrow
		args = {}
		args.targetArrowValue = self.targetArrowValue
		args.numTicks = self.numTicks
		args.checkpointPosition = self.race.checkpoints[self.targetCheckpoint]
		args.model = RaceBase.modelCache.TargetArrow
		RaceGUI.DrawTargetArrow(args)
		-- DrawLapCounter
		args = {}
		args.courseType = self.race.courseInfo.type
		args.currentLap = self.currentLap
		args.totalLaps = self.race.courseInfo.numLaps
		args.numCheckpoints = #self.race.checkpoints
		args.targetCheckpoint = self.targetCheckpoint
		args.isFinished = false
		RaceGUI.DrawLapCounter(args)
		-- DrawRacePosition
		args = {}
		args.position = self.racePosition
		args.numPlayers = self.race.numPlayers
		RaceGUI.DrawRacePosition(args)
		-- DrawTimers
		args = {}
		args.recordTime = self.race.recordTime
		args.recordTimePlayerName = self.race.recordTimePlayerName
		args.courseType = self.race.courseInfo.type
		args.previousTime = self.race.lapTimes[#self.race.lapTimes]
		args.currentTime = self.timer:GetSeconds()
		RaceGUI.DrawTimers(args)
		-- DrawLeaderboard
		args = {}
		args.leaderboard = self.race.leaderboard
		args.playerIdToInfo = self.race.playerIdToInfo
		RaceGUI.DrawLeaderboard(args)
		-- DrawPositionTags
		args = {}
		args.leaderboard = self.race.leaderboard
		RaceGUI.DrawPositionTags(args)
		-- DrawMinimapIcons
		args = {}
		args.targetCheckpoint = self.targetCheckpoint
		args.checkpoints = self.race.checkpoints
		args.courseType = self.race.courseInfo.type
		args.currentLap = self.currentLap
		args.numLaps = self.race.courseInfo.numLaps
		RaceGUI.DrawMinimapIcons(args)
		-- DrawNextCheckpointArrow
		args = {}
		args.targetCheckpoint = self.targetCheckpoint
		args.checkpoints = self.race.checkpoints
		args.courseType = self.race.courseInfo.type
		args.currentLap = self.currentLap
		args.numLaps = self.race.courseInfo.numLaps
		RaceGUI.DrawNextCheckpointArrow(args)
	end
end

function StateRacing:End()
	self:Destroy()
end

function StateRacing:GetTargetCheckpointDistanceSqr()
	local targetCheckpointPos = self.race.checkpoints[self.targetCheckpoint]
	return (targetCheckpointPos - LocalPlayer:GetPosition()):LengthSqr()
end

----------------------------------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------------------------------

function StateRacing:PostTick(args)
	-- Send checkpoint distance every interval.
	if self.sendCheckpointTimer:GetSeconds() >= settings.sendCheckpointDistanceInterval then
		self.sendCheckpointTimer:Restart()
		Network:Send(
			"ReceiveCheckpointDistanceSqr" ,
			{LocalPlayer:GetId() , self:GetTargetCheckpointDistanceSqr() , self.targetCheckpoint}
		)
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
			self.race.courseInfo.parachuteEnabled == false and
			parachuteActions[args.input]
		then
			return false
		end
		-- Block grappling if the course disabled it.
		if
			self.race.courseInfo.grappleEnabled == false and
			args.input == Action.FireGrapple
		then
			return false
		end
		-- If we're in a vehicle, prevent us from getting out.
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

----------------------------------------------------------------------------------------------------
-- Network events
----------------------------------------------------------------------------------------------------

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

function StateRacing:Respawn(assignedVehicleId)
	self.race.assignedVehicleId = assignedVehicleId
end
