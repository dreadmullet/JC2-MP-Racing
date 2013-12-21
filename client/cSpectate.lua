
function Spectate:__init(args) ; RaceBase.__init(self , args)
	if settings.debugLevel >= 2 then
		print("Spectate:__init")
	end
	
	self.Terminate = Spectate.Terminate
	
	self.version = args.version
	
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
	self.orbitCamera.maxDistance = 30
	self.orbitCamera.targetPosition = args.position
	
	self.requestTimer = nil
	
	self:EventSubscribe("Render")
	self:NetworkSubscribe("ReceiveTargetPosition")
	self:NetworkUnsubscribe("Terminate")
	self:NetworkSubscribe("Terminate")
end

-- Events

function Spectate:Render()
	local targetPlayer = Player.GetById(self.targetPlayerId)
	if IsValid(targetPlayer) then
		self.requestTimer = nil
		
		local vehicle = targetPlayer:GetVehicle()
		if vehicle then
			self.orbitCamera.targetPosition = vehicle:GetPosition() + Vector3(0 , 2 , 0)
		else
			self.orbitCamera.targetPosition = targetPlayer:GetPosition() + Vector3(0 , 2 , 0)
		end
	else
		if
			self.requestTimer == nil or
			self.requestTimer:GetSeconds() > settings.spectatorRequestInterval
		then
			self.requestTimer = Timer()
			
			Network:Send("RequestTargetPosition" , self.targetPlayerId)
		end
	end
end

-- Network events

function Spectate:ReceiveTargetPosition(position)
	self.orbitCamera.targetPosition = position
end

function Spectate:Terminate()
	if settings.debugLevel >= 2 then
		print("Spectate:Terminate")
	end
	self:Destroy()
	self.orbitCamera:Destroy()
end
