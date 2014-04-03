class("RaceManagerMode")

function RaceManagerMode:__init(args) ; EGUSM.SubscribeUtility.__init(self)
	self.voteSkipButton = nil
	self.voteSkipLabel = nil
	
	self:AddToRaceMenu()
	
	self:EventSubscribe("RaceCreate")
	self:EventSubscribe("RaceEnd")
	self:NetworkSubscribe("UpdateVoteSkipInfo")
	self:NetworkSubscribe("AcknowledgeVoteSkip")
	self:NetworkSubscribe("RaceSkipped")
	self:NetworkSubscribe("RaceWillEndIn")
end

function RaceManagerMode:AddToRaceMenu()
	local groupBox = RaceMenu.CreateGroupBox(RaceMenu.instance.addonArea)
	groupBox:SetDock(GwenPosition.Top)
	groupBox:SetHeight(140)
	groupBox:SetText("Current race")
	
	self.voteSkipBase = BaseWindow.Create(groupBox)
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

function RaceManagerMode:RaceSkipped()
	self.voteSkipButton:SetEnabled(false)
	self.voteSkipLabel:SetText("Skipping race!")
	self.voteSkipLabel:SetTextColor(Color.Green)
end

function RaceManagerMode:RaceWillEndIn()
	self.voteSkipButton:SetEnabled(false)
end
