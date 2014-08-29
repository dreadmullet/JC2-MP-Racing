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
	local maxPlayers = self.course:GetMaxPlayers()
	-- TODO: Is this necessary? It will be looked at with the client-side checkpoint overhaul.
	self.checkpointPositions = {}
	for n = 1 , #self.course.checkpoints do
		table.insert(self.checkpointPositions , self.course.checkpoints[n].position)
	end
	if self.course.type == "Circuit" then
		self.numLaps = settings.numLapsFunc(
			self.numPlayers ,
			#self.course.spawns ,
			self.course.numLaps
		)
	end
	
	-- Initialize map editor things such as generic objects.
	self.mapInstance = MapEditor.MapInstance(self.course.map)
	
	-- World
	
	self.world = World.Create()
	self.world:SetTimeStep(0)
	if self.course.minStartHour <= self.course.maxStartHour then
		self.world:SetTime(math.random(self.course.minStartHour , self.course.maxStartHour))
	else
		local range = 24 - self.course.minStartHour + self.course.maxStartHour
		self.world:SetTime((self.course.minStartHour + math.random(0 , range)) % 24)
	end
	if self.course.weatherSeverity == -1 then
		self.world:SetWeatherSeverity(math.pow(math.random() , 2.8) * 2)
	else
		self.world:SetWeatherSeverity(self.course.weatherSeverity)
	end
	
	-- Misc
	
	self.prizeMoneyCurrent = settings.prizeMoneyDefault
	
	self.overflowHandling = args.overflowHandling or Race.OverflowHandling.StackSpawns
	
	if args.quickStart == true then
		self.vehicleSelectionSeconds = 10
		self.startingGridSeconds = 6
	else
		self.vehicleSelectionSeconds = settings.vehicleSelectionSeconds
		self.startingGridSeconds = settings.startingGridSeconds
	end
	
	-- Collisions
	
	self.vehicleCollisions = args.collisions or settings.collisionChanceFunc()
	self.vehicleCollisions = self.course:ProcessCollisions(self.vehicleCollisions)
	
	-- Overflow handling
	
	if
		self.overflowHandling == Race.OverflowHandling.StackSpawns and
		self.numPlayers > maxPlayers
	then
		if settings.debugLevel >= 2 then
			print(
				string.format("%i/%i" , self.numPlayers , maxPlayers)..
				" players, turning collisions off"
			)
		end
		
		self.vehicleCollisions = false
		
		-- Create a new spawn for each vehicle info.
		local overflow = self.numPlayers - maxPlayers
		-- testing
		-- local overflow = 5
		for n = 1 , overflow do
			for index , entry in ipairs(self.course.vehicleInfoMap) do
				if #entry.spawns > 0 then
					entry.vehicleInfo.available = entry.vehicleInfo.available + 1
					
					local copiedSpawn = table.randomvalue(entry.spawns):Copy()
					table.insert(self.course.spawns , copiedSpawn)
				end
			end
		end
	end
	
	-- More stuff
	
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
	local forceSpectators = self.overflowHandling == Race.OverflowHandling.ForceSpectate
	for index , player in ipairs(args.players) do
		if index <= maxPlayers or forceSpectators == false then
			self:AddRacer(player)
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
	if #self.course.vehicleInfos == 1 and self.course.vehicleInfos[1].modelId == -1 then
		self:SetState("StateStartingGrid")
	else
		self:SetState("StateVehicleSelection")
	end
	
	Events:Fire("RaceCreate" , {id = self.id})
	
	self:ConsoleSubscribe("raceinfo")
end

function Race:AddRacer(player)
	local racer = Racer(self , player)
	self.playerIdToRacer[player:GetId()] = racer
	table.insert(self.participants , racer)
end

function Race:AddSpectator(player)
	local spectator = Spectator(self , player)
	self.playerIdToSpectator[player:GetId()] = spectator
	table.insert(self.participants , spectator)
	
	if self.state and self.state.SpectatorJoin then
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
	-- Make sure we only ever terminate once.
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
	
	-- Remove our map instance.
	self.mapInstance:Destroy()
	
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
		id = self.id ,
		numPlayers = self.numPlayers ,
		numLaps = self.numLaps ,
		playerIdToInfo = self.playerIdToInfo ,
		course = self.course:MarshalForClient() ,
		collisions = self.vehicleCollisions ,
		modules = self.moduleNames ,
		vehicleSelectionSeconds = self.vehicleSelectionSeconds ,
		startingGridSeconds = self.startingGridSeconds ,
	}
	
	-- Load the top time from the database.
	local topRecord
	if self.course.useStats then
		topRecord = Stats.GetCourseRecords(self.course.fileName , 1 , 1)[1]
	end
	if topRecord then
		info.topRecordTime = topRecord.time
		info.topRecordPlayerName = topRecord.playerName
	else -- If there are no records, use a fake one.
		-- TODO: This is silly
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
	print("Laps               "..tostring(self.numLaps))
	print("World id           "..self.world:GetId())
	print("Vehicle collisions "..tostring(self.vehicleCollisions))
	print()
end
