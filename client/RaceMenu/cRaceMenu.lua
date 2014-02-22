RaceMenu.command = "/racemenu"

RaceMenu.requestLimitSeconds = 3
RaceMenu.requestLimitCount = 3

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

-- Static functions

RaceMenu.CreateGroupBox = function(...)
	local groupBox = GroupBox.Create(...)
	groupBox:SetMargin(Vector2(4 , 7) , Vector2(4 , 4))
	groupBox:SetPadding(Vector2(1 , 3) , Vector2(1 , 1))
	groupBox:SetTextColor(Color.FromHSV(150 , 0.06 , 0.775))
	groupBox:SetTextSize(24)
	
	return groupBox
end

-- Instance functions

function RaceMenu:__init() ; EGUSM.SubscribeUtility.__init(self)
	self.size = Vector2(720 , 416)
	self.isEnabled = false
	-- These two help with only sending network requests every few seconds. Used in PostTick.
	self.requestTimers = {}
	self.requests = {}
	self.tabs = {}
	
	self:CreateWindow()
	self:AddTab(HomeTab)
	self:AddTab(CoursesTab)
	
	self:EventSubscribe("ControlDown")
	self:EventSubscribe("LocalPlayerInput")
	self:EventSubscribe("LocalPlayerChat")
	self:EventSubscribe("PostTick")
end

function RaceMenu:CreateWindow()
	self.window = Window.Create("RaceMenu")
	self.window:SetTitle("Race Menu")
	self.window:SetSize(self.size)
	self.window:SetPosition(Render.Size/2 - self.size/2) -- Center of screen.
	self.window:SetVisible(self.isEnabled)
	self.window:Subscribe("WindowClosed" , self , self.WindowClosed)
	
	self.tabControl = TabControl.Create(self.window)
	self.tabControl:SetDock(GwenPosition.Fill)
	self.tabControl:SetTabStripPosition(GwenPosition.Top)
	self.tabControl:Subscribe("TabSwitch" , self , self.TabSwitch)
end

function RaceMenu:SetEnabled(enabled)
	local wasEnabled = self.isEnabled
	self.isEnabled = enabled
	
	self.window:SetVisible(self.isEnabled)
	
	if self.isEnabled then
		self.window:BringToFront()
		
		if wasEnabled == false then
			self:ActivateCurrentTab()
		end
	end
	
	Mouse:SetVisible(self.isEnabled)
end

function RaceMenu:AddRequest(networkName , arg)
	table.insert(self.requests , {networkName , arg or "."})
end

function RaceMenu:AddTab(tabClass)
	table.insert(self.tabs , tabClass(self))
end

function RaceMenu:ActivateCurrentTab()
	-- Try to call OnActivate on the current tab.
	for index , tab in ipairs(self.tabs) do
		if tab.tabButton and tab.tabButton == self.tabControl:GetCurrentTab() then
			if tab.OnActivate then
				tab:OnActivate()
			end
		end
	end
end

-- Gwen events

function RaceMenu:WindowClosed()
	self:SetEnabled(false)
end

function RaceMenu:TabSwitch()
	self:ActivateCurrentTab()
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
	if #self.requests > 0 then
		-- Expire any old timers.
		for n = #self.requestTimers , 1 , -1 do
			if self.requestTimers[n]:GetSeconds() > RaceMenu.requestLimitSeconds then
				table.remove(self.requestTimers , n)
			end
		end
		
		if #self.requestTimers >= RaceMenu.requestLimitCount then
			return
		end
		
		table.insert(self.requestTimers , Timer())
		
		local request = self.requests[1]
		Network:Send(request[1] , request[2])
		
		table.remove(self.requests , 1)
	end
end
