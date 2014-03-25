class("Race")

function Race:__init(args) ; RaceBase.__init(self , args)
	Race.instance = self
	
	if settings.debugLevel >= 2 then
		print("Race:__init")
	end
	
	self.assignedVehicleId = -2
	self.lapTimes = {}
	
	Race.currentRaceTab = RaceMenu.instance:AddTab(CurrentRaceTab)
	
	-- Initialize RaceModules.
	for index , moduleName in ipairs(args.raceInfo.modules) do
		local class = RaceModules[moduleName]
		if class then
			class()
		end
	end
	
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
end
