
function Race:__init(raceManager , playerArray , course , vehicleCollisions)
	if settings.debugLevel >= 2 then
		print("Race:__init")
	end
	
	self.raceManager = raceManager
	
	-- Contains both Racers and Spectators in an array.
	self.participants = playerArray
	self.playerIdToRacer = {}
	self.numPlayers = #playerArray
	for index , player in ipairs(playerArray) do
		local newRacer = Racer(self , player)
		self.playerIdToRacer[player:GetId()] = newRacer
	end
	self.playerIdToSpectator = {}
	self.finishedRacers = {}
	
	self.course = course
	self.course.race = self
	self.checkpointPositions = {}
	for n = 1 , #self.course.checkpoints do
		table.insert(self.checkpointPositions , self.course.checkpoints[n].position)
	end
	
	-- Create world and randomise the time and weather.
	self.world = World.Create()
	self.world:SetTime(math.random(4, 21))
	self.world:SetWeatherSeverity(math.pow(math.random() , 2.5) * 2)
	
	self.prizeMoneyCurrent = course.prizeMoney
	self.vehicleCollisions = vehicleCollisions
	
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
end

function Race:AddSpectator(player)
	local spectator = Spectator(race , player)
	self.playerIdToSpectator[player:GetId()] = spectator
	table.insert(self.participants , spectator)
end

function Race:RemovePlayer(player)
	local playerId = player:GetId()
	
	local racer = self.playerIdToRacer[playerId]
	if racer then
		self:RemoveRacer(racer)
	else	
		local spectator = self.playerIdToSpectator[playerId]
		if spectator then
			self:RemoveSpectator(spectator)
		end
	end
	
	-- Remove from self.participants.
	for index , racerOrSpectator in ipairs(self.participants) do
		if racerOrSpectator.player == player then
			table.remove(self.participants , index)
			break
		end
	end
end

function Race:RemoveRacer(racer)
	-- If our state is StateRacing, remove from state.racePosTracker.
	if self.stateName == "StateRacing" then
		local removed = false
		for cp , map in pairs(self.state.racePosTracker) do
			for id , bool in pairs(self.state.racePosTracker[cp]) do
				if id == racer.playerId then
					self.state.racePosTracker[cp][id] = nil
					removed = true
					break
				end
			end
			if removed then
				break
			end
		end
	end
	
	-- If they haven't finished yet, add race result to database; their
	-- position is -1 (DNF).
	-- TODO: This should probably be part of the race manager, inside RacerFinish.
	if racer.hasFinished == false then
		Stats.AddRaceResult(racer , -1 , self.course)
	end
	
	racer:Remove()
	self.playerIdToRacer[racer.playerId] = nil
	self.numPlayers = self.numPlayers - 1
	
	-- If all players leave, end the race.
	if self.numPlayers == 0 then
		self:Terminate()
	end
end

function Race:RemoveSpectator(spectator)
	spectator:Remove()
	self.playerIdToSpectator[spectator.playerId] = nil
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

function Race:Message(message)
	for id , racer in pairs(self.playerIdToRacer) do
		racer:Message(message)
	end
	
	print(message)
end

function Race:NetworkSendRace(name , ...)
	for playerId , racer in pairs(self.playerIdToRacer) do
		if settings.debugLevel >= 3 then
			print("NetworkSendRace; player = "..racer.name..", network event = "..name)
		end
		Network:Send(racer.player , name , ...)
	end
end

-- Racer callbacks

-- TODO: Move parts of this to race manager.
function Race:RacerFinish(racer)
	table.insert(self.finishedRacers , racer)
	
	-- Award prize money.
	racer.player:SetMoney(racer.player:GetMoney() + self.prizeMoneyCurrent)
	racer:Message(string.format("%s%i%s" , "You won $" , self.prizeMoneyCurrent , "!"))
	self.prizeMoneyCurrent = self.prizeMoneyCurrent * settings.prizeMoneyMultiplier
	
	-- Add race result to database.
	Stats.AddRaceResult(racer , #self.finishedRacers , self.course)
	
	-- Messages to immediately print for all finishers.
	if #self.finishedRacers == 1 then
		self:NetworkSendRace(
			"ShowLargeMessage" ,
			{racer.name.." wins the race!" , 4}
		)
	else
		self:Message(racer.name.." finishes "..Utility.NumberToPlaceString(#self.finishedRacers))
	end
	
	-- Tell our RaceManager that a Racer finished.
	if self.raceManager.RacerFinish then
		self.raceManager:RacerFinish(racer)
	end
end

-- Events

function Race:PreTick()
	if self.state.Run then
		self.state:Run()
	end
end
