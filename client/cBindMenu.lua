
BindMenu = {}

-- Controls cannot be assigned to these if allowMouse is false (default).
BindMenu.blockedMouseActions = {
	Action.LookUp ,
	Action.LookDown ,
	Action.LookLeft ,
	Action.LookRight ,
	Action.HeliTurnLeft ,
	Action.HeliTurnRight ,
}

BindMenu.Create = function(...)
	local window = Rectangle.Create(...)
	window:SetColor(Color(16 , 16 , 16))
	window:SetPadding(Vector2(2 , 2) , Vector2(2 , 2))
	window:SetSize(Vector2(276 , 128))
	
	-- Array of tables. See Controls.
	window.controls = {}
	window.state = "Idle"
	window.eventInput = nil
	window.eventKeyUp = nil
	window.activatedButton = nil
	window.allowMouse = false
	
	-- defaultControl can be an Action name, a Key name, or nil.
	-- Examples: "SoundHornSiren", "LShift", "C", nil
	function window:AddControl(name , defaultControl)
		if not name then
			error("Invalid arguments")
		end
		
		local control = {}
		
		if defaultControl == nil then
			control.type = "Unassigned"
			control.value = -1
		elseif Action[defaultControl] then
			control.type = "Action"
			control.value = Action[defaultControl]
		elseif VirtualKey[defaultControl] or defaultControl:len() == 1 then
			control.type = "Key"
			control.value = VirtualKey[defaultControl] or string.byte(defaultControl:upper())
		else
			error("defaultControl is not a valid Action or Key")
		end
		
		control.name = name
		control.valueString = defaultControl or "Unassigned"
		table.insert(self.controls , control)
		
		local button = Button.Create(self)
		button:SetDock(GwenPosition.Top)
		button:SetAlignment(GwenPosition.CenterV)
		button:SetText(name)
		button:SetDataObject("control" , control)
		button:Subscribe("Press" , self , self.ButtonPressed)
		button:Subscribe("RightPress" , self , self.ButtonPressed)
		
		local unassignButton = Button.Create(button)
		unassignButton:SetDock(GwenPosition.Right)
		unassignButton:SetText(" X ")
		unassignButton:SizeToContents()
		unassignButton:SetToolTip("Unassign")
		unassignButton:SetTextNormalColor(Color(220 , 50 , 50))
		unassignButton:SetTextPressedColor(Color(150 , 40 , 40))
		unassignButton:SetTextHoveredColor(Color(255 , 70 , 70))
		unassignButton:Subscribe("Down" , self , self.UnassignButtonPressed)
		
		local labelValue = Label.Create(button)
		labelValue:SetTextColor(button:GetTextColor())
		labelValue:SetAlignment(GwenPosition.Right)
		labelValue:SetDock(GwenPosition.Right)
		labelValue:SetPadding(Vector2(4 , 4) , Vector2(4 , 4))
		labelValue:SetText(control.valueString)
		labelValue:SizeToContents()
		
		button:SetDataObject("label" , labelValue)
		
		self:Assign(button)
	end
	
	function window:Assign(activeButton)
		self.state = "Idle"
		
		BindMenu.SetEnabledRecursive(self , true)
		
		local control = activeButton:GetDataObject("control")
		local label = activeButton:GetDataObject("label")
		label:SetText(control.valueString)
		label:SizeToContents()
		if control.type == "Unassigned" then
			label:SetTextColor(Color(255 , 127 , 127))
		else
			label:SetTextColor(activeButton:GetTextColor())
		end
		
		Controls.Set(control)
		
		if IsValid(self.eventInput) then
			Events:Unsubscribe(self.eventInput)
			Events:Unsubscribe(self.eventKeyUp)
		end
	end
	
	-- GWEN events
	
	function window:ButtonPressed(button)
		if self.state ~= "Idle" then
			return
		end
		
		self.state = "Activated"
		
		BindMenu.SetEnabledRecursive(self , false)
		
		local label = button:GetDataObject("label")
		label:SetText("...")
		
		self.activatedButton = button
		
		self.eventInput = Events:Subscribe("LocalPlayerInput" , self , self.LocalPlayerInput)
		self.eventKeyUp = Events:Subscribe("KeyUp" , self , self.KeyUp)
	end
	
	function window:UnassignButtonPressed(button)
		if self.state ~= "Idle" then
			return
		end
		
		local activeButton = button:GetParent()
		local control = activeButton:GetDataObject("control")
		
		control.type = "Unassigned"
		control.value = -1
		control.valueString = "Unassigned"
		
		self:Assign(activeButton)
	end
	
	-- Events
	
	function window:LocalPlayerInput(args)
		if self.allowMouse == false then
			for index , action in ipairs(BindMenu.blockedMouseActions) do
				if args.input == action then
					return true
				end
			end
		end
		
		local control = self.activatedButton:GetDataObject("control")
		
		control.type = "Action"
		control.value = args.input
		control.valueString = "INVALID"
		
		for index , actionName in ipairs(InputNames.Action) do
			if Action[actionName] == args.input then
				control.valueString = actionName
			end
		end
		
		self:Assign(self.activatedButton)
		self.activatedButton = nil
		
		return true
	end
	
	function window:KeyUp(args)
		local control = self.activatedButton:GetDataObject("control")
		
		control.type = "Key"
		control.value = args.key
		control.valueString = "INVALID"
		
		for index , keyname in ipairs(InputNames.Key) do
			if VirtualKey[keyname] == args.key then
				control.valueString = keyname
			end
		end
		
		if control.valueString == "INVALID" then
			control.valueString = string.char(args.key) or "Unknown"
		end
		
		self:Assign(self.activatedButton)
		self.activatedButton = nil
	end
	
	return window
end

BindMenu.SetEnabledRecursive = function(window , enabled)
	window:SetEnabled(enabled)
	
	local children = window:GetChildren()
	for index , child in ipairs(children) do
		BindMenu.SetEnabledRecursive(child , enabled)
	end
end
