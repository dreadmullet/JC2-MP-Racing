
BindMenu = {}

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
		Controls.Set(control)
		
		local button = Button.Create(self)
		button:SetDock(GwenPosition.Top)
		button:SetAlignment(GwenPosition.CenterV)
		button:SetText(name)
		button:SetDataObject("control" , control)
		button:Subscribe("Press" , self , self.ButtonPressed)
		
		local labelValue = Label.Create(button)
		labelValue:SetTextColor(button:GetTextColor())
		labelValue:SetAlignment(GwenPosition.Right)
		labelValue:SetDock(GwenPosition.Right)
		labelValue:SetPadding(Vector2(4 , 4) , Vector2(4 , 4))
		labelValue:SetText(control.valueString)
		labelValue:SizeToContents()
		
		button:SetDataObject("label" , labelValue)
	end
	
	function window:Assign()
		if self.state ~= "Activated" then
			return
		end
		
		self.state = "Idle"
		
		local children = self:GetChildren()
		for index , child in ipairs(children) do
			child:SetEnabled(true)
		end
		
		local control = self.activatedButton:GetDataObject("control")
		local label = self.activatedButton:GetDataObject("label")
		label:SetText(control.valueString)
		label:SizeToContents()
		self.activatedButton = nil
		
		Controls.Set(control)
		
		Events:Unsubscribe(self.eventInput)
		Events:Unsubscribe(self.eventKeyUp)
	end
	
	-- GWEN events
	
	function window:ButtonPressed(button)
		if self.state ~= "Idle" then
			return
		end
		
		self.state = "Activated"
		
		local children = self:GetChildren()
		for index , child in ipairs(children) do
			child:SetEnabled(false)
		end
		
		local label = button:GetDataObject("label")
		label:SetText("...")
		
		self.activatedButton = button
		
		self.eventInput = Events:Subscribe("LocalPlayerInput" , self , self.LocalPlayerInput)
		self.eventKeyUp = Events:Subscribe("KeyUp" , self , self.KeyUp)
	end
	
	-- Events
	
	function window:LocalPlayerInput(args)
		local control = self.activatedButton:GetDataObject("control")
		
		control.type = "Action"
		control.value = args.input
		control.valueString = "INVALID"
		
		for index , actionName in ipairs(InputNames.Action) do
			if Action[actionName] == args.input then
				control.valueString = actionName
			end
		end
		
		self:Assign()
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
		
		self:Assign()
	end
	
	return window
end
