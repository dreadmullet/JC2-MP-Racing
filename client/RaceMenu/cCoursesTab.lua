class("CoursesTab")

function CoursesTab:__init() ; TabBase.__init(self , "Courses")
	self.recordsList = nil
	self.recordsIndex = nil
	self.selectedCourseInfo = nil
	self.previousRecordsButton = nil
	self.topRecordsButton = nil
	self.nextRecordsButton = nil
	
	local groupBoxCourseSelect = RaceMenu.CreateGroupBox(self.page)
	groupBoxCourseSelect:SetDock(GwenPosition.Left)
	groupBoxCourseSelect:SetWidth(250)
	groupBoxCourseSelect:SetText("Select course")
	
	self.coursesList = ListBox.Create(groupBoxCourseSelect)
	self.coursesList:SetDock(GwenPosition.Fill)
	self.coursesList:SetAutoHideBars(false)
	self.coursesList:Subscribe("RowSelected" , self , self.CourseSelected)
	self.coursesList:AddItem("Requesting course list...")
	self.coursesList:SetDataBool("isValid" , false)
	
	self.courseGroupBox = RaceMenu.CreateGroupBox(self.page)
	self.courseGroupBox:SetDock(GwenPosition.Fill)
	self.courseGroupBox:SetText("No course selected")
	self.courseGroupBox:SetColorDark()
	
	self.rightArea = BaseWindow.Create(self.courseGroupBox)
	self.rightArea:SetDock(GwenPosition.Fill)
	-- This entire area is hidden until a course is selected.
	self.rightArea:SetVisible(false)
	
	local courseInfoArea = BaseWindow.Create(self.rightArea)
	courseInfoArea:SetDock(GwenPosition.Top)
	courseInfoArea:SetHeight(29)
	
	local cells = {}
	
	local CreateCell = function()
		local cell = Rectangle.Create(courseInfoArea)
		cell:SetPadding(Vector2(4 , 3) , Vector2(4 , 0))
		cell:SetDock(GwenPosition.Left)
		cell:SetSize(Vector2(1000 , 1000))
		
		local color
		if #cells % 2 == 0 then
			color = Color.FromHSV(0 , 0 , 0.75)
		else
			color = Color.FromHSV(0 , 0 , 0)
		end
		color.a = 24
		cell:SetColor(color)
		
		table.insert(cells , cell)
	end
	
	CreateCell()
	CreateCell()
	
	local timesPlayed , title
	timesPlayed , title , self.timesPlayedLabel = RaceMenuUtility.CreateTitledLabel("Times played")
	timesPlayed:SetParent(cells[1])
	timesPlayed:SetDock(GwenPosition.Left)
	timesPlayed:SetToolTip("Server-wide number of races ran on this course")
	
	self.courseVoteControl = RaceMenuUtility.CreateCourseVoteControl()
	self.courseVoteControl.base:SetParent(cells[2])
	self.courseVoteControl.base:SetDock(GwenPosition.Left)
	
	cells[1]:SizeToChildren()
	cells[2]:SizeToChildren()
	
	self.tabControl = TabControl.Create(self.rightArea)
	self.tabControl:SetMargin(Vector2(0 , 4) , Vector2(0 , 0))
	self.tabControl:SetDock(GwenPosition.Fill)
	self.tabControl:SetTabStripPosition(GwenPosition.Top)
	
	self:CreateRecordsTab()
	self:CreateMapTab()
end

function CoursesTab:CreateRecordsTab()
	local tabButton = self.tabControl:AddPage("Records")
	
	self.recordsPage = tabButton:GetPage()
	
	self.recordsList = SortedList.Create(self.recordsPage)
	self.recordsList:SetMargin(Vector2(0 , 0) , Vector2(0 , 4))
	self.recordsList:SetDock(GwenPosition.Fill)
	self.recordsList:AddColumn("Rank" , 40)
	self.recordsList:AddColumn("Player")
	self.recordsList:AddColumn("Time" , 65)
	self.recordsList:AddColumn("Vehicle")
	
	local buttonsBase = BaseWindow.Create(self.recordsPage)
	buttonsBase:SetDock(GwenPosition.Bottom)
	buttonsBase:SetHeight(24)
	
	local CreateButton = function(text , dock)
		local button = Button.Create(buttonsBase)
		if dock ~= GwenPosition.Right then
			button:SetMargin(Vector2(0 , 0) , Vector2(40 , 0))
		end
		button:SetPadding(Vector2(2 , 0) , Vector2(2 , 0))
		button:SetDock(dock)
		button:SetText(text)
		button:SizeToContents()
		button:SetEnabled(false)
		button:Subscribe("Press" , self , self.RecordButtonPressed)
		
		return button
	end
	
	self.previousRecordsButton = CreateButton("Previous 10" , GwenPosition.Left)
	self.topRecordsButton = CreateButton("Top 10" , GwenPosition.Left)
	self.nextRecordsButton = CreateButton("Next 10" , GwenPosition.Right)
end

function CoursesTab:CreateMapTab()
	local tabButton = self.tabControl:AddPage("Map")
	
	local page = tabButton:GetPage()
	
	local todoLabel = Label.Create(page)
	todoLabel:SetDock(GwenPosition.Fill)
	todoLabel:SetTextSize(TextSize.Large)
	todoLabel:SetAlignment(GwenPosition.Center)
	todoLabel:SetColorDark()
	todoLabel:SetText("TODO")
end

function CoursesTab:SetRecordButtonsEnabled(enabled)
	self.previousRecordsButton:SetEnabled(enabled)
	self.topRecordsButton:SetEnabled(enabled)
	self.nextRecordsButton:SetEnabled(enabled)
end

-- Called when we receive the course list or when we're activated and already have the list cached.
function CoursesTab:FillCourseList()
	self.coursesList:Clear()
	
	if #RaceMenu.cache.courses > 0 then
		for index , course in ipairs(RaceMenu.cache.courses) do
			local row = self.coursesList:AddItem(course[2])
			row:SetDataObject("courseInfo" , course)
		end
		self.coursesList:SetDataBool("isValid" , true)
	else
		self.coursesList:AddItem("No courses found")
		self.coursesList:SetDataBool("isValid" , false)
	end
end

-- RaceMenu callbacks

function CoursesTab:OnActivate()
	self:NetworkSubscribe("ReceiveCourseRecords")
	
	if RaceMenu.cache.courses == nil or RaceMenu.cache.personalCourseVotes == nil then
		self:NetworkSubscribe("ReceiveCourseList")
		RaceMenu.instance:AddRequest("RequestCourseList")
	else
		self:FillCourseList()
	end
end

function CoursesTab:OnDeactivate()
	self:NetworkUnsubscribeAll()
end

-- GWEN events

function CoursesTab:CourseSelected()
	-- Make sure the course list has actual courses, and not "Requesting course list" or whatever.
	if self.coursesList:GetDataBool("isValid") == false then
		return
	end
	
	local row = self.coursesList:GetSelectedRow()
	local courseInfo = row:GetDataObject("courseInfo")
	self.selectedCourseInfo = courseInfo
	
	self.courseGroupBox:SetText(courseInfo[2])
	self.courseGroupBox:SetTextColor(RaceMenu.groupBoxColor)
	
	self.rightArea:SetVisible(true)
	
	self.timesPlayedLabel:SetText(string.format("%i" , courseInfo[3]))
	
	self.courseVoteControl:SetCourseInfo(courseInfo)
	
	self.recordsList:Clear()
	local row = self.recordsList:AddItem("")
	row:SetColumnCount(2)
	row:SetCellText(1 , "Requesting records...")
	
	self.recordsIndex = 1
	RaceMenu.instance:AddRequest("RequestCourseRecords" , {courseInfo[1] , 1})
	
	self:SetRecordButtonsEnabled(false)
end

function CoursesTab:RecordButtonPressed(button)
	if button == self.previousRecordsButton then
		self.recordsIndex = self.recordsIndex - 10
	elseif button == self.nextRecordsButton then
		self.recordsIndex = self.recordsIndex + 10
	elseif button == self.topRecordsButton then
		self.recordsIndex = 1
	end
	
	if self.recordsIndex < 1 then
		self.recordsIndex = 1
	end
	
	RaceMenu.instance:AddRequest(
		"RequestCourseRecords" ,
		{self.selectedCourseInfo[1] , self.recordsIndex}
	)
	self:SetRecordButtonsEnabled(false)
end

-- Network events

function CoursesTab:ReceiveCourseList(coursesAndVotes)
	RaceMenu.cache.courses = coursesAndVotes[1]
	RaceMenu.cache.personalCourseVotes = coursesAndVotes[2]
	
	self:FillCourseList()
end

function CoursesTab:ReceiveCourseRecords(args)
	local records = args[1]
	local startIndex = args[2]
	
	self.recordsList:Clear()
	
	for index , record in ipairs(records) do
		local row = self.recordsList:AddItem(string.format("%i" , startIndex + index - 1))
		row:SetColumnCount(4)
		row:SetCellText(1 , record.playerName)
		row:SetCellText(2 , Utility.LapTimeString(record.time))
		local vehicleName = "On-foot"
		if record.vehicle > 0 then
			vehicleName = VehicleList[record.vehicle].name
		end
		row:SetCellText(3 , vehicleName)
	end
	
	self:SetRecordButtonsEnabled(true)
end
