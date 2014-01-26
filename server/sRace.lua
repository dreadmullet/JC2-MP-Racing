
Race.idCounter = 1

function Race:__init(playerArray , course , vehicleCollisions)
	EGUSM.StateMachine.__init(self)
	
	if settings.debugLevel >= 2 then
		print("Race:__init")
	end
	
	self.id = Race.idCounter
	Race.idCounter = Race.idCounter + 1
	
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
	self.vehicleCollisions = vehicleCollisions or true
	
	-- Prevents terminating twice.
	self.isValid = true
	
	self:SetState("StateStartingGrid")
end

function Race:AddSpectator(player)
	local spectator = Spectator(self , player)
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
	if self.state.RacerLeave then
		self.state:RacerLeave(racer)
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
	if self.state.SpectatorLeave then
		self.state:SpectatorLeave(spectator)
	end
	
	spectator:Remove()
	self.playerIdToSpectator[spectator.playerId] = nil
end

-- This cleans up everything and can be called at any time.
function Race:Terminate()
	if self.isValid then
		self.isValid = false
	else
		return
	end
	
	if settings.debugLevel >= 2 then
		self:Message("Race ended with "..self.numPlayers.." players")
	end
	
	-- Clean up Racers.
	for id , racer in pairs(self.playerIdToRacer) do
		self:RemovePlayer(racer.player)
	end
	
	-- Clean up Spectators.
	for id , spectator in pairs(self.playerIdToSpectator) do
		self:RemovePlayer(spectator.player)
	end
	
	-- Remove the world, which removes anything in it.
	if self.world then
		self.world:Remove()
		self.world = nil
	end
	
	-- Fire RaceEnd event.
	local args = {
		id = self.id
	}
	Events:Fire("RaceEnd" , args)
	
	-- Call EGUSM Destroy method.
	self:Destroy()
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

function Race:GetRacerFromPlayerId(id)
	return self.playerIdToRacer[id]
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
	
	-- Fire the RacerFinish event.
	local args = {
		id = self.id ,
		playerId = racer.playerId
	}
	Events:Fire("RacerFinish" , args)
end

-- CreateRace event.

CreateRaceFromEvent = function(args)
	local playerArray = args.players
	if playerArray == nil then
		error("Could not create race: players is nil")
		return
	end
	
	local course = Course.Load(args.course)
	if course == nil then
		error("Could not create race: course not found")
		return
	end
	
	local collisions = args.collisions or true
	
	Race(nil , playerArray , course , collisions)
end

Events:Subscribe("CreateRace" , CreateRaceFromEvent)
