RaceMenuUtility = {}

-- Example:
-- 	Opinion: 70% [ 7 ] [ 3 ]
RaceMenuUtility.CreateCourseVoteControl = function()
	local miniClass = {}
	
	-- Button:SetToggleState fires the Toggle event. Argh.
	miniClass.isUpdating = false
	
	miniClass.courseNameHash = nil
	miniClass.courseName = nil
	miniClass.votesUp = nil
	miniClass.votesDown = nil
	miniClass.ourVote = nil
	
	miniClass.base = BaseWindow.Create("Course votes")
	
	local subBase = BaseWindow.Create(miniClass.base)
	subBase:SetSize(Vector2(1000 , 1000))
	
	local spacing = 4
	
	local opinion = Label.Create(subBase)
	opinion:SetMargin(Vector2(0 , 4) , Vector2(0 , 0))
	opinion:SetDock(GwenPosition.Left)
	opinion:SetTextSize(16)
	opinion:SetText("Opinion: ")
	opinion:SizeToContents()
	
	miniClass.percent = Label.Create(subBase)
	miniClass.percent:SetMargin(Vector2(2 , 4) , Vector2(spacing , 0))
	miniClass.percent:SetDock(GwenPosition.Left)
	miniClass.percent:SetTextSize(16)
	miniClass.percent:SetText("???% ")
	miniClass.percent:SizeToContents()
	
	miniClass.votesUpButton = Button.Create(subBase)
	miniClass.votesUpButton:SetMargin(Vector2(spacing , 0) , Vector2(spacing , 0))
	miniClass.votesUpButton:SetDock(GwenPosition.Left)
	miniClass.votesUpButton:SetText("??????")
	miniClass.votesUpButton:SizeToContents()
	miniClass.votesUpButton:SetTextNormalColor(Color.FromHSV(105 , 0.5 , 0.9))
	miniClass.votesUpButton:SetTextHoveredColor(Color.FromHSV(105 , 0.6 , 1))
	miniClass.votesUpButton:SetTextPressedColor(Color.FromHSV(105 , 0.7 , 0.9))
	miniClass.votesUpButton:SetToolTip("Likes")
	miniClass.votesUpButton:SetToggleable(true)
	miniClass.votesUpButton:SetEnabled(false)
	
	miniClass.votesDownButton = Button.Create(subBase)
	miniClass.votesDownButton:SetMargin(Vector2(spacing , 0) , Vector2(spacing , 0))
	miniClass.votesDownButton:SetDock(GwenPosition.Left)
	miniClass.votesDownButton:SetText("??????")
	miniClass.votesDownButton:SizeToContents()
	miniClass.votesDownButton:SetTextNormalColor(Color.FromHSV(0 , 0.5 , 0.9))
	miniClass.votesDownButton:SetTextHoveredColor(Color.FromHSV(0 , 0.6 , 1))
	miniClass.votesDownButton:SetTextPressedColor(Color.FromHSV(0 , 0.7 , 0.9))
	miniClass.votesDownButton:SetToolTip("Dislikes")
	miniClass.votesDownButton:SetToggleable(true)
	miniClass.votesDownButton:SetEnabled(false)
	
	subBase:SizeToChildren()
	subBase:SetHeight(opinion:GetTextHeight() + 4)
	
	miniClass.base:SizeToChildren()
	
	-- Functions
	
	function miniClass:SetCourseInfo(courseInfo)
		self.courseNameHash = courseInfo[1]
		self.courseName = courseInfo[2]
		self.votesUp = courseInfo[4]
		self.votesDown = courseInfo[5]
		
		self.ourVote = VoteType.None
		for index , vote in ipairs(RaceMenu.cache.personalCourseVotes) do
			if vote[1] == self.courseNameHash then
				self.ourVote = vote[2]
				break
			end
		end
		
		self:Update()
	end
	
	function miniClass:Update()
		miniClass.isUpdating = true
		
		self.votesUpButton:SetText(string.format("%i" , self.votesUp))
		self.votesDownButton:SetText(string.format("%i" , self.votesDown))
		
		if self.votesUp + self.votesDown == 0 then
			self.percent:SetText("N/A")
		else
			local percent = (self.votesUp / (self.votesUp + self.votesDown)) * 100
			percent = math.floor(percent + 0.5)
			self.percent:SetText(string.format("%i%%" , percent))
		end
		
		self.votesUpButton:SetEnabled(true)
		self.votesDownButton:SetEnabled(true)
		
		self.votesUpButton:SetToggleState(self.ourVote == VoteType.Up)
		self.votesDownButton:SetToggleState(self.ourVote == VoteType.Down)
		
		self.isUpdating = false
	end
	
	-- Events
	
	function miniClass:Voted(button)
		if self.isUpdating then
			return
		end
		
		local voteType
		
		if button == self.votesUpButton then
			if button:GetToggleState() == true then
				voteType = VoteType.Up
			else
				voteType = VoteType.RemoveUp
			end
		else
			if button:GetToggleState() == true then
				voteType = VoteType.Down
			else
				voteType = VoteType.RemoveDown
			end
		end
		
		RaceMenu.instance:AddRequest("VoteCourse" , {self.courseNameHash , voteType})
	end
	
	miniClass.votesUpButton:Subscribe("Toggle" , miniClass , miniClass.Voted)
	miniClass.votesDownButton:Subscribe("Toggle" , miniClass , miniClass.Voted)
	
	-- Network events
	
	function miniClass:VotedCourse(args)
		local courseHash = args[1]
		local voteType = args[2]
		local player = args[3]
		local newVotesUp = args[4]
		local newVotesDown = args[5]
		
		if self.courseNameHash and courseHash == self.courseNameHash then
			self.votesUp = newVotesUp
			self.votesDown = newVotesDown
			
			if player == LocalPlayer then
				self.ourVote = voteType
			end
			
			self:Update()
		end
	end
	
	Network:Subscribe("VotedCourse" , miniClass , miniClass.VotedCourse)
	
	return miniClass
end
