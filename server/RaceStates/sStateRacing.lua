----------------------------------------------------------------------------------------------------
-- Racing!
----------------------------------------------------------------------------------------------------

function StateRacing:__init(race)
	
	self.race = race
	self.timer = Timer()
	-- Key: number of CPs completed.
	-- Value: map of player ids that have completed key number of CPs.
	--     Key: player Id, value = pointermabob to checkpoint distance.
	self.racePosTracker = {}
	-- Starts at 0. When someone hits the first checkpoint, this becomes 1, etc.
	self.currentCheckpoint = 0
	-- Number of times ServerTick has been called.
	self.numTicks = 0
	self.eventSubs = {}
	self.netSubs = {}
	
	self.numPlayersAtStart = race.numPlayers
	
	-- Set up racePosTracker
	self.racePosTracker[0] = {}
	for id , racer in pairs(self.race.playerIdToRacer) do
		self.racePosTracker[0][id] = racer.targetCheckpointDistanceSqr -- wut
	end
	
	for id , racer in pairs(self.race.playerIdToRacer) do
		racer:RaceStart()
	end
	
	Utility.EventSubscribe(self , "PlayerChat")
	Utility.EventSubscribe(self , "PlayerEnterCheckpoint")
	Utility.EventSubscribe(self , "PlayerEnterVehicle")
	Utility.EventSubscribe(self , "PlayerExitVehicle")
	Utility.EventSubscribe(self , "PlayerDeath")
	Utility.EventSubscribe(self , "PostServerTick")
	Utility.NetSubscribe(self , "ReceiveCheckpointDistanceSqr")
	
end

function StateRacing:Run()
	
	-- Remove players who aren't in a vehicle for some time.
	for playerId , bool in pairs(self.race.playersOutOfVehicle) do
		local racer = self.race.playerIdToRacer[playerId]
		if
			-- If their assigned vehicle id is -1, it means they're on-foot.
			racer.assignedVehicleId ~= -1 and
			racer.hasFinished == false and
			racer.outOfVehicleTimer and
			racer.outOfVehicleTimer:GetSeconds() >= settings.outOfVehicleMaxSeconds and
			not debug.dontRemoveIfOutOfVehicle -- double negatives ftw
		then
			self.race:RemovePlayer(
				playerId ,
				"You were removed from the race for not being in a vehicle"
			)
			self.race:MessageRace(
				racer.player:GetName()..
				" was removed from the race for not being in a vehicle."
			)
		end
	end
	
	-- Remove dead players after a delay.
	for playerId , bool in pairs(self.race.playersDead) do
		local racer = self.race.playerIdToRacer[playerId]
		if IsValid(racer.player) and racer.deathTimer:GetSeconds() >= settings.playerDeathDelay then
			self.race:RemovePlayer(playerId)
			self.race.playersDead[playerId] = nil
		end
	end
	
	if self.timer:GetSeconds() >= self.race.course.timeLimitSeconds then
		self.race:MessageRace("Time limit up; ending race.")
		self.race:CleanUp()
	end
	
end

function StateRacing:End()
	
	Utility.EventUnsubscribeAll(self)
	Utility.NetUnsubscribeAll(self)
	
end

--
-- Events
--

function StateRacing:PlayerChat(args)
	
	-- If the race is public, it's not our hands; it's handled by the RaceManager.
	if self.race.isPublic then
		return
	end
	
	if args.text == settings.command then
		if self.race:HasPlayer(args.player) then
			self.race:RemovePlayer(
				args.player ,
				"You have exited the race."
			)
			
			return false
		end
	end
	
	return true
	
end

function StateRacing:PlayerEnterCheckpoint(args)
	
	local racer = self.race.playerIdToRacer[args.player:GetId()]
	if racer then	
		local checkpoint = self.race.course.checkpointMap[args.checkpoint:GetId()]
		if checkpoint then
			checkpoint:Enter(racer)
		end
	end
	
end

function StateRacing:PlayerEnterVehicle(args)
	
	local racer = self.race.playerIdToRacer[args.player:GetId()]
	if racer then
		racer:EnterVehicle(args)
	end
	
end

function StateRacing:PlayerExitVehicle(args)
	
	local racer = self.race.playerIdToRacer[args.player:GetId()]
	if racer then
		racer:ExitVehicle(args)
	end
	
end

function StateRacing:PlayerDeath(args)
	
	local racer = self.race.playerIdToRacer[args.player:GetId()]
	if racer then
		racer.deathTimer = Timer()
		self.race.playersDead[racer.player:GetId()] = true
		
		self.race:MessageRace(args.player:GetName().." has died!")
	end
	
end

-- wat
function StateRacing:PostServerTick()
	
	-- Call Update on all racers, if it's their turn.
	for id , racer in pairs(self.race.playerIdToRacer) do
		if self.numTicks % self.numPlayersAtStart == racer.updateTick then
			racer:Update()
		end
	end
	
	self.numTicks = self.numTicks + 1
	
end

--
-- Network
--

function StateRacing:ReceiveCheckpointDistanceSqr(args)
	
	local playerId = args[1]
	local distSqr = args[2]
	local cpIndex = args[3]
	
	local racer = self.race.playerIdToRacer[playerId]
	
	-- If player is in race and they're sending us the correct checkpoint distance.
	if racer and racer.targetCheckpoint == cpIndex then
		racer.targetCheckpointDistanceSqr[1] = distSqr
		-- print("Received distanceSqr from "..racer.name..": " , distSqr)
	end
	
end
