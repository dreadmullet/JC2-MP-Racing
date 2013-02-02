
----------------------------------------------------------------------------------------------------
-- Class: Racer
----------------------------------------------------------------------------------------------------

class("Racer")
function Racer:__init(player)

	self.player = player
	self.playerId = player:GetId()
	self.name = player:GetName()
	self.posOriginal = player:GetPosition() -- player is teleported back here when done.
	
	-- Set their model id immediately. Probably a good idea.
	self.modelIdOriginal = player:GetModelId()
	player:SetModelId(playerModelId)
	
	-- Index of checkpoints.
	self.targetCheckpoint = 1
	self.lapsCompleted = 0
	self.numCheckpointsHit = 0
	self.hasFinished = false
	self.targetCheckpointDistanceSqr = 0
	
	self.lastVehicleId = -1
	self.timeSinceOutOfVehicle = 0
	
	self.cheatDetection = nil

end

function Racer:AdvanceCheckpoint()

	self.targetCheckpoint = self.targetCheckpoint + 1

--~ 	MessagePlayer(
--~ 		self.player ,
--~ 		"Checkpoint! id = "..
--~ 			(self.targetCheckpointId - 1)..
--~ 			" , new target = "..
--~ 			self.targetCheckpointId
--~ 	)
	
	local vehicle = self.player:GetVehicle()
	
	-- if IsValid(vehicle) then
		-- MessageRace(self.name.."'s vehicle health before: "..vehicle:GetHealth())
		-- vehicle:SetHealth(vehicle:GetHealth() + 0.075)
		-- MessageRace(self.name.."'s vehicle health after: "..vehicle:GetHealth())
	-- end
	
	Network:Send(self.player , "SetTargetCheckpoint" , self.targetCheckpoint)
	
	-- MessagePlayer(
		-- self.player ,
		-- "Checkpoint!"
	-- )

end

function Racer:AdvanceLap()

	self.targetCheckpoint = 1

	self.lapsCompleted = self.lapsCompleted + 1

	if self.lapsCompleted >= currentCourse.info.laps then
		self:Finish()
	else
		-- local msg = (
			-- "Lap "..
			-- self.lapsCompleted..
			-- "/"..
			-- currentCourse.info.laps..
			-- " completed!"
		-- )
		-- if self.lapsCompleted == currentCourse.info.laps - 1 then
			-- msg = msg.." Final lap!"
		-- end
		-- MessagePlayer(self.player , msg)
		
		-- if IsValid(vehicle) then
			-- vehicle:SetHealth(vehicle:GetHealth() + 0.075)
		-- end
		
		Network:Send(self.player , "SetTargetCheckpoint" , 1)
	end

end

function Racer:Finish()
	
	self.hasFinished = true

	table.insert(finishedRacers , self)

	if #finishedRacers == 1 then
		timeOfFirstFinisher = os.time()
	end

	-- Messages to immediately print for top three finishers.
	if #finishedRacers == 1 then
		MessageServer(self.name.." wins the race!")
	elseif #finishedRacers == 2 then
		MessageRace(self.name.." finishes 2nd.")
	elseif #finishedRacers == 3 then
		MessageRace(self.name.." finishes 3rd.")
	end
	
	-- if IsValid(vehicle) then
		-- vehicle:SetHealth(vehicle:GetHealth() + 0.075)
	-- end
	
	Network:Send(self.player , "Finish")
	Network:Send(
		self.player ,
		"ShowLargeMessage" ,
		{"Finish!" , 7.5}
	)

end



