
function Spectate:__init(args) ; RaceBase.__init(self , args)
	if settings.debugLevel >= 2 then
		print("Spectate:__init")
		print("args.position = "..tostring(args.position))
	end
	
	self.version = args.version
	self.playerIdToInfo = args.playerIdToInfo
	-- TODO: make this better
	self.courseInfo = {}
	self.courseInfo.name = args.courseInfo[1]
	self.courseInfo.type = args.courseInfo[2]
	self.courseInfo.numLaps = args.courseInfo[3]
	self.courseInfo.weatherSeverity = args.courseInfo[4]
	self.courseInfo.authors = args.courseInfo[5]
	self.courseInfo.parachuteEnabled = args.courseInfo[6]
	self.courseInfo.grappleEnabled = args.courseInfo[7]
	self.recordTime = args.recordTime
	self.recordTimePlayerName = args.recordTimePlayerName
	self.checkpoints = args.checkpointPositions
	self.assignedVehicleId = args.assignedVehicleId
	
	if args.stateName == "StateStartingGrid" then
		-- TODO: wat
		for playerId , startPosition in pairs(args.startPositions) do
			table.insert(self.leaderboard , playerId)
		end
	elseif args.stateName == "StateRacing" then
		self:UpdateLeaderboard(args.racePosInfo)
	end
	
	self.targetPlayerId = self.leaderboard[1] or -1
	
	self.orbitCamera = OrbitCamera()
	self.orbitCamera.minDistance = 1.5
	self.orbitCamera.maxDistance = 50
	self.orbitCamera.targetPosition = args.position or Vector3(0 , 10000 , 0)
	
	self.requestTimer = nil
	self.changeTargetInputPressed = false
	
	self:EventSubscribe("Render")
	self:EventSubscribe("LocalPlayerInput")
	self:NetworkSubscribe("ReceiveTargetPosition")
	self:NetworkSubscribe("Terminate")
end

-- Events

function Spectate:Render()
	if Input:GetValue(Action.FireRight) == 0 and Input:GetValue(Action.FireLeft) == 0 then
		self.changeTargetInputPressed = false
	end
	
	if self.targetPlayerId == -1 then
		return
	end
	
	local targetPlayer = Player.GetById(self.targetPlayerId)
	if IsValid(targetPlayer) then
		self.requestTimer = nil
		
		local vehicle = targetPlayer:GetVehicle()
		if vehicle then
			self.orbitCamera.targetPosition = vehicle:GetPosition() + Vector3(0 , 0.2 , 0)
			self.orbitCamera.targetPosition.y = targetPlayer:GetPosition().y
		else
			self.orbitCamera.targetPosition = targetPlayer:GetPosition() + Vector3(0 , 1 , 0)
		end
		if self.orbitCamera.targetPosition:Distance(Vector3(0,0,0)) < 10 then
			self.orbitCamera.targetPosition = Vector3(100000 , 300 , 100000)
		end
	else
		if
			self.requestTimer == nil or
			self.requestTimer:GetSeconds() > settings.spectatorRequestInterval
		then
			self.requestTimer = Timer()
			
			Network:Send("RequestTargetPosition" , self.targetPlayerId)
			self:Message("Requesting target: "..self.targetPlayerId)
		end
	end
	
	local args
	-- DrawVersion
	RaceGUI.DrawVersion(self.version)
	-- DrawCourseName
	RaceGUI.DrawCourseName(self.courseInfo.name)
	-- DrawTimers
	args = {}
	args.recordTime = self.recordTime
	args.recordTimePlayerName = self.recordTimePlayerName
	args.courseType = self.courseInfo.type
	-- DrawLeaderboard
	args = {}
	args.leaderboard = self.leaderboard
	args.playerIdToInfo = self.playerIdToInfo
	RaceGUI.DrawLeaderboard(args)
	-- DrawPositionTags
	args = {}
	args.leaderboard = self.leaderboard
	RaceGUI.DrawPositionTags(args)
end

function Spectate:LocalPlayerInput(args)
	if self.changeTargetInputPressed == false then
		if args.input == Action.VehicleFireRight then
			self:ChangeTarget(1)
			self.changeTargetInputPressed = true
		elseif args.input == Action.VehicleFireLeft then
			self:ChangeTarget(-1)
			self.changeTargetInputPressed = true
		end
	end
end

function Spectate:ChangeTarget(delta)
	local position = -1
	for index , playerId in ipairs(self.leaderboard) do
		if self.targetPlayerId == playerId then
			position = index
			break
		end
	end
	position = position + delta
	position = math.clamp(position , 1 , #self.leaderboard)
	
	self.targetPlayerId = self.leaderboard[position] or -1
	self:Message("Target changed to "..self.targetPlayerId)
end

-- Network events

function Spectate:ReceiveTargetPosition(position)
	self:Message("Received target: "..tostring(position))
	if position then
		self.orbitCamera.targetPosition = position
	else
		self:ChangeTarget(1)
	end
end

function Spectate:Terminate()
	if settings.debugLevel >= 2 then
		print("Spectate:Terminate")
	end
	self:Destroy()
	self.orbitCamera:Destroy()
end
