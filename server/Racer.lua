
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
	player:SetModelId(table.randomvalue(playerModelIds))
	-- Set model of authors to something unique.
	for n , authorName in ipairs(currentCourse.info.authors) do
		if self.name == authorName then
			player:SetModelId(100)
			break
		end
	end
	
	-- Index of checkpoints.
	self.targetCheckpoint = 1
	self.lapsCompleted = 0
	self.numCheckpointsHit = 0
	self.hasFinished = false
	-- This is pretty much a pointer. o_O
	-- Used with racePosTracker and helps with NetworkSend parameters.
	self.targetCheckpointDistanceSqr = {[1] = 0}
	
	self.assignedVehicleId = -1
	self.timeSinceOutOfVehicle = 0
	
	-- TODO: Helps with vehicle theft.
	self.assignedVehicleId = -1
	
	self.cheatDetection = nil
	
	-- Helps with updating only one racer per tick.
	-- When the first Racer is added, numPlayers is 0.
	self.updateTick = numPlayers
	
	self.storedInventory = {}

end

function Racer:AdvanceCheckpoint()

	self.targetCheckpoint = self.targetCheckpoint + 1
	
	local vehicle = self.player:GetVehicle()
	
	-- Repair vehicle.
	if IsValid(vehicle) then
		vehicle:SetHealth(vehicle:GetHealth() + 0.05)
	end
	
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
	
	-- Start the countdown to end the race after someone finishes.
	timeOfLastFinisher = os.time()

	-- Messages to immediately print for all finishers.
	if #finishedRacers == 1 then
		MessageServer(self.name.." wins the race!")
		NetworkSendRace(
			"ShowLargeMessage" ,
			{self.name.." wins the race!" , 4}
		)
	else
		MessageRace(self.name.." finishes "..NumberToPlaceString(#finishedRacers))
	end
	
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

function Racer:ClearInventory()
	
	self.storedInventory = self.player:GetInventory()
	self.player:ClearInventory()
	
end

function Racer:RestoreInventory()
	
	for index , weapon in pairs(self.storedInventory) do
		self.player:GiveWeapon(index , weapon)
	end
	
end
