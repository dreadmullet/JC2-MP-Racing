class("Spectate")

-- TODO: racer leave and respawn network events

function Spectate:__init(args) ; RaceBase.__init(self , args)
	Spectate.instance = self
	
	if settings.debugLevel >= 2 then
		print("Spectate:__init")
		print("args.position = "..tostring(args.position))
	end
	
	-- This is set when we're waiting for the server to give us the target info, and nil otherwise.
	-- {id (number), timer (Timer)}
	self.targetRequest = nil
	-- Used to control our camera. position is updated every frame, and is used if the target is not
	-- valid for whatever reason.
	self.target = {
		id = -1 ,
		position = args.position or Vector3(0 , 5000 , 0)
	}
	
	if args.stateName == "StateVehicleSelection" then
		self:EventSubscribe("Render" , self.RenderVehicleSelection)
	elseif args.stateName == "StateStartingGrid" then
		-- TODO: wat
		for playerId , startPosition in pairs(args.startPositions) do
			table.insert(self.leaderboard , {playerId = playerId , isFinished = false})
		end
		
		self:EventSubscribe("Render" , self.RenderRacing)
	elseif args.stateName == "StateRacing" then
		self:UpdateLeaderboard(args.racePosInfo)
		
		self:EventSubscribe("Render" , self.RenderRacing)
	end
	
	-- If our leaderboard is valid, set our target to the leader.
	if self.leaderboard[1] then
		self.target.id = self.leaderboard[1].playerId
	end
	
	self.orbitCamera = OrbitCamera()
	self.orbitCamera.minDistance = 3
	self.orbitCamera.maxDistance = 50
	self.orbitCamera.targetPosition = self.target.position
	
	self:EventSubscribe("ControlDown")
	self:NetworkSubscribe("RaceSetState")
	self:NetworkSubscribe("SpectateReceiveTarget" , self.ReceiveTarget)
	self:NetworkSubscribe("UpdateRacePositions")
	self:NetworkSubscribe("Terminate")
	
	Events:Fire("SpectateCreate")
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
	
	if self.target == nil or self.target.id == nil then
		warn("Invalid spectate target!")
		return
	end
	
	-- Place the camera at our fallback position. It will likely be overwritten soon.
	self.orbitCamera.targetPosition = self.target.position
	
	local targetPlayer = Player.GetById(self.target.id)
	
	-- If this player isn't even on the server, change our target and bail out.
	if IsValid(targetPlayer , false) == false then
		if math.random() > 0.5 then
			self:ChangeTarget(1)
		else
			self:ChangeTarget(-1)
		end
		
		return
	end
	
	-- If we can see our target, follow them.
	if IsValid(targetPlayer) then
		local newTargetPosition
		local vehicle = targetPlayer:GetVehicle()
		if vehicle then
			newTargetPosition = vehicle:GetCenterOfMass() + Vector3(0 , 0.5 , 0)
		else
			newTargetPosition = targetPlayer:GetPosition() + Vector3(0 , 1 , 0)
		end
		
		if newTargetPosition:Distance(self.target.position) > 500 then
			-- The client thinks they're at 0,0,0 or something weird. Request their position.
			self:RequestTarget()
		else
			-- Success!
			self.orbitCamera.targetPosition = newTargetPosition
			self.target.position = newTargetPosition
			self.targetRequest = nil
		end
	-- Otherwise, we can't see our target, so request their position.
	else
		self:RequestTarget()
	end
	
	if Game:GetState() == GUIState.Game then
		RaceGUI.DrawVersion()
		
		RaceGUI.DrawCourseName(self.course.name)
		
		RaceGUI.DrawTimers{
			recordTime = self.recordTime ,
			recordTimePlayerName = self.recordTimePlayerName ,
			courseType = self.course.type ,
		}
		
		RaceGUI.DrawRaceProgress{
			currentCheckpoint = self.leaderboard[1].checkpointsHit or 0 ,
			checkpointCount = self.totalCheckpointCount ,
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

function Spectate:ControlDown(args)
	if args.name == "Next spectate target" then
		self:ChangeTarget(1)
	elseif args.name == "Previous spectate target" then
		self:ChangeTarget(-1)
	end
end

function Spectate:ChangeTarget(delta)
	local position = 0
	for index , entry in ipairs(self.leaderboard) do
		if self.target.id == entry.playerId then
			position = index
			break
		end
	end
	position = position + delta
	position = math.clamp(position , 1 , #self.leaderboard)
	
	local entry = self.leaderboard[position]
	if entry then
		self.target.id = entry.playerId
	else
		self.target.id = -1
	end
	print("Target changed to "..self.target.id)
end

function Spectate:RequestTarget()
	-- If we've already requested recently, bail out.
	if
		self.targetRequest ~= nil and
		self.targetRequest.timer:GetSeconds() < settings.spectatorRequestInterval
	then
		return
	end
	
	print("Requesting target: "..self.target.id)
	
	self.targetRequest = {id = self.target.id , timer = Timer()}
	
	Network:Send("SpectateRequestTarget" , self.target.id)
end

-- Network events

function Spectate:RaceSetState(args)
	if settings.debugLevel >= 2 then
		print("Spectate:RaceSetState: " , args.stateName)
	end
	
	if args.stateName == "StateStartingGrid" then
		self:EventUnsubscribe("Render")
		self:EventSubscribe("Render" , self.RenderRacing)
		
		-- TODO: Same wat as above
		for playerId , startPosition in pairs(args.startPositions) do
			table.insert(self.leaderboard , {playerId = playerId , isFinished = false})
		end
		
		-- Set our fallback target position to the first checkpoint.
		self.target.position = self.course.checkpoints[1][1]
		
		-- Set our target player to the leader.
		if self.leaderboard[1] then
			self.target.id = self.leaderboard[1].playerId
		else
			self.target.id = -1
		end
	end
end

function Spectate:ReceiveTarget(target)
	-- If our request became nil (we found our target), bail out.
	if self.targetRequest == nil then
		warn("Already found target!")
		return
	end
	
	-- If this isn't our target, bail out.
	if self.targetRequest.id ~= target.id then
		warn("Wrong target!")
		return
	end
	
	print("Received target: "..tostring(target.position))
	self.target = target
	
	-- If the target is not valid, set our target to the leader probably.
	if target.id < 0 then
		warn("Invalid target!")
		self:ChangeTarget(-500)
	end
end

function Spectate:UpdateRacePositions(racePosInfo)
	self:UpdateLeaderboard(racePosInfo)
end

function Spectate:Terminate()
	if settings.debugLevel >= 2 then
		print("Spectate:Terminate")
	end
	self:Destroy()
	self.orbitCamera:Destroy()
	
	Events:Fire("SpectateEnd")
	
	Spectate.instance = nil
end
