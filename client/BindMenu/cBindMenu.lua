BindMenu = {}

-- Controls can only be assigned to these if using a gamepad.
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
	window.buttons = {}
	window.state = "Idle"
	window.eventInput = nil
	window.eventKeyUp = nil
	window.eventMouseUp = nil
	window.eventMouseWheel = nil
	window.eventPostTick = nil
	window.activatedButton = nil
	window.receiveEvent = nil
	window.tickEvent = nil
	window.dirtySettings = false
	window.saveTimer = Timer()
	-- These two are used to delay Actions so it prefers keys or mouse buttons.
	window.activeAction = nil
	window.ticksSinceAction = 0
	-- Used to determine mouse delta.
	window.mousePositionStart = nil
	
	-- defaultControl can be an Action name, a Key name, or nil.
	-- Examples: "SoundHornSiren", "LShift", "C", "Mouse3", nil
	function window:AddControl(name , defaultControl)
		if not name then
			error("Invalid arguments")
		end
		
		local control = Controls.Add(name , defaultControl)
		
		local button = Button.Create(self)
		button:SetDock(GwenPosition.Top)
		button:SetAlignment(GwenPosition.CenterV)
		button:SetText(name)
		button:SetDataObject("control" , control)
		button:Subscribe("Press" , self , self.ButtonPressed)
		button:Subscribe("RightPress" , self , self.ButtonPressed)
		local baseButton = button
		table.insert(self.buttons , baseButton)
		
		-- Unassign button
		local button = Button.Create(baseButton)
		button:SetDock(GwenPosition.Right)
		button:SetText(" X ")
		button:SizeToContents()
		button:SetToolTip("Unassign")
		button:SetTextNormalColor(Color(220 , 50 , 50))
		button:SetTextPressedColor(Color(150 , 40 , 40))
		button:SetTextHoveredColor(Color(255 , 70 , 70))
		button:Subscribe("Down" , self , self.UnassignButtonPressed)
		
		-- Value label
		local label = Label.Create(baseButton)
		label:SetTextColor(baseButton:GetTextColor())
		label:SetAlignment(GwenPosition.Right)
		label:SetDock(GwenPosition.Right)
		label:SetPadding(Vector2(4 , 4) , Vector2(4 , 4))
		label:SetText(control.valueString)
		label:SizeToContents()
		
		baseButton:SetDataObject("label" , label)
		
		self:Assign(baseButton)
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
			Events:Unsubscribe(self.eventMouseUp)
			Events:Unsubscribe(self.eventMouseWheel)
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
		self.activeAction = nil
		self.mousePositionStart = Mouse:GetPosition()
		
		self.eventInput = Events:Subscribe("LocalPlayerInput" , self , self.LocalPlayerInput)
		self.eventKeyUp = Events:Subscribe("KeyUp" , self , self.KeyUp)
		self.eventMouseUp = Events:Subscribe("MouseUp" , self , self.MouseButtonUp)
		self.eventMouseWheel = Events:Subscribe("MouseScroll" , self , self.MouseScroll)
	end
	
	function window:MouseMovementButtonPressed(button)
		if self.state ~= "Idle" then
			return
		end
		
		self.state = "ActivatedMouse"
		
		BindMenu.SetEnabledRecursive(self , false)
		
		self.activatedButton = button:GetParent()
		
		self.mousePositionStart = Mouse:GetPosition()
		
		local label = self.activatedButton:GetDataObject("label")
		label:SetText("...")
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
		
		self.dirtySettings = true
	end
	
	function window:RequestSettings()
		Network:Send("BindMenuRequestSettings" , 12345)
	end
	
	function window:SaveSettings()
		local settings = {}
		
		-- Marshal every control into a format that will be stored in the database.
		for index , control in ipairs(Controls.controls) do
			local info = {
				name = control.name ,
				type = control.type ,
				value = tostring(control.value) ,
				module = module_name ,
			}
			table.insert(settings , info)
		end
		
		Network:Send("BindMenuSaveSettings" , settings)
	end
	
	window._Remove = window.Remove
	function window:Remove()
		Events:Unsubscribe(self.tickEvent)
		Network:Unsubscribe(self.receiveEvent)
		
		self:_Remove()
	end
	
	-- Events
	
	function window:LocalPlayerInput(args)
		-- Block mouse actions if we're not using a gamepad.
		if Game:GetSetting(GameSetting.GamepadInUse) == 0 then
			for index , action in ipairs(BindMenu.blockedMouseActions) do
				if args.input == action then
					return true
				end
			end
		end
		
		if args.state > 0.5 then
			-- PostTick handles these later.
			self.activeAction = args.input
			self.ticksSinceAction = 0
		end
		
		return true
	end
	
	function window:KeyUp(args)
		local control = self.activatedButton:GetDataObject("control")
		
		control.type = "Key"
		control.value = args.key
		control.valueString = InputNames.GetKeyName(args.key)
		
		self:Assign(self.activatedButton)
		self.activatedButton = nil
		
		self.dirtySettings = true
	end
	
	function window:MouseButtonUp(args)
		local control = self.activatedButton:GetDataObject("control")
		
		control.type = "MouseButton"
		control.value = args.button
		control.valueString = string.format("Mouse%i" , args.button)
		
		self:Assign(self.activatedButton)
		self.activatedButton = nil
		
		self.dirtySettings = true
	end
	
	function window:MouseScroll(args)
		local control = self.activatedButton:GetDataObject("control")
		
		control.type = "MouseWheel"
		control.value = math.clamp(args.delta , -1 , 1)
		if control.value == 1 then
			control.valueString = "Mouse wheel up"
		else
			control.valueString = "Mouse wheel down"
		end
		
		self:Assign(self.activatedButton)
		self.activatedButton = nil
		
		self.dirtySettings = true
	end
	
	function window:PostTick()
		if self.state == "Activated" then
			-- If we've tried to assign an action a few ticks ago, actually assign it. Actions are
			-- delayed so that keys and mouse buttons have preference.
			if self.activeAction then
				self.ticksSinceAction = self.ticksSinceAction + 1
				if self.ticksSinceAction >= 3 then
					local control = self.activatedButton:GetDataObject("control")
					control.type = "Action"
					control.value = self.activeAction
					control.valueString = InputNames.GetActionName(self.activeAction)
					
					self:Assign(self.activatedButton)
					self.activatedButton = nil
					
					self.dirtySettings = true
					
					self.activeAction = nil
				end
			-- Check for mouse movement.
			else
				local delta = Mouse:GetPosition() - self.mousePositionStart
				local requiredDistance = 12
				
				local Assign = function(value , valueString)
					local control = self.activatedButton:GetDataObject("control")
					
					control.type = "MouseMovement"
					control.value = value
					control.valueString = valueString
					
					self:Assign(self.activatedButton)
					self.activatedButton = nil
					
					self.dirtySettings = true
				end
				
				if delta.x > requiredDistance then
					Assign(">" , "Mouse right")
				elseif delta.x < -requiredDistance then
					Assign("<" , "Mouse left")
				elseif delta.y > requiredDistance then
					Assign("v" , "Mouse down")
				elseif delta.y < -requiredDistance then
					Assign("^" , "Mouse up")
				end
			end
		end
		
		-- Give the server our settings periodically.
		if self.saveTimer:GetSeconds() > 7 then
			self.saveTimer:Restart()
			
			if self.dirtySettings then
				self.dirtySettings = false
				self:SaveSettings()
			end
		end
	end
	
	function window:ReceiveSettings(settingsString)
		if settingsString == "Empty" then
			return
		end
		
		local settings = settingsString:split("\n")
		for index , setting in ipairs(settings) do
			local control = {}
			local module , name , type , value = table.unpack(setting:split("|"))
			control.name = name
			control.type = type
			if control.type == "Unassigned" then
				control.valueString = "Unassigned"
			elseif control.type == "Action" then
				control.value = tonumber(value) or -1
				control.valueString = InputNames.GetActionName(control.value)
			elseif control.type == "Key" then
				control.value = tonumber(value) or -1
				control.valueString = InputNames.GetKeyName(control.value)
			elseif control.type == "MouseButton" then
				control.value = tonumber(value) or -1
				control.valueString = ("Mouse%i"):format(value)
			elseif control.type == "MouseWheel" then
				control.value = tonumber(value) or 0
				if control.value == 1 then
					control.valueString = "Mouse wheel up"
				elseif control.value == -1 then
					control.valueString = "Mouse wheel down"
				else
					control.valueString = "Mouse wheel wat"
				end
			elseif control.type == "MouseMovement" then
				control.value = value
				control.valueString = ({
					[">"] = "Mouse right" ,
					["<"] = "Mouse left" ,
					["v"] = "Mouse down" ,
					["^"] = "Mouse up" ,
				})[control.value]
			end
			
			for index , button in ipairs(self.buttons) do
				local controlToAssign = button:GetDataObject("control")
				if controlToAssign.name == control.name then
					button:SetDataObject("control" , control)
					self:Assign(button)
					break
				end
			end
		end
	end
	
	window.tickEvent = Events:Subscribe("PostTick" , window , window.PostTick)
	window.receiveEvent = Network:Subscribe(
		"BindMenuReceiveSettings" , window , window.ReceiveSettings
	)
	
	return window
end

BindMenu.SetEnabledRecursive = function(window , enabled)
	window:SetEnabled(enabled)
	
	local children = window:GetChildren()
	for index , child in ipairs(children) do
		BindMenu.SetEnabledRecursive(child , enabled)
	end
end
