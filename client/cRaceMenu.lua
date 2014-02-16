RaceMenu.command = "/racemenu"

RaceMenu.requestLimitSeconds = 2.6

RaceMenu.allowedActions = {
	Action.Accelerate ,
	Action.Reverse ,
	Action.TurnLeft ,
	Action.TurnRight ,
	Action.HeliForward ,
	Action.HeliBackward ,
	Action.HeliRollLeft ,
	Action.HeliRollRight ,
	Action.HeliIncAltitude ,
	Action.HeliDecAltitude ,
	Action.PlaneIncTrust ,
	Action.PlaneDecTrust ,
	Action.PlanePitchUp ,
	Action.PlanePitchDown ,
	Action.PlaneTurnLeft ,
	Action.PlaneTurnRight ,
	Action.MoveForward ,
	Action.MoveBackward ,
	Action.MoveLeft ,
	Action.MoveRight ,
	Action.ParachuteOpenClose ,
	Action.Jump ,
}

RaceMenu.topAreaColor = Color.FromHSV(25 , 0.95 , 0.85)
RaceMenu.topAreaBorderColor = Color(144 , 144 , 144)
RaceMenu.groupBoxColor = Color.FromHSV(150 , 0.06 , 0.775)
RaceMenu.githubLabelColor = Color(255 , 255 , 255 , 228)

function RaceMenu:__init() ; EGUSM.SubscribeUtility.__init(self)
	self.size = Vector2(650 , 500)
	self.isEnabled = false
	self.statLabels = {}
	-- These two help with only sending network requests every few seconds. Used in PostTick.
	self.requestTimer = Timer()
	self.requests = {}
	
	self:CreateWindow()
	
	self:EventSubscribe("ControlDown")
	self:EventSubscribe("LocalPlayerInput")
	self:EventSubscribe("LocalPlayerChat")
	self:EventSubscribe("PostTick")
	self:NetworkSubscribe("ReceivePersonalStats")
end

function RaceMenu:CreateWindow()
	self.window = Window.Create("RaceMenu")
	self.window:SetTitle("Race Menu")
	self.window:SetSize(self.size)
	self.window:SetPosition(Render.Size/2 - self.size/2) -- Center of screen.
	self.window:SetVisible(self.isEnabled)
	self.window:Subscribe("WindowClosed" , self , self.WindowClosed)
	
	local tabControl = TabControl.Create(self.window)
	tabControl:SetDock(GwenPosition.Fill)
	tabControl:SetTabStripPosition(GwenPosition.Top)
	
	local homeTabButton = tabControl:AddPage("Home")
	
	local homePage = homeTabButton:GetPage()
	homePage:SetPadding(Vector2.One*2 , Vector2.One * 2)
	
	local topAreaBackground = Rectangle.Create(homePage)
	topAreaBackground:SetPadding(Vector2.One * 2 , Vector2.One * 2)
	topAreaBackground:SetDock(GwenPosition.Top)
	topAreaBackground:SetColor(RaceMenu.topAreaBorderColor)
	
	local topArea = ShadedRectangle.Create(topAreaBackground)
	topArea:SetPadding(Vector2.One * 8 , Vector2.One * 8)
	topArea:SetDock(GwenPosition.Top)
	topArea:SetColor(RaceMenu.topAreaColor)
	
	local largeName = Label.Create(topArea)
	largeName:SetDock(GwenPosition.Top)
	largeName:SetAlignment(GwenPosition.CenterH)
	largeName:SetTextSize(TextSize.VeryLarge)
	largeName:SetText(settings.gamemodeName)
	largeName:SizeToContents()
	
	local githubLabel = Label.Create(topArea)
	githubLabel:SetDock(GwenPosition.Top)
	githubLabel:SetAlignment(GwenPosition.CenterH)
	githubLabel:SetTextColor(RaceMenu.githubLabelColor)
	githubLabel:SetText("github.com/dreadmullet/JC2-MP-Racing")
	githubLabel:SizeToContents()
	
	topArea:SizeToChildren()
	topAreaBackground:SizeToChildren()
	
	local groupBoxBindMenu = GroupBox.Create(homePage)
	groupBoxBindMenu:SetDock(GwenPosition.Left)
	groupBoxBindMenu:SetMargin(Vector2(4 , 7) , Vector2(4 , 4))
	groupBoxBindMenu:SetPadding(Vector2(1 , 3) , Vector2(1 , 1))
	groupBoxBindMenu:SetTextColor(RaceMenu.groupBoxColor)
	groupBoxBindMenu:SetText("Controls")
	groupBoxBindMenu:SetTextSize(24)
	
	local bindMenu = BindMenu.Create(groupBoxBindMenu)
	bindMenu:SetDock(GwenPosition.Fill)
	bindMenu:AddControl("Toggle this menu" , nil)
	bindMenu:RequestSettings()
	
	groupBoxBindMenu:SetWidth(bindMenu:GetWidth())
	
	local groupBoxStats = GroupBox.Create(homePage)
	groupBoxStats:SetDock(GwenPosition.Fill)
	groupBoxStats:SetMargin(Vector2(4 , 7) , Vector2(4 , 4))
	groupBoxStats:SetPadding(Vector2(4 , 7) , Vector2(4 , 4))
	groupBoxStats:SetTextColor(RaceMenu.groupBoxColor)
	groupBoxStats:SetText("Personal stats")
	groupBoxStats:SetTextSize(24)
	
	local CreateStatLabel = function(name)
		local label = Label.Create(groupBoxStats)
		label:SetMargin(Vector2(0 , 0) , Vector2(0 , 3))
		label:SetDock(GwenPosition.Top)
		label:SetTextSize(18)
		label:SetText(name..": ????")
		label:SizeToContents()
		
		self.statLabels[name] = label
	end
	
	CreateStatLabel("Time spent racing")
	CreateStatLabel("Starts")
	CreateStatLabel("Finishes")
	CreateStatLabel("Wins")
end

function RaceMenu:SetEnabled(enabled)
	self.isEnabled = enabled
	
	self.window:SetVisible(self.isEnabled)
	
	if self.isEnabled then
		self.window:BringToFront()
		table.insert(self.requests , {"RequestPersonalStats" , "unused"})
	end
	
	Mouse:SetVisible(self.isEnabled)
end

-- Gwen events

function RaceMenu:WindowClosed()
	self:SetEnabled(false)
end

-- Events

function RaceMenu:ControlDown(control)
	if control.name == "Toggle this menu" then
		self:SetEnabled(not self.isEnabled)
	end
end

function RaceMenu:LocalPlayerInput(args)
	if self.isEnabled == false then
		return true
	end
	
	for index , action in ipairs(RaceMenu.allowedActions) do
		if args.input == action then
			return true
		end
	end
	
	return false
end

function RaceMenu:LocalPlayerChat(args)
	if args.text:lower() == RaceMenu.command then
		self:SetEnabled(not self.isEnabled)
		return false
	end
	
	return true
end

function RaceMenu:PostTick()
	if #self.requests > 0 and self.requestTimer:GetSeconds() > RaceMenu.requestLimitSeconds then
		local request = self.requests[1]
		Network:Send(request[1] , request[2])
		
		table.remove(self.requests , 1)
		self.requestTimer:Restart()
	end
end

-- Network events

function RaceMenu:ReceivePersonalStats(stats)
	local timePlayedString = "INVALID"
	if stats then
		local hours , minutes = Utility.SplitSeconds(tonumber(stats.PlayTime))
		timePlayedString = string.format("Time spent racing: %ih, %im" , hours , minutes)
	else
		stats = {}
		timePlayedString = "Time spent racing: none"
		stats.Starts = 0
		stats.Finishes = 0
		stats.Wins = 0
	end
	
	self.statLabels["Time spent racing"]:SetText(timePlayedString)
	self.statLabels.Starts:SetText("Starts: "..tostring(stats.Starts))
	self.statLabels.Finishes:SetText("Finishes: "..tostring(stats.Finishes))
	self.statLabels.Wins:SetText("Wins: "..tostring(stats.Wins))
end
