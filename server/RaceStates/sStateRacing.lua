
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
	
	-- Array of RacerBases. This is used to update one RacerBase per tick.
	self.updateList = {}
	for id , racer in pairs(self.race.playerIdToRacer) do
		table.insert(self.updateList , racer)
	end
	for id , spectator in pairs(self.race.playerIdToSpectator) do
		table.insert(self.updateList , spectator)
	end
	
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
	-- Call Update on one Racer or Spectator. If the list is less than 10, then sometimes skip.
	local index = (self.numTicks % math.max(10 , #self.updateList)) + 1
	if index <= #self.updateList then
		local racerBase = self.updateList[index]
		racerBase:Update()
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
