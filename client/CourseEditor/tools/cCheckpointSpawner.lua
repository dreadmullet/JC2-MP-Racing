
function CheckpointSpawner:__init()
	
	BaseSpawner.__init(self)
	
	self.gizmo = Models.checkpoint
	self.gizmoColor = Color(220 , 20 , 15 , 180)
	self.gizmoColorDisabled = Color(155 , 136 , 135 , 150)
	self.usePitch = true
	
end

function CheckpointSpawner:PrimaryReleased(state)
	
	if BaseSpawner.GetCanUse(self) then
		Network:Send("CEAddCP" , LocalPlayer:GetAimTarget().position)
	end
	
end

function CheckpointSpawner:SecondaryReleased(state)
	
	if BaseSpawner.GetCanUse(self) then
		Network:Send("CERemoveCP" , LocalPlayer:GetAimTarget().position)
	end
	
end
