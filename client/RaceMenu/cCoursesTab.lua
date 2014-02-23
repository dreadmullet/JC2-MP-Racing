class("CoursesTab")

function CoursesTab:__init(raceMenu) ; EGUSM.SubscribeUtility.__init(self)
	self.raceMenu = raceMenu
	
	self.recordsList = nil
	
	self:NetworkSubscribe("ReceiveCourseList")
	self:NetworkSubscribe("ReceiveCourseRecords")
	
	-- Create the tab.
	
	self.tabButton = self.raceMenu.tabControl:AddPage("Course records")
	
	local page = self.tabButton:GetPage()
	page:SetPadding(Vector2(2 , 2) , Vector2(2 , 2))
	
	local groupBoxCourseSelect = RaceMenu.CreateGroupBox(page)
	groupBoxCourseSelect:SetDock(GwenPosition.Left)
	groupBoxCourseSelect:SetText("Select course")
	groupBoxCourseSelect:SetWidth(250)
	
	self.coursesListBox = ListBox.Create(groupBoxCourseSelect)
	self.coursesListBox:SetDock(GwenPosition.Fill)
	self.coursesListBox:SetAutoHideBars(false)
	self.coursesListBox:Subscribe("RowSelected" , self , self.CourseSelected)
	self.coursesListBox:AddItem("Requesting course list...")
	self.coursesListBox:SetDataBool("isValid" , false)
	
	self.courseGroupBox = RaceMenu.CreateGroupBox(page)
	self.courseGroupBox:SetDock(GwenPosition.Fill)
	self.courseGroupBox:SetText("No course selected")
	self.courseGroupBox:SetColorDark()
	
	self.rightArea = BaseWindow.Create(self.courseGroupBox)
	self.rightArea:SetDock(GwenPosition.Fill)
	self.rightArea:SetVisible(false)
	
	local topArea = BaseWindow.Create(self.rightArea)
	topArea:SetDock(GwenPosition.Top)
	topArea:SetHeight(50)
	topArea:SetVisible(true)
	
	self.tabControl = TabControl.Create(self.rightArea)
	self.tabControl:SetDock(GwenPosition.Fill)
	self.tabControl:SetTabStripPosition(GwenPosition.Top)
	
	self:CreateRecordsTab()
	self:CreateMapTab()
end

function CoursesTab:CreateRecordsTab()
	local tabButton = self.tabControl:AddPage("Records")
	
	local page = tabButton:GetPage()
	
	self.recordsList = SortedList.Create(page)
	self.recordsList:SetDock(GwenPosition.Fill)
	self.recordsList:AddColumn("Player")
	self.recordsList:AddColumn("Time" , 65)
	-- self.recordsList:AddColumn("Vehicle" , 65)
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

function CoursesTab:OnActivate()
	self.raceMenu:AddRequest("RequestCourseList")
end

-- GWEN events

function CoursesTab:CourseSelected()
	-- Make sure the course list has actual courses, and not "Requesting course list" or whatever.
	if self.coursesListBox:GetDataBool("isValid") == false then
		return
	end
	
	local row = self.coursesListBox:GetSelectedRow()
	local courseName = row:GetCellText(0)
	local courseHash = row:GetDataNumber("FileNameHash")
	
	self.raceMenu:AddRequest("RequestCourseRecords" , courseHash)
	
	self.courseGroupBox:SetText(courseName)
	self.courseGroupBox:SetTextColor(RaceMenu.groupBoxColor)
	
	self.rightArea:SetVisible(true)
	
	self.recordsList:Clear()
	self.recordsList:AddItem("Requesting records...")
end

-- Network events

function CoursesTab:ReceiveCourseList(courses)
	self.coursesListBox:Clear()
	
	if #courses > 0 then
		for index , course in ipairs(courses) do
			local row = self.coursesListBox:AddItem(course[2])
			row:SetDataNumber("FileNameHash" , course[1])
		end
		self.coursesListBox:SetDataBool("isValid" , true)
	else
		self.coursesListBox:AddItem("No courses found")
		self.coursesListBox:SetDataBool("isValid" , false)
	end
end

function CoursesTab:ReceiveCourseRecords(records)
	self.recordsList:Clear()
	
	for index , record in ipairs(records) do
		local row = self.recordsList:AddItem(record.playerName)
		row:SetColumnCount(2)
		row:SetCellText(1 , Utility.LapTimeString(record.time))
	end
end
