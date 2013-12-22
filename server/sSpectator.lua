
function Spectator:__init(race , player)
	RacerBase.__init(self , race , player)
	EGUSM.SubscribeUtility.__init(self)
	
	player:SetStreamDistance(0)
	player:SetWorld(self.race.world)
	
	self.requestTimer = nil
	
	local args = {}
	args.version = settings.version
	args.checkpointPositions = self.race.checkpointPositions
	args.stateName = self.race.stateName
	if args.stateName == "StateStartingGrid" then
		args.startPositions = self.race.state.startPositions
		args.position = self.race.course.spawns[1].position
	elseif args.stateName == "StateRacing" then
		args.racePosInfo = self.race.state:GetRacePosInfo()
		local checkpointIndex = self.race.state.currentCheckpoint
		if checkpointIndex == 0 then
			checkpointIndex = 1
		end
		args.position = args.checkpointPositions[checkpointIndex]
	end
	
	player:SetPosition(Vector3(0 , 10000 , 0))
	
	Network:Send(self.player , "SpectateInitialise" , args)
end

function Spectator:Remove()
	self.player:SetStreamDistance(Config:GetValue("Streamer" , "PlayerStreamDistance") or 500)
	self.player:SetWorld(DefaultWorld)
	
	Network:Send(self.player , "Terminate")
	
	self:Destroy()
end

-- Network events

function Spectator:RequestTargetPosition(playerId)
	if
		self.requestTimer == nil or
		self.requestTimer:GetSeconds() > settings.spectatorRequestInterval * 1.2 + 0.2
	then
		print("Giving target pos to "..tostring(self.player))
		self.requestTimer = Timer()
		
		local targetPlayer = Player.GetById(playerId)
		if IsValid(targetPlayer) then
			Network:Send(self.player , "ReceiveTargetPosition" , targetPlayer:GetPosition())
		else
			Network:Send(self.player , "ReceiveTargetPosition" , nil)
		end
	end
end
