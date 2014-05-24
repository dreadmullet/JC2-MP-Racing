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
	window.buttons = {}
	window.state = "Idle"
	window.eventInput = nil
	window.eventKeyUp = nil
	window.eventMouseButtonUp = nil
	window.eventPostTick = nil
	window.activatedButton = nil
	window.allowMouse = false
	window.receiveEvent = nil
	window.tickEvent = nil
	window.dirtySettings = false
	window.saveTimer = Timer()
	-- These two are used to delay Actions so it prefers keys or mouse buttons.
	window.activeAction = nil
	window.ticksSinceAction = 0
	
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
		table.insert(self.buttons , button)
		
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
			Events:Unsubscribe(self.eventMouseUp)
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
		
		self.eventInput = Events:Subscribe("LocalPlayerInput" , self , self.LocalPlayerInput)
		self.eventKeyUp = Events:Subscribe("KeyUp" , self , self.KeyUp)
		self.eventMouseUp = Events:Subscribe("MouseUp" , self , self.MouseButtonUp)
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
		local settings = ""
		
		-- Marshal every control into a format that will be stored in the database.
		for index , control in ipairs(Controls.controls) do
			local type = "0"
			if control.type == "Action" then
				type = "1"
			elseif control.type == "Key" then
				type = "2"
			elseif control.type == "MouseButton" then
				type = "3"
			end
			settings = settings..control.name.."|"..type.."|"..tostring(control.value).."\n"
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
		if self.allowMouse == false then
			for index , action in ipairs(BindMenu.blockedMouseActions) do
				if args.input == action then
					return true
				end
			end
		end
		
		self.activeAction = args.input
		self.ticksSinceAction = 0
		
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
	
	function window:PostTick()
		-- If we've tried to assign an action a few ticks ago, actually assign it. Actions are delayed
		-- so that keys and mouse buttons have preference.
		if self.state == "Activated" and self.activeAction then
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
		end
		
		-- Give the server our settings periodically.
		if self.saveTimer:GetSeconds() > 9 then
			self.saveTimer:Restart()
			
			if self.dirtySettings then
				self.dirtySettings = false
				self:SaveSettings()
			end
		end
	end
	
	function window:ReceiveSettings(settings)
		if settings == "Empty" then
			return
		end
		
		local settingsTable = settings:split("\n")
		for index , setting in ipairs(settingsTable) do
			if setting:len() < 4 then
				goto continue
			end
			
			local control = {}
			local name , type , value = table.unpack(setting:split("|"))
			control.name = name
			if type == "0" then
				control.type = "Unassigned"
				control.value = -1
				control.valueString = "Unassigned"
			elseif type == "1" then
				control.type = "Action"
				control.value = tonumber(value) or -1
				control.valueString = InputNames.GetActionName(control.value)
			elseif type == "2" then
				control.type = "Key"
				control.value = tonumber(value) or -1
				control.valueString = InputNames.GetKeyName(control.value)
			elseif type == "3" then
				control.type = "MouseButton"
				control.value = tonumber(value) or -1
				control.valueString = ("Mouse%i"):format(value)
			end
			
			for index , button in ipairs(self.buttons) do
				local controlToAssign = button:GetDataObject("control")
				if controlToAssign.name == control.name then
					button:SetDataObject("control" , control)
					self:Assign(button)
					break
				end
			end
			
			::continue::
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
