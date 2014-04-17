class("TabBase")

function TabBase:__init(name , tabControl) ; EGUSM.SubscribeUtility.__init(self)
	self.tabButton = tabControl:AddPage(name)
	self.tabButton:SetDataObject("tab" , self)
	
	self.page = self.tabButton:GetPage()
	self.page:SetPadding(Vector2(2 , 2) , Vector2(2 , 2))
end
