
debugLevel = 2

class("Race")
function Race:__init()
	
	if debugLevel >= 2 then
		print("Race:__init")
		raceInstance = self
	end
	
	self.courseInfo = {}
	self.checkpoints = {}
	
	-- Index, not id.
	self.targetCheckpoint = 1
	
	self.isFinished = false
	
	-- Calculated at race start.
	self.courseLength = -1
	
	self.checkpoints = {}
	
	self.lapCount = 1
	
	self.racePosition = -1
	self.playerCount = -1
	
	self.leaderboard = {}
	
	-- Reset at beginning of every frame.
	-- Increased when Race:startingGridTextPos is called.
	self.startingGridTextPos = Vector2(0 , 0)
	
	-- Helps with flashing checkpoint arrow.
	self.checkpointArrowActivationValue = 1
	
	-- Reset when checkpoint distances are sent.
	self.sendCheckpointTimer = nil
	
	self.numTicksRace = 0
	
	-- Received at start of race.
	-- Variables: name, color.
	self.playerIdToInfo = {}
	
	-- Privides an easy way to unsubscribe from all events.
	self.netSubs = {}
	self.eventSubs = {}
	
	self.netSubs.setCourseInfo = Network:Subscribe("SetCourseInfo" , self , self.SetCourseInfo)
	self.netSubs.setCheckpoints = Network:Subscribe("SetCheckpoints" , self , self.SetCheckpoints)
	self.netSubs.setPlayerInfo = Network:Subscribe("SetPlayerInfo" , self , self.SetPlayerInfo)
	self.netSubs.setTargetCheckpoint = Network:Subscribe(
		"SetTargetCheckpoint" ,
		self ,
		self.SetTargetCheckpoint
	)
	self.netSubs.showLargeMessage = Network:Subscribe(
		"ShowLargeMessage" ,
		self ,
		self.ShowLargeMessage
	)
	
	self.netSubs.startPreRace = Network:Subscribe("StartPreRace" , self , self.StartPreRace)
	self.netSubs.startRace = Network:Subscribe("StartRace" , self , self.StartRace)
	self.netSubs.finish = Network:Subscribe("Finish" , self , self.Finish)
	self.netSubs.endRace = Network:Subscribe("EndRace" , self , self.EndRace)
	
	self.eventSubs.handleInput = Events:Subscribe("LocalPlayerInput" , self , self.HandleInput)
	self.eventSubs.debugUpdate = Events:Subscribe("Render" , self , self.DebugUpdate)
	
	-- Debug.
	self.netSubs.debugRacePositionTracker = Network:Subscribe(
		"DebugRacePosTracker" ,
		self ,
		self.DebugRacePosTracker
	)
	self.netSubs.debugCheckpointArrow = Network:Subscribe(
		"DebugCheckpointArrow" ,
		self ,
		self.DebugCheckpointArrow
	)
	
	-- Disable nametags.
	if Settings.useNametags == false then
		Events:FireRegisteredEvent("NametagsSetState" , false)
	end
	
	self.debug = {}
	self.debug.camPosStreak = 0
	
end


--
-- Network events
--

-- This stuff isn't in __init anymore, cause it would start drawing the GUI even if stuff wasn't
-- sent yet.
function Race:StartPreRace()
	
	if debugLevel >= 2 then
		print("Race:StartPreRace")
	end
	
	self.eventSubs.drawPreRaceGUI = Events:Subscribe("Render" , self , self.DrawPreRaceGUI)
	
end

-- Changes rendering event from PreRace to Race.
function Race:StartRace()
	
	if debugLevel >= 2 then
		print("Race:StartRace")
	end
	
	self.sendCheckpointTimer = Timer()
	
	Events:Unsubscribe(self.eventSubs.drawPreRaceGUI)
	self.eventSubs.drawPreRaceGUI = nil
	
	self.netSubs.setRacePosition = Network:Subscribe(
		"SetRacePosition" ,
		self ,
		self.SetRacePosition
	)
	self.netSubs.updateRacePositions = Network:Subscribe(
		"UpdateRacePositions" ,
		self ,
		self.UpdateRacePositions
	)
	
	self.eventSubs.drawRaceGUI = Events:Subscribe("Render" , self , self.DrawRaceGUI)
	self.eventSubs.sendCheckpointDistance = Events:Subscribe(
		"PostClientTick" ,
		self ,
		self.SendCheckpointDistance
	)
	
end

function Race:SetCourseInfo(args)
	
	self.courseInfo.name = args[1]
	self.courseInfo.type = args[2]
	self.courseInfo.laps = args[3]
	self.courseInfo.weatherSeverity = args[4]
	
	if not args[1] then print("Error: args[1] is nil for some reason! This should never happen!") end
	if not args[2] then print("Error: args[2] is nil for some reason! This should never happen!") end
	if not args[3] then print("Error: args[3] is nil for some reason! This should never happen!") end
	if not args[4] then print("Error: args[4] is nil for some reason! This should never happen!") end
	
	if debugLevel >= 2 then
		-- print("Race:SetCourseInfo")
		print("Name = " , self.courseInfo.name)
		print("type = " , self.courseInfo.type)
		print("laps = " , self.courseInfo.laps)
		print("WeatherSeverity = " , self.courseInfo.weatherSeverity)
	end
	
end

-- Called when the race begins.
function Race:SetCheckpoints(args)
	
	self.checkpoints = args
	
	if debugLevel >= 2 then
		-- print("Race:SetCheckpoints")
		print("#checkpoints = " , #self.checkpoints)
	end
	
	self:CalculateCourseLength()
	
end

function Race:SetPlayerInfo(playerIdToInfo)
	
	self.playerIdToInfo = playerIdToInfo
	
end


-- Player reached finish line.
function Race:Finish()
	
	if debugLevel >= 2 then
		print("Race:Finish!")
	end
	
	Events:Unsubscribe(self.eventSubs.drawRaceGUI)
	self.eventSubs.drawRaceGUI = nil
	Events:Unsubscribe(self.eventSubs.sendCheckpointDistance)
	self.eventSubs.sendCheckpointDistance = nil
	
	self.eventSubs.drawPostRaceGUI = Events:Subscribe("Render" , self , self.DrawPostRaceGUI)
	
end

-- Race end, everyone is teleported back or a single player is removed.
-- Unsubscribe from everything, pretty much deleting the class instance.
function Race:EndRace()
	
	if debugLevel >= 2 then
		print("Race:EndRace!")
	end
	
	for name , sub in pairs(self.netSubs) do
		Network:Unsubscribe(sub)
	end
	self.netSubs = nil
	
	for name , sub in pairs(self.eventSubs) do
		Events:Unsubscribe(sub)
	end
	self.eventSubs = nil
	
	-- Reenable nametags.
	if Settings.useNametags == false then
		Events:FireRegisteredEvent("NametagsSetState" , true)
	end
	
end

function Race:SetTargetCheckpoint(checkpoint)
	
	-- if debugLevel >= 2 then
		-- print("New target checkpoint: " , checkpoint)
	-- end
	
	self.targetCheckpoint = checkpoint
	
	-- If we started a new lap, increment self.lapCount.
	if checkpoint == 1 then
		self.lapCount = self.lapCount + 1
		self.checkpointArrowActivationValue = -1
	else
		self.checkpointArrowActivationValue = 0
	end
	
	
end

-- Race position AND player count.
function Race:SetRacePosition(args)
	
	self.racePosition = args[1]
	self.playerCount = args[2]
	
end

-- 
function Race:UpdateRacePositions(args)
	
	local racePosTracker = args[1]
	local currentCheckpoint = args[2]
	local finishedPlayerIds = args[3]
	
	-- print("racePosTracker = ")
	-- Utility.PrintTable(racePosTracker)
	-- if true then
		-- return
	-- end
	
	--
	-- Store the racePosTracker if debugLevel is 2.
	--
	if debugLevel >= 2 then
		self.racePosTracker = racePosTracker
	end
	
	--
	-- Transform the (playerId , bool) maps into arrays and fill checkpoint distance array.
	--
	local racePosTrackerArray = {}
	local playerIdToCheckpointDistanceSqr = {}
	self.playerCount = 0
	
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
	-- Calculate top three player positions.
	--
	self.leaderboard = {}
	
	-- Finished players
	for n = 1 , #finishedPlayerIds do
		table.insert(self.leaderboard , finishedPlayerIds[n])
		self.playerCount = self.playerCount + 1
	end
	
	-- Racing players.
	for cpIndex = currentCheckpoint , 0 , -1 do
		
		local numPlayerIds = #racePosTrackerArray[cpIndex]
		for playerIdIndex = 1 , numPlayerIds do
			
			local playerId = racePosTrackerArray[cpIndex][playerIdIndex]
			table.insert(self.leaderboard , playerId)
			self.playerCount = self.playerCount + 1
			
			-- If this is us, change some variables.
			if playerId == LocalPlayer:GetId() then
				self.racePosition = #self.leaderboard
			end
			
			-- if #self.leaderboard >= Settings.leaderboardMaxPlayers then
				-- break
			-- end
			
		end
		
		-- if #self.leaderboard >= Settings.leaderboardMaxPlayers then
			-- break
		-- end
		
	end
	
	
end

--
-- Events.
--

-- Called during the starting grid state.
function Race:DrawPreRaceGUI()
	
	-- Don't draw while in menus.
	if not Client:InState(GUIState.Game) then
		return
	end
	
	-- Reset startingGridTextPos
	self.startingGridTextPos = (
		NormVector2(
			Settings.startingGridBackgroundTopRight.x ,
			Settings.startingGridBackgroundTopRight.y
		) +
		Vector2(
			-Settings.startingGridBackgroundSize.x * Render.Width + Settings.padding ,
			Settings.padding
		)
	)
	
	self:DrawStartingGridBackground()
	
	self:DrawCourseName()
	self:DrawCourseType()
	self:DrawCourseLength()
	self:DrawVersion()
	
end

-- Called while actually racing.
function Race:DrawRaceGUI()
	
	-- print("DrawRaceGUI!")
	
	-- Don't draw while in menus.
	if not Client:InState(GUIState.Game) then
		return
	end
	
	self.numTicksRace = self.numTicksRace + 1
	
	self:DrawCheckpointArrow()
	self:DrawVersion()
	self:DrawCourseNameRace()
	-- TODO: Add race percentage for linear courses?
	self:DrawLapCounter()
	-- self:DrawTimers()
	self:DrawRacePosition()
	self:DrawMinimapIcons()
	self:DrawLeaderboard()
	
end

-- Called after finish.
function Race:DrawPostRaceGUI()
	
	-- Don't draw while in menus.
	if not Client:InState(GUIState.Game) then
		return
	end
	
	self:DrawVersion()
	self:DrawCourseNameRace()
	-- self:DrawTimers()
	self:DrawRacePosition()
	self:DrawMinimapIcons()
	self:DrawLeaderboard()
	
end

-- Called every frame.
function Race:SendCheckpointDistance(args)
	
	-- print("Race:SendCheckpointDistance!")
	
	-- Send checkpoint distance every interval.
	if self.sendCheckpointTimer:GetSeconds() >= Settings.sendCheckpointDistanceInterval then
		self.sendCheckpointTimer:Restart()
		-- print("Actually sending distance!")
		Network:Send(
			"ReceiveCheckpointDistanceSqr" ,
			{LocalPlayer:GetId() , self:GetTargetCheckpointDistanceSqr() , self.targetCheckpoint}
		)
	end
	
end

function Race:HandleInput(args)
	
	for n = 1 , #Settings.blockedInputs do
		if args.input == Settings.blockedInputs[n] and args.state ~= 0 then
			return false
		end
	end
	
	return true
	
end


--
-- Other functions.
--
function Race:CalculateCourseLength()
	
	local length = 0
	
	-- Get linear length between all checkpoints.
	for n = 2 , #self.checkpoints do
		length = length + Vector.Distance(self.checkpoints[n-1] , self.checkpoints[n])
	end
	
	-- Multiply length by a constant, since the actual distance is a little larger. Definitely.
	length = length * 1.2
	-- Round length, because precision doesn't mean anything anymore.
	length = math.floor(length / 100) * 100
	
	self.courseLength = length
	
end

function Race:GetTargetCheckpointDistanceSqr()
	
	return (self.checkpoints[self.targetCheckpoint] - LocalPlayer:GetPosition()):LengthSqr()
	
end



Network:Subscribe(
	"CreateRace" ,
	function(versionString)
		version = versionString
		Race()
	end
)

