
debugLevel = 1

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
	self.finishTime = -1
	self.lapTimes = {}
	
	-- Calculated at race start.
	self.courseLength = -1
	
	self.checkpoints = {}
	
	-- Current lap.
	self.lapCount = 1
	
	self.racePosition = -1
	self.playerCount = -1
	
	self.leaderboard = {}
	
	self.isRacing = false
	
	-- Reset at beginning of every frame.
	-- Increased when Race:startingGridTextPos is called.
	self.startingGridTextPos = Vector2(0 , 0)
	
	-- Helps with flashing checkpoint arrow.
	self.checkpointArrowActivationValue = 1
	
	-- Reset when checkpoint distances are sent.
	self.sendCheckpointTimer = nil
	-- This is independent of the server; the server keeps track of time.
	self.raceTimer = nil
	
	self.numTicksRace = 0
	
	-- Received at start of race.
	-- Variables: name, color.
	self.playerIdToInfo = {}
	
	-- Privides an easy way to unsubscribe from all events.
	self.netSubs = {}
	self.eventSubs = {}
	
	local NetSub = function(name)
		self.netSubs[name] = Network:Subscribe(name , self , self[name])
	end
	
	NetSub("StartPreRace")
	NetSub("StartRace")
	NetSub("SetCourseInfo")
	NetSub("SetCheckpoints")
	NetSub("SetPlayerInfo")
	NetSub("Finish")
	NetSub("EndRace")
	NetSub("SetTargetCheckpoint")
	NetSub("SetAssignedVehicleId")
	NetSub("RaceTimePersonal")
	NetSub("NewRecordTime")
	NetSub("ShowLargeMessage")
	
	NetSub("DebugRacePosTracker")
	NetSub("DebugCheckpointArrow")
	
	self.eventSubs.LocalPlayerInput = Events:Subscribe(
		"LocalPlayerInput" ,
		self ,
		self.LocalPlayerInput
	)
	self.eventSubs.DebugUpdate = Events:Subscribe("Render" , self , self.DebugUpdate)
	
	-- Disable nametags.
	if settings.useNametags == false then
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
	
	self.eventSubs.DrawPreRaceGUI = Events:Subscribe("Render" , self , self.DrawPreRaceGUI)
	
end

-- Changes rendering event from PreRace to Race.
function Race:StartRace()
	
	if debugLevel >= 2 then
		print("Race:StartRace")
	end
	
	self.isRacing = true
	
	self.sendCheckpointTimer = Timer()
	self.raceTimer = Timer()
	
	Events:Unsubscribe(self.eventSubs.DrawPreRaceGUI)
	self.eventSubs.DrawPreRaceGUI = nil
	
	self.netSubs.setRacePositionInfo = Network:Subscribe(
		"SetRacePosition" ,
		self ,
		self.SetRacePositionInfo
	)
	self.netSubs.updateRacePositions = Network:Subscribe(
		"UpdateRacePositions" ,
		self ,
		self.UpdateRacePositions
	)
	
	self.eventSubs.DrawRaceGUI = Events:Subscribe("Render" , self , self.DrawRaceGUI)
	self.eventSubs.SendCheckpointDistance = Events:Subscribe(
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
	self.courseInfo.authors = args[5]
	self.courseInfo.recordTime = args[6]
	self.courseInfo.recordTimePlayerName = args[7]
	
	if debugLevel >= 3 then
		print("Race:SetCourseInfo")
		print("Name = " , self.courseInfo.name)
		print("type = " , self.courseInfo.type)
		print("laps = " , self.courseInfo.laps)
		print("weatherSeverity = " , self.courseInfo.weatherSeverity)
		print("recordTime = " , self.courseInfo.recordTime)
		print("recordTimePlayerName = " , self.courseInfo.recordTimePlayerName)
	end
	
end

-- Called when the race begins.
function Race:SetCheckpoints(args)
	
	self.checkpoints = args
	
	if debugLevel >= 3 then
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
	
	self.isFinished = true
	
	Events:Unsubscribe(self.eventSubs.DrawRaceGUI)
	self.eventSubs.DrawRaceGUI = nil
	Events:Unsubscribe(self.eventSubs.SendCheckpointDistance)
	self.eventSubs.SendCheckpointDistance = nil
	
	self.eventSubs.DrawPostRaceGUI = Events:Subscribe("Render" , self , self.DrawPostRaceGUI)
	
end

-- Race end, everyone is teleported back or a single player is removed.
-- Unsubscribe from everything, pretty much deleting the class instance.
function Race:EndRace()
	
	if debugLevel >= 2 then
		print("Race:EndRace!")
	end
	
	for key , sub in pairs(self.netSubs) do
		Network:Unsubscribe(sub)
	end
	self.netSubs = nil
	
	for key , sub in pairs(self.eventSubs) do
		Events:Unsubscribe(sub)
	end
	self.eventSubs = nil
	
	-- Reenable nametags.
	if settings.useNametags == false then
		Events:FireRegisteredEvent("NametagsSetState" , true)
	end
	
end

function Race:SetTargetCheckpoint(checkpoint)
	
	self.targetCheckpoint = checkpoint
	
	-- If we started a new lap.
	if checkpoint == 1 then
		self.lapCount = self.lapCount + 1
		self.checkpointArrowActivationValue = -1
		self.raceTimer:Restart()
	else
		self.checkpointArrowActivationValue = 0
	end
	
end

function Race:SetAssignedVehicleId(id)
	
	self.assignedVehicleId = id
	
end

function Race:RaceTimePersonal(raceTime)
	
	table.insert(self.lapTimes , raceTime)
	
end

function Race:NewRecordTime(args)
	
	self.courseInfo.recordTime = args[1]
	self.courseInfo.recordTimePlayerName = args[2]
	
end

-- Race position AND player count.
function Race:SetRacePositionInfo(args)
	
	self.racePosition = args[1]
	self.playerCount = args[2]
	
end

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
			
		end
		
	end
	
end

function Race:ShowLargeMessage(args)
	
	LargeMessage(args[1] or "nil" , args[2] or 1.5)
	
end

--
-- Events.
--

-- Called during the starting grid state.
function Race:DrawPreRaceGUI()
	
	-- Don't draw while in menus.
	if Client:GetState() ~= GUIState.Game then
		return
	end
	
	self:DrawStartingGridBackground()
	
	self:DrawCourseName()
	self:DrawCourseType()
	self:DrawCourseLength()
	-- self:DrawCourseAuthors() -- I am the humblest person alive.
	self:DrawVersion()
	
end

-- Called while actually racing.
function Race:DrawRaceGUI()
	
	-- print("DrawRaceGUI!")
	
	-- Don't draw while in menus.
	if Client:GetState() ~= GUIState.Game then
		return
	end
	
	self.numTicksRace = self.numTicksRace + 1
	
	self:DrawCheckpointArrow()
	self:DrawVersion()
	self:DrawCourseNameRace()
	-- TODO: Add race percentage for linear courses?
	self:DrawLapCounter()
	self:DrawRacePosition()
	self:DrawTimers()
	self:DrawMinimapIcons()
	self:DrawLeaderboard()
	self:DrawNextCheckpointArrow()
	
end

-- Called after finish.
function Race:DrawPostRaceGUI()
	
	-- Don't draw while in menus.
	if Client:GetState() ~= GUIState.Game then
		return
	end
	
	self:DrawVersion()
	self:DrawCourseNameRace()
	self:DrawLapCounter()
	self:DrawRacePosition()
	self:DrawTimers()
	self:DrawMinimapIcons()
	self:DrawLeaderboard()
	
end

-- Called every frame.
function Race:SendCheckpointDistance(args)
	
	-- print("Race:SendCheckpointDistance!")
	
	-- Send checkpoint distance every interval.
	if self.sendCheckpointTimer:GetSeconds() >= settings.sendCheckpointDistanceInterval then
		self.sendCheckpointTimer:Restart()
		-- print("Actually sending distance!")
		Network:Send(
			"ReceiveCheckpointDistanceSqr" ,
			{LocalPlayer:GetId() , self:GetTargetCheckpointDistanceSqr() , self.targetCheckpoint}
		)
	end
	
end

--
-- Events
--

function Race:LocalPlayerInput(args)
	
	for index , input in ipairs(settings.blockedInputs) do
		if args.input == input and args.state ~= 0 then
			return false
		end
	end
	
	-- Prevent them from driving if race hasn't started yet, or if they've finished.
	-- This could be much better; use different states for starting grid and racing etc.
	if self.isRacing == false or self.isFinished == true then
		for index , input in ipairs(settings.blockedInputsStartingGrid) do
			if args.input == input then
				return false
			end
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

