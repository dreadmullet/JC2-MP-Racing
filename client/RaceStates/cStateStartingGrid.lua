class("StateStartingGrid")

function StateStartingGrid:__init(race , args) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	
	self.startPositions = args.startPositions
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
		table.insert(self.race.leaderboard , {playerId = playerId , isFinished = false})
		local playerInfo = self.race.playerIdToInfo[playerId]
		if playerInfo.name == LocalPlayer:GetName() then
			self.startPosition = startPosition
		end
	end
	
	-- Set up the IconPresenter.
	
	local icons = self.race.icons
	
	local icon = Icon("Models/Collision")
	if self.race.collisions then
		icon:SetText("Collisions on")
		icon:SetType(Icon.Type.Enabled)
	else
		icon:SetText("Collisions off")
		icon:SetType(Icon.Type.Disabled)
	end
	table.insert(icons , icon)
	
	if self.race.course.grappleEnabled == false then
		icon = Icon("Models/GrapplingHook")
		icon:SetText("Grapple disabled")
		icon:SetType(Icon.Type.Disabled)
		table.insert(icons , icon)
	end
	
	if self.race.course.parachuteEnabled == false then
		icon = Icon("Models/Parachute")
		icon:SetText("Parachute disabled")
		icon:SetType(Icon.Type.Disabled)
		table.insert(icons , icon)
	end
	
	local maxPresentTime = (
		self.race.startingGridSeconds -
		settings.countDownInterval * settings.countDownNumMessages
	)
	local presentTime = math.min(maxPresentTime , 5 * #icons)
	local initialWaitTime = maxPresentTime - presentTime
	
	self.iconPresenter = IconPresenter(icons , presentTime , initialWaitTime)
	
	-- Subscribe to events.
	self:EventSubscribe("Render")
	self:EventSubscribe("LocalPlayerInput")
	self:EventSubscribe("InputPoll")
end

function StateStartingGrid:End()
	self:Destroy()
end

-- Events

function StateStartingGrid:Render()
	-- Countdown timer
	--
	-- If there is a valid count down time left, and it's ready to be shown, show it.
	if
		#self.countDownTimes > 0 and
		self.timer:GetSeconds() > self.race.startingGridSeconds - self.countDownTimes[1]
	then
		LargeMessage(
			tostring(settings.countDownNumMessages - self.messageCount) ,
			settings.countDownInterval * 1
		)
		self.messageCount = self.messageCount + 1
		table.remove(self.countDownTimes , 1)
	end
	-- If the timer is done, change our race's state to StateRacing.
	if self.timer:GetSeconds() > self.race.startingGridSeconds then
		self.race:SetState("StateRacing")
	end
	
	-- Draw GUI.
	if Game:GetState() == GUIState.Game then
		RaceGUI.DrawVersion()
		
		RaceGUI.DrawCourseName(self.race.course.name)
		
		RaceGUI.DrawTargetArrow{
			checkpointPosition = self.race.course.checkpoints[1][1] ,
			model = Race.instance.targetArrowModel ,
		}
		
		RaceGUI.DrawLapCounter{
			courseType = self.race.course.type ,
			currentLap = 1 ,
			totalLaps = self.race.numLaps ,
			numCheckpoints = #self.race.course.checkpoints ,
			targetCheckpoint = 1 ,
			isFinished = false ,
		}
		
		RaceGUI.DrawRacePosition{
			position = self.startPosition ,
			numPlayers = self.race.numPlayers ,
		}
		
		RaceGUI.DrawTimers{
			recordTime = self.race.recordTime ,
			recordTimePlayerName = self.race.recordTimePlayerName ,
			courseType = self.race.course.type ,
			previousTime = nil ,
			currentTime = nil ,
		}
		
		RaceGUI.DrawLeaderboard{
			leaderboard = self.race.leaderboard ,
			playerIdToInfo = self.race.playerIdToInfo ,
		}
		
		RaceGUI.DrawPositionTags{
			leaderboard = self.race.leaderboard ,
		}
		
		RaceGUI.DrawMinimapIcons{
			targetCheckpoint = 1 ,
			checkpoints = self.race.course.checkpoints ,
			courseType = self.race.course.type ,
			currentLap = 1 ,
			numLaps = self.race.numLaps ,
		}
		
		RaceGUI.DrawNextCheckpointArrow{
			targetCheckpoint = 1 ,
			checkpoints = self.race.course.checkpoints ,
			courseType = self.race.course.type ,
			currentLap = 1 ,
			numLaps = self.race.numLaps ,
		}
	end
end

function StateStartingGrid:LocalPlayerInput(args)
	if args.state ~= 0 then
		-- Block starting grid actions.
		for index , input in ipairs(settings.blockedInputsStartingGrid) do
			if args.input == input then
				return false
			end
		end
		-- If we're on foot, block on-foot actions.
		if self.race.assignedVehicleId == -1 then
			for index , input in ipairs(settings.blockedInputsStartingGridOnFoot) do
				if args.input == input then
					return false
				end
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
		-- Block Action.Accelerate, but only if we don't have a car. (It's for boats.)
		if args.input == Action.Accelerate then
			local vehicle = Vehicle.GetById(self.race.assignedVehicleId)
			if IsValid(vehicle) then
				local vehicleInfo = VehicleList[vehicle:GetModelId()]
				if vehicleInfo and vehicleInfo.type ~= "Land" then
					return false
				end
			end
		end
		-- Always block grappling.
		if args.input == Action.FireGrapple then
			return false
		end
	end
	
	return true
end

function StateStartingGrid:InputPoll()
	Input:SetValue(Action.Handbrake , 1 , false)
end
