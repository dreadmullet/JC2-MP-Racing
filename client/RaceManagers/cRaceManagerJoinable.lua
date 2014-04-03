class("RaceManagerJoinable")

function RaceManagerJoinable:__init(args) ; EGUSM.SubscribeUtility.__init(self)
	self.courseInfoControl = nil
	self.labels = nil
	self.rows = nil
	
	self:AddToRaceMenu()
	
	self:QueuedRaceCreate(args.raceInfo)
	
	self:EventSubscribe("RaceCreate")
	self:EventSubscribe("RaceEnd")
	self:NetworkSubscribe("QueuedRaceCreate")
	self:NetworkSubscribe("QueuedRacePlayersChange")
	self:NetworkSubscribe("JoinQueue")
	self:NetworkSubscribe("LeaveQueue")
end

function RaceManagerJoinable:AddToRaceMenu()
	local groupBox = RaceMenu.CreateGroupBox(RaceMenu.instance.addonArea)
	groupBox:SetDock(GwenPosition.Fill)
	groupBox:SetText("Next race")
	
	local fontSize = 16
	
	self.courseInfoControl , self.labels , self.rows = RaceMenuUtility.CreateTable(
		fontSize ,
		{
			"Players" ,
			"Course" ,
			"Type" ,
			"Authors" ,
			"Checkpoints" ,
			"Collisions" ,
			-- Distance?
		}
	)
	self.courseInfoControl:SetParent(groupBox)
	self.labels.Course:SetTextColor(settings.textColor)
	self.rows.Checkpoints:SetToolTip("Checkpoints per lap")
	
	local buttonsBase = BaseWindow.Create(groupBox)
	buttonsBase:SetDock(GwenPosition.Top)
	buttonsBase:SetHeight(32)
	
	self.joinButton = Button.Create(buttonsBase)
	self.joinButton:SetPadding(Vector2(8 , 8) , Vector2(8 , 8))
	self.joinButton:SetDock(GwenPosition.Left)
	self.joinButton:SetTextSize(fontSize)
	self.joinButton:SetText("Join")
	self.joinButton:SizeToContents()
	self.joinButton:SetWidthAutoRel(0.475)
	self.joinButton:Subscribe("Press" , self , self.JoinButtonPressed)
	
	self.leaveButton = Button.Create(buttonsBase)
	self.leaveButton:SetPadding(Vector2(8 , 8) , Vector2(8 , 8))
	self.leaveButton:SetDock(GwenPosition.Fill)
	self.leaveButton:SetTextSize(fontSize)
	self.leaveButton:SetText("Leave")
	self.leaveButton:SizeToContents()
	self.leaveButton:SetEnabled(false)
	self.leaveButton:Subscribe("Press" , self , self.LeaveButtonPressed)
end

-- GWEN events

function RaceManagerJoinable:JoinButtonPressed()
	Network:Send("JoinRace" , ".")
	self.joinButton:SetEnabled(false)
end

function RaceManagerJoinable:LeaveButtonPressed()
	Network:Send("LeaveRace" , ".")
	self.leaveButton:SetEnabled(false)
end

-- Events

function RaceManagerJoinable:RaceCreate()
	self.leaveButton:SetEnabled(true)
end

function RaceManagerJoinable:RaceEnd()
	self.joinButton:SetEnabled(true)
	self.leaveButton:SetEnabled(false)
end

-- Network events

function RaceManagerJoinable:QueuedRaceCreate(args)
	self.nextRaceMaxPlayers = args.maxPlayers
	self.labels.Players:SetText(string.format("%i/%i" , args.currentPlayers , args.maxPlayers))
	self.labels.Course:SetText(args.course.name)
	self.labels.Authors:SetText(table.concat(args.course.authors , ", "))
	self.labels.Type:SetText(args.course.type)
	self.labels.Checkpoints:SetText(string.format("%i" , args.numCheckpoints))
	if args.collisions then
		self.labels.Collisions:SetText("On")
	else
		self.labels.Collisions:SetText("Off")
	end
	
	for title , label in pairs(self.labels) do
		label:SizeToContents()
	end
end

function RaceManagerJoinable:QueuedRacePlayersChange(newCount)
	self.labels.Players:SetText(string.format("%i/%i" , newCount , self.nextRaceMaxPlayers))
end

function RaceManagerJoinable:JoinQueue()
	self.joinButton:SetEnabled(false)
	self.leaveButton:SetEnabled(true)
end

function RaceManagerJoinable:LeaveQueue()
	self.joinButton:SetEnabled(true)
	self.leaveButton:SetEnabled(false)
end
