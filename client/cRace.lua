class("Race")

function Race:__init(args) ; RaceBase.__init(self , args)
	Race.instance = self
	
	if settings.debugLevel >= 2 then
		print("Race:__init")
	end
	
	self.assignedVehicleId = -2
	self.lapTimes = {}
	
	Race.currentRaceTab = RaceMenu.instance:AddTab(CurrentRaceTab)
	
	self:InitializeRaceModules()
	
	Events:Fire("RaceCreate")
	
	self:NetworkSubscribe("RaceSetState")
	self:NetworkSubscribe("Terminate")
end

-- Network events

function Race:RaceSetState(args)
	self:SetState(args.stateName , args)
end

function Race:Terminate()
	Events:Fire("RaceEnd")
	
	if settings.debugLevel >= 2 then
		print("Race:Terminate")
	end
	
	RaceMenu.instance:RemoveTab(self.currentRaceTab)
	
	self:Destroy()
	
	Race.instance = nil
end
