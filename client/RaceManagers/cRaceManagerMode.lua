class("RaceManagerMode")

function RaceManagerMode:__init(args) ; EGUSM.SubscribeUtility.__init(self)
	self.currentRaceLabels = nil
	self.currentRaceRows = nil
	self.voteSkipButton = nil
	self.voteSkipLabel = nil
	self.adminSkipButton = nil
	self.adminNextCourseTextBox = nil
	
	self:AddToRaceMenu()
	
	self:ApplyNextRaceInfo(args.nextRaceInfo)
	if args.currentRaceInfo then
		self:ApplyCurrentRaceInfo(args.raceInfo)
	end
	
	if AdminTab.instance then
		self:RaceAdminInitialize()
	else
		self:EventSubscribe("RaceAdminInitialize")
	end
	
	self:EventSubscribe("RaceCreate")
	self:EventSubscribe("RaceEnd")
	self:NetworkSubscribe("UpdateVoteSkipInfo")
	self:NetworkSubscribe("AcknowledgeVoteSkip")
	self:NetworkSubscribe("AcknowledgeAdminSkip")
	self:NetworkSubscribe("RaceSkipped")
	self:NetworkSubscribe("RaceWillEndIn")
	self:NetworkSubscribe("RaceInfoChanged")
end

function RaceManagerMode:AddToRaceMenu()
	local fontSize = 16
	
	-- Current race info
	
	local groupBox = RaceMenu.CreateGroupBox(RaceMenu.instance.addonArea)
	groupBox:SetDock(GwenPosition.Top)
	groupBox:SetHeight(196)
	groupBox:SetText("Current race")
	
	local tableControl
	local tableArgs = {
		"Players" ,
		"Course" ,
		"Type" ,
		"Authors" ,
		"Checkpoints" ,
		"Collisions" ,
		-- Distance?
	}
	tableControl , self.currentRaceLabels , self.currentRaceRows = RaceMenuUtility.CreateTable(
		fontSize ,
		tableArgs
	)
	tableControl:SetParent(groupBox)
	tableControl:SetDock(GwenPosition.Top)
	self.currentRaceLabels.Course:SetTextColor(settings.textColor)
	self.currentRaceRows.Players:SetToolTip("This is probably broken")
	self.currentRaceRows.Checkpoints:SetToolTip("Checkpoints per lap")
	
	-- Voteskip control
	
	self.voteSkipBase = BaseWindow.Create(groupBox)
	self.voteSkipBase:SetMargin(Vector2(0 , 6) , Vector2(0 , 0))
	self.voteSkipBase:SetDock(GwenPosition.Top)
	self.voteSkipBase:SetHeight(32)
	
	self.voteSkipButton = Button.Create(self.voteSkipBase)
	self.voteSkipButton:SetPadding(Vector2(24 , 0) , Vector2(24 , 0))
	self.voteSkipButton:SetDock(GwenPosition.Left)
	self.voteSkipButton:SetToggleable(true)
	self.voteSkipButton:SetTextSize(16)
	self.voteSkipButton:SetText("Vote skip")
	self.voteSkipButton:SizeToContents()
	self.voteSkipButton:Subscribe("ToggleOn" , self , self.VoteSkipButtonPressed)
	self.voteSkipButton:Subscribe("ToggleOff" , self , self.VoteSkipButtonUnpressed)
	
	self.voteSkipLabel = Label.Create(self.voteSkipBase)
	self.voteSkipLabel:SetDock(GwenPosition.Fill)
	self.voteSkipLabel:SetPadding(Vector2(6 , 7) , Vector2(4 , 0))
	self.voteSkipLabel:SetTextSize(16)
	self.voteSkipLabel:SetText("...")
	
	self.voteSkipBase:SetVisible(false)
	
	-- Next race info
	
	groupBox = RaceMenu.CreateGroupBox(RaceMenu.instance.addonArea)
	groupBox:SetDock(GwenPosition.Fill)
	groupBox:SetText("Next race")
	
	tableArgs = {
		"Course" ,
		"Collisions" ,
	}
	tableControl , self.nextRaceLabels , self.nextRaceRows = RaceMenuUtility.CreateTable(
		fontSize ,
		tableArgs
	)
	tableControl:SetParent(groupBox)
	tableControl:SetDock(GwenPosition.Fill)
	self.nextRaceLabels.Course:SetTextColor(settings.textColor)
end

function RaceManagerMode:ApplyCurrentRaceInfo(args)
	local labels = self.currentRaceLabels
	labels.Players:SetText(string.format("%i" , args.currentPlayers))
	labels.Course:SetText(args.course.name)
	labels.Authors:SetText(table.concat(args.course.authors , ", "))
	labels.Type:SetText(args.course.type)
	labels.Checkpoints:SetText(string.format("%i" , args.numCheckpoints))
	if args.collisions then
		labels.Collisions:SetText("On")
	else
		labels.Collisions:SetText("Off")
	end
	
	for title , label in pairs(labels) do
		label:SizeToContents()
	end
end

function RaceManagerMode:ApplyNextRaceInfo(args)
	local labels = self.nextRaceLabels
	labels.Course:SetText(args.courseName)
	if args.collisions then
		labels.Collisions:SetText("On")
	else
		labels.Collisions:SetText("Off")
	end
	
	for title , label in pairs(labels) do
		label:SizeToContents()
	end
end

-- GWEN events

function RaceManagerMode:VoteSkipButtonPressed()
	RaceMenu.instance:AddRequest("VoteSkip" , true)
	self.voteSkipButton:SetEnabled(false)
end

function RaceManagerMode:VoteSkipButtonUnpressed()
	RaceMenu.instance:AddRequest("VoteSkip" , false)
	self.voteSkipButton:SetEnabled(false)
end

function RaceManagerMode:AdminSkipButtonPressed()
	RaceMenu.instance:AddRequest("AdminSkip")
	self.adminSkipButton:SetEnabled(false)
end

function RaceManagerMode:NextCourseTextBoxAccepted()
	RaceMenu.instance:AddRequest("AdminSetNextCourse" , self.adminNextCourseTextBox:GetText())
	self.adminNextCourseTextBox:SetText("")
end

-- Events

function RaceManagerMode:RaceCreate()
	self.voteSkipBase:SetVisible(true)
	self.voteSkipButton:SetEnabled(true)
end

function RaceManagerMode:RaceEnd()
	-- Reset our vote skip controls.
	self.voteSkipButton:SetToggleState(false)
	self.voteSkipLabel:SetText("...")
	self.voteSkipLabel:SetColorNormal()
	self.voteSkipBase:SetVisible(false)
end

function RaceManagerMode:RaceAdminInitialize()
	local button = Button.Create(AdminTab.instance.page)
	button:SetPadding(Vector2(24 , 0) , Vector2(24 , 0))
	button:SetDock(GwenPosition.Top)
	button:SetTextSize(16)
	button:SetText("Force skip current race")
	button:SetHeight(32)
	button:Subscribe("Press" , self , self.AdminSkipButtonPressed)
	self.adminSkipButton = button
	
	local base = BaseWindow.Create(AdminTab.instance.page)
	base:SetMargin(Vector2(0 , 4) , Vector2(0 , 4))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(18)
	
	local textBox = TextBox.Create(base)
	textBox:SetDock(GwenPosition.Left)
	textBox:SetWidth(180)
	textBox:Subscribe("ReturnPressed" , self , self.NextCourseTextBoxAccepted)
	textBox:SetToolTip(
		[[Example: "BandarSelekeh". Make sure the name is correct, or else it will error.]]
	)
	self.adminNextCourseTextBox = textBox
	
	local label = Label.Create(base)
	label:SetMargin(Vector2(0 , 2) , Vector2(0 , 0))
	label:SetDock(GwenPosition.Left)
	label:SetTextSize(16)
	label:SetText(" Set next course")
	label:SizeToContents()
end

-- Network events

function RaceManagerMode:UpdateVoteSkipInfo(args)
	local votesString = "votes"
	if args.skipVotes == 1 then
		votesString = "vote"
	end
	local text = string.format(
		"%i "..votesString.." - %i needed" ,
		args.skipVotes ,
		args.skipVotesRequired
	)
	self.voteSkipLabel:SetText(text)
end

function RaceManagerMode:AcknowledgeVoteSkip(vote)
	self.voteSkipButton:SetEnabled(true)
	self.voteSkipButton:SetToggleState(vote)
end

function RaceManagerMode:AcknowledgeAdminSkip()
	self.adminSkipButton:SetEnabled(true)
end

function RaceManagerMode:RaceSkipped()
	self.voteSkipButton:SetEnabled(false)
	self.voteSkipLabel:SetText("Skipping race!")
	self.voteSkipLabel:SetTextColor(Color.Green)
end

function RaceManagerMode:RaceWillEndIn()
	self.voteSkipButton:SetEnabled(false)
end

function RaceManagerMode:RaceInfoChanged(args)
	self:ApplyNextRaceInfo(args.nextRaceInfo)
	self:ApplyCurrentRaceInfo(args.raceInfo)
end
