
function CourseCheckpoint:ActionRepairCar(racer)
	
	local vehicle = racer.player:GetVehicle()
	if IsValid(vehicle) then
		vehicle:SetHealth(vehicle:GetHealth() + settings.vehicleRepairAmount)
	end
	
end

function CourseCheckpoint:ActionJump(racer)
	
	local vehicle = racer.player:GetVehicle()
	if IsValid(vehicle) then
		local velocity = vehicle:GetLinearVelocity()
		velocity.y = velocity.y + 20
		vehicle:SetLinearVelocity(velocity)
	end
	
end

function CourseCheckpoint:ActionSpinout(racer)
	
	local vehicle = racer.player:GetVehicle()
	if IsValid(vehicle) then
		if math.random() > 0.5 then
			vehicle:SetAngularVelocity(Vector(0 , 25 , 0))
		else
			vehicle:SetAngularVelocity(Vector(0 , -25 , 0))
		end
	end
	
end

function CourseCheckpoint:ActionTeleportUp(racer)
	
	local vehicle = racer.player:GetVehicle()
	if IsValid(vehicle) then
		local position = vehicle:GetPosition()
		position.y = position.y + 50
		local velocity = vehicle:GetLinearVelocity()
		velocity = velocity * 0.25
		vehicle:SetPosition(position)
		vehicle:SetLinearVelocity(velocity)
	end
	
end

function CourseCheckpoint:ActionSpawnBus(racer)
	
	local vehicle = racer.player:GetVehicle()
	if IsValid(vehicle) then
		local args = {}
		args.position = self.position
		args.position = args.position + Vector(0 , 15 , 0)
		args.angle = vehicle:GetAngle()
		args.angle.yaw = args.angle.yaw + math.rad(90)
		args.world = self.course.race.worldId
		args.model_id = VehicleList.FindByName("LeisureLiner").modelId
		args.enabled = true
		Vehicle.Create(args)
	end
	
end

function CourseCheckpoint:ActionReverseDirection(racer)
	
	local vehicle = racer.player:GetVehicle()
	if IsValid(vehicle) then
		local velocity = vehicle:GetLinearVelocity()
		velocity = Angle(math.rad(180) , 0 , 0) * velocity
		vehicle:SetLinearVelocity(velocity)
		
		local angle = vehicle:GetAngle()
		angle.yaw = angle.yaw + math.rad(180)
		vehicle:SetAngle(angle)
	end
	
end

function CourseCheckpoint:ActionRespawnAsPinkTukTuk(racer)
	
	local oldVehicle = racer.player:GetVehicle()
	if IsValid(oldVehicle) then
		
		local args = {}
		args.position = Vector(0 , 0 , 0)
		args.angle = oldVehicle:GetAngle()
		args.world = self.course.race.worldId
		args.model_id = 22 -- Tuk-Tuk Laa
		args.enabled = false
		args.tone1 = Color(255 , 50 , 240)
		args.tone2 = Color(200 , 70 , 240)
		local herpVehicle = Vehicle.Create(args)
		racer.assignedVehicleId = herpVehicle:GetId()
		
		racer:Respawn()
		oldVehicle:Remove()
		
		local newVehicle = Vehicle.GetById(racer.assignedVehicleId)
	end
	
end

function CourseCheckpoint:ActionShootInRandomDirection(racer)
	
	local vehicle = racer.player:GetVehicle()
	if IsValid(vehicle) then
		local direction = Vector(
			(math.random() - 0.5) * 2 ,
			(math.random() - 0.5) * 2 ,
			0.5 + math.random() * 0.5
		)
		direction = direction:Normalized()
		local speed = 150 + math.random() * 100
		local velocity = direction * speed
		vehicle:SetLinearVelocity(velocity)
	end
	
end
