
function ObjectSpawner:__init()
	
	Tool.__init(self)
	
	if CourseEditor.settings.debugLevel >= 2 then
		print("ObjectSpawner:__init")
	end
	
	-- Lua less than three.
	-- Fancy pressed/unpressed input system in lua is super easy.
	Tool.AddInput(self , "Primary" , Action.FireRight)
	Tool.AddInput(self , "Secondary" , Action.FireLeft)
	
	self.gizmo = Models.objectSpawnerGizmo
	self.gizmoColor = Copy(CourseCheckpoint.color)
	self.usePitch = false
	
	table.insert(
		self.events ,
		Events:Subscribe("Render" , self , ObjectSpawner.Render)
	)
	
end

function ObjectSpawner:Render()
	
	local aimPos = LocalPlayer:GetAimTarget().position
	local angle = Camera:GetAngle()
	angle.roll = 0
	if self.usePitch == false then
		angle.pitch = 0
	end
	
	-- Only draw while unpaused and on foot.
	if self.gizmo then
		if ObjectSpawner.GetCanUse(self) then
			RenderModel(self.gizmo , aimPos , angle , self.gizmoColor)
		elseif self.gizmoColorDisabled then
			RenderModel(self.gizmoDisabled or self.gizmo , aimPos , angle , self.gizmoColorDisabled)
		end
	end
	
end

function ObjectSpawner:GetCanUse()
	
	local hitDistance = Vector.Distance(
		LocalPlayer:GetPosition() ,
		LocalPlayer:GetAimTarget().position
	)
	
	return(
		Client:InState(GUIState.Game) and
		LocalPlayer:GetVehicle() == nil and
		hitDistance < 92 -- No weapon.
	)
	
end
