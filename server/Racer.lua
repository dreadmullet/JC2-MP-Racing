
----------------------------------------------------------------------------------------------------
-- Class: Racer
----------------------------------------------------------------------------------------------------

class("Racer")
function Racer:__init(player)

	self.player = player
	self.playerId = player:GetId()
	self.name = player:GetName()
	self.color = player:GetColor()
	self.posOriginal = player:GetPosition() -- player is teleported back here when done.
	
	-- Set their model id immediately. Probably a good idea.
	self.modelIdOriginal = player:GetModelId()
	player:SetModelId(playerModelId)
	
	-- Index of checkpoints.
	self.targetCheckpoint = 1
	self.lapsCompleted = 0
	self.numCheckpointsHit = 0
	self.hasFinished = false
	-- This is pretty much a pointer. o_O
	-- Used with racePosTracker and helps with NetworkSend parameters.
	self.targetCheckpointDistanceSqr = {[1] = 0}
	
	self.lastVehicleId = -1
	self.timeSinceOutOfVehicle = 0
	
	-- TODO: Helps with vehicle theft.
	self.assignedVehicleId = -1
	
	self.cheatDetection = nil
	
	-- Helps with updating only one racer per tick.
	-- When the first Racer is added, numPlayers is 0.
	self.updateTick = numPlayers

end

function Racer:AdvanceCheckpoint()

	self.targetCheckpoint = self.targetCheckpoint + 1
	
	local vehicle = self.player:GetVehicle()
	
	-- if IsValid(vehicle) then
		-- MessageRace(self.name.."'s vehicle health before: "..vehicle:GetHealth())
		-- vehicle:SetHealth(vehicle:GetHealth() + 0.075)
		-- MessageRace(self.name.."'s vehicle health after: "..vehicle:GetHealth())
	-- end
	
	Network:Send(self.player , "SetTargetCheckpoint" , self.targetCheckpoint)

end

function Racer:AdvanceLap()

	self.targetCheckpoint = 1

	self.lapsCompleted = self.lapsCompleted + 1

	if self.lapsCompleted >= currentCourse.info.laps then
		self:Finish()
	else
		-- if IsValid(vehicle) then
			-- vehicle:SetHealth(vehicle:GetHealth() + 0.075)
		-- end
		
		Network:Send(self.player , "SetTargetCheckpoint" , 1)
	end

end

function Racer:Finish()
	
	self.hasFinished = true

	table.insert(finishedRacers , self)
	
	-- Start the countdown to end the race after 1st person finishes.
	if #finishedRacers == 1 then
		timeOfFirstFinisher = os.time()
	end

	-- Messages to immediately print for top three finishers.
	if #finishedRacers == 1 then
		MessageServer(self.name.." wins the race!")
		NetworkSendRace(
			"ShowLargeMessage" ,
			{self.name.." wins the race!" , 4}
		)
	elseif #finishedRacers == 2 then
		MessageRace(self.name.." finishes 2nd.")
	elseif #finishedRacers == 3 then
		MessageRace(self.name.." finishes 3rd.")
	end
	
	-- If this was the last finisher, end the race. (TODO)
	-- local allFinished = true
	-- for id , racer in pairs(players_PlayerIdToRacer) do
		-- if racer.hasFinished == false then
			-- allFinished = false
			-- break
		-- end
	-- end
	-- if allFinished then
		-- MessageServer("All players finished; ending race.")
		-- EndRace()
	-- end
	
	-- if IsValid(vehicle) then
		-- vehicle:SetHealth(vehicle:GetHealth() + 0.075)
	-- end
	
	-- Prize money.
	self.player:SetMoney(self.player:GetMoney() + prizeMoneyCurrent)
	MessagePlayer(self.player , string.format("%s%i%s" , "You won $" , prizeMoneyCurrent , "!"))
	prizeMoneyCurrent = prizeMoneyCurrent * prizeMoneyMult
	
	local message = NumberToPlaceString(#finishedRacers).." place!"
	Network:Send(self.player , "Finish")
	Network:Send(
		self.player ,
		"ShowLargeMessage" ,
		{message , 7.5}
	)

end

function Racer:Update()
	
	-- Only update us if it's our turn.
	if numTicks % numPlayersAtStart == self.updateTick then
		self:UpdateRacePosition()
	end
	
end

function Racer:UpdateRacePosition()
	
	local finishedPlayerIds = {}
	for n = 1 , #finishedRacers do
		table.insert(finishedPlayerIds , finishedRacers[n].playerId)
	end
	
	Network:Send(
		self.player ,
		"UpdateRacePositions" ,
		{racePosTracker , currentCheckpoint , finishedPlayerIds}
	)
	
end

