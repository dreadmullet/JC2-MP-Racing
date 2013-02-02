
numPlayersToUpdatePerTick = 1

class("CRacePosSender")
function CRacePosSender:__init(racePosTracker)
	
	self.racePosTracker = racePosTracker
	self.racePosTrackerBuffer = {}
	
	self.playerIdToCheckpointDistanceSqr = {}
	
	self.currentRacePosition = 0
	self.currentCPIndex = 0
	self.currentPlayerIdIndex = 0
	
	self.numTicks = 0
	
	self.needsNewBuffer = true
	
	self.topPlayers = {}
	
	self.eventSubTick = Events:Subscribe("PostServerTick" , self , self.Proc)
	
end

function CRacePosSender:CopyToBuffer()
	
	-- print("CopyToBuffer")
	
	--
	-- Copy racer checkpoint distances into this.
	--
	self.playerIdToCheckpointDistanceSqr = {}
	
	--
	-- Transform the (playerId , bool) maps into arrays and fill checkpoint distance array.
	--
	self.racePosTrackerBuffer = {}
	for cp , array in pairs(self.racePosTracker) do
		
		self.racePosTrackerBuffer[cp] = {}
		for id , bool in pairs(self.racePosTracker[cp]) do
			
			table.insert(self.racePosTrackerBuffer[cp] , id)
			
			local racer = players_PlayerIdToRacer[id]
			
			if racer == nil then
				print("WARNING: player of id " , id , " isn't in the race for some reason!")
				print("Name = "..Player.GetById(id):GetName())
			else
				self.playerIdToCheckpointDistanceSqr[id] = (
					racer.targetCheckpointDistanceSqr
				)
			end
			
		end
		
		-- Sort player id array by players' distances to their target checkpoints.
		table.sort(
			self.racePosTrackerBuffer[cp] ,
			function(id1 , id2)
				return (
					self.playerIdToCheckpointDistanceSqr[id1] <
					self.playerIdToCheckpointDistanceSqr[id2]
				)
			end
		)
		
	end
	
	--
	-- Reset values.
	--
	self.currentRacePosition = 1
	self.currentCPIndex = currentCheckpoint
	self.currentPlayerIdIndex = 1
	self.numPlayers = numPlayers
	self.numPlayersSentTotal = 0
	
	--
	-- Calculate top three player positions.
	--
	self.topPlayers = {}
	
	for cpIndex = self.currentCPIndex , 0 , -1 do
		
		local numPlayerIds = #self.racePosTrackerBuffer[cpIndex]
		for	playerIdIndex = 1 ,	numPlayerIds do
			
			local playerId = self.racePosTrackerBuffer[cpIndex][playerIdIndex]
			if IsValid(Player.GetById(playerId)) then
				table.insert(self.topPlayers , playerId)
			else
				print(
					"[Racing] Player not valid: " ,
					self.racePosTrackerBuffer[self.currentCPIndex][self.currentPlayerIdIndex] ,
					" (This should probably never happen!)"
				)
			end
			
			if #self.topPlayers >= leaderboardMaxPlayers then
				break
			end
			
		end
		
		if #self.topPlayers >= leaderboardMaxPlayers then
			break
		end
		
	end
	
	
end

-- Send race position to a few players. Also sends the top three racers.
-- Also, may as well do some per-player calculations here instead of every tick.
-- Called every server tick.
function CRacePosSender:Proc()
	
	self.numTicks = self.numTicks + 1
	
	if self.numTicks % 2 ~= 0 then
		return
	end
	
	-- Make sure we're in the racing state.
	if GetState() ~= "StateRacing" then
		return
	end
	
	if self.needsNewBuffer then
		
		self:CopyToBuffer()
		
		self.needsNewBuffer = false
		
	else
		
		local numPlayersSent = 0
		local isLooping = true
		for cpIndex = self.currentCPIndex , 0 , -1 do
			
			local array = self.racePosTrackerBuffer[self.currentCPIndex]
			
			local numPlayerIds = 0
			if array == nil then
				print("This is nil: " , "self.racePosTrackerBuffer[" , self.currentCPIndex , "]")
			else
				numPlayerIds = #array
			end
			
			for playerIdIndex = self.currentPlayerIdIndex ,	numPlayerIds do
				
				if not isLooping then
					break
				end
				
				-- if self.currentRacePosition == nil then
					-- print("WARNING: currentRacePosition is not valid!")
				-- end
				
				-- if self.numPlayers == nil then
					-- print("WARNING: numPlayers is not valid!")
				-- end
				
				local player = Player.GetById(
					self.racePosTrackerBuffer[self.currentCPIndex][self.currentPlayerIdIndex]
				)
				
				-- Check both buffer and current for if the player is in the race.
				if
					IsValid(player) and
					players_PlayerIdToRacer[
						self.racePosTrackerBuffer[self.currentCPIndex][self.currentPlayerIdIndex]
					]
				then
					
					--
					-- Send race position and leaderboard.
					--
					-- print(
						-- "Sending race position to " ,
						-- player:GetName() ,": " ,
						-- self.currentRacePosition
					-- )
					Network:Send(
						player ,
						"SetRacePosition" ,
						{self.currentRacePosition , self.numPlayers}
					)
					Network:Send(
						player ,
						"SetLeaderboard" ,
						self.topPlayers
					)
					
					--
					-- Miscellaneous per-player updates.
					--
					
					-- Check if this player is currently is the world. If not, remove them.
					if player:GetWorldId() ~= worldId then
						MessagePlayer(
							player ,
							(
								"You have been removed from the race "..
								"for being in the wrong world: "..
								player:GetWorldId()
							)
						)
						RemovePlayer(player)
					end
					
					self.currentRacePosition = self.currentRacePosition + 1
					numPlayersSent = numPlayersSent + 1
					self.numPlayersSentTotal = self.numPlayersSentTotal + 1
					
					
				else
					-- This should happen when a player leaves the race.
					-- print(
						-- "[Racing] Player not valid: " ,
						-- self.racePosTrackerBuffer[self.currentCPIndex][self.currentPlayerIdIndex] ,
						-- " (This is not a big deal.)"
					-- )
					self.racePosTrackerBuffer[self.currentCPIndex][self.currentPlayerIdIndex] = nil
				end
				
				self.currentPlayerIdIndex = self.currentPlayerIdIndex + 1
				-- if self.currentPlayerIdIndex > numPlayerIds then
					-- self.currentPlayerIdIndex = 1
				-- end
				
				if numPlayersSent >= numPlayersToUpdatePerTick then
					isLooping = false
				end
				
			end
			
			-- print(
				-- "currentPlayerIdIndex = " , self.currentPlayerIdIndex ,
				-- ", numPlayerIds = " , numPlayerIds
			-- )
			-- print(
				-- "num players sent = " , self.numPlayersSentTotal ,
				-- ", numPlayers = " , self.numPlayers
			-- )
			
			if
				self.currentPlayerIdIndex > numPlayerIds
			then
				self.needsNewBuffer = true
			end
			
			if not isLooping then
				-- print("Breaking CP loop")
				break
			end
			
			self.currentCPIndex = self.currentCPIndex - 1
			
		end
		
	end
	
	
	-- print()
	-- print("racePosTrackerBuffer = ")
	-- Utility.PrintTable(self.racePosTrackerBuffer)
	-- print()
	-- print("playerIdToCheckpointDistanceSqr = ")
	-- Utility.PrintTable(self.playerIdToCheckpointDistanceSqr)
	-- print()
	
end

function CRacePosSender:Destroy()
	
	Events:Unsubscribe(self.eventSubTick)
	
end






