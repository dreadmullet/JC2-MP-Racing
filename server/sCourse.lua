function Course:__init()
	self.race = nil
	-- Includes finish or start/finish.
	self.name = "unnamed course"
	self.type = "Invalid"
	-- Array of CourseCheckpoints.
	self.checkpoints = {}
	self.weatherSeverity = 0.5
	self.authors = {}
	self.numLaps = -1
	-- Map of CourseCheckpoints, useful for mapping PlayerEnterCheckpoint event to a CourseCheckpoint
	-- Key = checkpointId
	-- Value = CourseCheckpoint
	-- Checkpoints add themselves to this.
	self.checkpointMap = {}
	-- Array of CourseSpawns. Determines max player count.
	self.spawns = {}
	self.prizeMoney = settings.prizeMoneyDefault
	self.parachuteEnabled = true
	self.grappleEnabled = true
	-- Key = modelId
	-- value = true
	self.dlcVehicles = {}
	
	-- Note: if two races are running at the same time with the same course, lap records could be
	-- overwritten, because lap records are stored when a course is loaded. Not a huge issue, since
	-- most servers won't be running more than one race at a time. Could always loop through every
	-- race currently running when a record is added. Or could cache courses, so two Races use the
	-- same Course.
	self.topRecords = {}
end

function Course:GetMaxPlayers()
	return #self.spawns
end

function Course:AssignRacers(playerIdToRacer)
	local numRacers = table.count(playerIdToRacer)
	if numRacers > #self.spawns then
		error(
			"Too many racers for course! "..self.name..", "..numRacers.."/"..#self.spawns.." racers"
		)
	end
	
	local racers = {}
	for id , racer in pairs(playerIdToRacer) do
		table.insert(racers , racer)
	end
	
	-- Randomly sort the racers table. Otherwise, the starting grid is (consistently) random; we
	-- want it to always be random.
	for n = #racers , 2 , -1 do
		local r = math.random(n)
		racers[n] , racers[r] = racers[r] , racers[n]
	end
	
	local spawnIndex = 1
	for index , racer in ipairs(racers) do
		racer.startPosition = index
		self.spawns[spawnIndex].racer = racer
		spawnIndex = spawnIndex + 1
	end
end

function Course:SpawnVehicles()
	if debug.alwaysMaxPlayers then
		self.race.numPlayers = #self.spawns
		self.race:Message("Vehicle count: "..self.race.numPlayers)
	end
	
	for n , spawn in ipairs(self.spawns) do
		if n <= self.race.numPlayers then
			spawn:SpawnVehicle()
		end
	end
end

function Course:SpawnCheckpoints()
	for n, checkpoint in ipairs(self.checkpoints) do
		checkpoint:Spawn()
	end
end

function Course:SpawnRacers()
	for n , spawn in ipairs(self.spawns) do
		spawn:SpawnRacer()
	end
end

function Course:GetSpawnPositionAverage()
	local average = Vector3(0 , 0 , 0)
	
	for index , spawn in ipairs(self.spawns) do
		average = average + spawn.position
	end
	
	average = average / #self.spawns
	
	return average
end

-- For use with sending course info to clients.
function Course:Marshal()
	local info = self:MarshalInfo()
	
	info.checkpoints = {}
	for index , checkpoint in ipairs(self.checkpoints) do
		table.insert(info.checkpoints , checkpoint:Marshal())
	end
	
	info.spawns = {}
	for index , spawn in ipairs(self.spawns) do
		table.insert(info.spawns , spawn:Marshal())
	end
	
	return info
end

-- Marshals variables like name and numLaps, but not checkpoints and such.
function Course:MarshalInfo()
	local info = {}
	
	info.name = self.name
	info.type = self.type
	info.numLaps = self.numLaps
	info.prizeMoney = self.prizeMoney
	
	return info
end

function Course:Save(name)
	local ctable = {}
	
	ctable.name = self.name
	ctable.type = self.type
	ctable.weatherSeverity = self.weatherSeverity
	ctable.authors = self.authors
	ctable.numLaps = self.numLaps
	ctable.prizeMoney = self.prizeMoney
	ctable.parachuteEnabled = self.parachuteEnabled
	ctable.grappleEnabled = self.grappleEnabled
	
	ctable.checkpoints = {}
	
	for index, checkpoint in ipairs(self.checkpoints) do
		table.insert(ctable.checkpoints , checkpoint:MarshalJSON())
	end
	
	ctable.spawns = {}
	
	for index, spawn in ipairs(self.spawns) do
		table.insert(ctable.spawns , spawn:MarshalJSON())
	end
	
	local json = require "JSON"
	
	local file = io.open(settings.coursesPath..name..".course" , "w")
	
	file:write(json.encode(ctable))
	
	file:close()
end

function Course.Load(name)
	if settings.debugLevel >= 2 then
		print("Loading course file: "..name)
	end
	
	local path = settings.coursesPath..name..".course"
	
	--
	-- Make sure file exists.
	--
	if path == nil then
		print()
		print("*ERROR*")
		print("Course path is nil!")
		print()
		return nil
	end
	
	local file = io.open(path , "r")
	
	if not file then
		print()
		print("*ERROR*")
		print("Cannot open course file: "..path)
		print()
		return nil
	end
	
	local string = ""
	
	for line in file:lines() do 
		string = string..line
	end
	
	local json = require 'JSON'
	
	local ctable = json.decode(string)
	local course = Course()
	
	course.name = ctable.name
	course.type = ctable.type
	course.weatherSeverity = ctable.weatherSeverity
	course.authors = ctable.authors
	course.numLaps = ctable.numLaps
	course.prizeMoney = ctable.prizeMoney
	course.parachuteEnabled = ctable.parachuteEnabled
	course.grappleEnabled = ctable.grappleEnabled
	-- Temporary because I'm not going to change every course just for this.
	if course.parachuteEnabled == nil then course.parachuteEnabled = true end
	if course.grappleEnabled == nil then course.grappleEnabled = true end
	
	course.checkpoints = {}
	
	for index , checkpoint in ipairs(ctable.checkpoints) do
		local cp = CourseCheckpoint(course)
		table.insert(course.checkpoints , cp)
		
		cp.index = #course.checkpoints
		
		cp.position = Vector3(
			checkpoint.position.x ,
			checkpoint.position.y ,
			checkpoint.position.z
		)
		
		cp.validVehicles = checkpoint.validVehicles
		cp.actions = checkpoint.actions or {}
	end
	
	course.spawns = {}
	course.dlcVehicles = {}
	
	for index , spawn in ipairs(ctable.spawns) do
		local sp = CourseSpawn(course)
		
		sp.position = Vector3(
			spawn.position.x ,
			spawn.position.y ,
			spawn.position.z
		)
		
		sp.angle = Angle(
			spawn.angle.x,
			spawn.angle.y,
			spawn.angle.z,
			spawn.angle.w
		)
		
		sp.modelIds = spawn.modelIds
		sp.templates = spawn.templates
		sp.decals = spawn.decals
		
		-- Add to dlcVehicles.
		for index , modelId in ipairs(spawn.modelIds) do
			local vehicleInfo = VehicleList[modelId]
			if vehicleInfo.isDLC then
				course.dlcVehicles[modelId] = true
			end
		end
		
		table.insert(course.spawns , sp)
	end
	
	course.fileName = path
	-- Replace backslashes with slashes for OS compatibility.
	course.fileName = course.fileName:gsub("\\" , "/")
	-- Strip out everything except the file name.
	course.fileName = course.fileName:gsub(".*/" , "")
	
	-- Add to database.
	Stats.AddCourse(course)
	
	-- Load top times from database.
	course.topRecords = Stats.GetCourseRecords(course.fileName , 1 , 10)
	-- If there are no records yet, use a fake one.
	if #course.topRecords == 0 then
		local newRecord = {}
		newRecord.time = 59 * 60 + 59 + 0.99
		newRecord.playerName = "xXxSUpA1337r4c3rxXx"
		table.insert(course.topRecords , newRecord)
	end
	
	return course
end
