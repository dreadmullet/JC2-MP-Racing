class("StateVehicleSelection")

function StateVehicleSelection:__init(race , args) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	self.vehicles = args.vehicles
	self.vehicleIndex = args.vehicleIndex
	self.templateIndex = args.templateIndex
	self.garagePosition = args.garagePosition
	self.garageAngle = args.garageAngle
	self.startColor = args.color2
	self.window = nil
	self.timer = Timer()
	self.setColorsTimer = Timer()
	self.colorBuffer = nil
	self.camera = nil
	-- Contains arrays of {button , radioButton}.
	self.templateControls = {}
	
	self.timerControl = RaceMenuUtility.CreateTimer(
		"race start" ,
		self.race.vehicleSelectionSeconds
	)
	
	self:EventSubscribe("Render" , self.StateLoading)
	self:NetworkSubscribe("VehicleSelectionInitialize")
end

function StateVehicleSelection:End()
	if self.camera then
		self.camera:Destroy()
	end
	self:Destroy()
	self.timerControl:Remove()
	if self.window then
		self.window:Remove()
	end
	Mouse:SetVisible(false)
end

function StateVehicleSelection:DrawLoadingScreen(text)
	-- Render a loading screen.
	-- TODO: Genericize this into a loading screen class for use in other places.
	Render:FillArea(Vector2() , Render.Size , Color(12 , 12 , 12))
	local fontSize = TextSize.Large
	local textSize = Render:GetTextSize(text , fontSize)
	Render:DrawText(Render.Size/2 - textSize/2 , text , settings.textColor , fontSize)
end

function StateVehicleSelection:CreateCamera()
	self.camera = OrbitCamera(self.garagePosition , Angle(math.rad(45) , math.rad(-10) , 0))
	self.camera.minPitch = math.rad(-35)
	self.camera.maxPitch = math.rad(2)
	self.camera.minDistance = 3.6
	self.camera.maxDistance = 6.5
	self.camera.collision = false
	self.camera.isInputEnabled = false
end

function StateVehicleSelection:CreateMenus()
	self.window = Window.Create()
	local size = Vector2(290 , 600)
	self.window:SetSize(size)
	self.window:SetPosition(Vector2(Render.Width - size.x - 5 , Render.Height/2 - size.y/2))
	self.window:SetTitle("Select vehicle")
	self.window:SetClosable(false)
	
	-- Vehicle list
	
	local groupBoxVehicleList = RaceMenu.CreateGroupBox(self.window)
	groupBoxVehicleList:SetDock(GwenPosition.Top)
	groupBoxVehicleList:SetText("Model")
	
	local baseButton
	
	for index , vehicleInfo in ipairs(self.vehicles) do
		baseButton = Button.Create(groupBoxVehicleList)
		baseButton:SetMargin(Vector2(0 , 3) , Vector2(0 , 3))
		baseButton:SetDock(GwenPosition.Top)
		baseButton:SetHeight(24)
		baseButton:SetToggleable(true)
		baseButton:SetDataObject("vehicleIndex" , index)
		if index == self.vehicleIndex then
			baseButton:SetToggleState(true)
		end
		baseButton:Subscribe("Press" , self , self.ButtonPressed)
		
		local radioButton = RadioButton.Create(baseButton)
		radioButton:SetMargin(Vector2(4 , 3) , Vector2(5 , 4))
		radioButton:SetDock(GwenPosition.Left)
		radioButton:SetWidth(radioButton:GetHeight())
		radioButton:SetDataObject("vehicleIndex" , index)
		if index == self.vehicleIndex then
			radioButton:SetChecked(true)
		end
		radioButton:Subscribe("Checked" , self , self.RadioButtonPressed)
		
		local label = Label.Create(baseButton)
		label:SetMargin(Vector2(0 , 6) , Vector2(0 , 0))
		label:SetDock(GwenPosition.Left)
		label:SetTextSize(16)
		if vehicleInfo.modelId == -1 then
			label:SetText("On-foot")
		else
			label:SetText(VehicleList[vehicleInfo.modelId].name)
		end
		label:SizeToContents()
		
		local usageLabel = Label.Create(baseButton)
		usageLabel:SetMargin(Vector2(0 , 6) , Vector2(3 , 0))
		usageLabel:SetDock(GwenPosition.Right)
		usageLabel:SetTextSize(16)
		usageLabel:SetText(string.format("%i/%i" , vehicleInfo.used , vehicleInfo.available))
		usageLabel:SizeToContents()
		
		vehicleInfo.button = baseButton
		vehicleInfo.radioButton = radioButton
		vehicleInfo.usageLabel = usageLabel
	end
	
	groupBoxVehicleList:SizeToChildren()
	groupBoxVehicleList:SetHeight(28 + baseButton:GetPosition().y + baseButton:GetHeight())
	
	-- Template list
	
	self.groupBoxTemplateList = RaceMenu.CreateGroupBox(self.window)
	self.groupBoxTemplateList:SetDock(GwenPosition.Top)
	self.groupBoxTemplateList:SetText("Version")
	
	self:UpdateTemplateControls()
	
	-- Color picker
	
	self.groupBoxColorPicker = RaceMenu.CreateGroupBox(self.window)
	self.groupBoxColorPicker:SetDock(GwenPosition.Top)
	self.groupBoxColorPicker:SetText("Color")
	self.groupBoxColorPicker:SetHeight(200)
	
	self.colorPicker = HSVColorPicker.Create(self.groupBoxColorPicker)
	self.colorPicker:SetMargin(Vector2(0 , 6) , Vector2(0 , 0))
	self.colorPicker:SetDock(GwenPosition.Fill)
	self.colorPicker:SetColor(self.startColor)
	self.colorPicker:Subscribe("ColorChanged" , self , self.ColorChanged)
	
	self:UpdateColorControls()
end

function StateVehicleSelection:UpdateTemplateControls()
	-- self.groupBoxTemplateList:RemoveAllChildren()
	self.tempChildren = self.tempChildren or {}
	for index , child in ipairs(self.tempChildren) do
		child:Remove()
	end
	self.tempChildren = {}
	
	local templates = self.vehicles[self.vehicleIndex].templates
	
	-- If there is only one template to choose from, hide the template selection list.
	if #templates == 1 then
		self.groupBoxTemplateList:SetVisible(false)
		return
	else
		self.groupBoxTemplateList:SetVisible(true)
	end
	
	self.templateControls = {}
	
	local baseButton
	
	-- TODO: Have both model and template use a generic function.
	for index , template in ipairs(templates) do
		baseButton = Button.Create(self.groupBoxTemplateList)
		table.insert(self.tempChildren , baseButton)
		baseButton:SetMargin(Vector2(0 , 3) , Vector2(0 , 3))
		baseButton:SetDock(GwenPosition.Top)
		baseButton:SetHeight(24)
		baseButton:SetToggleable(true)
		baseButton:SetDataObject("templateIndex" , index)
		if index == self.templateIndex then
			baseButton:SetToggleState(true)
		end
		baseButton:Subscribe("Press" , self , self.TemplateButtonPressed)
		
		local radioButton = RadioButton.Create(baseButton)
		radioButton:SetMargin(Vector2(4 , 3) , Vector2(5 , 4))
		radioButton:SetDock(GwenPosition.Left)
		radioButton:SetWidth(radioButton:GetHeight())
		radioButton:SetDataObject("templateIndex" , index)
		if index == self.templateIndex then
			radioButton:SetChecked(true)
		end
		radioButton:Subscribe("Checked" , self , self.TemplateRadioButtonPressed)
		
		local label = Label.Create(baseButton)
		label:SetMargin(Vector2(0 , 6) , Vector2(0 , 0))
		label:SetDock(GwenPosition.Left)
		label:SetTextSize(16)
		label:SetText(template)
		label:SizeToContents()
		
		self.templateControls[index] = {}
		self.templateControls[index].button = baseButton
		self.templateControls[index].radioButton = radioButton
	end
	
	self.groupBoxTemplateList:SizeToChildren()
	self.groupBoxTemplateList:SetHeight(34 + baseButton:GetPosition().y + baseButton:GetHeight())
end

function StateVehicleSelection:UpdateColorControls()
	-- Hide the color picker if we're on-foot.
	if self.vehicles[self.vehicleIndex].modelId == -1 then
		self.groupBoxColorPicker:SetVisible(false)
		return
	else
		self.groupBoxColorPicker:SetVisible(true)
	end
end

function StateVehicleSelection:RenderAlways()
	if Game:GetState() == GUIState.Game then
		RaceGUI.DrawVersion()
	end
	
	if self.window then
		self.window:SetVisible(Game:GetState() == GUIState.Game)
	end
end

-- GWEN events

function StateVehicleSelection:ButtonPressed(button)
	local vehicleIndex = button:GetDataObject("vehicleIndex")
	if self.vehicleIndex == vehicleIndex then
		button:SetToggleState(true)
		return
	end
	
	self.vehicles[self.vehicleIndex].button:SetToggleState(false)
	
	button:SetToggleState(false)
	
	Network:Send("VehicleSelected" , vehicleIndex)
end

function StateVehicleSelection:RadioButtonPressed(button)
	local vehicleIndex = button:GetDataObject("vehicleIndex")
	if self.vehicleIndex == vehicleIndex then
		button:SetChecked(true)
		return
	end
	
	self.vehicles[self.vehicleIndex].radioButton:SetToggleState(false)
	
	button:SetChecked(false)
	
	Network:Send("VehicleSelected" , vehicleIndex)
end

function StateVehicleSelection:TemplateButtonPressed(button)
	local templateIndex = button:GetDataObject("templateIndex")
	if self.templateIndex == templateIndex then
		button:SetToggleState(true)
		return
	end
	
	self.templateControls[self.templateIndex].button:SetToggleState(false)
	
	button:SetToggleState(false)
	
	Network:Send("VehicleTemplateSelected" , templateIndex)
end

function StateVehicleSelection:TemplateRadioButtonPressed(button)
	local templateIndex = button:GetDataObject("templateIndex")
	if self.templateIndex == templateIndex then
		button:SetChecked(true)
		return
	end
	
	self.templateControls[self.templateIndex].radioButton:SetToggleState(false)
	
	button:SetChecked(false)
	
	Network:Send("VehicleTemplateSelected" , templateIndex)
end

function StateVehicleSelection:ColorChanged()
	self.colorBuffer = self.colorPicker:GetColor()
end

-- Events

function StateVehicleSelection:StateLoading()
	self:DrawLoadingScreen("Loading..")
	self:RenderAlways()
	-- Wait for a short time.
	-- TODO: Wait until the local player has spawned and then continue. I'm not sure how to do that
	-- right now, maybe it's just missing functionality.
	if self.timer:GetSeconds() < 4 then
		return
	end
	-- Change the state function to StatePreSelection.
	self:EventUnsubscribe("Render")
	self:EventSubscribe("Render" , self.StatePreSelection)
	-- Tell the server we're ready.
	Network:Send("VehicleSelectionLoaded" , ".")
end

function StateVehicleSelection:StatePreSelection()
	self:DrawLoadingScreen("Loading....")
	self:RenderAlways()
end

function StateVehicleSelection:StateSelection()
	self:RenderAlways()
	
	RaceGUI.DrawCourseName(self.race.course.name)
	
	Mouse:SetVisible(self.camera.isInputEnabled == false or inputSuspensionValue > 0)
	
	if self.colorBuffer and self.setColorsTimer:GetSeconds() > 0.1 then
		self.setColorsTimer:Restart()
		Network:Send("VehicleSetColors" , {self.colorBuffer * 0.85 , self.colorBuffer})
		self.colorBuffer = nil
	end
end

function StateVehicleSelection:ControlDown(control)
	if control.name == "Rotate camera" and inputSuspensionValue == 0 then
		if self.camera then
			self.camera.isInputEnabled = true
		end
	end
end

function StateVehicleSelection:ControlUp(control)
	if control.name == "Rotate camera" and inputSuspensionValue == 0 then
		if self.camera then
			self.camera.isInputEnabled = false
		end
	end
end

-- Network events

function StateVehicleSelection:VehicleSelectionInitialize(vehicleUsages)
	self:NetworkUnsubscribe("VehicleSelectionInitialize")
	self:EventUnsubscribe("Render")
	
	self:EventSubscribe("Render" , self.StateSelection)
	self:EventSubscribe("ControlDown")
	self:EventSubscribe("ControlUp")
	self:NetworkSubscribe("VehicleSelected")
	self:NetworkSubscribe("VehicleTemplateSelected")
	self:NetworkSubscribe("ReceiveVehicleUsages")
	
	self:CreateCamera()
	self:CreateMenus()
	
	self:ReceiveVehicleUsages(vehicleUsages)
end

function StateVehicleSelection:VehicleSelected(vehicleIndex)
	local oldVehicleInfo = self.vehicles[self.vehicleIndex]
	oldVehicleInfo.button:SetToggleState(false)
	oldVehicleInfo.radioButton:SetChecked(false)
	
	self.vehicleIndex = vehicleIndex
	self.templateIndex = 1
	
	local vehicleInfo = self.vehicles[self.vehicleIndex]
	vehicleInfo.button:SetToggleState(true)
	vehicleInfo.radioButton:SetChecked(true)
	
	self:UpdateTemplateControls()
	self:UpdateColorControls()
end

function StateVehicleSelection:VehicleTemplateSelected(templateIndex)
	self.templateControls[self.templateIndex].button:SetToggleState(false)
	self.templateControls[self.templateIndex].radioButton:SetChecked(false)
	
	self.templateIndex = templateIndex
	
	self.templateControls[self.templateIndex].button:SetToggleState(true)
	self.templateControls[self.templateIndex].radioButton:SetChecked(true)
end

function StateVehicleSelection:ReceiveVehicleUsages(vehicleUsages)
	for index , vehicleUsage in ipairs(vehicleUsages) do
		for index , vehicleInfo in ipairs(self.vehicles) do
			if vehicleInfo.modelId == vehicleUsage.modelId then
				vehicleInfo.used = vehicleUsage.count
				
				vehicleInfo.usageLabel:SetText(
					string.format("%i/%i" , vehicleInfo.used , vehicleInfo.available)
				)
				
				break
			end
		end
	end
end
