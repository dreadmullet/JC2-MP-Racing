class("HomeTab")

HomeTab.topAreaColor = Color.FromHSV(25 , 0.95 , 0.85)
HomeTab.topAreaBorderColor = Color(144 , 144 , 144)
HomeTab.groupBoxColor = Color.FromHSV(150 , 0.06 , 0.775)
HomeTab.githubLabelColor = Color(255 , 255 , 255 , 228)

function HomeTab:__init(raceMenu) ; EGUSM.SubscribeUtility.__init(self)
	self.raceMenu = raceMenu
	
	self.statLabels = {}
	self.rankLabels = {}
	
	self:NetworkSubscribe("ReceivePersonalStats")
	
	-- Create the tab.
	
	self.tabButton = self.raceMenu.tabControl:AddPage("Home")
	
	local homePage = self.tabButton:GetPage()
	homePage:SetPadding(Vector2(2 , 2) , Vector2(2 , 2))
	
	local topAreaBackground = Rectangle.Create(homePage)
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
	
	local groupBoxBindMenu = GroupBox.Create(homePage)
	groupBoxBindMenu:SetDock(GwenPosition.Left)
	groupBoxBindMenu:SetMargin(Vector2(4 , 7) , Vector2(4 , 4))
	groupBoxBindMenu:SetPadding(Vector2(1 , 3) , Vector2(1 , 1))
	groupBoxBindMenu:SetTextColor(HomeTab.groupBoxColor)
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
	groupBoxStats:SetTextColor(HomeTab.groupBoxColor)
	groupBoxStats:SetText("Personal stats")
	groupBoxStats:SetTextSize(24)
	
	local statFontSize = 16
	local rowHeight = Render:GetTextHeight("W" , statFontSize) + 4
	local count = 1
	
	local CreateStat = function(name , isHeader)
		local row = Rectangle.Create(groupBoxStats)
		row:SetPadding(Vector2(4 , 2) , Vector2(5 , 2))
		row:SetDock(GwenPosition.Top)
		row:SetHeight(rowHeight)
		
		local labelName = Label.Create(row)
		labelName:SetDock(GwenPosition.Left)
		labelName:SetTextSize(statFontSize)
		labelName:SetText(name)
		labelName:SetHeight(rowHeight)
		labelName:SetWidthRel(0.5)
		
		local labelValue = Label.Create(row)
		labelValue:SetDock(GwenPosition.Left)
		labelValue:SetTextSize(statFontSize)
		labelValue:SetText("?")
		labelValue:SetHeight(rowHeight)
		labelValue:SetWidthRel(0.25)
		
		local labelRank = Label.Create(row)
		labelRank:SetDock(GwenPosition.Right)
		labelRank:SetAlignment(GwenPosition.Right)
		labelRank:SetTextSize(statFontSize)
		labelRank:SetText("?")
		labelRank:SetHeight(rowHeight)
		labelRank:SetWidthRel(0.25)
		
		local rowColor
		
		if isHeader then
			rowColor = Color.FromHSV(0 , 0 , 0)
			rowColor.a = 40
			row:SetHeight(rowHeight + 2)
			
			labelName:SetText("Stat")
			labelValue:SetText("Value")
			labelRank:SetText("Rank")
		else
			if count % 2 == 0 then
				rowColor = Color.FromHSV(0 , 0 , 1)
				rowColor.a = 16
			else
				rowColor = Color.FromHSV(0 , 0 , 0.5)
				rowColor.a = 16
			end
			
			self.statLabels[name] = labelValue
			self.rankLabels[name] = labelRank
		end
		
		row:SetColor(rowColor)
		
		count = count + 1
	end
	
	CreateStat("." , true)
	CreateStat("Time spent racing")
	CreateStat("Starts")
	CreateStat("Finishes")
	CreateStat("Wins")
end

function HomeTab:OnActivate()
	self.raceMenu:AddRequest("RequestPersonalStats")
end

-- Network events

function HomeTab:ReceivePersonalStats(personalStats)
	Chat:Print("ReceivePersonalStats" , Color.LawnGreen)
	
	local stats = personalStats.stats
	local ranks = personalStats.ranks
	
	local hours , minutes = Utility.SplitSeconds(tonumber(stats.PlayTime))
	local timePlayedString = string.format("%ih, %im" , hours , minutes)
	
	self.statLabels["Time spent racing"]:SetText(timePlayedString)
	self.statLabels.Starts:SetText(tostring(stats.Starts))
	self.statLabels.Finishes:SetText(tostring(stats.Finishes))
	self.statLabels.Wins:SetText(tostring(stats.Wins))
	
	local UpdateRankLabel = function(rankLabel , rank)
		local textColor
		if rank == 1 then
			textColor = Color.FromHSV(60 , 0.75 , 1)
		elseif rank == 2 then
			textColor = Color.FromHSV(190 , 0.1 , 1)
		elseif rank == 3 then
			textColor = Color.FromHSV(42 , 0.65 , 0.95)
		else
			textColor = Color.FromHSV(0 , 0 , 0.85)
		end
		
		rankLabel:SetTextColor(textColor)
		rankLabel:SetText(tostring(rank))
	end
	
	UpdateRankLabel(self.rankLabels["Time spent racing"] , ranks.PlayTime)
	UpdateRankLabel(self.rankLabels.Starts , ranks.Starts)
	UpdateRankLabel(self.rankLabels.Finishes , ranks.Finishes)
	UpdateRankLabel(self.rankLabels.Wins , ranks.Wins)
end
