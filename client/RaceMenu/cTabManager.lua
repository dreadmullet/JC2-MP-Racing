class("TabManager")

function TabManager:__init(parent)
	-- Expose functions
	self.CreateTabControl = TabManager.CreateTabControl
	self.AddTab = TabManager.AddTab
	self.RemoveTab = TabManager.RemoveTab
	self.ActivateCurrentTab = TabManager.ActivateCurrentTab
	self.DeactivateCurrentTab = TabManager.DeactivateCurrentTab
	
	self.tabControl = nil
	self.tabs = {}
	self.currentTab = nil
end

function TabManager:CreateTabControl(parent)
	self.tabControl = TabControl.Create(parent)
	self.tabControl:SetTabStripPosition(GwenPosition.Top)
	self.tabControl:SetBackgroundVisible(false)
	self.addTabSub = self.tabControl:Subscribe("AddTab" , self , TabManager.OnAddTab)
	self.tempFix = true
end

function TabManager:AddTab(tabClass)
	local instance = tabClass(self)
	table.insert(self.tabs , instance)
	
	instance.__id = {}
	
	return instance
end

function TabManager:RemoveTab(tabToRemove)
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

function TabManager:ActivateCurrentTab()
	self.currentTab = self.tabControl:GetCurrentTab():GetDataObject("tab")
	
	if self.currentTab.OnActivate then
		self.currentTab:OnActivate()
	end
end

function TabManager:DeactivateCurrentTab()
	if self.currentTab.OnDeactivate then
		self.currentTab:OnDeactivate()
	end
end

-- GWEN events

function TabManager:OnAddTab()
	-- self.tabControl:Unsubscribe(self.addTabSub)
	if self.tempFix then
		self.tabControl:Subscribe("TabSwitch" , self , TabManager.TabSwitch)
		self.tempFix = false
	end
end

function TabManager:TabSwitch()
	if self.currentTab then
		self:DeactivateCurrentTab()
	end
	
	self:ActivateCurrentTab()
end
