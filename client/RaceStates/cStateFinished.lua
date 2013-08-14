
function StateFinished:__init(race , args)
	
	self.race = race
	self.place = args.place
	
	local message = Utility.NumberToPlaceString(args.place).." place!"
	self.largeMessage = LargeMessage(message , 7.5)
	
	Utility.NetSub(self , "UpdateRacePositions")
	
end

function StateFinished:Run()
	
	-- Draw GUI.
	RaceGUI.DrawVersion(self.race.version)
	RaceGUI.DrawCourseName(self.race.courseInfo.name)
	-- DrawLapCounter
	args = {}
	args.courseType = self.race.courseInfo.type
	args.currentLap = 1
	args.totalLaps = self.race.courseInfo.numLaps
	args.numCheckpoints = #self.race.checkpoints
	args.targetCheckpoint = 1
	args.isFinished = true
	RaceGUI.DrawLapCounter(args)
	-- DrawRacePosition
	args = {}
	args.position = self.place
	args.numPlayers = self.race.numPlayers
	RaceGUI.DrawRacePosition(args)
	-- DrawTimers
	args = {}
	args.recordTime = self.race.recordTime
	args.recordTimePlayerName = self.race.recordTimePlayerName
	args.courseType = self.race.courseInfo.type
	args.previousTime = self.race.lapTimes[#self.race.lapTimes - 1] or nil
	args.currentTime = self.race.lapTimes[#self.race.lapTimes]
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
	args.targetCheckpoint = #self.race.checkpoints
	args.checkpoints = self.race.checkpoints
	args.courseType = self.race.courseInfo.type
	args.currentLap = self.race.courseInfo.numLaps
	args.numLaps = self.race.courseInfo.numLaps
	RaceGUI.DrawMinimapIcons(args)
	
end

function StateFinished:End()
	
	self.largeMessage:Destroy()
	
	Utility.EventUnsubscribeAll(self)
	Utility.NetUnsubscribeAll(self)
	
end

function StateFinished:UpdateRacePositions(args)
	
	local racePosTracker = args[1]
	local currentCheckpoint = args[2]
	local finishedPlayerIds = args[3]
	
	self.race:UpdateLeaderboard(racePosTracker , currentCheckpoint , finishedPlayerIds)
	
end
