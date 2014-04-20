class("Race")

Race.OverflowHandling = {
	ForceSpectate = 1 ,
	StackSpawns = 2 , -- Forces collision off and spawns more than one player at spawns.
}

Race.idCounter = 1

function Race:__init(args)
	EGUSM.StateMachine.__init(self)
	
	if settings.debugLevel >= 2 then
		print("Race:__init")
	end
	
	-- Id
	
	self.id = Race.idCounter
	Race.idCounter = Race.idCounter + 1
	
	-- Players
	
	-- Contains both Racers and Spectators in an array.
	self.participants = {}
	self.playerIdToRacer = {}
	-- TODO: Is this the count of Racers, and not spectators? This needs to be clarified and be
	-- consistent. Use #self.participants instead?
	self.numPlayers = #args.players
	self.playerIdToSpectator = {}
	self.finishedRacers = {}
	-- This is sent to Racers now and any Spectators who join later.
	self.info = {}
	
	-- Course
	
	self.course = args.course
	self.course.race = self
	-- TODO: Is this necessary?
	self.checkpointPositions = {}
	for n = 1 , #self.course.checkpoints do
		table.insert(self.checkpointPositions , self.course.checkpoints[n].position)
	end
	self.numLaps = settings.numLapsFunc(
		self.numPlayers ,
		#self.course.spawns ,
		self.course.numLaps
	)
	
	-- World
	
	self.world = World.Create()
	self.world:SetTime(math.random(4, 21))
	self.world:SetWeatherSeverity(math.pow(math.random() , 2.5) * 2)
	
	-- Misc
	
	self.prizeMoneyCurrent = settings.prizeMoneyDefault
	
	self.overflowHandling = args.overflowHandling or Race.OverflowHandling.StackSpawns
	
	-- Collisions
	
	self.vehicleCollisions = args.collisions
	if self.vehicleCollisions == nil then
		self.vehicleCollisions = false
	end
	
	self.vehicleCollisions = self.course:ProcessCollisions(self.vehicleCollisions)
	
	if
		self.overflowHandling == Race.OverflowHandling.StackSpawns and
		self.numPlayers > self.course:GetMaxPlayers()
	then
		if settings.debugLevel >= 2 then
			print(
				string.format("%i/%i" , self.numPlayers , self.course:GetMaxPlayers())..
				" players, turning collisions off"
			)
		end
		
		self.vehicleCollisions = false
	end
	
	self.moduleNames = args.modules or {}
	
	self.info = self:MarshalForClient()
	self.info.playerIdToInfo = {}
	for index , player in ipairs(args.players) do
		self.info.playerIdToInfo[player:GetId()] = {
			name = player:GetName() ,
			color = player:GetColor()
		}
	end
	
	-- Initialize Racers and Spectators.
	local maxPlayers = self.course:GetMaxPlayers()
	local forceSpectators = self.overflowHandling == Race.OverflowHandling.ForceSpectate
	for index , player in ipairs(args.players) do
		if index <= maxPlayers or forceSpectators == false then
			self:AddPlayer(player)
		else
			self:AddSpectator(player)
		end
	end
	for index , player in ipairs(args.spectators or {}) do
		self:AddSpectator(player)
	end
	
	-- Initialize RaceModules.
	for index , moduleName in ipairs(self.moduleNames) do
		local class = RaceModules[moduleName]
		if class then
			class(self)
		end
	end
	
	-- Prevents terminating twice.
	self.isValid = true
	
	-- Start the vehicle selection state, unless this is a purely on-foot race.
	if #self.course.vehiclesInfo == 1 and self.course.vehiclesInfo[1].modelId == -1 then
		self:SetState("StateStartingGrid")
	else
		self:SetState("StateVehicleSelection")
	end
	
	Events:Fire("RaceCreate" , {id = self.id})
	
	self:ConsoleSubscribe("raceinfo")
end

function Race:AddPlayer(player)
	local racer = Racer(self , player)
	self.playerIdToRacer[player:GetId()] = racer
	table.insert(self.participants , racer)
end

function Race:AddSpectator(player)
	local spectator = Spectator(self , player)
	self.playerIdToSpectator[player:GetId()] = spectator
	table.insert(self.participants , spectator)
	
	if self.state.SpectatorJoin then
		self.state:SpectatorJoin(spectator)
	end
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

function Race:MarshalForClient()
	local info = {
		numPlayers = self.numPlayers ,
		numLaps = self.numLaps ,
		playerIdToInfo = self.playerIdToInfo ,
		course = self.course:MarshalForClient() ,
		collisions = self.vehicleCollisions ,
		modules = self.moduleNames
	}
	
	-- Load the top time from the database.
	local topRecord = Stats.GetCourseRecords(self.course.fileName , 1 , 1)[1]
	if topRecord then
		info.topRecordTime = topRecord.time
		info.topRecordPlayerName = topRecord.playerName
	else -- If there are no records yet, use a fake one.
		topRecord = {}
		info.topRecordTime = 59 * 60 + 59 + 0.99
		info.topRecordPlayerName = "xXxSUpA1337r4c3rxXx"
	end
	
	return info
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
	
	-- Tell every client they finished.
	self:NetworkSendRace("RacerFinish" , {racer.player:GetId() , #self.finishedRacers})
	
	-- Fire the RacerFinish event.
	local args = {
		id = self.id ,
		playerId = racer.playerId
	}
	Events:Fire("RacerFinish" , args)
end

-- Console events

function Race:raceinfo()
	print()
	print("Race info:")
	print("id                 "..self.id)
	print("numPlayers         "..self.numPlayers)
	print("Participants count "..#self.participants)
	print("Racer count        "..table.count(self.playerIdToRacer))
	print("Spectator count    "..table.count(self.playerIdToSpectator))
	print("Max players        "..self.course:GetMaxPlayers())
	print("Course name        "..self.course.name)
	print("World id           "..self.world:GetId())
	print("Vehicle collisions "..tostring(self.vehicleCollisions))
	print()
end

-- Static CreateRace event function.

Race.CreateRaceFromEvent = function(args)
	local course = Course.Load(args.courseName)
	
	local raceArgs = {
		players = args.players ,
		course = course ,
		collisions = args.collisions
	}
	Race(raceArgs)
end

Events:Subscribe("CreateRace" , Race.CreateRaceFromEvent)
