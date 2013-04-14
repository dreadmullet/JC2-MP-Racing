
----------------------------------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------------------------------

OnPlayerChat = function(args)

	local player = args.player
	local msg = args.text

	-- We only want /commands.
	if string.sub(msg , 1 , 1) ~= "/" then
		return true
	end

	-- Split the message up into words (by spaces).
	local words = {}
    for word in string.gmatch(msg, "[^%s]+") do
        table.insert(words, word)
    end

	if words[1] == commandName then

		-- "/race"
		if words[2] == nil then
			if GetState() == "StateWaiting" then
				if players_PlayerIdToRacer[player:GetId()] then
					RemovePlayer(player)
				else
					AddPlayer(player)
				end
			else
				if players_PlayerIdToRacer[player:GetId()] then
					RemovePlayer(player)
					MessagePlayer(
						player ,
						"You have dropped out of the race."
					)
				else
					-- I suspect lots of people will get this message. Better make it helpful.
					local percentage = math.floor(
						(currentCheckpoint / numCheckpointsToFinish) * 100
					)
					MessagePlayer(
						player ,
						"A race is currently in progress, "..
						"please wait until it finishes. "..
						"("..percentage.."%)"
					)
				end
			end
		elseif words[2] == "carrot" then
			if
				words[3] == "abort" and
				GetState() == "StateRacing"
			then -- End race.
				MessageServer("Race aborted.")
				EndRace()
			elseif -- Force start.
				words[3] == "start" and
				GetState() == "StateWaiting" and
				numPlayers >= minimumPlayers
			then
				MessageServer("Race forced to start.")
				SetState("StateStartingGrid")
			elseif -- Force restart. DO NOT USE.
				words[3] == "restart" and
				GetState() == "StateRacing"
			then
				-- MessageServer("Race forced to restart.")
				-- RestartRace()
			elseif -- Load a course by index.
				words[3] == "loadcourse" and
				GetState() == "StateWaiting"
			then
				local courseIndex = tonumber(words[4])
				if courseIndex and courseIndex >= 1 and courseIndex <= #coursePaths then
					currentCourse = CourseFileLoader.Load(coursePaths[courseIndex])
					MessagePlayer(player , "Course changed to "..currentCourse.info.name)
				end
			elseif -- Self destruction sequence.
				words[3] == "kill12345"
			then
				-- OnModuleUnload()
				-- MessageServer("Racing has been manually terminated (Probably Woet's fault).")
				-- fatalError = true
			else
				ShowCommandHelp(player)
			end
		elseif words[2] == "debug" then
			if
				words[3] == "racepos" and
				GetState() == "StateRacing"
			then
				
			elseif
				words[3] == "arrow" and
				GetState() == "StateRacing"
			then
				-- Send them the entire RacePosTracker stuff.
				Network:Send(
					player ,
					"DebugCheckpointArrow"
				)
			else
				ShowCommandHelp(player)
			end
		else -- Invalid usage, learn the user some infos.
			ShowCommandHelp(player)
		end

		return false

	else
		return true
	end



end

OnPlayerQuit = function(args)

	-- If player is part of the gamemode, remove them from it.
	if players_PlayerIdToRacer[args.player:GetId()] then
		RemovePlayer(args.player)
	end

end

OnPlayerDeath = function(args)

	-- If player is part of the gamemode, and the state is StateRacing, tell everyone they died
	-- so people can laugh.
	if GetState() == "StateRacing" and players_PlayerIdToRacer[args.player:GetId()] then
		MessageRace(args.player:GetName().." has died!")
		players_DeadPlayerIdToTimeOfDeath[args.player:GetId()] = os.time()
	end

end


OnModuleLoad = function(args)
	
	MessageServer("Racing "..version.." has been loaded.")
	
	-- Seed random number generator.
	-- os.time() resolution is in seconds.
	math.randomseed(os.time())
	-- This has to be called first, otherwise math.random()
	-- always returns the same thing the first time it's called.
	math.random()

	-- Get a list of course file paths from the course manifest.
	LoadManifest()
	
	SetState("StateWaiting")
	
end


local timePrevious = os.time()
numTicks = 0
OnServerTick = function(args)
	
	if fatalError then
		Events:Unsubscribe(eventSubServerTick)
		fatalError = false
		return
	end
	
	numTicks = numTicks + 1
	
	deltaTime = os.time() - timePrevious
	timePrevious = os.time()


	state:Run()

end

OnModuleUnload = function(args)

	EndRace(false)

end

OnPlayerEnterVehicle = function(args)
	
	if debugLevel >= 3 then
		print(
			"Player "..args.player:GetId()..
			" entered vehicle "..args.vehicle:GetId()..
			". Driver = "..tostring(args.isdriver)
		)
		
		print("Players in vehicle: ")
		local playersInVehicle = args.vehicle:GetOccupants()
		for n = 1 , #playersInVehicle do
			local pState = playersInVehicle[n]:GetState()
			if pState and pState <= 5 then
				pState = playerStateToString[pState]
			else
				pState = "INVALID"
			end
			print(
				n..": "..playersInVehicle[n]:GetName()..
				" - "..pState
			)
		end
	end
	
	-- If we're not in a race, we don't care.
	if GetState() ~= "StateRacing" then
		return
	end
	
	-- If player is not in race, we don't care.
	if not GetIsRacer(args.player) then
		return
	end
	
	local playerId = args.player:GetId()
	local vehicleId = args.vehicle:GetId()
	local racer = players_PlayerIdToRacer[args.player:GetId()]
	
	vehiclesDriven[vehicleId] = true
	
	playersOutOfVehicle[args.player:GetId()] = nil
	
	-- If the racer gets in a car that is not theirs, remove them from it or kick them if they stole
	-- it.
	if racer.assignedVehicleId ~= vehicleId then
		-- Kick player from server if they steal a vehicle.
		if args.isdriver and args.olddriver then
			MessageRace(
				args.player:GetName().." has been kicked for vehicle theft."
			)
			args.player:Kick()
		else -- Otherwise, just remove them from the car.
			args.player:Teleport(
				args.player:GetPosition() + Vector(0 , 2 , 0) ,
				args.player:GetAngle()
			)
			MessagePlayer(args.player , "This is not your car!")
		end
	end
	
	-- If this is the first time they've entered a vehicle, set up their CCheatDetection.
	-- This is here, instead of StateRacing:__init or something, because otherwise their velocity
	-- would be calculated wrong, since it's just after they've teleported and weird stuff happens.
	if racer.cheatDetection == nil then
		cheatDetectionNumRacersAdded = cheatDetectionNumRacersAdded + 1
		racer.cheatDetection = CCheatDetection(racer.player , cheatDetectionNumRacersAdded)
	end

end

OnPlayerExitVehicle = function(args)
	
	-- If we're not in a race, we don't care.
	if GetState() ~= "StateRacing" then
		return
	end
	
	-- If player is not in a race, we don't care.
	if not GetIsRacer(args.player) then
		return
	end
	
	
	local racer = players_PlayerIdToRacer[args.player:GetId()]
	if racer then
		playersOutOfVehicle[args.player:GetId()] = racer
		racer.timeSinceOutOfVehicle = 0
	end
	
end

OnPlayerEnterCheckpoint = function(args)
	
	-- If we're not in a race, we don't care.
	if GetState() ~= "StateRacing" then
		return
	end
	
	-- If player is not in race, we don't care.
	if not GetIsRacer(args.player) then
		return
	end
	
	local id = args.checkpoint:GetId()
	local racer = players_PlayerIdToRacer[args.player:GetId()]
	
	if racer == nil then
		MessagePlayer(
			args.player ,
			"You're not in a race! How did you trigger a checkpoint?!"
		)
		print(
			"** WARNING **  "..
			args.player:GetName()..
			" hit a checkpoint, but wasn't in a race!"
		)
		return
	end
	
	-- If the racer has finished the race, then we do not care.
	if racer.hasFinished then
		return
	end
	
	-- If the racer doesn't have a vehicle, then we do not care.
	if racer.player:GetVehicle() == nil then
		return
	end

	-- if debugLevel >= 3 then
		-- print(racer.name.." entered checkpoint "..id)
	-- end
	
	if id == checkpoints[racer.targetCheckpoint]:GetId() then
		
		-- Remove racer from table containing racers with previous number of checkpoints hit.
		racePosTracker[racer.numCheckpointsHit][racer.playerId] = nil
		
		-- If we reached the finish or startFinish...
		if id == checkpoints[#checkpoints]:GetId() then
			if currentCourse.info.type == "circuit" then
				racer:AdvanceLap()
			elseif currentCourse.info.type == "linear" then
				racer:Finish()
			end
		else -- Else, just a regular checkpoint.
			racer:AdvanceCheckpoint()
		end
		racer.numCheckpointsHit = racer.numCheckpointsHit + 1
		-- If this is not set to a large value, it will contain the previous value, which is small.
		racer.targetCheckpointDistanceSqr[1] = 1000000000
		
		-- Initialize the table in racePosTracker if it doesn't exist yet.
		-- Also, since this is the first racer to hit this checkpoint, increase currentCheckpoint.
		if racePosTracker[racer.numCheckpointsHit] == nil then
			racePosTracker[racer.numCheckpointsHit] = {}
			currentCheckpoint = currentCheckpoint + 1
		end
		
		-- Add racer to table that contains racers who have hit the current number of checkpoints.
		-- Only add it if they're still racing.
		if racer.hasFinished == false then
			racePosTracker[racer.numCheckpointsHit][racer.playerId] = racer.targetCheckpointDistanceSqr
		end

	elseif id ~= checkpoints[#checkpoints]:GetId() then

		-- Show wrong checkpoint message if the checkpoint is not the finish.
		-- MessagePlayer(
			-- racer.player ,
			-- -- "Wrong checkpoint! id = "..id.." , target = "..racer.targetCheckpointId
			-- "Wrong checkpoint!"
		-- )

	end



end

--
-- Network
--

ReceiveCheckpointDistanceSqr = function(args)
	
	-- If the state isn't racing, then ignore this.
	if GetState() ~= "StateRacing" then
		return
	end
	
	local playerId = args[1]
	local distSqr = args[2]
	local cpIndex = args[3]
	
	local racer = players_PlayerIdToRacer[playerId]
	
	-- If player is in race and they're sending us the correct checkpoint distance.
	if racer and racer.targetCheckpoint == cpIndex then
		racer.targetCheckpointDistanceSqr[1] = distSqr
	end
	
	-- print("Received distance from "..players_PlayerIdToRacer[args[1]].name..": " , args[2])
	
end



--
-- Testing.
--
playerStateToString = {
	[PlayerState.None] = "None" ,
	[PlayerState.InVehicle] = "InVehicle" ,
	[PlayerState.InVehiclePassenger] = "InVehiclePassenger" ,
	[PlayerState.InMountedGun] = "InMountedGun" ,
	[PlayerState.OnFoot] = "OnFoot"
	-- [PlayerState.InStunt] = "InStunt"
}


OnPlayerStateChange = function(args)
	
	args.newstate = playerStateToString[args.newstate]
	args.oldstate = playerStateToString[args.oldstate]
	
	if not args.newstate then args.newstate = "invalid" end
	if not args.oldstate then args.oldstate = "invalid" end
	
	MessageServer(
		args.player:GetName().."'s state went from "..
		args.oldstate.." to "..args.newstate
	)
	
end


Events:Subscribe("PlayerChat" , OnPlayerChat)
Events:Subscribe("PlayerQuit" , OnPlayerQuit)
Events:Subscribe("PlayerDeath" , OnPlayerDeath)
Events:Subscribe("ModuleLoad", OnModuleLoad)
eventSubServerTick = Events:Subscribe("PostServerTick", OnServerTick)
Events:Subscribe("ModuleUnload", OnModuleUnload)
Events:Subscribe("PlayerEnterVehicle", OnPlayerEnterVehicle)
Events:Subscribe("PlayerExitVehicle", OnPlayerExitVehicle)
Events:Subscribe("PlayerEnterCheckpoint", OnPlayerEnterCheckpoint)

-- Events:Subscribe("PlayerStateChange", OnPlayerStateChange)

Network:Subscribe("ReceiveCheckpointDistanceSqr" , ReceiveCheckpointDistanceSqr)


