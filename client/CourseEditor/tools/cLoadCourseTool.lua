
function LoadCourseTool:__init()
	
	Tool.__init(self)
	
	self.toolWindow = nil
	self.courseName = ""
	
	self.currentY = 0
	self.spacingY = settingsCE.gui.toolWindow.elementHeight
	self.leftX = 0
	self.centerX = 0.4
	
end

function LoadCourseTool:CreateWindowElements()
	
	self.currentY = 0
	
	self:CreateCourseNameEditbox()
	self:CreateLoadCourseButton()
	
end

function LoadCourseTool:CreateCourseNameEditbox()
	
	-- Label.
	self.labelCourseName = Window.Create(
		"GWEN/StaticText" ,
		"labelCourseName"..PhilpaxSucks ,
		self.toolWindow
	)
	PhilpaxSucks = PhilpaxSucks + 1
	self.labelCourseName:SetPositionRel(Vector2(self.leftX , self.currentY))
	self.labelCourseName:SetSizeRel(
		Vector2(self.centerX , settingsCE.gui.toolWindow.elementHeight)
	)
	self.labelCourseName:SetText("Course name")
	
	-- Editbox.
	self.editboxCourseName = Editbox.Create("GWEN/Editbox" , "editboxCourseName"..PhilpaxSucks , self.toolWindow)
	PhilpaxSucks = PhilpaxSucks + 1
	self.editboxCourseName:SetPositionRel(Vector2(self.centerX , self.currentY))
	self.editboxCourseName:SetSizeRel(
		Vector2((1 - self.centerX) , settingsCE.gui.toolWindow.elementHeight)
	)
	self.editboxCourseName:SetText("")
	self.editboxCourseName:Subscribe("TextChanged" , self , self.CourseNameChanged)
	
	self.currentY = self.currentY + self.spacingY
	
end

function LoadCourseTool:CreateLoadCourseButton()
	
	self.buttonLoadCourse = Window.Create("GWEN/Button" , "buttonLoadCourse"..PhilpaxSucks , self.toolWindow)
	PhilpaxSucks = PhilpaxSucks + 1
	self.buttonLoadCourse:SetPositionRel(Vector2(0 , self.currentY))
	self.buttonLoadCourse:SetSizeRel(
		Vector2(1 , settingsCE.gui.toolWindow.elementHeight)
	)
	self.buttonLoadCourse:SetText("Load course")
	self.buttonLoadCourse:Subscribe("Clicked" , self , self.LoadCourse)
	
	self.currentY = self.currentY + self.spacingY
	
end

--
-- CEGUI Events.
--

function LoadCourseTool:CourseNameChanged(args)
	
	self.courseName = args.window:GetText()
	
end

function LoadCourseTool:LoadCourse(args)
	
	Network:Send("CELoadCourse" , self.courseName)
	
end
