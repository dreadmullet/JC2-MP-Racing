RaceMenu.testKey = "K"

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
}

function RaceMenu:__init() ; EGUSM.SubscribeUtility.__init(self)
	self.size = Vector2(768 , 496)
	self.isEnabled = false
	
	self:CreateWindow()
	
	self:EventSubscribe("KeyUp")
	self:EventSubscribe("LocalPlayerInput")
	self:EventSubscribe("InputPoll")
end

function RaceMenu:SetEnabled(enabled)
	self.isEnabled = enabled
	
	self.window:SetVisible(self.isEnabled)
	
	if self.isEnabled then
		self.window:BringToFront()
	end
end

function RaceMenu:CreateWindow()
	self.window = Window.Create()
	self.window:SetTitle("Race Menu")
	self.window:SetSize(self.size)
	self.window:SetPosition(Render.Size/2 - self.size/2) -- Center of screen.
	self.window:SetVisible(self.isEnabled)
end

-- Events

function RaceMenu:KeyUp(args)
	if args.key == string.byte(RaceMenu.testKey) then
		self:SetEnabled(not self.isEnabled)
		Mouse:SetVisible(self.isEnabled)
	end
end

function RaceMenu:LocalPlayerInput(args)
	if self.isEnabled == false then
		return
	end
	
	for index , action in ipairs(RaceMenu.allowedActions) do
		if args.input == action then
			return true
		end
	end
	
	return false
end

function RaceMenu:InputPoll()
	if self.isEnabled == false then
		return
	end
	
	local inputRollRight = Input:GetValue(Action.HeliRollRight)
	if inputRollRight > 0 then
		Input:SetValue(Action.HeliTurnRight , inputRollRight)
	end
	
	local inputRollLeft = Input:GetValue(Action.HeliRollLeft)
	if inputRollLeft > 0 then
		Input:SetValue(Action.HeliTurnLeft , inputRollLeft)
	end
end

-- Testing
raceMenu = RaceMenu()
