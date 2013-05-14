
function CourseCheckpoint:__init(course)
	
	self.course = course
	self.index = -1
	self.position = nil
	self.radius = 12.05
	self.type = 7
	-- nil = Allow all vehicles and on-foot.
	-- {} -- Allow all vehicles but not on-foot.
	-- {0} = Only allow on-foot.
	self.validVehicles = nil
	self.useIcon = false
	self.checkpoint = nil
	-- When racer enters checkpoint, this function of ours is called. One argument: racer.
	self.action = ""
	
end

function CourseCheckpoint:Spawn()
	
	local spawnArgs = {}
	spawnArgs.position = self.position
	spawnArgs.create_checkpoint = true
	spawnArgs.create_trigger = true
	spawnArgs.create_indicator = self.useIcon
	spawnArgs.type = self.type
	spawnArgs.world = self.course.race.worldId
	spawnArgs.despawn_on_enter = false
	spawnArgs.activation_box = Vector(
		self.radius ,
		self.radius ,
		self.radius
	)
	spawnArgs.enabled = true
	
	self.checkpoint = Checkpoint.Create(spawnArgs)
	
	self.course.checkpointMap[self.checkpoint:GetId()] = self
	
end

function CourseCheckpoint:GetIsValidVehicle(vehicle)
	
	-- We don't have a required vehicle.
	if self.validVehicles == nil then
		return true
	-- We require any vehicle.
	elseif table.count(self.validVehicles) == 0 then
		return vehicle ~= nil
	-- We require a vehicle from a list.
	else
		local vehicleModelId
		if vehicle then
			vehicleModelId = vehicle:GetModelId()
		else
			-- On-foot.
			vehicleModelId = 0
		end
		
		for n , modelId in ipairs(self.validVehicles) do
			if modelId == vehicleModelId then
				return true
			end
		end
	end
	
	return false
	
end

-- Called by PlayerEnterVehicle event of race.
function CourseCheckpoint:Enter(racer)
	
	if self:GetIsValidVehicle(racer.player:GetVehicle()) then
		if racer.targetCheckpoint == self.index then
			racer:AdvanceCheckpoint(self.index)
		end
	end
	
end

-- For use with sending course checkpoint info to clients.
function CourseCheckpoint:Marshal()
	
	local info = {}
	
	info.index = self.index
	info.courseEditorId = self.courseEditorId
	info.position = self.position
	info.radius = self.radius
	info.validVehicles = self.validVehicles
	info.action = self.action
	
	return info
	
end

function CourseCheckpoint:MarshalJSON()
	local checkpoint = {}

	checkpoint.position = {}

	checkpoint.position.x = self.position.x
	checkpoint.position.y = self.position.y
	checkpoint.position.z = self.position.z
	checkpoint.radius = self.radius
	checkpoint.type = self.type
	checkpoint.validVehicles = self.validVehicles
	checkpoint.useIcon = self.useIcon
	checkpoint.action = self.action

	return checkpoint
end