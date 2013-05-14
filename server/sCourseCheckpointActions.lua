
function CourseCheckpoint:RepairCar(racer)
	
	local vehicle = racer.player:GetVehicle()
	if IsValid(vehicle) then
		vehicle:SetHealth(vehicle:GetHealth() + settings.vehicleRepairAmount)
	end
	
end
