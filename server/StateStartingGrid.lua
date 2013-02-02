
----------------------------------------------------------------------------------------------------
-- State: StateStartingGrid
----------------------------------------------------------------------------------------------------

class("StateStartingGrid")
function StateStartingGrid:__init()
	self.__type = "StateStartingGrid"

	-- Yes, this state has a state. METAAAAA
	-- Possible states: waiting, countdown
	self.state = "waiting"

	-- Time variables, used in Run(). Reused for each state.
	self.timerStart = os.time()
	-- Variable often reused for timer stuff.
	-- Set initially to startGridWaitSeconds, but in the countdown timer
	-- it is set to countdownIntervalSeconds.
	self.timerWaitAmount = startGridWaitSeconds

	self.countdownMessagesIndex = 1
	
	--
	-- Scale number of laps by number of players.
	--
	local lapsMultPlayers = (numPlayers / currentCourse.maxPlayers)
	lapsMultPlayers = (lapsMultPlayers - 0.24)
	lapsMultPlayers = lapsMultPlayers + 1
	-- Global laps multipier.
	currentCourse.info.laps = currentCourse.info.laps * lapsMult
	-- Multiply laps and then round it.
	currentCourse.info.laps = math.ceil(currentCourse.info.laps * lapsMultPlayers - 0.5)
	-- Minimum laps of 1
	if currentCourse.info.laps < 1 then
		currentCourse.info.laps = 1
	end
	
	--
	-- numCheckpointsToFinish. Used for racePosTracker.
	--
	if currentCourse.info.type == "linear" then
		numCheckpointsToFinish = #currentCourse.checkpoints + 1
	elseif currentCourse.info.type == "circuit" then
		numCheckpointsToFinish = (#currentCourse.checkpoints + 1) * currentCourse.info.laps
	end
	
	
	--
	-- Set up currentCourse.gridPositions and other variables.
	-- currentCourse.gridPositions:
	-- key = Vector
	-- value = index of currentCourse.startGrids
	--
	currentCourse.gridPositions = {}
	currentCourse.gridAngles = {}
	for k,sg in pairs(currentCourse.startGrids) do
		sg.numVehicles = numPlayers / (currentCourse.maxPlayers / sg.maxPlayers)
		sg.numVehicles = sg.numVehicles * vehicleToPlayerRatio
		sg.numVehicles = math.ceil(sg.numVehicles)
		sg.numVehicles = Utility.Clamp(sg.numVehicles , 2 , sg.maxPlayers)
		
		-- Get sg.numVehiclesPerRow.
		-- Finely balanced formula. Fewer players means fewer vehicles per row.
		sg.numVehiclesPerRow = (
			(5 * sg.numVehicles^1.30) /
			(125 + sg.maxPlayers*0.25)
		)
		sg.numVehiclesPerRow = math.ceil(sg.numVehiclesPerRow)
		-- Minumum vehicles per row of 1.
		sg.numVehiclesPerRow = Utility.Clamp(
			sg.numVehiclesPerRow ,
			1 ,
			sg.maxVehiclesPerRow
		)
		
		-- Get sg.numRows.
		sg.numRows = math.ceil(sg.numVehicles / sg.numVehiclesPerRow)
		-- Simple error correcting. Wait, why did I write it this way?
		while sg.numRows > sg.maxRows do
			sg.numRows = sg.numRows - 1
		end
		-- Minumum of 1 row.
		sg.numRows = Utility.Clamp(sg.numRows , 1 , sg.maxRows)
		
		-- Make sure that sg.numVehiclesPerRow produces enough vehicles.
		while sg.numVehiclesPerRow * sg.numRows < sg.numVehicles do
			sg.numVehiclesPerRow = sg.numVehiclesPerRow + 1
		end
		
		-- gridPositions
		local count = 0
		for y=0 , sg.numRows - 1 do
			for x=0 , sg.numVehiclesPerRow - 1 do
				local xDivisor = sg.numVehiclesPerRow - 1
				local gridPos , gridAngle
				if xDivisor == 0 then
					gridPos , gridAngle = sg:GetPoint(
						0.5 ,
						(y / (sg.numRows - 1)) * (sg.numRows / sg.maxRows)
					)
				else
					gridPos , gridAngle = sg:GetPoint(
						x / (xDivisor) ,
						(y / (sg.numRows - 1)) * (sg.numRows / sg.maxRows)
					)
				end
				-- Constant offset.
				gridPos = gridPos + Vector(0 , 0.5 , 0)
				currentCourse.gridPositions[
					gridPos
				] = k
				currentCourse.gridAngles[
					gridPos
				] = gridAngle
				count = count + 1
				if count >= sg.numVehicles then
					break
				end
			end
			if count >= sg.numVehicles then
				break
			end
		end

	end

	timeLimit = (
		(currentCourse.info.lapTimeMinutes * 60 + currentCourse.info.lapTimeSeconds) *
		currentCourse.info.laps *
		timeLimitMult
	)

	despawnSeconds = (
		(currentCourse.info.lapTimeMinutes * 60 + currentCourse.info.lapTimeSeconds) *
		despawnLapRatio
	)

	--
	-- If we just changed to this state, set up the grid:
	--     Spawn vehicles and put players in them. (no functionality yet)
	-- Temporarily moved to StateRacing
	--
	
	
	
	-- [TEMP FEATURE]
	-- Teleport everyone to a skydive above the starting line and set their world and weather.
	if debugLevel >= 2 then
		print("Teleporting "..numPlayers.." players above the starting line.")
	end
	local count = 1
	for id , p in pairs(players_PlayerIdToPlayer) do
		-- If this player's world isn't -1, they did something whacky.
		if p:GetWorldId() ~= -1 then
			MessagePlayer(
				p ,
				(
					"You have been removed from the race "..
					"for being in the wrong world: "..
					p:GetWorldId()
				)
			)
			RemovePlayer(p)
		else
			p:SetWorldId(worldId)
			p:Teleport(currentCourse.skydivePos , Angle(90 , 0 , 0))
			p:SetWeatherSeverity(currentCourse.info.weatherSeverity)
			count = count + 1
		end
	end
	
	--
	-- Send info to clients.
	--
	
	-- Set up a new checkpoints table, containing only the data to send out.
	local checkpointData = {} -- [1] = {1}
	for n = 1 , #currentCourse.checkpoints do
		table.insert(checkpointData , currentCourse.checkpoints[n].position)
	end
	-- Add the start/finish or finish.
	if currentCourse.info.type == "circuit" then
		table.insert(checkpointData , currentCourse.startFinish.position)
	elseif currentCourse.info.type == "linear" then
		table.insert(checkpointData , currentCourse.finish.position)
	end
	
	--
	-- Remove every vehicle in the Racing world, just in case.
	--
	for vehicle in Server:GetVehicles() do
		if vehicle:GetWorldId() == worldId then
			vehicle:Remove()
		end
	end
	
	-- Make them instantiate a Race class.
	NetworkSendRace("CreateRace" , version)
	-- Race.courseInfo.
	NetworkSendRace(
		"SetCourseInfo" ,
		{
			currentCourse.info.name ,
			currentCourse.info.type ,
			currentCourse.info.laps ,
			currentCourse.info.weatherSeverity ,
		}
	)
	-- Race.checkpoints.
	NetworkSendRace("SetCheckpoints" , checkpointData)
	-- Tell the client to begin drawing pre race stuff explicitly. Otherwise, they will start drawing
	-- even if they didn't get the stuff above.
	NetworkSendRace("StartPreRace")


end

-- Called every PreServerTick if state is startGrid.
-- Handles short wait time after vehicles are spawned on starting grid, and the countdown.
function StateStartingGrid:Run()

	-- Future feature; need vehicle input freezing.
	-- If the timer has elapsed, do stuff depending on self.state.
 	if os.time() - self.timerStart >= self.timerWaitAmount then
		
 		-- Waiting state
 		if self.state == "waiting" then
			
 			self.timerStart = os.time()
 			self.timerWaitAmount = countdownIntervalSeconds
 			self.state = "countdown"
			
 		-- Countdown state.
 		elseif self.state == "countdown" then
			
			-- If we've gone through all of the countdown messages, then
 			-- change the state to StateRacing.
			if self.countdownMessagesIndex >= #countdownMessages then
 				SetState("StateRacing")
 			end
			
			local duration = countdownIntervalSeconds * 0.85
			-- Multiply the duration for the "Go!" message.
			if self.countdownMessagesIndex == #countdownMessages then
				duration = duration * 1.75
			end
			NetworkSendRace(
				"ShowLargeMessage" ,
				{countdownMessages[self.countdownMessagesIndex] , duration}
			)
 			self.countdownMessagesIndex = self.countdownMessagesIndex + 1
			
			self.timerStart = os.time()
			
 		end
		
 	end

end
