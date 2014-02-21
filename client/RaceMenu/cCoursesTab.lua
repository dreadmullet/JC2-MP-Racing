class("CoursesTab")

CoursesTab.titleColor = Color.FromHSV(25 , 0.95 , 0.85)

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
	
	self.tabControl = TabControl.Create(page)
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
	self.recordsList:AddColumn("Time" , 75)
	-- self.recordsList:AddColumn("Vehicle")
	
	self.recordsList:AddItem("No course selected")
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
	local courseName = self.coursesListBox:GetSelectedRow():GetCellText(0)
	
	self.raceMenu:AddRequest("RequestCourseRecords" , courseName)
	
	self.recordsList:Clear()
	self.recordsList:AddItem("Requesting data...")
end

-- Network events

function CoursesTab:ReceiveCourseList(courses)
	self.coursesListBox:Clear()
	
	for index , course in ipairs(courses) do
		self.coursesListBox:AddItem(course)
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
