
----------------------------------------------------------------------------------------------------
-- State: StateWaiting
----------------------------------------------------------------------------------------------------

class("StateWaiting")
function StateWaiting:__init()
	self.__type = "StateWaiting" -- I wish this were the default for all classes.

	timeOfLastRace = os.time()
	
	if courseSelectMode == "Random" then
		SelectCourseRandom()
	elseif courseSelectMode == "Sequential" then
		SelectCourseSequential()
	else
		SelectCourseRandom()
	end

	MessageServer("A race is about to begin, use /race to join.")

end

-- Called every PreServerTick if state is waiting.
function StateWaiting:Run()

	-- Postpone timer if not enough players have joined yet.
	if numPlayers < minimumPlayers then
		timeOfLastRace = os.time()
		return
	end


	if os.time() - timeOfLastRace >= maxWaitSecondsBetweenRaces then
		if debug_ForceMaxPlayers then
			numPlayers = math.floor(currentCourse.maxPlayers / 1)
		end
		MessageServer(
			"Time elapsed; starting race with "..
			numPlayers..
			" players."
		)
		SetState("StateStartingGrid")
	elseif
		numPlayers >= currentCourse.maxPlayers or
		numPlayers >= Server:GetPlayerCount()
	then
		if debug_ForceMaxPlayers then
			numPlayers = math.floor(currentCourse.maxPlayers / 1)
		end
		MessageServer(
			"Max players reached; starting race with "..
			numPlayers..
			" players."
		)
		SetState("StateStartingGrid")
	end


end
