
function CourseSpawn:__init(course)
	
	self.course = course
	self.position = nil
	self.angle = nil
	self.modelIds = {}
	self.templates = {}
	self.decals = {}
	self.racer = nil
	self.vehicle = nil
	
end

function CourseSpawn:SpawnVehicle()
	
	if self.modelId == -1 then
		return
	end
	
	local modelIdIndex = math.random(1 , #self.modelIds)
	
	local spawnArgs = {}
	spawnArgs.model_id = self.modelIds[modelIdIndex]
	spawnArgs.position = self.position
	spawnArgs.angle = self.angle
	spawnArgs.world = self.course.race.worldId
	spawnArgs.enabled = true
	spawnArgs.template = self.templates[modelIdIndex] or ""
	spawnArgs.decal = self.decals[modelIdIndex] or ""
	
	self.vehicle = Vehicle.Create(spawnArgs)
	
end

function CourseSpawn:SpawnRacer()
	
	if self.racer == nil or IsValid(self.racer.player) == false then
		return
	end
	
	local teleportPos = self.position + Vector(0 , 2 , 0)
	-- If there is a vehicle, spawn them next to the door of their car.
	if self.vehicle then
		local angleForward = self.angle
		local dirToPlayerSpawn = angleForward * Vector(-1 , 0 , 0)
		teleportPos = teleportPos + dirToPlayerSpawn * 2
	-- Otherwise, place them directly on the spawn position.
	else
		
	end
	
	self.racer.assignedVehicleId = self.vehicle:GetId()
	
	self.racer.player:Teleport(teleportPos , self.angle)
	self.racer.player:SetWorldId(self.course.race.worldId)
	
end

-- For use with sending course checkpoint info to clients.
function CourseSpawn:Marshal()
	
	local info = {}
	
	info.courseEditorId = self.courseEditorId
	info.position = self.position
	info.angle = self.angle
	info.modelIds = self.modelIds
	
	return info
	
end

function CourseSpawn:MarshalJSON()

	local spawn = {}

	spawn.position = {}
	spawn.angle = {}

	spawn.position.x = self.position.x
	spawn.position.y = self.position.y
	spawn.position.z = self.position.z
	spawn.angle.x = self.angle.x
	spawn.angle.y = self.angle.y
	spawn.angle.z = self.angle.z
	spawn.angle.w = self.angle.w
	spawn.modelIds = self.modelIds
	spawn.templates = self.templates
	spawn.decals = self.decals

	return spawn
end