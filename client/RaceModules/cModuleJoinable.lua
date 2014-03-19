
class("Joinable" , RaceModules)

function RaceModules.Joinable:__init()
	-- Add a leave button to the current race tab.
	local leaveButton = Button.Create(Race.instance.currentRaceTab.page)
	leaveButton:SetDock(GwenPosition.Top)
	leaveButton:SetText("Leave race")
	leaveButton:SizeToContents()
	leaveButton:SetHeight(32)
	leaveButton:Subscribe("Press" , self , self.LeaveButtonPressed)
end

-- Gwen events

function RaceModules.Joinable:LeaveButtonPressed()
	Network:Send("LeaveRace" , ".")
end
