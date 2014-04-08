class("Course")

-- TODO: Perhaps Course should only contain info, it should not do anything; that is up to other
-- classes.

function Course:__init()
	-- Course properties which are saved and loaded.
	
	self.name = "Unnamed Course"
	self.type = "Invalid"
	self.numLaps = -1
	-- -1 is random.
	-- TODO: This isn't even used.
	self.weatherSeverity = -1
	self.parachuteEnabled = true
	self.grappleEnabled = true
	self.authors = {}
	-- Array of CourseCheckpoints.
	self.checkpoints = {}
	-- Array of CourseSpawns. Determines max player count.
	self.spawns = {}
	
	-- Other variables.
	-- TODO: Some of these should be in Race.
	
	self.race = nil
	self.fileName = "Invalid file name"
	-- Map of CourseCheckpoints.
	-- Useful for mapping PlayerEnterCheckpoint events to a CourseCheckpoint.
	-- Key = checkpointId
	-- Value = CourseCheckpoint
	-- Checkpoints add themselves to this.
	self.checkpointMap = {}
	-- Array of tables; each table has the following:
	--    modelId = number ,
	--    templates = array of strings ,
	--    available = number
	-- Much better than using self.spawns for some things, such as vehicle selection.
	self.vehiclesInfo = {}
	-- Key = modelId
	-- value = true
	self.dlcVehicles = {}
	self.averageSpawnPosition = Vector3()
end

function Course:GetMaxPlayers()
	return #self.spawns
end

function Course:AssignRacers(playerIdToRacer)
	local numRacers = table.count(playerIdToRacer)
	if
		numRacers > #self.spawns and
		self.race.overflowHandling ~= Race.OverflowHandling.StackSpawns
	then
		error(
			"Too many racers for course! "..self.name..", "..numRacers.."/"..#self.spawns.." racers"
		)
	end
	
	local racers = {}
	for id , racer in pairs(playerIdToRacer) do
		table.insert(racers , racer)
	end
	
	-- Randomly sort the racers table. Otherwise, the starting grid is consistent; we want it to
	-- always be completely random.
	table.sortrandom(racers)
	
	local spawnIndex = 1
	local spawnCount = #self.spawns
	for index , racer in ipairs(racers) do
		-- If the players overflow, copy a random spawn.
		if spawnIndex > spawnCount then
			local copiedSpawn = self.spawns[math.random(1 , spawnCount)]:Copy()
			table.insert(self.spawns , copiedSpawn)
		end
		
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
		if spawn.racer then
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

-- Used to send course info to clients at the start of a race.
function Course:MarshalForClient()
	local info = self:MarshalInfo()
	
	info.checkpoints = {}
	for index , checkpoint in ipairs(self.checkpoints) do
		table.insert(info.checkpoints , checkpoint:MarshalForClient())
	end
	
	return info
end

function Course:MarshalInfo()
	return {
		name = self.name ,
		type = self.type ,
		parachuteEnabled = self.parachuteEnabled ,
		grappleEnabled = self.grappleEnabled ,
		authors = self.authors
	}
end

function Course:Save(name)
	local ctable = {}
	
	ctable.name = self.name
	ctable.type = self.type
	ctable.numLaps = self.numLaps
	ctable.weatherSeverity = self.weatherSeverity
	ctable.parachuteEnabled = self.parachuteEnabled
	ctable.grappleEnabled = self.grappleEnabled
	ctable.authors = self.authors
	
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
	
	local timer = Timer()
	
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
	
	local json = require("JSON")
	
	local ctable = json:decode(string)
	local course = Course()
	
	course.name = ctable.name
	course.type = ctable.type
	course.numLaps = ctable.numLaps
	course.weatherSeverity = ctable.weatherSeverity
	course.parachuteEnabled = ctable.parachuteEnabled
	course.grappleEnabled = ctable.grappleEnabled
	course.authors = ctable.authors
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
		
		-- Fix for old courses: if there are no model ids, it's an on-foot race. But on-foot has a
		-- pseudo model id of -1, which breaks some things (vehicle selection, at least).
		if #sp.modelIds == 0 then
			sp.modelIds = {-1}
		end
		
		table.insert(course.spawns , sp)
	end
	
	course.fileName = path
	-- Replace backslashes with slashes for OS compatibility.
	course.fileName = course.fileName:gsub("\\" , "/")
	-- Strip out everything except the file name.
	course.fileName = course.fileName:gsub(".*/" , "")
	
	-- Populate course.vehiclesInfo.
	
	-- Create temporary vehicles map.
	local vehicles = {}
	for index , courseSpawn in ipairs(course.spawns) do
		-- Map to help with removing duplicate model ids.
		local modelIds = {}
		for index , modelId in ipairs(courseSpawn.modelIds) do
			-- If there are no templates, make a blank one.
			if #courseSpawn.templates == 0 then
				courseSpawn.templates = {"."}
			end
			
			if vehicles[modelId] then
				vehicles[modelId].templates[courseSpawn.templates[index]] = true
				if modelIds[modelId] == nil then
					vehicles[modelId].available = vehicles[modelId].available + 1
					modelIds[modelId] = true
				end
			else
				vehicles[modelId] = {
					templates = {[courseSpawn.templates[index]] = true} ,
					available = 1 ,
				}
				modelIds[modelId] = true
			end
		end
	end
	-- Translate vehicles (map) into course.vehiclesInfo (array).
	for modelId , vehicleInfo in pairs(vehicles) do
		local templates = {}
		for template , alwaysTrue in pairs(vehicleInfo.templates) do
			table.insert(templates , template)
		end
		
		local vehicleInfo = {
			modelId = modelId ,
			templates = templates ,
			available = vehicleInfo.available ,
		}
		table.insert(course.vehiclesInfo , vehicleInfo)
	end
	
	-- Calculate course.averageSpawnPosition.
	for index , courseSpawn in ipairs(course.spawns) do
		course.averageSpawnPosition = course.averageSpawnPosition + courseSpawn.position
	end
	course.averageSpawnPosition = course.averageSpawnPosition / #course.spawns
	
	-- Add to database.
	Stats.AddCourse(course)
	
	print(string.format("%s loaded in %.3f seconds" , course.name , timer:GetSeconds()))
	
	return course
end
