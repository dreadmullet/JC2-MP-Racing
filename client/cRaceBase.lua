----------------------------------------------------------------------------------------------------
-- Both Race and Spectate inherit from this.
----------------------------------------------------------------------------------------------------
class("RaceBase")

function RaceBase:__init(args) ; EGUSM.StateMachine.__init(self)
	-- Expose functions
	self.UpdateLeaderboard = RaceBase.UpdateLeaderboard
	self.Message = RaceBase.Message
	self.Destroy = RaceBase.Destroy
	
	if settings.debugLevel >= 2 then
		print("RaceBase:__init")
	end
	
	local raceInfo = args.raceInfo
	self.numPlayers = raceInfo.numPlayers
	self.numLaps = raceInfo.numLaps
	self.playerIdToInfo = raceInfo.playerIdToInfo
	self.course = raceInfo.course
	self.recordTime = raceInfo.topRecordTime
	self.recordTimePlayerName = raceInfo.topRecordPlayerName
	self.collisions = raceInfo.collisions
	
	-- Array of tables, each element is like:
	-- {playerId (number), isFinished (boolean)}
	self.leaderboard = {}
	self.targetArrowModel = nil
	self.icons = {}
	
	-- Initialize RaceModules.
	for index , moduleName in ipairs(args.raceInfo.modules) do
		local class = RaceModules[moduleName]
		if class then
			class()
		end
	end
	
	-- Request target arrow model.
	local args = {
		path = "Models/TargetArrow" ,
		type = OBJLoader.Type.Single ,
	}
	OBJLoader.Request(args , self , RaceBase.ModelReceive)
	
	self:NetworkSubscribe("ShowLargeMessage" , RaceBase.ShowLargeMessage)
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
		local entry = {
			playerId = finishedPlayerIds[n] ,
			isFinished = true ,
		}
		table.insert(self.leaderboard , entry)
		self.numPlayers = self.numPlayers + 1
	end
	
	-- Racing players.
	for cpIndex = currentCheckpoint , 0 , -1 do
		local numPlayerIds = #racePosTrackerArray[cpIndex]
		for playerIdIndex = 1 , numPlayerIds do
			local entry = {
				playerId = racePosTrackerArray[cpIndex][playerIdIndex] ,
				isFinished = false ,
			}
			table.insert(self.leaderboard , entry)
			self.numPlayers = self.numPlayers + 1
		end
	end
end

function RaceBase:Message(message)
	Chat:Print(message , settings.textColor)
	print(message)
end

function RaceBase:ModelReceive(model , name)
	self.targetArrowModel = model
end

function RaceBase:Destroy()
	EGUSM.StateMachine.Destroy(self)
	
	for index , icon in ipairs(self.icons) do
		icon:Destroy()
	end
end

-- Network events

function RaceBase:ShowLargeMessage(args)
	LargeMessage(args[1] , args[2])
end
