class("HomeTab")

HomeTab.topAreaColor = Color.FromHSV(25 , 0.95 , 0.85)
HomeTab.topAreaBorderColor = Color(144 , 144 , 144)
HomeTab.githubLabelColor = Color(255 , 255 , 255 , 228)

function HomeTab:__init() ; EGUSM.SubscribeUtility.__init(self)	
	self:NetworkSubscribe("ReceivePlayerStats")
	
	-- Create the tab.
	
	self.tabButton = RaceMenu.instance.tabControl:AddPage("Home")
	
	local page = self.tabButton:GetPage()
	page:SetPadding(Vector2(2 , 2) , Vector2(2 , 2))
	
	local topAreaBackground = Rectangle.Create(page)
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
	
	local groupBoxBindMenu = RaceMenu.CreateGroupBox(page)
	groupBoxBindMenu:SetDock(GwenPosition.Left)
	groupBoxBindMenu:SetText("Controls")
	
	local bindMenu = BindMenu.Create(groupBoxBindMenu)
	bindMenu:SetDock(GwenPosition.Fill)
	bindMenu:AddControl("Toggle this menu" , nil)
	bindMenu:RequestSettings()
	
	groupBoxBindMenu:SetWidth(bindMenu:GetWidth())
	
	local groupBoxStats = RaceMenu.CreateGroupBox(page)
	groupBoxStats:SetDock(GwenPosition.Fill)
	groupBoxStats:SetText("Personal stats")
	
	self.playerStatsControl = RaceMenuUtility.CreatePlayerStatsControl(groupBoxStats)
	self.playerStatsControl.base:SetDock(GwenPosition.Fill)
end

function HomeTab:OnActivate()
	RaceMenu.instance:AddRequest("RequestPlayerStats" , LocalPlayer:GetSteamId().id)
end

-- Network events

function HomeTab:ReceivePlayerStats(playerStats)
	if playerStats.steamId ~= LocalPlayer:GetSteamId().id then
		return
	end
	
	self.playerStatsControl:Update(playerStats)
end
