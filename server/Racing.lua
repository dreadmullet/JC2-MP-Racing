----------------------------------------------------------------------------------------------------
-- Racing gamemode
--
-- Typical happenings: (outdated)
-- The gamemode goes into a state of waiting after a random course is selected.
-- Players can type "/race" to join the next race. When the maximum number of
-- players for the course has been reached, or if the maximum waiting time
-- has been reached, the wait period finishes. Vehicles are spawned on the
-- starting grid and players are teleported into them. The gamemode waits for
-- a little bit then begins the countdown. After someone finishes, a
-- global message inform the server of the top 3, and the race ends after
-- some defined time (perhaps 30 seconds), then the players are cleared and it
-- goes back into the wait state.
--
--
--
--
----------------------------------------------------------------------------------------------------

-- Version history:
-- 0.1 - Broken, rushed version ran in the November test.
-- 0.2.2 - 31 January IRC test.
-- 0.2.3 - 0.2.10 - Early Febuary public test.
-- 0.2.11 - Closed tests.
-- 0.3.1 - 2013-04-17 Closed test.
-- 0.3.2+ - 2013-04-20 Open test.
version = "0.3.3"


----------------------------------------------------------------------------------------------------
-- Config variables.
----------------------------------------------------------------------------------------------------

settings = "Release"
-- settings = "Debug"

--
-- Release settings
--
if settings == "Release" then
	courseManifestFilePath = "course_manifest.txt"
	maxWaitSecondsBetweenRaces = 35
	textColorGlobal = Color(250 , 157 , 133 , 255) -- light red-orange
	textColorLocal =  Color(255 , 80 , 36 , 255) -- full red-orange
	commandName = "/race"
	startGridWaitSeconds = 7
	countdownMessages = {"Three!" , "Two!" , "One!" , "GO!!!"}
	countdownIntervalSeconds = 2 -- precision of 1 second
	vehicleToPlayerRatio = 1 -- default of 1
	worldId = 2 -- vehicles, checkpoints, and players are set to this world.
	raceEndTime = 25 -- Extra racing time after a person has finished. Reset after each finisher.
	minimumPlayers = 1
	despawnLapRatio = 0.25 -- 0.5 means vehicles despawn at 50% lap time.
	outOfVehicleTrackingDelaySeconds = 8 -- Delay to prevent people from parachuting everywhere.
	outOfVehicleMaxSeconds = 20 -- After this many seconds out of a vehicle, remove player.
	timeLimitMult = 1.8 -- Estimated course time is multiplied by this factor to get time limit.
	playerDeathDelay = 7 -- When players die, they are removed after this delay in seconds.
	courseSelectMode = "Sequential"
	playerModelIds = {60 , 65 , 69}
	useCheckpointIcons = false
	useFinishIcon = true
	lapsMult = 1
	leaderboardMaxPlayers = 8
	-- Prize money awarded starts here and is multiplied by prizeMoneyMult for every racer past 1st.
	prizeMoneyBase = 10000
	prizeMoneyMult = 0.75
	
	debugLevel = 1
end


--
-- Debug settings
--
if settings == "Debug" then
	courseManifestFilePath = "course_manifest.txt"
	maxWaitSecondsBetweenRaces = 30
	textColorGlobal = Color(250 , 157 , 133 , 255) -- light red-orange
	textColorLocal =  Color(255 , 80 , 36 , 255) -- full red-orange
	commandName = "/race"
	startGridWaitSeconds = 5
	countdownMessages = {"Three!" , "Two!" , "One!" , "GO!!!"}
	countdownIntervalSeconds = 2 -- precision of 1 second
	vehicleToPlayerRatio = 1 -- default of 1
	worldId = 2 -- Vehicles, checkpoints, and players are set to this world when racing.
	raceEndTime = 10 -- Extra racing time after a person has finished. Reset after each finisher.
	minimumPlayers = 1
	despawnLapRatio = 1000.6 -- 0.5 means vehicles despawn at 50% lap time.
	outOfVehicleTrackingDelaySeconds = 8 -- Delay to prevent people from parachuting everywhere.
	outOfVehicleMaxSeconds = 6000 -- After this many seconds out of a vehicle, remove player.
	timeLimitMult = 1000.5 -- Estimated course time is multiplied by this factor to get time limit.
	playerDeathDelay = 7 -- When players die, they are removed after this delay in seconds.
	courseSelectMode = "Sequential"
	playerModelIds = {64}
	useCheckpointIcons = false
	useFinishIcon = true
	lapsMult = 0
	leaderboardMaxPlayers = 8
	-- Prize money awarded starts here and is multiplied by prizeMoneyMult for every racer past 1st.
	prizeMoneyBase = 10000
	prizeMoneyMult = 0.75
	
	debug_ForceMaxPlayers = true
	
	version = version.." (Debug)"
	
	-- 0 means no printing except for errors.
	-- 1 is very reasonable for normal use.
	-- 2 is quite annoying for normal use.
	-- 3 can be a spamfest.
	debugLevel = 3
end






----------------------------------------------------------------------------------------------------
-- Global variables.
----------------------------------------------------------------------------------------------------

coursePaths = {}
currentCourse = {}
currentCourseIndex = -1
numCourses = -1

-- If this ever becomes true, the script will self destruct.
-- Only happens when the course manifest cannot be found.
fatalError = false
eventSubServerTick = nil

players_PlayerIdToRacer = {}
players_PlayerIdToPlayer = {}
players_DeadPlayerIdToTimeOfDeath = {}
numPlayers = 0
numPlayersAtStart = 0

vehicles = {}

-- Current checkpoints that are spawned.
-- Not to be confused with currentCourse.checkpoints.
checkpoints = {}

-- key = number of CPs completed.
-- value = map of player ids that have completed key number of CPs.
--     key = player Id, value = pointermabob to checkpoint distance
racePosTracker = {}

-- Starts at 0. When someone hits the first checkpoint, this becomes 1, etc.
currentCheckpoint = 0

numCheckpointsToFinish = 0

-- Array.
finishedRacers = {}
-- Set to os.time() when someone finishes. Used in race state.
timeOfLastFinisher = 0

-- Holds a state class.
-- Possible states:
-- StateWaiting        Waiting for players to join.
-- StateStartingGrid   Lined up at start grid right before race.
-- StateRacing         In a race.
-- StateFinished       Race end. (todo (or maybe not))
state = {}

-- Reset at the end of each race.
timeOfLastRace = 0
-- Reset at the start of each race. Only used during races.
timeOfRaceBegin = 0

-- Helps with despawning untouched vehicles halfway through a lap.
despawnSeconds = 0
hasDespawnedUntouchedVehicles = false

-- Helps with despawning unused vehicles.
-- key = Vehicle Id
-- value = true
vehiclesDriven = {}

-- Helps with kicking out players who parachute everywhere.
isTrackingOutOfVehicle = false
-- key = playerId
-- value = Racer
playersOutOfVehicle = {}

-- Time elapsed since last tick.
deltaTime = 0

-- WeatherSeverity of world -1 when a race begins.
weatherPrevious = 0

-- Used to check on only one player per tick.
cheatDetectionTick = 1
cheatDetectionNumRacersAdded = 0

prizeMoneyCurrent = prizeMoneyBase




----------------------------------------------------------------------------------------------------
-- Functions
----------------------------------------------------------------------------------------------------

-- Called at end of race.
-- Clean up checkpoints and vehicles, and reset each player's world, etc.
-- Call client-side stuff.
-- Restart to StateWaiting.
-- Can be called from anywhere with no problems.
EndRace = function(beginAnotherRace)

	if beginAnotherRace == nil then
		beginAnotherRace = true
	end

	if debugLevel >= 1 then
		print("Ending race.")
	end

	-- Reset some racer related things.
	if debugLevel >= 3 then
		print("Teleporting players back to their world.")
	end
	for id , racer in pairs(players_PlayerIdToRacer) do
		racer.player:SetWorldId(-1)
		racer.player:Teleport(racer.posOriginal , Angle(0 , 0 , 0))
		racer.player:SetModelId(racer.modelIdOriginal)
		racer.player:SetWeatherSeverity(0)
		Network:Send(racer.player , "EndRace")
	end
	
	Cleanup()
	
	players_PlayerIdToRacer = {}
	players_PlayerIdToPlayer = {}
	players_DeadPlayerIdToTimeOfDeath = {}
	numPlayers = 0
	
	if beginAnotherRace then
		SetState("StateWaiting")
	end

end

-- If a race is in progress, it restarts the race and reloads the course from disk.
-- Holy crap this is a hack. Do not use it. (Laps completed per racer is fucked.)
RestartRace = function()
	
	-- if debugLevel >= 1 then
		-- print("Restarting race.")
	-- end
	
	-- Cleanup()
	
	-- currentCourse = CourseFileLoader.Load(coursePaths[currentCourseIndex])
	
	-- SetState("StateStartingGrid")
	
end

-- Cleans up vehicles/checkpoints and resets race related things. This should probably go
-- in StateWaiting:__init
Cleanup = function()
	
	if debugLevel >= 2 then
		print("Cleaning up.")
	end
	
	-- Clean up checkpoints.
	for n=1 , #checkpoints do
		if IsValid(checkpoints[n]) then
			checkpoints[n]:Remove()
		else
			MessageServer("Warning: tried to remove invalid checkpoint! n = "..n)
		end
	end
	checkpoints = {}
	
	-- Clean up vehicles.
	for n=1 , #vehicles do
		if IsValid(vehicles[n]) then
			vehicles[n]:Remove()
		else
			MessageRace("Warning: tried to remove invalid vehicle! n = "..n)
		end
	end
	vehicles = {}
	
	racePosTracker = {}
	
	currentCheckpoint = 0
	
	finishedRacers = {}
	
	vehiclesDriven = {}
	hasDespawnedUntouchedVehicles = false
	
	isTrackingOutOfVehicle = false
	
	cheatDetectionNumRacersAdded = 0
	
	prizeMoneyCurrent = prizeMoneyBase
	
end


-- Loads a new, random course from coursePaths.
SelectCourseRandom = function()
	
	local newCourseIndex = -2
	
	if numCourses > 1 then
		repeat newCourseIndex = math.random(1 , numCourses)
		until newCourseIndex ~= currentCourseIndex
		currentCourseIndex = newCourseIndex
	else
		currentCourseIndex = 1
	end
	
	currentCourse = CourseFileLoader.Load(coursePaths[currentCourseIndex])
	
end

-- Loads the next course from coursePaths.
SelectCourseSequential = function()
	
	if numCourses > 1 then
		currentCourseIndex = currentCourseIndex + 1
		if currentCourseIndex > #coursePaths then
			currentCourseIndex = 1
		end
	else
		currentCourseIndex = 1
	end
	
	currentCourse = CourseFileLoader.Load(coursePaths[currentCourseIndex])
	
end



AddPlayer = function(player)
	
	-- Make sure they're in the default world.
	if player:GetWorldId() ~= -1 then
		MessagePlayer(player , "You must exit all other game modes before joining.")
		return
	end
	
	-- Make sure numPlayers isn't max. This is taken care of elsewhere, but just in case.
	if numPlayers >= currentCourse.maxPlayers then
		MessagePlayer(player , "No more slots. Also, you shouldn't be able to see this message!")
	end
	
	-- Make sure they're not already in the mode.
	if players_PlayerIdToRacer[player:GetId()] then
		MessagePlayer(
			player ,
			"You're already in the race. Also, you shouldn't be able to see this message!"
		)
	end
	
	local racer = Racer(player)

	players_PlayerIdToRacer[racer.playerId] = racer
	players_PlayerIdToPlayer[racer.playerId] = player
	
	numPlayers = numPlayers + 1
	
	MessagePlayer(
		player ,
		"You have been added to the next race. Use "..commandName.." to drop out."
	)
	
end

RemovePlayer = function(player)
	
	if not player then
		return
	end
	
	local racer = players_PlayerIdToRacer[player:GetId()]
	
	-- Make sure they're in the mode before we remove them, just in case.
	if not racer then
		return
	end
	
	-- Reset their model.
	racer.player:SetModelId(racer.modelIdOriginal)
	
	-- Give them their weapons back.
	racer:RestoreInventory()
	
	-- Always remove their vehicle.
	local vehicle = Vehicle.GetById(racer.assignedVehicleId)
	if IsValid(vehicle) then
		RemoveVehicle(vehicle)
	end
	
	-- Remove from racePosTracker, if applicable.
	if GetState() == "StateRacing" then
		
		local removed = false
		for cp , map in pairs(racePosTracker) do
			for id , bool in pairs(racePosTracker[cp]) do
				if id == player:GetId() then
					racePosTracker[cp][id] = nil
					removed = true
					break
				end
			end
			if removed then
				break
			end
		end
		
		if not removed then
			print("Error: " , racer.name , " could not be removed from the race pos tracker!")
		end
		
	end
	
	players_PlayerIdToRacer[racer.playerId] = nil
	players_PlayerIdToPlayer[racer.playerId] = nil
	playersOutOfVehicle[racer.playerId] = nil
	numPlayers = numPlayers - 1

	if GetState() == "StateWaiting" then
		MessagePlayer(player , "You have been removed from the next race.")
	else
		player:SetWorldId(-1)
		player:Teleport(racer.posOriginal , Angle(0 , 0 , 0))
		player:SetWeatherSeverity(0)
		Network:Send(racer.player , "EndRace")
	end

	-- If there are no players left then end the race.
	if numPlayers == 0 and GetState() ~= "StateWaiting" then
		MessageServer("No players left, ending race.")
		EndRace()
	end

end

RemoveVehicle = function(vehicle)
	
	if IsValid(vehicle) then
		for n=1 , #vehicles do
			if vehicles[n] == vehicle then
				table.remove(vehicles , n)
				break
			end
		end
		vehicle:Remove()
	end
	
end

GetIsRacer = function(player)
	
	return players_PlayerIdToRacer[player:GetId()] ~= nil
	
end

MessageServer = function(message)
	
	local output = "[Racing] "..message
	
	Server:BroadcastChatMessage(output , textColorGlobal)
	
	print(output)
	
end

MessageRace = function(message)

	local output = "[Racing] "..message

	for id , player in pairs(players_PlayerIdToPlayer) do
		player:SendChatMessage(
			"[Racing] "..message , textColorLocal
		)
	end

	print(output)

end

MessagePlayer = function(player , message)

	player:SendChatMessage("[Racing] "..message , textColorLocal)

end

ShowCommandHelp = function(player)

	MessagePlayer(player , "Use the '/race' command to join and leave races.")

end

NetworkSendRace = function(name , ...)
	
	for id , racer in pairs(players_PlayerIdToRacer) do
		Network:Send(Player.GetById(id) , name , ...)
	end
	
end


LoadManifest = function()
	
	-- File endings on unix fix
	local path = courseManifestFilePath
	string.gsub(path, "\r", "")
	string.gsub(path, "\n", "")
	
	-- Make sure course manifest exists.
	local tempFile , tempFileError = io.open(path , "r")
	if tempFileError then
		print()
		print("*ERROR*")
		print(tempFileError)
		print()
		fatalError = true
		return
	else
		io.close(tempFile)
	end


	-- Erase coursePaths if it's already been filled.
	-- This allows it to be updated just by calling
	-- this function again.
	coursePaths = {}
	numCourses = 0

	-- Loop through each line in the manifest .txt.
	for line in io.lines(path) do
		-- Trim comments.
		line = CourseFileLoader.TrimCommentsFromLine(line)
		-- Make sure this line has stuff in it.
		if string.find(line , "%S") then
			-- Add the path to a course file to coursePaths.
			table.insert(coursePaths , line)
			numCourses = numCourses + 1
		end
	end

	if debugLevel >= 1 then
		print("Course manifest loaded - "..numCourses.." courses found")
	end

end

NumberToPlaceString = function(number)
	
	if number == 1 then
		return string.format("%i%s" , 1 , "st")
	elseif number == 2 then
		return string.format("%i%s" , 2 , "nd")
	elseif number == 3 then
		return string.format("%i%s" , 3 , "rd")
	else
		return string.format("%i%s" , number , "th")
	end
	
end


