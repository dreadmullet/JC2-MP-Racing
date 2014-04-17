class("AdminTab")

function AdminTab:__init(...) ; TabBase.__init(self , "Admin" , ...)
	AdminTab.instance = self
	
	-- MOTD text box
	
	local base = BaseWindow.Create(AdminTab.instance.page)
	base:SetMargin(Vector2(0 , 4) , Vector2(0 , 4))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(50)
	
	local textBox = TextBoxMultiline.Create(base)
	textBox:SetDock(GwenPosition.Left)
	textBox:SetWidth(180)
	self.motdTextBox = textBox
	
	local button = Button.Create(base)
	button:SetMargin(Vector2(4 , 0) , Vector2(0 , 0))
	button:SetPadding(Vector2(8 , 0) , Vector2(8 , 0))
	button:SetDock(GwenPosition.Left)
	button:SetTextSize(16)
	button:SetText("Set MOTD text")
	button:SizeToContents()
	button:Subscribe("Press" , self , self.MOTDTextBoxAccepted)
	
	-- Kick text box
	
	local base , textBox , label = RaceMenuUtility.CreateLabeledTextBox(self.page)
	base:SetDock(GwenPosition.Top)
	textBox:Subscribe("ReturnPressed" , self , self.KickTextBoxAccepted)
	label:SetText("Kick by name")
	
	-- Ban text box
	
	local base , textBox , label = RaceMenuUtility.CreateLabeledTextBox(self.page)
	base:SetDock(GwenPosition.Top)
	textBox:Subscribe("ReturnPressed" , self , self.BanTextBoxAccepted)
	label:SetText("Ban by name")
	
	-- Fire event.
	
	Events:Fire("RaceAdminInitialize")
end

-- GWEN events

function AdminTab:MOTDTextBoxAccepted()
	RaceMenu.instance:AddRequest("AdminSetMOTD" , self.motdTextBox:GetText())
end

function AdminTab:KickTextBoxAccepted(textBox)
	RaceMenu.instance:AddRequest("AdminKick" , textBox:GetText())
end

function AdminTab:BanTextBoxAccepted(textBox)
	RaceMenu.instance:AddRequest("AdminBan" , textBox:GetText())
end

-- Network events

Network:Subscribe("AdminInitialize" , function()
	if AdminTab.instance == nil then
		RaceMenu.instance:AddTab(AdminTab)
	end
end)
