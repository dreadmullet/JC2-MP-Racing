
function Race:__init(args) ; RaceBase.__init(self , args)
	if settings.debugLevel >= 2 then
		print("Race:__init")
	end
	
	self.recordTime = -1
	self.recordTimePlayerName = ""
	self.assignedVehicleId = -2
	
	self:NetworkSubscribe("RaceSetState")
end

-- Network events

function Race:RaceSetState(args)
	self:SetState(args.stateName , args)
end
