
function StateFinished:__init(race , args) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	self.place = args.place
	
	local message = Utility.NumberToPlaceString(args.place).." place!"
	self.largeMessage = LargeMessage(message , 7.5)
	
	self:EventSubscribe("Render")
	self:EventSubscribe("LocalPlayerInput")
	self:NetworkSubscribe("UpdateRacePositions")
end

function StateFinished:Render()
	-- Draw GUI.
	if Game:GetState() == GUIState.Game then
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
end

function StateFinished:End()
	self.largeMessage:Destroy()
	
	self:Destroy()
end

-- Events

function StateFinished:LocalPlayerInput(args)
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

-- Network events

function StateFinished:UpdateRacePositions(racePosInfo)
	self.race:UpdateLeaderboard(racePosInfo)
end
