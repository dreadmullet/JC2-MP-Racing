
function Race:__init(name , raceManager , worldId , course)
	
	if settings.debugLevel >= 2 then
		print("Race:__init")
	end
	
	self.name = name
	self.raceManager = raceManager
	self.worldId = worldId
	-- A race should never change its course.
	self.course = course
	self.course.race = self
	
	-- If a race is public, it can be entered without specifying the name.
	self.isPublic = false
	self.vehicleCollisions = true
	self.playerIdToRacer = {}
	self.numPlayers = 0
	self.maxPlayers = course:GetMaxPlayers()
	self.state = StateNone()
	-- Set along with SetState. This allows you to see what the current state is.
	self.stateName = "StateNone"
	self.finishedRacers = {}
	-- Key: player Id
	-- Value: true
	self.playersOutOfVehicle = {}
	self.prizeMoneyCurrent = course.prizeMoney
	
	self:CleanWorld()
	
	self.eventSubs = {}
	table.insert(self.eventSubs , Events:Subscribe("PreServerTick" , self , self.PreServerTick))
	table.insert(self.eventSubs , Events:Subscribe("PlayerQuit" , self , self.PlayerQuit))
	table.insert(self.eventSubs , Events:Subscribe("ModuleUnload" , self , self.ModuleUnload))
	
end

function Race:SetState(state , ...)
	
	if settings.debugLevel >= 2 then
		print("Changing state to "..state)
	end
	
	-- Call End function on previous state.
	if self.state.End then
		self.state:End()
	end
	-- Something like, StateRacing(self , someArg1 , someArg2)
	self.state = _G[state](self , ...)
	
	self.stateName = state
	
	for id , racer in pairs(self.playerIdToRacer) do
		racer:RaceStateChange(self.stateName)
	end
	
end

function Race:HasPlayer(player)
	
	return self.playerIdToRacer[Racing.PlayerId(player)] ~= nil
	
end

-- Awesomesauce iterator. Usage: for player in race:GetPlayers() do blah end
-- function Race:GetRacers()
	
	-- local racerIteraterCounter = self:GetPlayerCount() + 1
	
	-- local function func()
		-- if (racerIteraterCounter <= 0) then
			-- return nil
		-- else
			-- racerIteraterCounter = racerIteraterCounter - 1
			-- return self.players[racerIteraterCounter]
		-- end
	-- end
	
	-- return func
	
-- end

function Race:GetRacerCount()
	
	return table.count(self.playerIdToRacer)
	
end

function Race:AddPlayer(player , message)
	
	-- If the racer already exists, return.
	if self:HasPlayer(player) then
		warn("Attempting to add player twice: " , player)
		return
	end
	-- If player is already in some other race, return.
	if self.raceManager:HasPlayer(player) then
		self:MessagePlayer(player , "You are already in a race!")
		return
	end
	
	player = Racing.Player(player)
	local playerId = Racing.PlayerId(player)
	
	self.raceManager.playerIds[playerId] = true
	
	local racer = Racer(self , player)
	self.playerIdToRacer[playerId] = racer
	self.numPlayers = self.numPlayers + 1
	
	if self.state.RacerJoin then
		self.state.RacerJoin(racer)
	end
	
	if message then
		self:MessagePlayer(player , message)
	end
	
end

function Race:RemovePlayer(player , message)
	
	message = message or "You have been removed from the race."
	
	-- If the racer doesn't exist, return.
	if self:HasPlayer(player) == false then
		warn("Attempting to remove player that doesn't exist: " , player)
		return
	end
	
	player = Racing.Player(player)
	local playerId = Racing.PlayerId(player)
	
	-- Reenable collisions.
	-- Why is this in Race and not Racer:Remove
	if self.vehicleCollisions == false then
		player:EnableCollision(CollisionGroup.Vehicle)
	end
	player:EnableCollision(CollisionGroup.Player)
	
	-- If state is StateRacing, remove from state.racePosTracker.
	if self.stateName == "StateRacing" then
		local removed = false
		for cp , map in pairs(self.state.racePosTracker) do
			for id , bool in pairs(self.state.racePosTracker[cp]) do
				if id == playerId then
					self.state.racePosTracker[cp][id] = nil
					removed = true
					break
				end
			end
			if removed then
				break
			end
		end
		
		if not removed then
			-- print("Error: " , player:GetName() , " could not be removed from the race pos tracker!")
		end
	end
	
	self.raceManager.playerIds[playerId] = nil
	
	local racer = self.playerIdToRacer[playerId]
	
	-- If they haven't finished yet, and the race is going on, add race result to database; their
	-- position is -1 (DNF).
	if not settings.WTF then
		if racer.hasFinished == false and self.stateName ~= "StateAddPlayers" then
			Stats.AddRaceResult(racer , -1 , self.course)
		end
	end
	
	racer:Remove()
	self.playerIdToRacer[playerId] = nil
	self.numPlayers = self.numPlayers - 1
	
	if message then
		self:MessagePlayer(player , message)
	end
	
	-- If we're in the race and all players leave, end the race.
	if self.numPlayers == 0 and self.stateName ~= "StateAddPlayers" then
		-- self:MessageServer("No players left; ending race.")
		self:CleanUp()
	end
	
end

-- Attempts to add player to race.
function Race:JoinPlayer(player)
	
	-- State is not StateAddPlayers.
	if self.stateName ~= "StateAddPlayers" then
		return false
	end
	
	-- Player's world id is not -1.
	if player:GetWorldId() ~= -1 then
		self:MessagePlayer(
			player ,
			"You must exit other gamemodes before you can join."
		)
		return false
	end
	
	-- Race is full.
	if self.numPlayers >= self.maxPlayers then
		self:MessageServer(
			"Error: race is full but "..
			player:GetName()..
			" is trying to join!"
		)
		return false
	end
	
	-- Success.
	self:AddPlayer(
		player ,
		"You have been added to the next race. Use "..settings.command.." to drop out."
	)
	
	-- Race is now full after adding a player.
	if self.numPlayers == self.maxPlayers then
		self:MessageServer(
			"Max players reached; starting race with "..
			self.numPlayers..
			" players."
		)
		self:SetState("StateStartingGrid")
	end
	
	return true
	
end

function Race:CleanUp()
	
	-- Remove self from the RaceManager.
	self.raceManager:RemoveRace(self)
	
	self:SetState("StateNone")
	
	-- Clean up Racers.
	for id , racer in pairs(self.playerIdToRacer) do
		self:RemovePlayer(racer.player)
	end
	
	-- Remove checkpoints.
	for n , checkpoint in ipairs(self.course.checkpoints) do
		if IsValid(checkpoint.checkpoint) then
			checkpoint.checkpoint:Remove()
		end
	end
	self.course.checkpoints = {}
	
	-- Remove vehicles.
	for n , spawn in ipairs(self.course.spawns) do
		if IsValid(spawn.vehicle) then
			spawn.vehicle:Remove()
		end
	end
	self.course.spawns = {}
	
	-- Unsubscribe from events.
	for n , event in ipairs(self.eventSubs) do
		Events:Unsubscribe(event)
	end
	self.eventSubs = {}
	
end

function Race:RacerFinish(racer)
	
	table.insert(self.finishedRacers , racer)
	
	-- Award prize money.
	racer.player:SetMoney(racer.player:GetMoney() + self.prizeMoneyCurrent)
	self:MessagePlayer(
		racer.player ,
		string.format("%s%i%s" , "You won $" , self.prizeMoneyCurrent , "!")
	)
	self.prizeMoneyCurrent = self.prizeMoneyCurrent * settings.prizeMoneyMultiplier
	
	-- Add race result to database.
	if not settings.WTF then
		Stats.AddRaceResult(racer , #self.finishedRacers , self.course)
	end
	
	-- Messages to immediately print for all finishers.
	if #self.finishedRacers == 1 then
		self:MessageServer(racer.name.." wins the race!")
		self:NetworkSendRace(
			"ShowLargeMessage" ,
			{racer.name.." wins the race!" , 4}
		)
	else
		self:MessageRace(racer.name.." finishes "..Utility.NumberToPlaceString(#self.finishedRacers))
	end
	
end

function Race:MessageServer(message)
	
	local output = "[Racing-"..self.name.."] "..message
	
	Chat:Broadcast(output , settings.textColorGlobal)
	
	print(output)
	
end

function Race:MessageRace(message)
	
	local output = "[Racing-"..self.name.."] "..message
	
	for id , racer in pairs(self.playerIdToRacer) do
		racer.player:SendChatMessage(
			output , settings.textColorLocal
		)
	end
	
	print(output)
	
end

function Race:MessagePlayer(player , message)
	
	player:SendChatMessage("[Racing-"..self.name.."] "..message , settings.textColorLocal)
	
end

-- Removes all vehicles and checkpoints in our world. Just in case the script exploded and left
-- pieces of spawns all over the place.
function Race:CleanWorld()
	
	for vehicle in Server:GetVehicles() do
		if vehicle:GetWorldId() == self.worldId then
			vehicle:Remove()
		end
	end
	
	for checkpoint in Server:GetCheckpoints() do
		if checkpoint:GetWorldId() == self.worldId then
			checkpoint:Remove()
		end
	end
	
end

function Race:NetworkSendRace(name , ...)
	
	for playerId , racer in pairs(self.playerIdToRacer) do
		if settings.debugLevel >= 3 then
			print("NetworkSendRace; player = "..racer.name..", network event = "..name)
		end
		Network:Send(racer.player , name , ...)
	end
	
end

--
-- Events
--

function Race:PreServerTick()
	
	if self.state.Run then
		self.state:Run()
	end
	
end

function Race:PlayerQuit(args)
	
	if self.playerIdToRacer[args.player:GetId()] then
		self:RemovePlayer(args.player)
	end
	
end

function Race:ModuleUnload()
	
	self:CleanUp()
	
end
