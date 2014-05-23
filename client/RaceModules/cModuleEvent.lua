class("Event" , RaceModules)

function RaceModules.Event:__init() ; EGUSM.SubscribeUtility.__init(self)
	self.endRaceButton = nil
	self.isOwner = false
	
	Network:Send("RequestRaceOwners" , RaceBase.instance.id)
	
	self:EventSubscribe("RaceEnd" , self.RaceOrSpectateEnd)
	self:EventSubscribe("SpectateEnd" , self.RaceOrSpectateEnd)
	self:EventSubscribe("RaceFinish")
	self:NetworkSubscribe("ReceiveRaceOwners")
end

-- Gwen events

function RaceModules.Event:EndRaceButtonPressed()
	Network:Send("OwnerEndRace" , {})
end

-- Events

function RaceModules.Event:RaceOrSpectateEnd()
	if self.endRaceButton then
		self.endRaceButton:Remove()
	end
	
	self:Destroy()
end

function RaceModules.Event:RaceFinish()
	if self.isOwner then
		RaceBase.instance:Message(
			string.format("Open the race menu (/%s) to end the race." , settings.command)
		)
	end
end

-- Network events

function RaceModules.Event:ReceiveRaceOwners(owners)
	if table.find(owners , LocalPlayer) then
		self.isOwner = true
		
		local button = Button.Create(RaceMenu.instance.addonArea)
		button:SetDock(GwenPosition.Top)
		button:SetTextSize(16)
		button:SetText("End race")
		button:SizeToContents()
		button:SetHeight(36)
		button:Subscribe("Press" , self , self.EndRaceButtonPressed)
		self.endRaceButton = button
	end
end
