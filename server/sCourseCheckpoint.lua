function CourseCheckpoint:__init(course)
	self.course = course
	
	self.position = nil
	self.radius = 12.05
	-- Array of model ids. -1 is on-foot.
	self.validVehicles = {}
	self.allowAllVehicles = false
	self.isRespawnable = true
	-- Array of tables, each has position, angle, speed, modelId, and counter
	self.respawnPoints = {}
	
	self.index = -1
	self.checkpoint = nil
end

function CourseCheckpoint:Spawn()
	self.checkpoint = Checkpoint.Create{
		position = self.position ,
		create_checkpoint = true ,
		create_trigger = true ,
		create_indicator = false ,
		type = 7 ,
		world = self.course.race.world ,
		despawn_on_enter = false ,
		activation_box = Vector3(
			self.radius ,
			self.radius ,
			self.radius
		) ,
	}
	
	self.course.checkpointMap[self.checkpoint:GetId()] = self
end

function CourseCheckpoint:GetIsValidVehicle(vehicle)
	if self.allowAllVehicles then
		return true
	end
	
	-- -1 is on-foot.
	local vehicleModelId = -1
	if vehicle then
		vehicleModelId = vehicle:GetModelId()
	end
	
	for index , modelId in ipairs(self.validVehicles) do
		if modelId == vehicleModelId then
			return true
		end
	end
	
	return false
end

-- Called by PlayerEnterVehicle event of race.
function CourseCheckpoint:Enter(racer)
	if
		racer.hasFinished == false and
		self:GetIsValidVehicle(racer.player:GetVehicle()) and
		racer.targetCheckpoint == self.index
	then
		-- Advance racer's checkpoint.
		racer:AdvanceCheckpoint(self.index)
	end
end

function CourseCheckpoint:MarshalForClient()
	return {
		self.position
	}
end
