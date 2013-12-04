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

--
-- Events
--

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

-- wat
function StateRacing:PostTick()
	
	-- Call Update on all racers, if it's their turn.
	for id , racer in pairs(self.race.playerIdToRacer) do
		if self.numTicks % self.numPlayersAtStart == racer.updateTick then
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
