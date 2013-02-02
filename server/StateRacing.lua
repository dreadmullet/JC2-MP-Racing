
----------------------------------------------------------------------------------------------------
-- State: StateRacing
----------------------------------------------------------------------------------------------------

class("StateRacing")
function StateRacing:__init()
	self.__type = "StateRacing"

	if debugLevel >= 1 then
		print("Race started.")
	end
	
	-- print GO
	-- MessageRace(countdownMessages[#countdownMessages])
	
	
	-- Temporary: Spawn vehicles.
	vehicles = {}
	vehicleIdToVehicle = {}
	local vehicleIdToAngle = {}
	-- Loop through grid positions in order of how far they are to the front (I think).
	-- Spawn Vehicles and add them to the table vehicles.
	for pos , SGindex in pairs(currentCourse.gridPositions) do
		local angle = currentCourse.gridAngles[pos]
		
		local spawnArgs = {}
		spawnArgs.model_id = currentCourse.startGrids[SGindex].vehicle
		spawnArgs.position = pos
		spawnArgs.angle = angle
		spawnArgs.world = worldId
		-- spawnArgs.health = 1
		spawnArgs.enabled = true
		spawnArgs.template = currentCourse.startGrids[SGindex].vehicleTemplate
		spawnArgs.decal = currentCourse.startGrids[SGindex].vehicleDecal
		
		local newVehicle = Vehicle.Create(spawnArgs)
		table.insert(
			vehicles ,
			newVehicle
		)
		vehicleIdToVehicle[newVehicle:GetId()] = newVehicle
		vehicleIdToAngle[newVehicle:GetId()] = angle

	end
	
	-- Randomly sort the vehicles table. Otherwise, the starting grid is (consistently) random.
	for n = #vehicles , 2 , -1 do
		local r = math.random(n)
		vehicles[n] , vehicles[r] = vehicles[r] , vehicles[n]
	end
	
	
	-- temp: should be in StateStartingGrid
	-- Teleport everyone to their vehicle and set their world.
	if debugLevel >= 2 then
		print("Teleporting "..numPlayers.." players next to their vehicles.")
	end
	local count = 1
	for id , racer in pairs(players_PlayerIdToRacer) do
		local teleportPos = vehicles[count]:GetPosition()
		local angle = vehicleIdToAngle[vehicles[count]:GetId()]
		local angleToPlayerSpawn = Angle(0 , 0 , 0) * angle
		local dirToPlayerSpawn = angleToPlayerSpawn * Vector(-1 , 0 , 0)
		teleportPos = teleportPos + dirToPlayerSpawn * 2
		teleportPos.y = teleportPos.y + 2
		racer.player:Teleport(teleportPos , angle)
		racer.player:SetWorldId(worldId)
		count = count + 1
	end
	
	

	--
	-- Spawn checkpoints.
	--

	if debugLevel >= 2 then
		print("Spawning "..#currentCourse.checkpoints.." Checkpoints")
	end
	
	local checkpointRadius = currentCourse.info.checkpointRadiusMult * 12.05

	for n=1 , #currentCourse.checkpoints do

		-- if debugLevel >= 3 then
			-- print(currentCourse.checkpoints[n].position)
			-- print()
		-- end
		
		local spawnArgs = {}
		spawnArgs.position = currentCourse.checkpoints[n].position
		spawnArgs.create_checkpoint = true
		spawnArgs.create_trigger = true
		spawnArgs.create_indicator = useCheckpointIcons
		spawnArgs.world = worldId
		spawnArgs.despawn_on_enter = false
		-- spawnArgs.text = "-"..n.."-   " --  "-3-    123m"
		spawnArgs.activation_box = Vector(
			checkpointRadius ,
			checkpointRadius ,
			checkpointRadius
		)
		spawnArgs.enabled = true
		
		local cp = Checkpoint.Create(spawnArgs)
		table.insert(checkpoints , cp)

	end

	-- Spawn either a FINISH or a STARTFINISH
	if currentCourse.info.type == "circuit" then
		
		local spawnArgs = {}
		spawnArgs.position = currentCourse.startFinish.position
		spawnArgs.create_checkpoint = true
		spawnArgs.create_trigger = true
		spawnArgs.create_indicator = useFinishIcon
		spawnArgs.type = 7
		spawnArgs.world = worldId
		spawnArgs.despawn_on_enter = false
		-- spawnArgs.text = "-"..n.."-   " --  "-3-    123m"
		spawnArgs.activation_box = Vector(
			checkpointRadius ,
			checkpointRadius ,
			checkpointRadius
		)
		spawnArgs.enabled = true
		
		local cp = Checkpoint.Create(spawnArgs)
		table.insert(checkpoints , cp)
		
	elseif currentCourse.info.type == "linear" then
		
		local spawnArgs = {}
		spawnArgs.position = currentCourse.finish.position
		spawnArgs.create_checkpoint = true
		spawnArgs.create_trigger = true
		spawnArgs.create_indicator = useFinishIcon
		spawnArgs.type = 7
		spawnArgs.world = worldId
		spawnArgs.despawn_on_enter = false
		-- spawnArgs.text = "-"..n.."-   " --  "-3-    123m"
		spawnArgs.activation_box = Vector(
			checkpointRadius ,
			checkpointRadius ,
			checkpointRadius
		)
		spawnArgs.enabled = true
		
		local cp = Checkpoint.Create(spawnArgs)
		table.insert(checkpoints , cp)
		
	end


	--
	-- Set up properties for each Player.
	--
	racePosTracker[0] = {}
	for id , racer in pairs(players_PlayerIdToRacer) do
		racer.targetCheckpoint = 1
		playersOutOfVehicle[id] = racer
		racePosTracker[0][id] = true
	end

	timeOfRaceBegin = os.time()

	--
	-- Send network events.
	--
	NetworkSendRace("StartRace")
	
	NetworkSendRace(
		"SetRacePosition" ,
		{1 , numPlayers}
	)
	
	
	if debugLevel >= 2 then
		print("------Race Report------")
		print("Players: "..numPlayers)
		print("Vehicles: "..#vehicles)
		print("Weather: "..currentCourse.info.weatherSeverity)
		print("Laps: "..currentCourse.info.laps)
		print("Time limit: " , timeLimit)
		for k,sg in pairs(currentCourse.startGrids) do
			local tab = "    "
			print("STARTGRID:")
			print(tab.."Max rows: "..sg.maxRows)
			print(tab.."Max vehicles per row: "..sg.maxVehiclesPerRow)
			print(tab.."Max vehicles: "..(sg.maxVehiclesPerRow * sg.maxRows))
			print(tab.."Rows: "..sg.numRows)
			print(tab.."Vehicles per row: "..sg.numVehiclesPerRow)
			print(tab.."Length: "..sg.length)
			print(tab.."Width: "..sg.width)
			print(tab.."Vehicle modelid: "..sg.vehicle)
			print(tab.."Vehicle template: "..(sg.vehicleTemplate or "none"))
			print(tab.."Vehicle decal: "..(sg.vehicleDecal or "none"))
			print(tab.."Vehicle width: "..sg.vehicleWidth)
			print(tab.."Vehicle length: "..sg.vehicleLength)
			print(tab.."Vehicle spacing X: "..(sg.width / sg.maxVehiclesPerRow))
			print(tab.."Vehicle spacing Y: "..(sg.length / sg.maxRows))
			print()
		end
	end

end

-- Called every PreServerTick if state is racing.
function StateRacing:Run()

	-- Despawn vehicles halfway through the first lap if it's a circuit.
	if
		currentCourse.info.type == "circuit" and
		hasDespawnedUntouchedVehicles == false and
		os.time() - timeOfRaceBegin > despawnSeconds
	then
		hasDespawnedUntouchedVehicles = true
		if debugLevel >= 2 then
			print("Despawning untouched vehicles.")
		end
		for v=#vehicles , 1 , -1 do
			if vehiclesDriven[vehicles[v]:GetId()] ~= true then
				vehicles[v]:Remove()
				table.remove(vehicles , v)
			end
		end
	end

	if
		#finishedRacers >= 1 and
		os.time() - timeOfFirstFinisher >= raceEndTime
	then
		MessageRace("Race finished.")
		EndRace()
		return
	end
	
	-- Begin tracking players out of vehicles after some time is elapsed.
	if
		isTrackingOutOfVehicle == false and
		os.time() - timeOfRaceBegin > outOfVehicleTrackingDelaySeconds
	then
		if debugLevel >= 2 then
			print("Now tracking players out of vehicles.")
		end
		isTrackingOutOfVehicle = true
	end

	-- Remove dead players after a delay.
	for id , t in pairs(players_DeadPlayerIdToTimeOfDeath) do
		if os.time() - t > playerDeathDelay then
			local player = players_PlayerIdToPlayer[id]
			local racer = players_PlayerIdToRacer[id]
			if racer then
				
				-- Remove their vehicle as well.
				local vehicle = vehicleIdToVehicle[racer.lastVehicleId]
				if IsValid(vehicle) then
					-- Remove from vehicles array.
					for v = 1 , #vehicles do
						if vehicles[v]:GetId() == vehicle:GetId() then
							table.remove(vehicles , v)
							break
						end
					end
					vehicle:Remove()
				end
				
			end
			
			RemovePlayer(player)
			players_DeadPlayerIdToTimeOfDeath[id] = nil
		end
	end
	
	if isTrackingOutOfVehicle then
		for pId , racer in pairs(playersOutOfVehicle) do
			
			racer.timeSinceOutOfVehicle = racer.timeSinceOutOfVehicle + deltaTime
			
			if
				IsValid(racer.player) and
				racer.timeSinceOutOfVehicle >= outOfVehicleMaxSeconds and
				not racer.hasFinished
			then
				
				
				MessageRace(
					racer.player:GetName()..
					" was removed from the race for not being in a vehicle."
				)
				RemovePlayer(racer.player)
				playersOutOfVehicle[pId] = nil
				local vehicle = vehicleIdToVehicle[racer.lastVehicleId]
				if IsValid(vehicle) then
					-- print(
						-- "Removing vehicle: id = "..
						-- racer.lastVehicleId
					-- )
					-- print("id = "..vehicle:GetId())
					for n=1 , #vehicles do
						if vehicles[n]:GetId() == racer.lastVehicleId then
							-- print(
								-- "Removing vehicle from index: index = "..
								-- n
							-- )
							table.remove(vehicles , n)
							break
						end
					end
					vehicle:Remove()
				else
					-- print("Could not remove vehicle: "..racer.lastVehicleId)
				end
				
				
			end
			
		end
	end
	
	--
	-- Cheat detection. Maximum of one racer updates per tick.
	--
	for id , racer in pairs(players_PlayerIdToRacer) do
		if racer.cheatDetection and racer.cheatDetection.updateTick == cheatDetectionTick then
			racer.cheatDetection:Update()
		end
	end
	
	cheatDetectionTick = cheatDetectionTick + 1
	-- Example: In a 2 player race, don't update them very quickly.
	if cheatDetectionTick >= math.max(numPlayers , 250) then
		cheatDetectionTick = 1
	end
	
	-- Time limit.
	if os.time() - timeOfRaceBegin > timeLimit then
		MessageServer("Time limit up! Race ending.")
		EndRace()
		return
	end
	
end
