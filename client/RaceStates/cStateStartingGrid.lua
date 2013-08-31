
function StateStartingGrid:__init(race , args)
	
	self.race = race
	self.delay = args.delay
	self.race.numPlayers = args.numPlayers
	self.race.playerIdToInfo = args.playerIdToInfo
	self.startPositions = args.startPositions
	self.race.courseInfo = {}
	self.race.courseInfo.name = args.courseInfo[1]
	self.race.courseInfo.type = args.courseInfo[2]
	self.race.courseInfo.numLaps = args.courseInfo[3]
	self.race.courseInfo.weatherSeverity = args.courseInfo[4]
	self.race.courseInfo.authors = args.courseInfo[5]
	self.race.courseInfo.parachuteEnabled = args.courseInfo[6]
	self.race.courseInfo.grappleEnabled = args.courseInfo[7]
	self.race.recordTime = args.recordTime
	self.race.recordTimePlayerName = args.recordTimePlayerName
	self.race.checkpoints = args.checkpointData
	self.race.assignedVehicleId = args.assignedVehicleId
	
	self.timer = Timer()
	
	-- Set up self.countDownTimes.
	self.messageCount = 0
	self.countDownTimes = {}
	local buffer = settings.countDownInterval
	for n = 1 , settings.countDownNumMessages do
		self.countDownTimes[settings.countDownNumMessages - n + 1] = buffer
		buffer = buffer + settings.countDownInterval
	end
	
	-- Get our starting position, and fill self.race.leaderboard with starting positions.
	self.startPosition = -1
	for playerId , startPosition in pairs(self.startPositions) do
		table.insert(self.race.leaderboard , playerId)
		local playerInfo = self.race.playerIdToInfo[playerId]
		if playerInfo.name == LocalPlayer:GetName() then
			self.startPosition = startPosition
		end
	end
	
	Utility.EventSubscribe(self , "LocalPlayerInput")
	Utility.EventSubscribe(self , "InputPoll")
	
end

function StateStartingGrid:Run()
	
	-- Countdown timer
	--
	-- If there is a valid count down time left, and it's ready to be shown, show it.
	if
		#self.countDownTimes > 0 and
		self.timer:GetSeconds() > self.delay - self.countDownTimes[1]
	then
		LargeMessage(
			tostring(settings.countDownNumMessages - self.messageCount) ,
			settings.countDownInterval * 1
		)
		self.messageCount = self.messageCount + 1
		table.remove(self.countDownTimes , 1)
	end
	-- If the timer is done, change our race's state to StateRacing.
	if self.timer:GetSeconds() > self.delay then
		local args = {}
		args.stateName = "StateRacing"
		self.race:SetState(args)
	end
	
	-- Draw GUI.
	local args = {}
	RaceGUI.DrawVersion(self.race.version)
	RaceGUI.DrawCourseName(self.race.courseInfo.name)
	-- DrawLapCounter
	args = {}
	args.courseType = self.race.courseInfo.type
	args.currentLap = 1
	args.totalLaps = self.race.courseInfo.numLaps
	args.numCheckpoints = #self.race.checkpoints
	args.targetCheckpoint = 1
	args.isFinished = false
	RaceGUI.DrawLapCounter(args)
	-- DrawRacePosition
	args = {}
	args.position = self.startPosition
	args.numPlayers = self.race.numPlayers
	RaceGUI.DrawRacePosition(args)
	-- DrawTimers
	args = {}
	args.recordTime = self.race.recordTime
	args.recordTimePlayerName = self.race.recordTimePlayerName
	args.courseType = self.race.courseInfo.type
	args.previousTime = nil
	args.currentTime = nil
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
	args.targetCheckpoint = 1
	args.checkpoints = self.race.checkpoints
	args.courseType = self.race.courseInfo.type
	args.currentLap = 1
	args.numLaps = self.race.courseInfo.numLaps
	RaceGUI.DrawMinimapIcons(args)
	-- DrawNextCheckpointArrow
	args = {}
	args.targetCheckpoint = 1
	args.checkpoints = self.race.checkpoints
	args.courseType = self.race.courseInfo.type
	args.currentLap = 1
	args.numLaps = self.race.courseInfo.numLaps
	RaceGUI.DrawNextCheckpointArrow(args)
	
end

function StateStartingGrid:End()
	
	Utility.EventUnsubscribeAll(self)
	Utility.NetUnsubscribeAll(self)
	
end

-- Events

function StateStartingGrid:LocalPlayerInput(args)
	
	if args.state ~= 0 then
		for index , input in ipairs(settings.blockedInputsStartingGrid) do
			if args.input == input then
				return false
			end
		end
		-- If we're on foot, block our movement.
		if self.race.assignedVehicleId == -1 then
			for index , input in ipairs(settings.blockedInputsStartingGridOnFoot) do
				if args.input == input then
					return false
				end
			end
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

function StateStartingGrid:InputPoll()
	
	-- Spam the enter vehicle key until they're in a vehicle.
	if LocalPlayer:InVehicle() == false then
		Input:SetValue(Action.UseItem , 1 , false)
	end
	
end
