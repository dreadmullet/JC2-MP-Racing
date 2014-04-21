class("Spectator")

function Spectator:__init(race , player)
	RacerBase.__init(self , race , player)
	EGUSM.SubscribeUtility.__init(self)
	
	self.Remove = Spectator.Remove
	
	player:SetStreamDistance(0)
	player:SetWorld(self.race.world)
	player:SetPosition(self.race.course.averageSpawnPosition + Vector3(0 , 2 , 0))
	
	self.requestTimer = nil
	
	local args = {
		className = "Spectate" ,
		raceInfo = self.race.info ,
		stateName = self.race.stateName
	}
	if args.stateName == nil or args.stateName == "" then
		args.stateName = "StateVehicleSelection"
	end
	if args.stateName == "StateVehicleSelection" then
		args.position = self.race.course.averageSpawnPosition + Vector3(0 , 4 , 0)
	elseif args.stateName == "StateStartingGrid" then
		args.startPositions = self.race.state.startPositions
		args.position = self.race.course.averageSpawnPosition + Vector3(0 , 4 , 0)
	elseif args.stateName == "StateRacing" then
		args.racePosInfo = self.race.state:GetRacePosInfo()
		local checkpointIndex = self.race.state.currentCheckpoint
		if checkpointIndex == 0 then
			checkpointIndex = 1
		end
		args.position = self.race.checkpointPositions[checkpointIndex]
	end
	
	Network:Send(self.player , "InitializeClass" , args)
end

function Spectator:Remove()
	RacerBase.Remove(self)
	
	self.player:SetStreamDistance(Config:GetValue("Streamer" , "PlayerStreamDistance") or 500)
	self.player:SetWorld(DefaultWorld)
	
	Network:Send(self.player , "Terminate")
	
	self:Destroy()
end

function Spectator:RequestTarget(playerId)
	if
		self.requestTimer == nil or
		self.requestTimer:GetSeconds() > settings.spectatorRequestInterval * 1.2 + 0.2
	then
		print("Giving target pos to "..tostring(self.player))
		self.requestTimer = Timer()
		
		local targetPlayer = Player.GetById(playerId)
		if IsValid(targetPlayer) then
			local target = {id = playerId , position = targetPlayer:GetPosition()}
			Network:Send(self.player , "SpectateReceiveTarget" , target)
		-- If the player isn't valid, give them an invalid target, but set the position to the current
		-- checkpoint in the race.
		else
			warn(tostring(self.player).." is requesting an invalid player id: "..tostring(playerId))
			
			local target = {id = -1}
			
			local checkpointIndex = self.race.state.currentCheckpoint
			if checkpointIndex == 0 then
				checkpointIndex = 1
			end
			target.position = self.race.checkpointPositions[checkpointIndex]
			
			Network:Send(self.player , "SpectateReceiveTarget" , target)
		end
	end
end
