
function StateRacing:__init(race , args)
	
	self.race = race
	self.racePosition = -1
	self.currentLap = 1
	self.targetCheckpoint = 1
	self.checkpointArrowValue = 1
	self.timer = Timer()
	self.numTicks = 0
	self.sendCheckpointTimer = Timer()
	
	LargeMessage("GO!" , 2)
	
	Utility.EventSubscribe(self , "PostClientTick")
	Utility.EventSubscribe(self , "LocalPlayerInput")
	Utility.NetSubscribe(self , "SetTargetCheckpoint")
	Utility.NetSubscribe(self , "UpdateRacePositions")
	Utility.NetSubscribe(self , "RaceTimePersonal")
	Utility.NetSubscribe(self , "NewRecordTime")
	
end

function StateRacing:Run()
	
	self.numTicks = self.numTicks + 1
	
	-- Checkpoint arrow value.
	local maxValue = settings.checkpointArrowFlashNum * settings.checkpointArrowFlashInterval * 2
	-- Always try to increment the value.
	self.checkpointArrowValue = self.checkpointArrowValue + 1
	-- Always clamp, too.
	if self.checkpointArrowValue > maxValue then
		self.checkpointArrowValue = maxValue
	end
	
	-- Extract our race position from the leaderboard.
	for index , playerId in ipairs(self.race.leaderboard) do
		if playerId == LocalPlayer:GetId() then
			self.racePosition = index
		end
	end
	
	-- Draw GUI.
	--
	-- DrawVersion
	RaceGUI.DrawVersion(self.race.version)
	-- DrawCourseName
	RaceGUI.DrawCourseName(self.race.courseInfo.name)
	-- DrawCheckpointArrow
	args = {}
	args.checkpointArrowValue = self.checkpointArrowValue
	args.numTicks = self.numTicks
	args.checkpointPosition = self.race.checkpoints[self.targetCheckpoint]
	RaceGUI.DrawCheckpointArrow(args)
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

function StateRacing:End()
	
	Utility.EventUnsubscribeAll(self)
	Utility.NetUnsubscribeAll(self)
	
end

function StateRacing:GetTargetCheckpointDistanceSqr()
	
	local targetCheckpointPos = self.race.checkpoints[self.targetCheckpoint]
	return (targetCheckpointPos - LocalPlayer:GetPosition()):LengthSqr()
	
end

----------------------------------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------------------------------

function StateRacing:PostClientTick(args)
	
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
		self.checkpointArrowValue = -1
		self.timer:Restart()
	else
		self.checkpointArrowValue = 0
	end
	
end

function StateRacing:UpdateRacePositions(args)
	
	local racePosTracker = args[1]
	local currentCheckpoint = args[2]
	local finishedPlayerIds = args[3]
	
	self.race:UpdateLeaderboard(racePosTracker , currentCheckpoint , finishedPlayerIds)
	
end

function StateRacing:RaceTimePersonal(time)
	
	table.insert(self.race.lapTimes , time)
	
end

function StateRacing:NewRecordTime(args)
	
	self.race.recordTime = args[1]
	self.race.recordTimePlayerName = args[2]
	
end
