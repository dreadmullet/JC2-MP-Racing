class("RaceManagerEvent")

function RaceManagerEvent:__init(race , name) ; RaceManagerBase.__init(self)
	self.race = race
	self.name = name
	
	for index , racerBase in ipairs(self.race.participants) do
		self:AddPlayer(racerBase.player)
	end
	
	self:EventSubscribe("EndRace")
end

function RaceManagerEvent:EndRace(name)
	if self.name == name then
		self.race:Terminate()
		self:Destroy()
	end
end

-- PlayerManager callbacks

function RaceManagerEvent:ManagedPlayerLeave(player)
	self.race:RemovePlayer(player)
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
	}
	
	raceManagerEvent = RaceManagerEvent(race , args.name)
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
