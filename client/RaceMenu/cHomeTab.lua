class("HomeTab")

HomeTab.topAreaColor = Color.FromHSV(25 , 0.95 , 0.85)
HomeTab.topAreaBorderColor = Color(160 , 160 , 160)
HomeTab.githubLabelColor = Color(255 , 255 , 255 , 228)

function HomeTab:__init() ; TabBase.__init(self , "Home")
	-- Top area
	
	local topAreaBackground = Rectangle.Create(self.page)
	topAreaBackground:SetPadding(Vector2.One * 2 , Vector2.One * 2)
	topAreaBackground:SetDock(GwenPosition.Top)
	topAreaBackground:SetColor(HomeTab.topAreaBorderColor)
	
	local topArea = ShadedRectangle.Create(topAreaBackground)
	topArea:SetPadding(Vector2(6 , 6) , Vector2(6 , 6))
	topArea:SetDock(GwenPosition.Top)
	topArea:SetColor(HomeTab.topAreaColor)
	
	local largeName = Label.Create(topArea)
	largeName:SetMargin(Vector2() , Vector2(0 , -6))
	largeName:SetDock(GwenPosition.Top)
	largeName:SetAlignment(GwenPosition.CenterH)
	largeName:SetTextSize(42)
	largeName:SetText(settings.gamemodeName)
	largeName:SizeToContents()
	
	local githubLabel = Label.Create(topArea)
	githubLabel:SetDock(GwenPosition.Top)
	githubLabel:SetAlignment(GwenPosition.CenterH)
	githubLabel:SetTextColor(HomeTab.githubLabelColor)
	githubLabel:SetText("github.com/dreadmullet/JC2-MP-Racing")
	githubLabel:SizeToContents()
	
	topArea:SizeToChildren()
	topAreaBackground:SizeToChildren()
	
	-- MOTD area
	
	self.motdLabel = Label.Create(self.page)
	self.motdLabel:SetMargin(Vector2(8 , 10) , Vector2(8 , 10))
	self.motdLabel:SetDock(GwenPosition.Top)
	self.motdLabel:SetAlignment(GwenPosition.CenterH)
	self.motdLabel:SetHeight(48)
	-- self.motdLabel:SetWrap(true)
	self.motdLabel:SetTextSize(16)
	self.motdLabel:SetTextColor(Color.FromHSV(215 , 0.25 , 0.95))
	self.motdLabel:SetText(settings.motdText)
	
	-- Left side
	
	local leftSide = BaseWindow.Create(self.page)
	leftSide:SetDock(GwenPosition.Left)
	leftSide:SetWidth(350)
	
	local groupBoxStats = RaceMenu.CreateGroupBox(leftSide)
	groupBoxStats:SetHeight(136)
	groupBoxStats:SetDock(GwenPosition.Top)
	groupBoxStats:SetText("Personal stats")
	
	self.playerStatsControl = RaceMenuUtility.CreatePlayerStatsControl(groupBoxStats)
	self.playerStatsControl.base:SetDock(GwenPosition.Fill)
	
	local groupBoxBindMenu = RaceMenu.CreateGroupBox(leftSide)
	groupBoxBindMenu:SetDock(GwenPosition.Fill)
	groupBoxBindMenu:SetText("Controls")
	
	local bindMenu = BindMenu.Create(groupBoxBindMenu)
	bindMenu:SetDock(GwenPosition.Fill)
	bindMenu:AddControl("Toggle this menu" , nil)
	bindMenu:AddControl("Respawn" , "R")
	bindMenu:AddControl("Rotate camera" , "FireLeft")
	bindMenu:RequestSettings()
	
	groupBoxBindMenu:SetWidth(bindMenu:GetWidth())
	
	-- Right side
	
	RaceMenu.instance.addonArea = BaseWindow.Create(self.page)
	RaceMenu.instance.addonArea:SetDock(GwenPosition.Fill)
end

-- RaceMenu callbacks

function HomeTab:OnActivate()
	self:NetworkSubscribe("ReceivePlayerStats")
	
	RaceMenu.instance:AddRequest("RequestPlayerStats" , LocalPlayer:GetSteamId().id)
end

function HomeTab:OnDeactivate()
	self:NetworkUnsubscribeAll()
end

-- Network events

function HomeTab:ReceivePlayerStats(playerStats)
	if playerStats.steamId ~= LocalPlayer:GetSteamId().id then
		return
	end
	
	self.playerStatsControl:Update(playerStats)
end
