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
	
	self.coursesList = ListBox.Create(groupBoxCourseSelect)
	self.coursesList:SetDock(GwenPosition.Fill)
	self.coursesList:SetAutoHideBars(false)
	self.coursesList:Subscribe("RowSelected" , self , self.CourseSelected)
	self.coursesList:AddItem("Requesting course list...")
	self.coursesList:SetDataBool("isValid" , false)
	
	self.courseGroupBox = RaceMenu.CreateGroupBox(page)
	self.courseGroupBox:SetDock(GwenPosition.Fill)
	self.courseGroupBox:SetText("No course selected")
	self.courseGroupBox:SetColorDark()
	
	self.rightArea = BaseWindow.Create(self.courseGroupBox)
	self.rightArea:SetDock(GwenPosition.Fill)
	-- This entire area is hidden until a course is selected.
	self.rightArea:SetVisible(false)
	
	local courseInfoArea = BaseWindow.Create(self.rightArea)
	courseInfoArea:SetDock(GwenPosition.Top)
	courseInfoArea:SetHeight(28)
	
	self.courseInfoLabels = {}
	
	local CreateLabel = function(name)
		local base = BaseWindow.Create(courseInfoArea)
		base:SetMargin(Vector2(2 , 2) , Vector2(4 , 2))
		
		local title = Label.Create(base)
		title:SetDock(GwenPosition.Left)
		title:SetTextSize(16)
		title:SetText(name..": ")
		title:SizeToContents()
		
		local label = Label.Create(base)
		label:SetDock(GwenPosition.Left)
		label:SetTextSize(18)
		label:SetText("?????")
		label:SizeToContents()
		
		base:SizeToChildren()
		base:SetHeight(title:GetTextHeight())
		
		self.courseInfoLabels[name] = label
		
		return base
	end
	
	CreateLabel("Votes up"):SetDock(GwenPosition.Left)
	CreateLabel("Votes down"):SetDock(GwenPosition.Left)
	local timesPlayed = CreateLabel("Times played")
	timesPlayed:SetDock(GwenPosition.Left)
	timesPlayed:SetToolTip("Server-wide number of races ran on this course")
	
	self.courseInfoLabels["Votes up"]:SetTextColor(Color.FromHSV(105 , 0.5 , 1))
	self.courseInfoLabels["Votes down"]:SetTextColor(Color.FromHSV(0 , 0.5 , 1))
	
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
	self.recordsList:AddColumn("Rank" , 40)
	self.recordsList:AddColumn("Player")
	self.recordsList:AddColumn("Time" , 65)
	self.recordsList:AddColumn("Vehicle")
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
	if self.coursesList:GetDataBool("isValid") == false then
		return
	end
	
	local row = self.coursesList:GetSelectedRow()
	local courseInfo = row:GetDataObject("courseInfo")
	
	self.courseInfoLabels["Times played"]:SetText(string.format("%i" , courseInfo[3]))
	self.courseInfoLabels["Votes up"]:SetText(string.format("%i" , courseInfo[4]))
	self.courseInfoLabels["Votes down"]:SetText(string.format("%i" , courseInfo[5]))
	
	self.courseGroupBox:SetText(courseInfo[2])
	self.courseGroupBox:SetTextColor(RaceMenu.groupBoxColor)
	
	self.rightArea:SetVisible(true)
	
	self.recordsList:Clear()
	local row = self.recordsList:AddItem("")
	row:SetColumnCount(2)
	row:SetCellText(1 , "Requesting records...")
	
	self.raceMenu:AddRequest("RequestCourseRecords" , courseInfo[1])
end

-- Network events

function CoursesTab:ReceiveCourseList(courses)
	self.coursesList:Clear()
	
	if #courses > 0 then
		for index , course in ipairs(courses) do
			local row = self.coursesList:AddItem(course[2])
			row:SetDataObject("courseInfo" , course)
		end
		self.coursesList:SetDataBool("isValid" , true)
	else
		self.coursesList:AddItem("No courses found")
		self.coursesList:SetDataBool("isValid" , false)
	end
end

function CoursesTab:ReceiveCourseRecords(records)
	self.recordsList:Clear()
	
	for index , record in ipairs(records) do
		local row = self.recordsList:AddItem(string.format("%i" , index))
		row:SetColumnCount(4)
		row:SetCellText(1 , record.playerName)
		row:SetCellText(2 , Utility.LapTimeString(record.time))
		local vehicleName = "On-foot"
		if record.vehicle > 0 then
			vehicleName = VehicleList[record.vehicle].name
		end
		row:SetCellText(3 , vehicleName)
	end
end
