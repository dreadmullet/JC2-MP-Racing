
function VehicleSpawner:__init()
	
	BaseSpawner.__init(self)
	
	self.gizmo = Models.vehicleSpawn
	self.gizmoColor = Color.FromHSV(195 , 0.75 , 0.75)
	self.gizmoColor.a = 180
	self.gizmoColorDisabled = Color.FromHSV(195 , 0.1 , 0.75)
	self.gizmoColorDisabled.a = 150
	
end

function VehicleSpawner:PrimaryReleased(state)
	
	local angle = Camera:GetAngle()
	angle.roll = 0
	angle.pitch = 0
	
	if BaseSpawner.GetCanUse(self) then
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

function VehicleSpawner:SecondaryReleased(state)
	
	if BaseSpawner.GetCanUse(self) then
		Network:Send("CERemoveSpawn" , LocalPlayer:GetAimTarget().position)
	end
	
end

function VehicleSpawner:CreateWindowElements(toolWindow)
	
	local spacingY = settingsCE.gui.toolWindow.buttonHeight / 0.75
	local currentY = 0
	local leftX = 0
	
	local button = Window.Create("GWEN/Button" , "TestButton"..PhilpaxSucks , toolWindow)
	PhilpaxSucks = PhilpaxSucks + 1
	button:SetText("spawn dat vehicle namsayin")
	button:SetPositionRel(Vector2(leftX , currentY))
	currentY = currentY + spacingY
	button:SetSizeRel(
		Vector2(settingsCE.gui.toolWindow.buttonWidth , settingsCE.gui.toolWindow.buttonHeight)
	)
	
end
