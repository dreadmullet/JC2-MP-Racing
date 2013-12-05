
function Race:__init(raceManager , playerArray , course , vehicleCollisions)
	
	if settings.debugLevel >= 2 then
		print("Race:__init")
	end
	
	self.raceManager = raceManager
	self.vehicleCollisions = vehicleCollisions
	self.playerIdToRacer = {}
	self.numPlayers = #playerArray
	for index , player in ipairs(playerArray) do
		local newRacer = Racer(self , player , index)
		self.playerIdToRacer[player:GetId()] = newRacer
	end
	self.course = course
	self.course.race = self
	
	self.world = World.Create()
	self.finishedRacers = {}
	self.prizeMoneyCurrent = course.prizeMoney
	
	-- TODO: This will be replaced with EGUSM.StateMachine.
	self:SetState("StateStartingGrid")
	
	self.eventSubs = {}
	table.insert(self.eventSubs , Events:Subscribe("PreTick" , self , self.PreTick))
	
end

function Race:SetState(state , ...)
	
	if settings.debugLevel >= 2 then
		print("Changing state to "..state)
	end
	
	-- Call End function on previous state.
	if self.state and self.state.End then
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

function Race:GetRacerCount()
	
	return table.count(self.playerIdToRacer)
	
end

-- Add a player to a race that is currently in progress.
function Race:AddPlayer(player)
	
	-- If the racer already exists, return.
	if self:HasPlayer(player) then
		error("Attempting to add player twice: " , player)
		return
	end
	
	player = Racing.Player(player)
	local playerId = Racing.PlayerId(player)
	
	local newRacer = Racer(self , player)
	self.playerIdToRacer[playerId] = newRacer
	self.numPlayers = self.numPlayers + 1
	
	if self.state.RacerJoin then
		self.state.RacerJoin(racer)
	end
	
end

function Race:RemovePlayer(player)
	
	-- If the player isn't part of this Race, return.
	if self:HasPlayer(player) == false then
		return
	end
	
	player = Racing.Player(player)
	local playerId = Racing.PlayerId(player)
	
	-- Reenable collisions.
	-- TODO: Why is this in Race and not Racer:Remove
	if self.vehicleCollisions == false then
		player:EnableCollision(CollisionGroup.Vehicle)
	end
	player:EnableCollision(CollisionGroup.Player)
	
	-- If state is StateRacing, remove from state.racePosTracker.
	-- TODO: This should be a part of a RacerRemove state callback.
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
	
	local racer = self.playerIdToRacer[playerId]
	
	-- If they haven't finished yet, add race result to database; their
	-- position is -1 (DNF).
	-- TODO: This should probably be part of the race manager, inside RacerFinish.
	if not settings.WTF then
		if racer.hasFinished == false then
			Stats.AddRaceResult(racer , -1 , self.course)
		end
	end
	
	racer:Remove()
	self.playerIdToRacer[playerId] = nil
	self.numPlayers = self.numPlayers - 1
	
	-- If all players leave, end the race.
	if self.numPlayers == 0 then
		self:Terminate()
	end
	
end

-- This cleans up everything and can be called at any time.
function Race:Terminate()
	
	self:SetState("StateNone")
	
	-- Clean up Racers.
	for id , racer in pairs(self.playerIdToRacer) do
		self:RemovePlayer(racer.player)
	end
	
	-- Remove the world, which removes anything in it.
	if self.world then
		self.world:Remove()
		self.world = nil
	end
	
	-- Remove self from the RaceManager.
	if self.raceManager and self.raceManager.RaceEnd then
		self.raceManager:RaceEnd(self)
		self.raceManager = nil
	end
	
	-- Unsubscribe from events.
	for n , event in ipairs(self.eventSubs) do
		Events:Unsubscribe(event)
	end
	self.eventSubs = {}
	
end

-- TODO: Move this to race manager.
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
		self:NetworkSendRace(
			"ShowLargeMessage" ,
			{racer.name.." wins the race!" , 4}
		)
	else
		self:MessageRace(racer.name.." finishes "..Utility.NumberToPlaceString(#self.finishedRacers))
	end
	
end

function Race:MessageRace(message)
	
	local output = "[Racing] "..message
	
	for id , racer in pairs(self.playerIdToRacer) do
		racer.player:SendChatMessage(
			output , settings.textColorLocal
		)
	end
	
	print(output)
	
end

function Race:MessagePlayer(player , message)
	
	player:SendChatMessage("[Racing] "..message , settings.textColorLocal)
	
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

function Race:PreTick()
	
	if self.state.Run then
		self.state:Run()
	end
	
end
