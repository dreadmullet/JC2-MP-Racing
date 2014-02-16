RaceMenu.command = "/racemenu"

RaceMenu.requestLimitSeconds = 3.3

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

function RaceMenu:__init() ; EGUSM.SubscribeUtility.__init(self)
	self.size = Vector2(650 , 500)
	self.isEnabled = false
	self.timePlayedLabel = nil
	-- These two help with only sending network requests every few seconds. Used in PostTick.
	self.requestTimer = Timer()
	self.requests = {}
	
	self:CreateWindow()
	
	-- Note: All other stats requests should be done using self.requests.
	Network:Send("RequestPersonalStats" , "unused")
	
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
	topAreaBackground:SetColor(Color(144 , 144 , 144 , 255))
	
	local topArea = ShadedRectangle.Create(topAreaBackground)
	topArea:SetPadding(Vector2.One * 8 , Vector2.One * 8)
	topArea:SetDock(GwenPosition.Top)
	topArea:SetColor(Color(217 , 110 , 43 , 255))
	
	local largeName = Label.Create(topArea)
	largeName:SetDock(GwenPosition.Top)
	largeName:SetAlignment(GwenPosition.CenterH)
	largeName:SetTextSize(TextSize.VeryLarge)
	largeName:SetText(settings.gamemodeName)
	largeName:SizeToContents()
	
	local githubLabel = Label.Create(topArea)
	githubLabel:SetDock(GwenPosition.Top)
	githubLabel:SetAlignment(GwenPosition.CenterH)
	githubLabel:SetTextColor(Color(200 , 200 , 200))
	githubLabel:SetText("github.com/dreadmullet/JC2-MP-Racing")
	githubLabel:SizeToContents()
	
	topArea:SizeToChildren()
	topAreaBackground:SizeToChildren()
	
	local groupBoxBindMenu = GroupBox.Create(homePage)
	groupBoxBindMenu:SetDock(GwenPosition.Left)
	groupBoxBindMenu:SetText("Controls")
	groupBoxBindMenu:SetMargin(Vector2.One * 4 , Vector2.One * 4)
	
	local bindMenu = BindMenu.Create(groupBoxBindMenu)
	bindMenu:SetDock(GwenPosition.Fill)
	bindMenu:AddControl("Toggle this menu" , nil)
	bindMenu:RequestSettings()
	
	groupBoxBindMenu:SetWidth(bindMenu:GetWidth())
	
	local groupBoxInfo = GroupBox.Create(homePage)
	groupBoxInfo:SetDock(GwenPosition.Fill)
	groupBoxInfo:SetText("Information")
	groupBoxInfo:SetMargin(Vector2(4 , 4) , Vector2(4 , 4))
	groupBoxInfo:SetPadding(Vector2(4 , 4) , Vector2(4 , 4))
	
	self.timePlayedLabel = Label.Create(groupBoxInfo)
	self.timePlayedLabel:SetDock(GwenPosition.Fill)
	self.timePlayedLabel:SetTextSize(20)
	self.timePlayedLabel:SetText("Time played: ????")
	self.timePlayedLabel:SizeToContents()
end

function RaceMenu:SetEnabled(enabled)
	self.isEnabled = enabled
	
	self.window:SetVisible(self.isEnabled)
	
	if self.isEnabled then
		self.window:BringToFront()
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
	local totalSeconds = stats[1]
	local timePlayedString = "INVALID"
	if totalSeconds then
		local hours , minutes = Utility.SplitSeconds(stats[1] or 0)
		timePlayedString = string.format("%i hours, %i minutes" , hours , minutes)
	end
	
	self.timePlayedLabel:SetText(timePlayedString)
end

-- TODO: This should probably be moved.
Events:Subscribe("ModuleLoad" , function()
	raceMenu = RaceMenu()
end)
