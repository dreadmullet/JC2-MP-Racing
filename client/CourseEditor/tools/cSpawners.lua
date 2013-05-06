----------------------------------------------------------------------------------------------------
-- CheckpointSpawner
----------------------------------------------------------------------------------------------------

function CheckpointSpawner:__init()
	
	ObjectSpawner.__init(self)
	
	self.gizmo = Models.checkpoint
	self.gizmoColor = Color(220 , 20 , 15 , 180)
	self.gizmoColorDisabled = Color(155 , 136 , 135 , 150)
	self.usePitch = true
	
end

function CheckpointSpawner:PrimaryPressed(state)
	
	if ObjectSpawner.GetCanUse(self) then
		Network:Send("CEAddCP" , LocalPlayer:GetAimTarget().position)
	end
	
end

function CheckpointSpawner:SecondaryPressed(state)
	
	if ObjectSpawner.GetCanUse(self) then
		Network:Send("CERemoveCP" , LocalPlayer:GetAimTarget().position)
	end
	
end

----------------------------------------------------------------------------------------------------
-- VehicleSpawner
----------------------------------------------------------------------------------------------------

function VehicleSpawner:__init()
	
	ObjectSpawner.__init(self)
	
	self.gizmo = Models.vehicleSpawn
	self.gizmoColor = Color.FromHSV(195 , 0.75 , 0.75)
	self.gizmoColor.a = 180
	self.gizmoColorDisabled = Color.FromHSV(195 , 0.1 , 0.75)
	self.gizmoColorDisabled.a = 150
	
end

function VehicleSpawner:PrimaryPressed(state)
	
	local angle = Camera:GetAngle()
	angle.roll = 0
	angle.pitch = 0
	
	if ObjectSpawner.GetCanUse(self) then
		Network:Send(
			"CEAddSpawn" ,
			{
				LocalPlayer:GetAimTarget().position ,
				angle ,
				{91}
			}
		)
	end
	
end

function VehicleSpawner:SecondaryPressed(state)
	
	if ObjectSpawner.GetCanUse(self) then
		Network:Send("CERemoveSpawn" , LocalPlayer:GetAimTarget().position)
	end
	
end
