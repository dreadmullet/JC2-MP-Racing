class("HomeTab")

HomeTab.topAreaColor = Color.FromHSV(25 , 0.95 , 0.85)
HomeTab.topAreaBorderColor = Color(160 , 160 , 160)
HomeTab.githubLabelColor = Color(255 , 255 , 255 , 228)

function HomeTab:__init(...) ; TabBase.__init(self , "Home" , ...)
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
	
	local groupBoxMOTD = RaceMenu.CreateGroupBox(self.page)
	groupBoxMOTD:SetDock(GwenPosition.Top)
	groupBoxMOTD:SetHeight(104)
	groupBoxMOTD:SetText("Message of the day")
	
	self.motdLabel = Label.Create(groupBoxMOTD)
	self.motdLabel:SetMargin(Vector2(12 , 2) , Vector2(12 , 2))
	self.motdLabel:SetDock(GwenPosition.Fill)
	self.motdLabel:SetAlignment(GwenPosition.CenterH)
	-- self.motdLabel:SetWrap(true)
	self.motdLabel:SetTextSize(16)
	self.motdLabel:SetTextColor(Color.FromHSV(215 , 0.25 , 0.95))
	self.motdLabel:SetText(settings.motdText)
	
	-- Addon area
	
	RaceMenu.instance.addonArea = BaseWindow.Create(self.page)
	RaceMenu.instance.addonArea:SetDock(GwenPosition.Fill)
	
	self:NetworkSubscribe("SetMOTD")
end

-- RaceMenu callbacks

function HomeTab:OnActivate()
	
end

function HomeTab:OnDeactivate()
	
end

-- Network events

function HomeTab:SetMOTD(text)
	self.motdLabel:SetText(text)
end
