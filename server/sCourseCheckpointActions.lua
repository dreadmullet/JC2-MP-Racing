
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
