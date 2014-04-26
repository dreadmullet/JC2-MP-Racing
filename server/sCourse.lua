ForceCollision = {
	None = 0 ,
	On = 1 ,
	Off = 2 ,
}

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
	self.forceCollision = ForceCollision.None
	self.authors = {}
	-- Array of CourseCheckpoints.
	self.checkpoints = {}
	-- Array of CourseSpawns. Determines max player count.
	self.spawns = {}
	-- Array of tables; each table has the following:
	--    modelId = number ,
	--    templates = array of strings ,
	--    available = number
	self.vehicleInfos = {}
	
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
	-- Key = modelId
	-- value = true
	self.dlcVehicles = {}
	self.averageSpawnPosition = Vector3(0 , 0 , 0)
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
		checkpointCount = #self.checkpoints ,
		parachuteEnabled = self.parachuteEnabled ,
		grappleEnabled = self.grappleEnabled ,
		authors = self.authors ,
	}
end

-- Returns collisions, but modifies it if our forceCollision is not None.
function Course:ProcessCollisions(collisions)
	if self.forceCollision == ForceCollision.On then
		return true
	elseif self.forceCollision == ForceCollision.Off then
		return false
	else
		return collisions
	end
end

function Course:HasDLCConflict(player)
	for modelId , alwaysTrue in pairs(self.dlcVehicles) do
		if player:HasVehicleDLC(modelId) == false then
			return true
		end
	end
	
	return false
end

function Course.Load(name)
	if settings.debugLevel >= 2 then
		print("Loading course file: "..name)
	end
	
	local timer = Timer()
	
	local LoadError = function(message)
		error("Cannot load "..path..": "..message)
	end
	
	local path = settings.coursesPath..name..".course"
	
	local file , openError = io.open(path , "r")
	
	if openError then
		LoadError(openError)
	end
	
	local entireFile = file:read("*a")
	
	local json = require("JSON")
	
	local map = json:decode(entireFile)
	local course = Course()
	
	course.name = map.properties.title or LoadError("No title")
	course.type = map.properties.type or LoadError("No type")
	course.numLaps = map.properties.laps
	course.weatherSeverity = map.properties.weatherSeverity or -1
	course.parachuteEnabled = map.properties.parachuteEnabled
	course.grappleEnabled = map.properties.grappleEnabled
	course.forceCollision = map.properties.forceCollision or ForceCollision.None
	course.authors = map.properties.authors or {"No author"}
	
	local objectIdToVehicleInfo = {}
	
	-- We need vehicle infos first.
	for index , object in ipairs(map.objects) do
		if object.type == "RaceVehicleInfo" then
			local vehicleInfo = {
				modelId = object.properties.modelId or LoadError("Invalid vehicle model") ,
				templates = object.properties.templates or LoadError("Invalid vehicle templates") ,
				available = 0 ,
			}
			table.insert(course.vehicleInfos , vehicleInfo)
			objectIdToVehicleInfo[object.id] = vehicleInfo
		end
	end
	
	for index , object in ipairs(map.objects) do
		if object.type == "RaceCheckpoint" then
			local cp = CourseCheckpoint(course)
			table.insert(course.checkpoints , cp)
			
			cp.index = #course.checkpoints
			
			cp.position = Vector3(
				object.position[1] ,
				object.position[2] ,
				object.position[3]
			)
			
			cp.validVehicles = object.properties.validVehicles or LoadError("Invalid checkpoint")
			cp.allowAllVehicles = object.properties.allowAllVehicles
			cp.isRespawnable = object.properties.isRespawnable
		elseif object.type == "RaceSpawn" then
			local spawn = CourseSpawn(course)
			table.insert(course.spawns , spawn)
			
			spawn.position = Vector3(
				object.position[1] ,
				object.position[2] ,
				object.position[3]
			)
			
			spawn.angle = Angle(
				object.angle[1] ,
				object.angle[2] ,
				object.angle[3] ,
				object.angle[4]
			)
			
			spawn.vehicleInfos = {}
			for index , objectId in ipairs(object.properties.vehicles) do
				local vehicleInfo = objectIdToVehicleInfo[objectId] or LoadError("Invalid spawn")
				table.insert(spawn.vehicleInfos , vehicleInfo)
				vehicleInfo.available = vehicleInfo.available + 1
			end
			
			-- Add to dlcVehicles.
			for index , v in ipairs(spawn.vehicleInfos) do
				local modelId = v.modelId
				local vehicleInfo = VehicleList[modelId]
				if vehicleInfo.isDLC then
					course.dlcVehicles[modelId] = true
				end
			end
		end
	end
	
	course.fileName = path
	-- Replace backslashes with slashes for OS compatibility.
	course.fileName = course.fileName:gsub("\\" , "/")
	-- Strip out everything except the file name.
	course.fileName = course.fileName:gsub(".*/" , "")
	
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
