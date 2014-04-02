RaceMenuUtility = {}

-- Example:
-- 	Opinion: 70% [ 7 ] [ 3 ]
RaceMenuUtility.CreateCourseVoteControl = function()
	local self = {}
	
	-- Button:SetToggleState fires the Toggle event. Argh.
	self.isUpdating = false
	
	self.courseNameHash = nil
	self.courseName = nil
	self.votesUp = nil
	self.votesDown = nil
	self.ourVote = nil
	
	self.base = BaseWindow.Create("Course votes")
	
	local subBase = BaseWindow.Create(self.base)
	subBase:SetSize(Vector2(1000 , 1000))
	
	local spacing = 4
	
	local opinion = Label.Create(subBase)
	opinion:SetMargin(Vector2(0 , 4) , Vector2(0 , 0))
	opinion:SetDock(GwenPosition.Left)
	opinion:SetTextSize(16)
	opinion:SetText("Opinion: ")
	opinion:SizeToContents()
	
	self.percent = Label.Create(subBase)
	self.percent:SetMargin(Vector2(2 , 4) , Vector2(spacing , 0))
	self.percent:SetDock(GwenPosition.Left)
	self.percent:SetTextSize(16)
	self.percent:SetText("???% ")
	self.percent:SizeToContents()
	
	self.votesUpButton = Button.Create(subBase)
	self.votesUpButton:SetMargin(Vector2(spacing , 0) , Vector2(spacing , 0))
	self.votesUpButton:SetDock(GwenPosition.Left)
	self.votesUpButton:SetText("??????")
	self.votesUpButton:SizeToContents()
	self.votesUpButton:SetTextNormalColor(Color.FromHSV(105 , 0.5 , 0.9))
	self.votesUpButton:SetTextHoveredColor(Color.FromHSV(105 , 0.6 , 1))
	self.votesUpButton:SetTextPressedColor(Color.FromHSV(105 , 0.7 , 0.9))
	self.votesUpButton:SetToolTip("Likes")
	self.votesUpButton:SetToggleable(true)
	self.votesUpButton:SetEnabled(false)
	
	self.votesDownButton = Button.Create(subBase)
	self.votesDownButton:SetMargin(Vector2(spacing , 0) , Vector2(spacing , 0))
	self.votesDownButton:SetDock(GwenPosition.Left)
	self.votesDownButton:SetText("??????")
	self.votesDownButton:SizeToContents()
	self.votesDownButton:SetTextNormalColor(Color.FromHSV(0 , 0.5 , 0.9))
	self.votesDownButton:SetTextHoveredColor(Color.FromHSV(0 , 0.6 , 1))
	self.votesDownButton:SetTextPressedColor(Color.FromHSV(0 , 0.7 , 0.9))
	self.votesDownButton:SetToolTip("Dislikes")
	self.votesDownButton:SetToggleable(true)
	self.votesDownButton:SetEnabled(false)
	
	subBase:SizeToChildren()
	subBase:SetHeight(opinion:GetTextHeight() + 4)
	
	self.base:SizeToChildren()
	
	-- Functions
	
	function self:SetCourseInfo(courseInfo)
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
	
	function self:Update()
		self.isUpdating = true
		
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
	
	function self:Voted(button)
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
	
	self.votesUpButton:Subscribe("Toggle" , self , self.Voted)
	self.votesDownButton:Subscribe("Toggle" , self , self.Voted)
	
	-- Network events
	
	function self:VotedCourse(args)
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
				-- Update vote cache.
				for index , vote in ipairs(RaceMenu.cache.personalCourseVotes) do
					if vote[1] == self.courseNameHash then
						vote[2] = self.ourVote
						break
					end
				end
			end
			
			self:Update()
			
			-- Update course cache.
			for index , course in ipairs(RaceMenu.cache.courses) do
				if course[1] == self.courseNameHash then
					course[4] = newVotesUp
					course[5] = newVotesDown
					break
				end
			end
		end
	end
	
	Network:Subscribe("VotedCourse" , self , self.VotedCourse)
	
	return self
end

RaceMenuUtility.CreatePlayerStatsControl = function(parent)
	local self = {}
	
	self.statLabels = {}
	self.rankLabels = {}
	
	self.base = BaseWindow.Create(parent , "Player stats")
	
	local statFontSize = 16
	local rowHeight = Render:GetTextHeight("W" , statFontSize) + 4
	local count = 1
	
	local CreateStat = function(name , isHeader)
		local row = Rectangle.Create(self.base)
		row:SetPadding(Vector2(4 , 2) , Vector2(5 , 2))
		row:SetDock(GwenPosition.Top)
		row:SetHeight(rowHeight)
		
		local labelName = Label.Create(row)
		labelName:SetDock(GwenPosition.Left)
		labelName:SetTextSize(statFontSize)
		labelName:SetText(name)
		labelName:SetHeight(rowHeight)
		labelName:SetWidthAutoRel(0.5)
		
		local labelValue = Label.Create(row)
		labelValue:SetDock(GwenPosition.Left)
		labelValue:SetTextSize(statFontSize)
		labelValue:SetText("?")
		labelValue:SetHeight(rowHeight)
		labelValue:SetWidthAutoRel(0.25)
		
		local labelRank = Label.Create(row)
		labelRank:SetDock(GwenPosition.Right)
		labelRank:SetAlignment(GwenPosition.Right)
		labelRank:SetTextSize(statFontSize)
		labelRank:SetText("?")
		labelRank:SetHeight(rowHeight)
		labelRank:SetWidthAutoRel(0.25)
		
		local rowColor
		
		if isHeader then
			rowColor = Color.FromHSV(0 , 0 , 0)
			rowColor.a = 40
			row:SetHeight(rowHeight + 2)
			
			labelName:SetText("Stat")
			labelValue:SetText("Value")
			labelRank:SetText("Rank")
		else
			if count % 2 == 0 then
				rowColor = Color.FromHSV(0 , 0 , 1)
				rowColor.a = 16
			else
				rowColor = Color.FromHSV(0 , 0 , 0.5)
				rowColor.a = 16
			end
			
			self.statLabels[name] = labelValue
			self.rankLabels[name] = labelRank
		end
		
		row:SetColor(rowColor)
		
		count = count + 1
	end
	
	CreateStat("." , true)
	CreateStat("Time spent racing")
	CreateStat("Starts")
	CreateStat("Finishes")
	CreateStat("Wins")
	
	function self:Update(playerStats)
		local stats = playerStats.stats
		local ranks = playerStats.ranks
		
		local hours , minutes = Utility.SplitSeconds(tonumber(stats.PlayTime))
		local timePlayedString = string.format("%ih, %im" , hours , minutes)
		
		self.statLabels["Time spent racing"]:SetText(timePlayedString)
		self.statLabels.Starts:SetText(tostring(stats.Starts))
		self.statLabels.Finishes:SetText(tostring(stats.Finishes))
		self.statLabels.Wins:SetText(tostring(stats.Wins))
		
		local UpdateRankLabel = function(rankLabel , rank)
			local textColor
			if rank == 1 then
				textColor = Color.FromHSV(60 , 0.75 , 1)
			elseif rank == 2 then
				textColor = Color.FromHSV(190 , 0.1 , 1)
			elseif rank == 3 then
				textColor = Color.FromHSV(42 , 0.65 , 0.95)
			else
				textColor = Color.FromHSV(0 , 0 , 0.85)
			end
			
			rankLabel:SetTextColor(textColor)
			rankLabel:SetText(tostring(rank))
		end
		
		UpdateRankLabel(self.rankLabels["Time spent racing"] , ranks.PlayTime)
		UpdateRankLabel(self.rankLabels.Starts , ranks.Starts)
		UpdateRankLabel(self.rankLabels.Finishes , ranks.Finishes)
		UpdateRankLabel(self.rankLabels.Wins , ranks.Wins)
	end
	
	return self
end

RaceMenuUtility.CreateTitledLabel = function(titleText)
	local base = BaseWindow.Create()
	base:SetMargin(Vector2(2 , 4) , Vector2(8 , 0))
	
	local title = Label.Create(base)
	title:SetDock(GwenPosition.Left)
	title:SetTextSize(16)
	title:SetText(titleText..": ")
	title:SizeToContents()
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetTextSize(16)
	label:SetText("?????")
	label:SizeToContents()
	
	base:SizeToChildren()
	base:SetHeight(title:GetTextHeight())
	
	return base , title , label
end

RaceMenuUtility.CreateTimer = function(text , seconds)
	local base = BaseWindow.Create("Timer")
	base:SetSize(Render.Size)
	
	local timerLabel = Label.Create(base)
	timerLabel:SetAlignment(GwenPosition.Center)
	timerLabel:SetTextSize(TextSize.Large)
	timerLabel:SetText("...")
	timerLabel:SizeToContents()
	timerLabel:SetWidth(Render.Width)
	
	local bottomLabel = Label.Create(base)
	bottomLabel:SetPosition(Vector2(0 , TextSize.Large - 2))
	bottomLabel:SetAlignment(GwenPosition.Center)
	bottomLabel:SetText(text)
	bottomLabel:SizeToContents()
	bottomLabel:SetWidth(Render.Width)
	
	local UpdateTimer = function(self)
		local secondsLeft = math.max(0 , seconds - self.timer:GetSeconds())
		self.timerLabel:SetText(string.format("%.0f" , secondsLeft))
		local hue = math.lerp(140 , 0 , self.timer:GetSeconds() / seconds)
		local sat = math.lerp(0 , 1 , self.timer:GetSeconds() / seconds)
		self.timerLabel:SetTextColor(Color.FromHSV(hue , sat , 0.95))
	end
	
	local Remove = function(self)
		self.base:Remove()
		Events:Unsubscribe(self.sub)
	end
	
	-- Luabuse
	local t = {
		base = base ,
		timerLabel = timerLabel ,
		bottomLabel = bottomLabel ,
		timer = Timer() ,
		seconds = seconds ,
		Remove = Remove ,
	}
	t.sub = Events:Subscribe("Render" , t , UpdateTimer)
	return t
end
