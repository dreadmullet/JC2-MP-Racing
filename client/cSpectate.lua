class("Spectate")

function Spectate:__init(args) ; RaceBase.__init(self , args)
	Spectate.instance = self
	
	if settings.debugLevel >= 2 then
		print("Spectate:__init")
		print("args.position = "..tostring(args.position))
	end
	
	self.stateName = args.stateName
	
	if self.stateName == "StateVehicleSelection" then
		self:EventSubscribe("Render" , self.RenderVehicleSelection)
	elseif self.stateName == "StateStartingGrid" then
		-- TODO: wat
		for playerId , startPosition in pairs(args.startPositions) do
			table.insert(self.leaderboard , playerId)
		end
		
		self:EventSubscribe("Render" , self.RenderRacing)
	elseif self.stateName == "StateRacing" then
		self:UpdateLeaderboard(args.racePosInfo)
		
		self:EventSubscribe("Render" , self.RenderRacing)
	end
	
	self.targetPlayerId = self.leaderboard[1] or -1
	
	self.orbitCamera = OrbitCamera()
	self.orbitCamera.minDistance = 3
	self.orbitCamera.maxDistance = 50
	self.orbitCamera.targetPosition = args.position or Vector3(0 , 10000 , 0)
	
	self.requestTimer = nil
	self.changeTargetInputPressed = false
	
	self:EventSubscribe("LocalPlayerInput")
	self:NetworkSubscribe("RaceSetState")
	self:NetworkSubscribe("ReceiveTargetPosition")
	self:NetworkSubscribe("Terminate")
end

-- Events

function Spectate:RenderVehicleSelection()
	local text = "Players are selecting vehicles. Please wait..."
	Render:FillArea(Vector2() , Render.Size , Color(12 , 12 , 12))
	local fontSize = TextSize.Large
	local textSize = Render:GetTextSize(text , fontSize)
	Render:DrawText(Render.Size/2 - textSize/2 , text , settings.textColor , fontSize)
end

function Spectate:RenderRacing()
	self.orbitCamera.isInputEnabled = inputSuspensionValue == 0
	
	if Input:GetValue(Action.FireRight) == 0 and Input:GetValue(Action.FireLeft) == 0 then
		self.changeTargetInputPressed = false
	end
	
	local targetPlayer = Player.GetById(self.targetPlayerId)
	if IsValid(targetPlayer) then
		self.requestTimer = nil
		
		local vehicle = targetPlayer:GetVehicle()
		if vehicle then
			self.orbitCamera.targetPosition = vehicle:GetCenterOfMass() + Vector3(0 , 0.5 , 0)
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
	
	if Game:GetState() == GUIState.Game then
		RaceGUI.DrawVersion()
		
		RaceGUI.DrawCourseName(self.course.name)
		
		RaceGUI.DrawTimers{
			recordTime = self.recordTime ,
			recordTimePlayerName = self.recordTimePlayerName ,
			courseType = self.course.type ,
		}
		
		RaceGUI.DrawLeaderboard{
			leaderboard = self.leaderboard ,
			playerIdToInfo = self.playerIdToInfo ,
		}
		
		RaceGUI.DrawPositionTags{
			leaderboard = self.leaderboard
		}
	end
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

function Spectate:RaceSetState(args)
	if settings.debugLevel >= 2 then
		print("Spectate:RaceSetState: " , self.stateName , args.stateName)
	end
	
	if args.stateName == "StateStartingGrid" then
		self:EventUnsubscribe("Render")
		self:EventSubscribe("Render" , self.RenderRacing)
		
		-- TODO: Same wat as above
		for playerId , startPosition in pairs(args.startPositions) do
			table.insert(self.leaderboard , playerId)
		end
		
		self.targetPlayerId = self.leaderboard[1] or -1
	end
	
	self.stateName = args.stateName
end

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
