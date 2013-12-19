
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
	
	self.racerUpdateInterval = math.max(10 , race.numPlayers)
	
	self.racePosTracker[0] = {}
	for id , racer in pairs(self.race.playerIdToRacer) do
		racer.bestTimeTimer = Timer()
		self.racePosTracker[0][id] = racer.targetCheckpointDistanceSqr -- wut
	end
	
	Utility.EventSubscribe(self , "PlayerEnterCheckpoint")
	Utility.EventSubscribe(self , "PlayerEnterVehicle")
	Utility.EventSubscribe(self , "PostTick")
	Utility.EventSubscribe(self , "PlayerSpawn")
	Utility.NetSubscribe(self , "ReceiveCheckpointDistanceSqr")
end

function StateRacing:End()
	Utility.EventUnsubscribeAll(self)
	Utility.NetUnsubscribeAll(self)
end

-- Events

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

function StateRacing:PostTick()
	-- Loop through each Racer and call Update on them if its their turn. Only one Racer should be
	-- chosen.
	for id , racer in pairs(self.race.playerIdToRacer) do
		if (self.numTicks + racer.updateOffset) % self.racerUpdateInterval == 0 then
			racer:Update()
		end
	end
	
	self.numTicks = self.numTicks + 1
end

function StateRacing:PlayerSpawn(args)
	local racer = self.race.playerIdToRacer[args.player:GetId()]
	if racer then
		racer:Respawn()
	end
	
	return false
end

-- Network events

function StateRacing:ReceiveCheckpointDistanceSqr(args)
	local playerId = args[1]
	local distSqr = args[2]
	local cpIndex = args[3]
	
	local racer = self.race.playerIdToRacer[playerId]
	
	-- If player is in race and they're sending us the correct checkpoint distance.
	if racer and racer.targetCheckpoint == cpIndex then
		racer.targetCheckpointDistanceSqr[1] = distSqr
	end
end
