
VirtualKey.Apostrophe = 222 -- wut

CEMainMenu.size = Vector2(0.1125 , 0.39)
CEMainMenu.elementHeight = 0.0625
CEMainMenu.textColor = Color(128 , 128 , 128 , 255):ToCEGUIString()

function CEMainMenu:__init(courseEditor)
	
	self.courseEditor = courseEditor
	self.isActive = false
	
	self.window = Window.Create("GWEN/FrameWindow" , "MainMenu" , RootWindow)
	self.window:SetText(Color(224 , 224 , 224 , 255):ToCEGUIString().."Course Editor")
	self.window:SetSizeRel(CEMainMenu.size)
	self.window:SetPositionRel(Vector2(0.01 , 0.25))
	self.window:SetCloseButtonEnabled(false)
	self.window:SetRollupEnabled(false)
	
	-- Used in content addition methods below.
	self.currentY = 0
	
	-- Used to align tool window with its respective button.
	self.currentButtonName = nil
	
	self:AddMiscText("Hold q or ' to focus")
	
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
	EventSub("Render")
	
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
	
	if self[buttonName] then
		window:Subscribe("Clicked" , function() self:ButtonPressed(buttonName) end)
	else
		window:Subscribe("Clicked" , function() end)
	end
	
	self["button"..buttonName] = window
	
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

function CEMainMenu:CreateToolWindow(windowName)
	
	self.toolWindow = Window.Create(
		"GWEN/FrameWindow" ,
		-- "ToolWindow-"..windowName ,
		"ToolWindow" ,
		RootWindow
	)
	self.toolWindow:SetText(windowName)
	-- (Position is spammed during Render.)
	self.toolWindow:SetSizeRel(Vector2(0.2 , 0.25))
	self.toolWindow:SetCloseButtonEnabled(false)
	self.toolWindow:SetRollupEnabled(false)
	
end

function CEMainMenu:DestroyToolWindow()
	
	if self.toolWindow then
		self.toolWindow:Remove()
		self.toolWindow = nil
	end
	
end

--
-- Button events
--

function CEMainMenu:ButtonPressed(buttonName)
	
	-- Second click, remove window and reset tool.
	if self.toolWindow and self.currentButtonName == buttonName then
		self:DestroyToolWindow()
		self["button"..buttonName]:SetText(buttonName)
		self.currentButtonName = nil
		self.courseEditor:SetTool()
	-- First click.
	else
		if self.currentButtonName then
			self["button"..self.currentButtonName]:SetText(self.currentButtonName)
		end
		self.currentButtonName = buttonName
		self["button"..buttonName]:SetText("»»"..buttonName.."««")
		self[buttonName](self)
	end
	
end

CEMainMenu["Checkpoint"] = function(self)
	
	self.courseEditor:SetTool("CheckpointSpawner")
	self.courseEditor.currentTool.isEnabled = false
	
	self:DestroyToolWindow()
	self:CreateToolWindow("Checkpoint Spawner")
	
	local button = Window.Create("GWEN/Button" , "TestButton" , self.toolWindow)
	button:SetText("tets")
	button:SetPositionRel(Vector2(0 , self.currentY))
	button:SetSizeRel(Vector2(0.5 , 0.1))
	
end

CEMainMenu["Vehicle spawn"] = function(self)
	
	self.courseEditor:SetTool("VehicleSpawner")
	self.courseEditor.currentTool.isEnabled = false
	
	self:DestroyToolWindow()
	self:CreateToolWindow("Vehicle Spawner")
	
	local button = Window.Create("GWEN/Button" , "TestButton" , self.toolWindow)
	button:SetText("spawn dat vehicle namsayin")
	button:SetPositionRel(Vector2(0 , self.currentY))
	button:SetSizeRel(Vector2(0.5 , 0.1))
	
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
	
	if
		(args.key == VirtualKey.Apostrophe or args.key == string.byte('Q')) and
		not self.isActive
	then
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
	
	if args.key == VirtualKey.Apostrophe or args.key == string.byte('Q') then
		self.isActive = false
		if self.courseEditor.currentTool then
			self.courseEditor.currentTool.isEnabled = true
		end
		MouseCursor:SetVisible(false)
		self.window:SetText(Color(224 , 224 , 224 , 255):ToCEGUIString().."Course Editor")
	end
	
end

function CEMainMenu:Render()
	
	if self.toolWindow then
		local pos = self:GetWindowPositionAbs() + Vector2(CEMainMenu.size.x * Render.Width + 0 , 0)
		local buttonY = pos.y
		pos.y = (
			pos.y +
			(
				self["button"..self.currentButtonName]:GetPositionRel().y *
				CEMainMenu.size.y *
				Render.Height
			)
		)
		-- Compensate for title bar.
		pos.y = pos.y + 0.02 * Render.Height
		self.toolWindow:SetPositionAbs(pos)
	end
	
end


-- Utility debug chat print function
PrintChat = function(message)
	
	Client:ChatMessage(message , Color(64 , 192 , 192))
	
end
