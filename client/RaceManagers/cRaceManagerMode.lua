class("RaceManagerMode")

function RaceManagerMode:__init(args) ; EGUSM.SubscribeUtility.__init(self)
	self.currentRaceLabels = nil
	self.currentRaceRows = nil
	self.voteSkipButton = nil
	self.voteSkipLabel = nil
	self.adminSkipButton = nil
	self.adminNextCourseTextBox = nil
	self.raceMenuHelpText = "Use '/"..settings.command.."' to open the race menu"
	
	self:AddToRaceMenu()
	
	self:ApplyNextRaceInfo(args.nextRaceInfo)
	if args.raceInfo then
		self:ApplyCurrentRaceInfo(args.raceInfo)
	end
	
	if AdminTab.instance then
		self:RaceAdminInitialize()
	else
		self:EventSubscribe("RaceAdminInitialize")
	end
	
	self:EventSubscribe("PostRender")
	self:EventSubscribe("RaceCreate")
	self:EventSubscribe("SpectateCreate")
	self:EventSubscribe("RaceEnd" , self.RaceOrSpectateEnd)
	self:EventSubscribe("SpectateEnd" , self.RaceOrSpectateEnd)
	self:EventSubscribe("RaceMenuOpened")
	self:NetworkSubscribe("UpdateVoteSkipInfo")
	self:NetworkSubscribe("AcknowledgeVoteSkip")
	self:NetworkSubscribe("AcknowledgeSpectate")
	self:NetworkSubscribe("AcknowledgeAdminSkip")
	self:NetworkSubscribe("RaceSkipped")
	self:NetworkSubscribe("RaceWillEndIn")
	self:NetworkSubscribe("RaceInfoChanged")
end

function RaceManagerMode:AddToRaceMenu()
	local fontSize = 16
	
	--
	-- Current race info
	--
	
	local groupBox = RaceMenu.CreateGroupBox(RaceMenu.instance.addonArea)
	groupBox:SetDock(GwenPosition.Left)
	groupBox:SetWidthAutoRel(0.5)
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
	self.voteSkipBase:SetDock(GwenPosition.Top)
	self.voteSkipBase:SetHeight(32)
	
	local button = Button.Create(self.voteSkipBase)
	button:SetPadding(Vector2(24 , 0) , Vector2(24 , 0))
	button:SetDock(GwenPosition.Left)
	button:SetToggleable(true)
	button:SetTextSize(16)
	button:SetText("Vote skip")
	button:SizeToContents()
	button:Subscribe("ToggleOn" , self , self.VoteSkipButtonPressed)
	button:Subscribe("ToggleOff" , self , self.VoteSkipButtonUnpressed)
	self.voteSkipButton = button
	
	self.voteSkipLabel = Label.Create(self.voteSkipBase)
	self.voteSkipLabel:SetDock(GwenPosition.Fill)
	self.voteSkipLabel:SetPadding(Vector2(6 , 7) , Vector2(4 , 0))
	self.voteSkipLabel:SetTextSize(16)
	self.voteSkipLabel:SetText("...")
	
	self.voteSkipButton:SetEnabled(false)
	
	-- Other buttons
	
	local base = BaseWindow.Create(groupBox)
	base:SetDock(GwenPosition.Top)
	base:SetHeight(32)
	
	local button = Button.Create(base)
	button:SetPadding(Vector2(24 , 0) , Vector2(24 , 0))
	button:SetDock(GwenPosition.Left)
	button:SetTextSize(16)
	button:SetText("Spectate")
	button:SizeToContents()
	button:Subscribe("Press" , self , self.SpectateButtonPressed)
	self.spectateButton = button
	
	--
	-- Next race info
	--
	
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

function RaceManagerMode:SpectateButtonPressed()
	RaceMenu.instance:AddRequest("RequestSpectate")
	self.spectateButton:SetEnabled(false)
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

function RaceManagerMode:PostRender()
	if Game:GetState() ~= GUIState.Game then
		return
	end
	
	-- If we haven't opened the race menu yet, draw help text under the chat box.
	if self.raceMenuHelpText then
		DrawText(
			Vector2(30 , Render.Height * 0.875) ,
			self.raceMenuHelpText ,
			Color(255 , 232 , 60) ,
			TextSize.Default ,
			"left"
		)
	end
end

function RaceManagerMode:RaceCreate()
	self.voteSkipButton:SetEnabled(true)
	self.spectateButton:SetEnabled(true)
end

function RaceManagerMode:SpectateCreate()
	self.voteSkipButton:SetEnabled(true)
	self.spectateButton:SetEnabled(false)
end

function RaceManagerMode:RaceOrSpectateEnd()
	-- Reset our vote skip controls.
	self.voteSkipButton:SetToggleState(false)
	self.voteSkipButton:SetEnabled(false)
	self.voteSkipLabel:SetText("...")
	self.voteSkipLabel:SetColorNormal()
end

function RaceManagerMode:RaceMenuOpened()
	self.raceMenuHelpText = nil
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
	
	local base , textBox , label = RaceMenuUtility.CreateLabeledTextBox(AdminTab.instance.page)
	base:SetDock(GwenPosition.Top)
	textBox:Subscribe("ReturnPressed" , self , self.NextCourseTextBoxAccepted)
	textBox:SetToolTip(
		[[Example: "BandarSelekeh". Make sure the name is correct, or else it will error.]]
	)
	self.adminNextCourseTextBox = textBox
	label:SetText("Set next course")
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

function RaceManagerMode:AcknowledgeSpectate(success)
	if success == false then
		self.spectateButton:SetEnabled(true)
	end
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
