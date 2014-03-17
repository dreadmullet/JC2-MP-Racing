class("HomeTab")

HomeTab.topAreaColor = Color.FromHSV(25 , 0.95 , 0.85)
HomeTab.topAreaBorderColor = Color(144 , 144 , 144)
HomeTab.githubLabelColor = Color(255 , 255 , 255 , 228)

function HomeTab:__init() ; TabBase.__init(self , "Home")
	local topAreaBackground = Rectangle.Create(self.page)
	topAreaBackground:SetPadding(Vector2.One * 2 , Vector2.One * 2)
	topAreaBackground:SetDock(GwenPosition.Top)
	topAreaBackground:SetColor(HomeTab.topAreaBorderColor)
	
	local topArea = ShadedRectangle.Create(topAreaBackground)
	topArea:SetPadding(Vector2.One * 8 , Vector2.One * 8)
	topArea:SetDock(GwenPosition.Top)
	topArea:SetColor(HomeTab.topAreaColor)
	
	local largeName = Label.Create(topArea)
	largeName:SetDock(GwenPosition.Top)
	largeName:SetAlignment(GwenPosition.CenterH)
	largeName:SetTextSize(TextSize.VeryLarge)
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
	
	local groupBoxBindMenu = RaceMenu.CreateGroupBox(self.page)
	groupBoxBindMenu:SetDock(GwenPosition.Left)
	groupBoxBindMenu:SetText("Controls")
	
	local bindMenu = BindMenu.Create(groupBoxBindMenu)
	bindMenu:SetDock(GwenPosition.Fill)
	bindMenu:AddControl("Toggle this menu" , nil)
	bindMenu:RequestSettings()
	
	groupBoxBindMenu:SetWidth(bindMenu:GetWidth())
	
	local groupBoxStats = RaceMenu.CreateGroupBox(self.page)
	groupBoxStats:SetDock(GwenPosition.Fill)
	groupBoxStats:SetText("Personal stats")
	
	self.playerStatsControl = RaceMenuUtility.CreatePlayerStatsControl(groupBoxStats)
	self.playerStatsControl.base:SetDock(GwenPosition.Fill)
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
