
function CourseSettings:__init()
	
	Tool.__init(self)
	
	self.course = nil
	self.toolWindow = nil
	
	self.currentY = 0
	self.spacingY = settingsCE.gui.toolWindow.elementHeight
	self.leftX = 0
	self.centerX = 0.4
	
	self.radioGroupCourseType = PhilpaxSucks
	PhilpaxSucks = PhilpaxSucks + 1
	
end

-- This is called before our base class, Tool, is destroyed.
function CourseSettings:Destroy()
	
	-- Send course info to server.
	local courseInfo = {}
	courseInfo.name = self.course.name
	courseInfo.type = self.course.type
	courseInfo.numLaps = self.course.numLaps
	courseInfo.timeLimitSeconds = self.course.timeLimitSeconds
	Network:Send("CESetCourseInfo" , courseInfo)
	
end

function CourseSettings:CreateWindowElements()
	
	self.currentY = 0
	
	self:CreateNameEditbox()
	self:CreateLapsSelector()
	self:CreateTypeSelector()
	self:CreateTimeLimitSelector()
	
end

function CourseSettings:CreateNameEditbox()
	
	-- Label.
	self.labelName = Window.Create(
		"GWEN/StaticText" ,
		"labelName"..PhilpaxSucks ,
		self.toolWindow
	)
	PhilpaxSucks = PhilpaxSucks + 1
	self.labelName:SetPositionRel(Vector2(self.leftX , self.currentY))
	self.labelName:SetSizeRel(
		Vector2(self.centerX , settingsCE.gui.toolWindow.elementHeight)
	)
	self.labelName:SetText("Name")
	
	-- Editbox.
	self.editboxName = Editbox.Create("GWEN/Editbox" , "editboxName"..PhilpaxSucks , self.toolWindow)
	PhilpaxSucks = PhilpaxSucks + 1
	self.editboxName:SetPositionRel(Vector2(self.centerX , self.currentY))
	self.editboxName:SetSizeRel(
		Vector2((1 - self.centerX) , settingsCE.gui.toolWindow.elementHeight)
	)
	self.editboxName:SetText(self.course.name)
	self.editboxName:Subscribe("TextChanged" , self , self.NameChanged)
	
	self.currentY = self.currentY + self.spacingY
	
end

function CourseSettings:CreateLapsSelector()
	
	-- Label.
	self.labelNumLaps = Window.Create(
		"GWEN/StaticText" ,
		"labelNumLaps"..PhilpaxSucks ,
		self.toolWindow
	)
	PhilpaxSucks = PhilpaxSucks + 1
	self.labelNumLaps:SetPositionRel(Vector2(self.leftX , self.currentY))
	self.labelNumLaps:SetSizeRel(
		Vector2(self.centerX , settingsCE.gui.toolWindow.elementHeight)
	)
	self.labelNumLaps:SetText("Laps")
	
	-- Spinner.
	self.spinnerNumLaps = Spinner.Create("GWEN/Spinner" , "spinnerNumLaps"..PhilpaxSucks , self.toolWindow)
	PhilpaxSucks = PhilpaxSucks + 1
	self.spinnerNumLaps:SetPositionRel(Vector2(self.centerX , self.currentY))
	self.spinnerNumLaps:SetSizeRel(
		Vector2((1 - self.centerX) / 4 , settingsCE.gui.toolWindow.elementHeight)
	)
	self.spinnerNumLaps:SetValue(self.course.numLaps)
	self.spinnerNumLaps:SetMinValue(1)
	self.spinnerNumLaps:Subscribe("ValueChanged" , self , self.NumLapsChanged)
	
	self.currentY = self.currentY + self.spacingY
	
end

function CourseSettings:CreateTypeSelector()
	
	-- Label.
	self.labelType = Window.Create(
		"GWEN/StaticText" ,
		"labelType"..PhilpaxSucks ,
		self.toolWindow
	)
	PhilpaxSucks = PhilpaxSucks + 1
	self.labelType:SetPositionRel(Vector2(self.leftX , self.currentY))
	self.labelType:SetSizeRel(
		Vector2(self.centerX , settingsCE.gui.toolWindow.elementHeight)
	)
	self.labelType:SetText("Type")
	
	-- Radios.
	--
	-- Linear.
	self.radioLinear = Window.Create(
		"GWEN/RadioButton" ,
		"radioLinear"..PhilpaxSucks ,
		self.toolWindow
	)
	PhilpaxSucks = PhilpaxSucks + 1
	self.radioLinear:SetPositionRel(Vector2(self.centerX * 1.05 , self.currentY))
	self.radioLinear:SetSizeRel(
		Vector2((1 - self.centerX)/2 , settingsCE.gui.toolWindow.elementHeight)
	)
	self.radioLinear:SetText("Linear")
	self.radioLinear:SetGroupId(self.radioGroupCourseType)
	self.radioLinear:Subscribe(
		"SelectStateChanged" ,
		self ,
		self.TypeChanged
	)
	-- Circuit.
	self.radioCircuit = Window.Create(
		"GWEN/RadioButton" ,
		"radioCircuit"..PhilpaxSucks ,
		self.toolWindow
	)
	PhilpaxSucks = PhilpaxSucks + 1
	self.radioCircuit:SetPositionRel(Vector2(1 - (1 - self.centerX)/2 , self.currentY))
	self.radioCircuit:SetSizeRel(
		Vector2((1 - self.centerX)/2 , settingsCE.gui.toolWindow.elementHeight)
	)
	self.radioCircuit:SetText("Circuit")
	self.radioCircuit:SetGroupId(self.radioGroupCourseType)
	-- If this event is also subscribed, the event fires twice, but both times the radio button
	-- argument is the same. WTF CEGUI?
	-- self.radioCircuit:Subscribe(
		-- "SelectStateChanged" ,
		-- self ,
		-- self.TypeChanged
	-- )
	
	-- Enable radio buttons based on course.
	if self.course.type == "Linear" then
		self.radioLinear:SetSelected(true)
	else
		self.radioCircuit:SetSelected(true)
	end
	
	self.currentY = self.currentY + self.spacingY
	
end

function CourseSettings:CreateTimeLimitSelector()
	
	-- Label.
	self.labelTimeLimit = Window.Create(
		"GWEN/StaticText" ,
		"labelTimeLimit"..PhilpaxSucks ,
		self.toolWindow
	)
	PhilpaxSucks = PhilpaxSucks + 1
	self.labelTimeLimit:SetPositionRel(Vector2(self.leftX , self.currentY))
	self.labelTimeLimit:SetSizeRel(
		Vector2(self.centerX , settingsCE.gui.toolWindow.elementHeight)
	)
	self.labelTimeLimit:SetText("Time limit (mins)")
	
	-- Spinner.
	self.spinnerTimeLimit = Spinner.Create("GWEN/Spinner" , "spinnerTimeLimit"..PhilpaxSucks , self.toolWindow)
	PhilpaxSucks = PhilpaxSucks + 1
	self.spinnerTimeLimit:SetPositionRel(Vector2(self.centerX , self.currentY))
	self.spinnerTimeLimit:SetSizeRel(
		Vector2((1 - self.centerX) / 4 , settingsCE.gui.toolWindow.elementHeight)
	)
	self.spinnerTimeLimit:SetValue(self.course.timeLimitSeconds / 60)
	self.spinnerTimeLimit:SetMinValue(1)
	-- I want the step size to be 0.5, but it bugs out and doesn't show the decimal point.
	self.spinnerTimeLimit:SetStepSize(1)
	self.spinnerTimeLimit:Subscribe("ValueChanged" , self , self.TimeLimitChanged)
	
	self.currentY = self.currentY + self.spacingY
	
end

--
-- CEGUI Events.
--

function CourseSettings:NameChanged(args)
	
	self.course.name = args.window:GetText()
	
end

function CourseSettings:NumLapsChanged(args)
	
	self.course.numLaps = args.window:GetValue()
	
end

function CourseSettings:TypeChanged(args)
	
	if self.radioLinear:IsSelected() then
		self.course.type = "Linear"
	else
		self.course.type = "Circuit"
	end
	
end

function CourseSettings:TimeLimitChanged(args)
	
	self.course.timeLimitSeconds = math.floor(args.window:GetValue() + 0.5) * 60
	
end
