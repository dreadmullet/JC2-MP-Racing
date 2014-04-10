class("AdminTab")

function AdminTab:__init() ; TabBase.__init(self , "Admin")
	AdminTab.instance = self
	
	Events:Fire("RaceAdminInitialize")
end

Network:Subscribe("AdminInitialize" , function()
	if AdminTab.instance == nil then
		RaceMenu.instance:AddTab(AdminTab)
	end
end)
