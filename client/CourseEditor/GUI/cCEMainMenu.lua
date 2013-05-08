
VirtualKey.Apostrophe = 222 -- wut

CEMainMenu.elementHeight = 0.0625
CEMainMenu.textColor = Color(128 , 128 , 128 , 255):ToCEGUIString()

function CEMainMenu:__init(courseEditor)
	
	self.courseEditor = courseEditor
	self.isActive = false
	
	self.window = Window.Create("GWEN/FrameWindow" , "MainMenu" , RootWindow)
	self.window:SetText(Color(224 , 224 , 224 , 255):ToCEGUIString().."Course Editor")
	self.window:SetSizeRel(Vector2(0.1125 , 0.39))
	self.window:SetPositionRel(Vector2(0.01 , 0.25))
	self.window:SetCloseButtonEnabled(false)
	self.window:SetRollupEnabled(false)
	
	-- Used in content addition methods below.
	self.currentY = 0
	
	self:AddMiscText("Hold ' or q to focus")
	
	self:AddSection("Spawning")
	self:AddButton("Checkpoint")
	self:AddButton("Vehicle spawn")
	
	self:AddSection("Editing tools")
	self:AddButton("Remove")
	self:AddButton("Move/rotate")
	self:AddButton("Ordering")
	self:AddButton("Course settings")
	
	self:AddSection("Editor")
	self:AddButton("Editor settings")
	self:AddButton("Save course")
	self:AddButton("Load course")
	
	self.currentY = 1 - CEMainMenu.elementHeight
	self:AddButton("Exit")
	
	self.initialWindowPosition = self.window:GetPositionRel()
	self.initialWindowPosition = Vector2(
		math.floor(self.initialWindowPosition.x * Render.Width) ,
		math.floor(self.initialWindowPosition.y * Render.Height)
	)
	
	self.events = {}
	local EventSub = function(name)
		table.insert(self.events , Events:Subscribe(name , self , self[name]))
	end
	EventSub("LocalPlayerInput")
	EventSub("KeyDown")
	EventSub("KeyUp")
	
end

-- CEGUI is balls.
function CEMainMenu:GetWindowPositionAbs()
	
	return self.initialWindowPosition + self.window:GetPositionAbs()
	
end

function CEMainMenu:AddSection(sectionName)
	
	local window = Window.Create("GWEN/StaticText" , "MainMenuSection-"..sectionName , self.window)
	window:SetText(CEMainMenu.textColor..sectionName)
	window:SetPositionRel(Vector2(0 , self.currentY))
	window:SetSizeRel(Vector2(1 , CEMainMenu.elementHeight))
	
	self.currentY = self.currentY + CEMainMenu.elementHeight
	
end

function CEMainMenu:AddButton(buttonName)
	
	local window = Window.Create("GWEN/Button" , "MainMenuButton-"..buttonName , self.window)
	window:SetText(CEMainMenu.textColor..buttonName)
	window:SetPositionRel(Vector2(0 , self.currentY))
	window:SetSizeRel(Vector2(1 , CEMainMenu.elementHeight))
	
	-- Grey it out if function doesn't exist.
	if self[buttonName] == nil then
		window:SetEnabled(false)
	end
	
	window:Subscribe("Clicked" , self , self[buttonName] or function() end)
	
	self.currentY = self.currentY + CEMainMenu.elementHeight
	
end

function CEMainMenu:AddMiscText(text)
	
	local window = Window.Create("GWEN/StaticText" , "MainMenuMiscText-"..text , self.window)
	window:SetText(Color(255 , 255 , 255 , 192):ToCEGUIString()..text)
	window:SetPositionRel(Vector2(0 , self.currentY))
	window:SetSizeRel(Vector2(1 , CEMainMenu.elementHeight))
	
	self.currentY = self.currentY + CEMainMenu.elementHeight
	
end

function CEMainMenu:AddSpacer(size)
	
	self.currentY = self.currentY + size
	
end

function CEMainMenu:Destroy()
	
	-- Commenting this out for now, since it causes a crash.
	-- self.window:Remove()
	
	self.window:SetText(Color(240 , 20 , 20 , 255):ToCEGUIString().."Please reload script")
	
	-- Unsubscribe from all events.
	for n , event in ipairs(self.events) do
		Events:Unsubscribe(event)
	end
	
end

--
-- Button events
--

CEMainMenu["Checkpoint"] = function(self)
	
	self.courseEditor:SetTool("CheckpointSpawner")
	self.courseEditor.currentTool.isEnabled = false
	
end

CEMainMenu["Vehicle spawn"] = function(self)
	
	self.courseEditor:SetTool("VehicleSpawner")
	-- Disable the tool until the main menu is unfocused. Otherwise, the tool will pick up the input
	-- of the user's click.
	self.courseEditor.currentTool.isEnabled = false
	
end

CEMainMenu["Exit"] = function(self)
	
	Network:Send("CEExit")
	
end

--
-- Events
--

function CEMainMenu:LocalPlayerInput(args)
	
	return not self.isActive
	
end

function CEMainMenu:KeyDown(args)
	
	if args.key == VirtualKey.Apostrophe and not self.isActive then
		self.isActive = true
		if self.courseEditor.currentTool then
			self.courseEditor.currentTool.isEnabled = false
		end
		MouseCursor:SetVisible(true)
		MouseCursor:SetPosition(self:GetWindowPositionAbs())
		self.window:SetText(Color(180 , 255 , 170 , 255):ToCEGUIString().."Course Editor")
	end
	
end

function CEMainMenu:KeyUp(args)
	
	if args.key == VirtualKey.Apostrophe then
		self.isActive = false
		if self.courseEditor.currentTool then
			self.courseEditor.currentTool.isEnabled = true
		end
		MouseCursor:SetVisible(false)
		self.window:SetText(Color(224 , 224 , 224 , 255):ToCEGUIString().."Course Editor")
	end
	
end

-- Utility debug chat print function
PrintChat = function(message)
	
	Client:ChatMessage(message , Color(64 , 192 , 192))
	
end
