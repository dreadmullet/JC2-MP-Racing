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
	self.minStartHour = 0
	self.maxStartHour = 24
	-- -1 is random.
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
	self.allowFirstLapRecord = true
	
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
	-- Stats shouldn't be used in some cases, such as when testing courses in the map editor.
	self.useStats = false
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

Course.Load = function(name)
	if settings.debugLevel >= 2 then
		print("Loading course file: "..name)
	end
	
	local timer = Timer()
	
	local path = settings.coursesPath..name..".map"
	
	local map = MapEditor.LoadFromFile(path)
	
	local course = Course.LoadFromMap(map)
	
	course.fileName = path
	-- Replace backslashes with slashes for OS compatibility.
	course.fileName = course.fileName:gsub("\\" , "/")
	-- Strip out everything except the file name.
	course.fileName = course.fileName:gsub(".*/" , "")
	
	-- Add to database.
	course.useStats = true
	Stats.AddCourse(course)
	
	print(string.format("%s loaded in %.3f seconds" , course.name , timer:GetSeconds()))
	
	return course
end

Course.LoadFromMap = function(map)
	local course = Course()
	
	course.map = map
	course.name = map.properties.title
	course.type = "Linear"
	course.numLaps = map.properties.laps
	course.minStartHour = map.properties.minStartHour
	course.maxStartHour = map.properties.maxStartHour
	course.weatherSeverity = map.properties.weatherSeverity
	course.parachuteEnabled = map.properties.parachuteEnabled
	course.grappleEnabled = map.properties.grappleEnabled
	course.forceCollision = map.properties.forceCollision
	course.authors = map.properties.authors
	course.allowFirstLapRecord = map.properties.allowFirstLapRecord
	
	local objectIdToVehicleInfo = {}
	
	-- Checkpoints
	
	-- Create a linked list of checkpoints.
	-- Values are like, {previous = table , checkpoint = RaceCheckpoint , next = table}
	local checkpointList = {}
	for objectIdSometimes , object in pairs(map.objects) do
		if object.type == "RaceCheckpoint" then
			table.insert(checkpointList , {checkpoint = object})
		end
	end
	for index , listItem in ipairs(checkpointList) do
		local nextCheckpoint = listItem.checkpoint.properties.nextCheckpoint
		if nextCheckpoint then
			for index2 , listItem2 in ipairs(checkpointList) do
				if listItem2.checkpoint.id == nextCheckpoint.id then
					listItem.next = listItem2
					listItem2.previous = listItem
				end
			end
		end
	end
	
	-- Find the first checkpoint and also determine if the course is a circuit.
	local startingCheckpointItem = checkpointList[1]
	while true do
		startingCheckpointItem.beenTo = true
		
		if
			course.type == "Circuit" and
			startingCheckpointItem.checkpoint == map.properties.firstCheckpoint
		then
			break
		end
		
		if startingCheckpointItem.previous then
			startingCheckpointItem = startingCheckpointItem.previous
			-- Prevent an infinite loop in case it's a circuit.
			if startingCheckpointItem.beenTo then
				-- We know it's a circuit now, so start searching for the first checkpoint.
				course.type = "Circuit"
			end
		else
			break
		end
	end
	-- Create the CourseCheckpoints by iterating through the checkpointList linked list.
	local listItem = startingCheckpointItem
	repeat
		local object = listItem.checkpoint
		
		local checkpoint = CourseCheckpoint(course)
		table.insert(course.checkpoints , checkpoint)
		
		checkpoint.index = #course.checkpoints
		
		checkpoint.position = object.position
		
		checkpoint.validVehicles = object.properties.validVehicles
		checkpoint.allowAllVehicles = object.properties.allowAllVehicles
		checkpoint.isRespawnable = object.properties.isRespawnable
		
		for index , respawnPointObject in ipairs(object.properties.respawnPoints) do
			if respawnPointObject ~= MapEditor.NoObject then
				local respawnPoint = {
					position = respawnPointObject.position ,
					angle = respawnPointObject.angle ,
					speed = respawnPointObject.properties.speed ,
					modelId = respawnPointObject.properties.modelId ,
					counter = 0 ,
				}
				table.insert(checkpoint.respawnPoints , respawnPoint)
			end
		end
		
		listItem = listItem.next
	until listItem == nil or listItem == startingCheckpointItem
	
	-- Spawns
	
	-- We need vehicle infos first.
	for objectIdSometimes , object in pairs(map.objects) do
		if object.type == "RaceVehicleInfo" then
			local vehicleInfo = {
				modelId = object.properties.modelId ,
				templates = object.properties.templates ,
				available = 0 ,
			}
			if #vehicleInfo.templates == 0 then
				vehicleInfo.templates[1] = ""
			end
			table.insert(course.vehicleInfos , vehicleInfo)
			objectIdToVehicleInfo[object.id] = vehicleInfo
		end
	end
	
	-- Create the CourseSpawns.
	for objectIdSometimes , object in pairs(map.objects) do
		if object.type == "RaceSpawn" then
			local spawn = CourseSpawn(course)
			table.insert(course.spawns , spawn)
			
			spawn.position = object.position
			
			spawn.angle = object.angle
			
			spawn.vehicleInfos = {}
			for index , object in ipairs(object.properties.vehicles) do
				local vehicleInfo = objectIdToVehicleInfo[object.id]
				table.insert(spawn.vehicleInfos , vehicleInfo)
				vehicleInfo.available = vehicleInfo.available + 1
			end
			
			-- Add to dlcVehicles.
			for index , v in ipairs(spawn.vehicleInfos) do
				local modelId = v.modelId
				local vehicleInfo = VehicleList[modelId]
				if vehicleInfo and vehicleInfo.isDLC then
					course.dlcVehicles[modelId] = true
				end
			end
		end
	end
	
	-- Misc
	
	-- Calculate course.averageSpawnPosition.
	for index , courseSpawn in ipairs(course.spawns) do
		course.averageSpawnPosition = course.averageSpawnPosition + courseSpawn.position
	end
	course.averageSpawnPosition = course.averageSpawnPosition / #course.spawns
	
	return course
end
