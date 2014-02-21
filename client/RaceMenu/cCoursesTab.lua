class("CoursesTab")

CoursesTab.titleColor = Color.FromHSV(25 , 0.95 , 0.85)

function CoursesTab:__init(raceMenu) ; EGUSM.SubscribeUtility.__init(self)
	self.raceMenu = raceMenu
	
	self:NetworkSubscribe("ReceiveCourseList")
	
	-- Create the tab.
	
	self.tabButton = self.raceMenu.tabControl:AddPage("Course records")
	
	local page = self.tabButton:GetPage()
	page:SetPadding(Vector2(2 , 2) , Vector2(2 , 2))
	
	local groupBoxCourseSelect = RaceMenu.CreateGroupBox(page)
	groupBoxCourseSelect:SetDock(GwenPosition.Left)
	groupBoxCourseSelect:SetText("Select course")
	groupBoxCourseSelect:SetWidth(250)
	
	self.listBox = ListBox.Create(groupBoxCourseSelect)
	self.listBox:SetDock(GwenPosition.Fill)
	self.listBox:SetAutoHideBars(false)
	
	local todoLabel = Label.Create(page)
	todoLabel:SetDock(GwenPosition.Fill)
	todoLabel:SetTextSize(TextSize.Large)
	todoLabel:SetAlignment(GwenPosition.Center)
	todoLabel:SetColorDark()
	todoLabel:SetText("TODO: Course map")
end

function CoursesTab:OnActivate()
	self.raceMenu:AddRequest("RequestCourseList")
end

-- Network events

function CoursesTab:ReceiveCourseList(courses)
	self.listBox:Clear()
	
	for index , course in ipairs(courses) do
		self.listBox:AddItem(course)
	end
end
