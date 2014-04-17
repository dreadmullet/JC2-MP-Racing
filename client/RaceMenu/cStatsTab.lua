class("StatsTab")

function StatsTab:__init(...)
	TabBase.__init(self , "Stats" , ...)
	TabManager.__init(self)
	-- It's a tab, but also a tab manager? What has the world come to???
	
	self:CreateTabControl(self.page)
	self.tabControl:SetDock(GwenPosition.Fill)
	
	self:AddTab(PlayersTab)
	self:AddTab(CoursesTab)
end

function StatsTab:OnActivate()
	self:ActivateCurrentTab()
end

function StatsTab:OnDeactivate()
	self:DeactivateCurrentTab()
end
