class("RaceManagerJoinable")

function RaceManagerJoinable:__init(args)
	self.labels = nil
	self.rows = nil
	
	self:AddToRaceMenu()
	
	self:QueuedRaceCreate(args.raceInfo)
	
	Network:Subscribe("QueuedRaceCreate" , self , self.QueuedRaceCreate)
	Network:Subscribe("QueuedRacePlayersChange" , self , self.QueuedRacePlayersChange)
end

function RaceManagerJoinable:AddToRaceMenu()
	local groupBox = RaceMenu.CreateGroupBox(RaceMenu.instance.addonArea)
	groupBox:SetDock(GwenPosition.Top)
	groupBox:SetHeight(160)
	groupBox:SetText("Next race")
	
	self.labels = {}
	self.rows = {}
	
	local nextRaceTable = Table.Create(groupBox)
	nextRaceTable:SetDock(GwenPosition.Top)
	nextRaceTable:SetHeight(128)
	nextRaceTable:SetColumnCount(2)
	nextRaceTable:SetColumnWidth(0 , 112)
	
	local CreateLabel = function(text)
		local label = Label.Create()
		label:SetTextSize(16)
		label:SetText(text)
		label:SizeToContents()
		
		return label
	end
	
	local AddRow = function(title)
		local row = nextRaceTable:AddRow()
		
		row:SetCellContents(0 , CreateLabel(title..":"))
		
		local label = CreateLabel("??")
		row:SetCellContents(1 , label)
		
		self.labels[title] = label
		self.rows[title] = row
	end
	
	AddRow("Players")
	AddRow("Course")
	AddRow("Type")
	AddRow("Authors")
	AddRow("Checkpoints")
	AddRow("Collisions")
	-- Distance?
	
	self.labels.Course:SetTextColor(settings.textColor)
	
	self.rows.Checkpoints:SetToolTip("Checkpoints per lap")
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
