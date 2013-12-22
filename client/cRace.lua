
function Race:__init(args) ; RaceBase.__init(self , args)
	if settings.debugLevel >= 2 then
		print("Race:__init")
	end
	
	self.assignedVehicleId = -2
	
	self:NetworkSubscribe("RaceSetState")
	self:NetworkSubscribe("Terminate")
end

-- Network events

function Race:RaceSetState(args)
	self:SetState(args.stateName , args)
end

function Race:Terminate()
	if settings.debugLevel >= 2 then
		print("Spectate:Terminate")
	end
	self:Destroy()
end
