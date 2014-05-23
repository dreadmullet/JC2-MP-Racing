class("RaceManagerEvent")

function RaceManagerEvent:__init(race , name , owners) ; RaceManagerBase.__init(self)
	self.race = race
	self.name = name
	-- Owners can end the race at any time by using the race menu.
	self.owners = owners
	
	for index , racerBase in ipairs(self.race.participants) do
		self:AddPlayer(racerBase.player)
	end
	
	self:EventSubscribe("EndRace")
	self:NetworkSubscribe("RequestRaceOwners")
	self:NetworkSubscribe("OwnerEndRace")
end

-- PlayerManager callbacks

function RaceManagerEvent:ManagedPlayerLeave(player)
	self.race:RemovePlayer(player)
end

-- Events

function RaceManagerEvent:EndRace(name)
	if self.name == name then
		self.race:Terminate()
		self:Destroy()
	end
end

-- Network events

function RaceManagerEvent:RequestRaceOwners(raceId , player)
	if raceId == self.race.id then
		Network:Send(player , "ReceiveRaceOwners" , self.owners)
	end
end

function RaceManagerEvent:OwnerEndRace(args , player)
	if IsValid(player) == false then
		warn("Invalid player in OwnerEndRace")
		return
	end
	
	if self.name == args.name and table.find(self.owners , player) then
		self.race:Terminate()
		self:Destroy()
	end
end

-- Static CreateRaceX event functions.

RaceManagerEvent.CreateRaceFromEvent = function(args)
	if args.players == nil then
		error("No players")
	end
	
	local course
	if args.courseName then
		course = Course.Load(args.courseName)
		if course == nil then
			error("Failed to load course: "..tostring(args.courseName))
		end
	elseif args.map then
		course = Course.LoadFromMap(args.map)
	end
	
	if course == nil then
		error("Failed to load course")
	end
	
	local race = Race{
		players = args.players ,
		course = course ,
		collisions = args.collisions ,
		modules = {"Event"} ,
	}
	
	raceManagerEvent = RaceManagerEvent(race , args.name , args.owners or args.players)
end
Events:Subscribe("CreateRace" , RaceManagerEvent.CreateRaceFromEvent)

RaceManagerEvent.CreateRaceFromConsole = function(args)
	if args.text:len() <= 1 then
		warn("Please provide a course name, such as 'BandarSelekeh'")
		return
	end
	
	local players = {}
	for player in Server:GetPlayers() do
		table.insert(players , player)
	end
	
	RaceManagerEvent.CreateRaceFromEvent{
		players = players ,
		courseName = args.text ,
	}
end
Console:Subscribe("createrace" , RaceManagerEvent.CreateRaceFromConsole)

RaceManagerEvent.CreateRaceFromMapEditor = function(args)
	local map = MapEditor.LoadFromMarshalledMap(args.marshalledMap)
	
	RaceManagerEvent.CreateRaceFromEvent{
		players = args.players ,
		map = map ,
	}
end
Events:Subscribe("CreateRaceFromMapEditor" , RaceManagerEvent.CreateRaceFromMapEditor)
