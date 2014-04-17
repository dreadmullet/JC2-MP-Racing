class("RaceMenu")

-- Static constants

RaceMenu.command = "/racemenu"

RaceMenu.requestLimitSeconds = 3.5
RaceMenu.requestLimitCount = 5

-- Helps with requesting courses and votes only once.
RaceMenu.cache = {}

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

RaceMenu.groupBoxColor = Color.FromHSV(150 , 0.06 , 0.775)

-- Static functions

RaceMenu.CreateGroupBox = function(...)
	local groupBox = GroupBox.Create(...)
	groupBox:SetMargin(Vector2(4 , 7) , Vector2(4 , 4))
	groupBox:SetPadding(Vector2(1 , 7) , Vector2(1 , 3))
	groupBox:SetTextColor(RaceMenu.groupBoxColor)
	groupBox:SetTextSize(24)
	
	return groupBox
end

-- Instance functions

function RaceMenu:__init() ; EGUSM.SubscribeUtility.__init(self)
	RaceMenu.instance = self
	
	self.size = Vector2(736 , 472)
	self.isEnabled = false
	-- These two help with limiting network requests. Used in PostTick.
	self.requestTimers = {}
	self.requests = {}
	self.tabs = {}
	self.currentTab = nil
	self.addonArea = nil
	
	self:CreateWindow()
	self:AddTab(HomeTab)
	self:AddTab(SettingsTab)
	self:AddTab(PlayersTab)
	self:AddTab(CoursesTab)
	
	self:EventSubscribe("ControlDown")
	self:EventSubscribe("LocalPlayerInput")
	self:EventSubscribe("LocalPlayerChat")
	self:EventSubscribe("PostTick")
	Console:Subscribe(settings.command , self , self.ConsoleActivate)
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
	self.tabControl:SetBackgroundVisible(false)
	self.addTabSub = self.tabControl:Subscribe("AddTab" , self , self.OnAddTab)
	self.tempFix = true
end

function RaceMenu:SetEnabled(enabled)
	self.isEnabled = enabled
	
	self.window:SetVisible(self.isEnabled)
	
	if self.isEnabled then
		self:ActivateCurrentTab()
		self.window:BringToFront()
	else
		self:DeactivateCurrentTab()
	end
	
	Mouse:SetVisible(self.isEnabled)
end

function RaceMenu:AddRequest(networkName , arg)
	if arg == nil then
		arg = "."
	end
	
	table.insert(self.requests , {networkName , arg})
end

function RaceMenu:AddTab(tabClass)
	local instance = tabClass(self)
	table.insert(self.tabs , instance)
	
	instance.__id = {}
	
	return instance
end

function RaceMenu:RemoveTab(tabToRemove)
	for index , tab in ipairs(self.tabs) do
		if tab.__id == tabToRemove.__id then
			self.tabControl:SetCurrentTab(self.tabs[1].tabButton)
			self.tabControl:RemovePage(tab.tabButton)
			if tab.OnRemove then
				tab:OnRemove()
			end
			
			table.remove(self.tabs , index)
			
			break
		end
	end
end

function RaceMenu:ActivateCurrentTab()
	self.currentTab = self.tabControl:GetCurrentTab():GetDataObject("tab")
	
	if self.currentTab.OnActivate then
		self.currentTab:OnActivate()
	end
end

function RaceMenu:DeactivateCurrentTab()
	if self.currentTab.OnDeactivate then
		self.currentTab:OnDeactivate()
	end
end

-- Gwen events

function RaceMenu:WindowClosed()
	self:SetEnabled(false)
end

function RaceMenu:OnAddTab()
	-- self.tabControl:Unsubscribe(self.addTabSub)
	if self.tempFix then
		self.tabControl:Subscribe("TabSwitch" , self , self.TabSwitch)
		self.tempFix = false
	end
end

function RaceMenu:TabSwitch()
	if self.currentTab then
		self:DeactivateCurrentTab()
	end
	
	self:ActivateCurrentTab()
end

-- Events

function RaceMenu:ControlDown(control)
	if control.name == "Toggle this menu" and inputSuspensionValue == 0 then
		self:SetEnabled(not self.isEnabled)
	end
end

function RaceMenu:LocalPlayerInput(args)
	if self.isEnabled == false then
		return true
	end
	
	if inputSuspensionValue > 0 then
		return false
	end
	
	for index , action in ipairs(RaceMenu.allowedActions) do
		if args.input == action then
			return true
		end
	end
	
	return false
end

function RaceMenu:LocalPlayerChat(args)
	if args.text:lower() == "/"..settings.command then
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

function RaceMenu:ConsoleActivate(args)
	if args.text:len() == 0 then
		self:SetEnabled(not self.isEnabled)
	end
end
