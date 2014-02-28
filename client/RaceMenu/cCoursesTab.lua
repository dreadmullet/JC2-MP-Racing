class("CoursesTab")

function CoursesTab:__init() ; EGUSM.SubscribeUtility.__init(self)
	self.recordsList = nil
	
	self:NetworkSubscribe("ReceiveCourseList")
	self:NetworkSubscribe("ReceiveCourseRecords")
	
	-- Create the tab.
	
	self.tabButton = RaceMenu.instance.tabControl:AddPage("Course records")
	
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
	
	local CreateLabel = function(name)
		local base = BaseWindow.Create()
		base:SetMargin(Vector2(2 , 3) , Vector2(8 , 0))
		
		local title = Label.Create(base)
		title:SetDock(GwenPosition.Left)
		title:SetTextSize(16)
		title:SetText(name..": ")
		title:SizeToContents()
		
		local label = Label.Create(base)
		label:SetDock(GwenPosition.Left)
		label:SetTextSize(16)
		label:SetText("?????")
		label:SizeToContents()
		
		base:SizeToChildren()
		base:SetHeight(title:GetTextHeight())
		
		return base
	end
	
	local timesPlayed = CreateLabel("Times played")
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
	RaceMenu.instance:AddRequest("RequestCourseList")
end

-- GWEN events

function CoursesTab:CourseSelected()
	-- Make sure the course list has actual courses, and not "Requesting course list" or whatever.
	if self.coursesList:GetDataBool("isValid") == false then
		return
	end
	
	local row = self.coursesList:GetSelectedRow()
	local courseInfo = row:GetDataObject("courseInfo")
	
	self.courseVoteControl:SetCourseInfo(courseInfo)
	
	self.courseGroupBox:SetText(courseInfo[2])
	self.courseGroupBox:SetTextColor(RaceMenu.groupBoxColor)
	
	self.rightArea:SetVisible(true)
	
	self.recordsList:Clear()
	local row = self.recordsList:AddItem("")
	row:SetColumnCount(2)
	row:SetCellText(1 , "Requesting records...")
	
	RaceMenu.instance:AddRequest("RequestCourseRecords" , courseInfo[1])
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
