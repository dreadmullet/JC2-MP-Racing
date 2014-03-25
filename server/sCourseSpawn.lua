class("CourseSpawn")

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
	local vehicleInfo = self.racer.vehicleInfo
	-- If they are on foot, return out of here.
	if vehicleInfo.modelId == -1 then
		return
	end
	-- Create the vehicle.
	local spawnArgs = {
		model_id = vehicleInfo.modelId ,
		position = self.position ,
		angle = self.angle ,
		world = self.course.race.world ,
		enabled = true ,
		template = vehicleInfo.template ,
		-- Disabled for now.
		decal = "" ,
		tone1 = vehicleInfo.color1 ,
		tone2 = vehicleInfo.color2 ,
	}
	self.vehicle = Vehicle.Create(spawnArgs)
	self.vehicle:SetDeathRemove(true)
	self.vehicle:SetUnoccupiedRemove(true)
end

function CourseSpawn:SpawnRacer()
	if self.racer == nil or IsValid(self.racer.player) == false then
		return
	end
	
	local teleportPos = self.position + Vector3(0 , 2 , 0)
	-- If there is a vehicle, teleport them and put them in the vehicle.
	if self.vehicle then
		local angleForward = self.angle
		local dirToPlayerSpawn = angleForward * Vector3(-1 , 0 , 0)
		teleportPos = teleportPos + dirToPlayerSpawn * 2
		self.racer.assignedVehicleId = self.vehicle:GetId()
		self.racer.player:EnterVehicle(self.vehicle , VehicleSeat.Driver)
	-- Otherwise, place them directly on the spawn position.
	else
		
	end
	
	self.racer.courseSpawn = self
	
	self.racer.player:Teleport(teleportPos , self.angle)
end

function CourseSpawn:MarshalJSON()
	local spawn = {}
	
	spawn.position = {}
	spawn.position.x = self.position.x
	spawn.position.y = self.position.y
	spawn.position.z = self.position.z
	spawn.angle = {}
	spawn.angle.x = self.angle.x
	spawn.angle.y = self.angle.y
	spawn.angle.z = self.angle.z
	spawn.angle.w = self.angle.w
	spawn.modelIds = self.modelIds
	spawn.templates = self.templates
	spawn.decals = self.decals
	
	return spawn
end
