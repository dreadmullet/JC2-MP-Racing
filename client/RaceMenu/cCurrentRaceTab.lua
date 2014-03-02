class("CurrentRaceTab")

function CurrentRaceTab:__init() ; EGUSM.SubscribeUtility.__init(self)
	self:NetworkSubscribe("ReceiveCourseList")
	
	-- Create the tab.
	
	self.tabButton = RaceMenu.instance.tabControl:AddPage("Current race")
	
	self.page = self.tabButton:GetPage()
	self.page:SetPadding(Vector2(2 , 2) , Vector2(2 , 2))
	
	self.course = Race.instance.course
	
	local groupBoxCourse = RaceMenu.CreateGroupBox(self.page)
	groupBoxCourse:SetDock(GwenPosition.Top)
	groupBoxCourse:SetText(self.course.name)
	groupBoxCourse:SetHeight(60)
	
	self.courseVoteControl = RaceMenuUtility.CreateCourseVoteControl()
	self.courseVoteControl.base:SetParent(groupBoxCourse)
	self.courseVoteControl.base:SetDock(GwenPosition.Top)
end

function CurrentRaceTab:SetCourseInfo()
	for index , course in ipairs(RaceMenu.cache.courses) do
		if course[2] == self.course.name then
			self.courseVoteControl:SetCourseInfo(course)
			break
		end
	end
end

-- RaceMenu callbacks

function CurrentRaceTab:OnActivate()
	if RaceMenu.cache.courses == nil or RaceMenu.cache.personalCourseVotes == nil then
		RaceMenu.instance:AddRequest("RequestCourseList")
	else
		self:SetCourseInfo()
	end
end

function CurrentRaceTab:OnRemove()
	self:Destroy()
end

-- Network events

function CurrentRaceTab:ReceiveCourseList(coursesAndVotes)
	RaceMenu.cache.courses = coursesAndVotes[1]
	RaceMenu.cache.personalCourseVotes = coursesAndVotes[2]
	
	self:SetCourseInfo()
end
