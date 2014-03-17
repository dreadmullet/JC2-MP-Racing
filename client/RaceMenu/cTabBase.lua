class("TabBase")

function TabBase:__init(name) ; EGUSM.SubscribeUtility.__init(self)
	self.tabButton = RaceMenu.instance.tabControl:AddPage(name)
	self.tabButton:SetDataObject("tab" , self)
	
	self.page = self.tabButton:GetPage()
	self.page:SetPadding(Vector2(2 , 2) , Vector2(2 , 2))
end
