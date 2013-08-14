
function Race:__init(args)
	
	if settings.debugLevel >= 2 then
		print("Race:__init")
	end
	
	self.state = nil
	self.stateName = nil
	self.version = args.version
	self.numPlayers = -1
	self.playerIdToInfo = {}
	self.courseInfo = {}
	self.recordTime = -1
	self.recordTimePlayerName = ""
	self.checkpoints = {}
	self.lapTimes = {}
	self.leaderboard = {}
	
	self:SetState(args)
	
	Utility.EventSub(self , "Render")
	Utility.NetSub(self , "SetState")
	
end

function Race:Terminate()
	
	local args = {}
	args.stateName = "StateNone"
	self:SetState(args)
	
	Utility.EventUnsubscribeAll(self)
	Utility.NetUnsubscribeAll(self)
	
end

function Race:Render()
	
	if self.state then
		self.state:Run()
	end
	
end

function Race:SetState(args)
	
	if settings.debugLevel >= 2 then
		print("Changing state to "..args.stateName)
	end
	
	-- Call End function on previous state.
	if self.state and self.state.End then
		self.state:End()
	end
	self.state = _G[args.stateName](self , args)
	self.stateName = args.stateName
	
end

function Race:UpdateLeaderboard(racePosTracker , currentCheckpoint , finishedPlayerIds)
	
	--
	-- Transform the (playerId , bool) maps into arrays and fill checkpoint distance array.
	--
	local racePosTrackerArray = {}
	local playerIdToCheckpointDistanceSqr = {}
	
	for cp , array in pairs(racePosTracker) do
		
		racePosTrackerArray[cp] = {}
		for id , distSqr in pairs(racePosTracker[cp]) do
			table.insert(racePosTrackerArray[cp] , id)
			playerIdToCheckpointDistanceSqr[id] = distSqr[1]
		end
		
		-- Sort player id array by players' distances to their target checkpoints.
		table.sort(
			racePosTrackerArray[cp] ,
			function(id1 , id2)
				return (
					playerIdToCheckpointDistanceSqr[id1] <
					playerIdToCheckpointDistanceSqr[id2]
				)
			end
		)
		
	end
	
	--
	-- Calculate top player positions.
	--
	self.leaderboard = {}
	self.numPlayers = 0
	
	-- Finished players
	for n = 1 , #finishedPlayerIds do
		table.insert(self.leaderboard , finishedPlayerIds[n])
		self.numPlayers = self.numPlayers + 1
	end
	
	-- Racing players.
	for cpIndex = currentCheckpoint , 0 , -1 do
		local numPlayerIds = #racePosTrackerArray[cpIndex]
		for playerIdIndex = 1 , numPlayerIds do
			local playerId = racePosTrackerArray[cpIndex][playerIdIndex]
			table.insert(self.leaderboard , playerId)
			self.numPlayers = self.numPlayers + 1
		end
	end
	
end
