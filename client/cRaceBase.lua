----------------------------------------------------------------------------------------------------
-- Both Race and Spectate inherit from this.
----------------------------------------------------------------------------------------------------

-- Key: model name
-- Value: Model
RaceBase.modelCache = {}

function RaceBase:__init(args) ; EGUSM.StateMachine.__init(self)
	-- Expose functions
	self.UpdateLeaderboard = RaceBase.UpdateLeaderboard
	
	if settings.debugLevel >= 2 then
		print("RaceBase:__init")
	end
	
	self.version = args.version
	self.numPlayers = -1
	self.playerIdToInfo = {}
	self.courseInfo = {}
	self.checkpoints = {}
	self.lapTimes = {}
	self.leaderboard = {}
	
	-- Request Models from server, if we don't have them already.
	if RaceBase.modelCache.TargetArrow == nil then
		OBJLoader.Request("TargetArrow" , self , RaceBase.ModelReceive)
	end
	
	self:NetworkSubscribe("Terminate")
end

function RaceBase:UpdateLeaderboard(racePosInfo)
	local racePosTracker = racePosInfo[1]
	local currentCheckpoint = racePosInfo[2]
	local finishedPlayerIds = racePosInfo[3]
	
	-- Transform the (playerId , bool) maps into arrays and fill checkpoint distance array.
	
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
	
	-- Calculate top player positions.
	
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

function RaceBase:ModelReceive(model , name)
	RaceBase.modelCache[name] = model
end

function Race:Terminate()
	self:Destroy()
end
