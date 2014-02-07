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
	self.size = Vector2(704 , 496)
	self.isEnabled = false
	
	self:CreateWindow()
	
	self:EventSubscribe("LocalPlayerInput")
	self:EventSubscribe("InputPoll")
	self:EventSubscribe("ControlDown")
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
	
	local topArea = Rectangle.Create(homePage)
	topArea:SetPadding(Vector2.One * 8 , Vector2.One * 8)
	topArea:SetDock(GwenPosition.Top)
	topArea:SetColor(Color(179 , 112 , 54 , 192))
	
	local largeName = Label.Create(topArea)
	largeName:SetDock(GwenPosition.Top)
	largeName:SetAlignment(GwenPosition.CenterH)
	largeName:SetTextSize(TextSize.VeryLarge)
	largeName:SizeToContents()
	largeName:SetText(settings.gamemodeName)
	
	local githubLabel = Label.Create(topArea)
	githubLabel:SetDock(GwenPosition.Top)
	githubLabel:SetAlignment(GwenPosition.CenterH)
	githubLabel:SetTextColor(Color(192 , 192 , 192))
	githubLabel:SetText("github.com/dreadmullet/JC2-MP-Racing")
	githubLabel:SizeToContents()
	
	topArea:SizeToChildren()
	
	local bindMenu = BindMenu.Create(homePage)
	bindMenu:SetDock(GwenPosition.Left)
	bindMenu:AddControl("Toggle this menu" , "K")
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

-- This allows you to control helicopters with left/right instead of the mouse.
function RaceMenu:InputPoll()
	if self.isEnabled == false then
		return
	end
	
	-- TODO: GetValue returns 0 - 65535 as of 0.1.3. Blame Trix.
	local inputRollRight = Input:GetValue(Action.HeliRollRight)
	if inputRollRight > 0 then
		Input:SetValue(Action.HeliTurnRight , inputRollRight / 65535 / 2)
	end
	
	local inputRollLeft = Input:GetValue(Action.HeliRollLeft)
	if inputRollLeft > 0 then
		Input:SetValue(Action.HeliTurnLeft , inputRollLeft / 65535 / 2)
	end
end

-- Testing
Events:Subscribe("ModuleLoad" , function()
	raceMenu = RaceMenu()
	raceMenu:SetEnabled(true)
end)