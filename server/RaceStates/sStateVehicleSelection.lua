class("StateVehicleSelection")

-- TODO: Different garages for vehicle type (cars, boats, planes) and perhaps course location.
StateVehicleSelection.garagePosition = Vector3(-6902.009277, 207.25, -10532.0)
StateVehicleSelection.garageAngle = Angle(math.tau * 0.5 , 0 , 0)

function StateVehicleSelection:__init(race) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	self.timer = Timer()
	self.playerIdToVehicleSelector = {}
	-- Array of tables; each table has the following:
	--    modelId = number ,
	--    templates = array of strings ,
	--    available = number ,
	--    used = number
	self.vehicles = Copy(self.race.course.vehicleInfos)
	
	-- Add the 'used' variable to each vehicle info.
	for index , vehicleInfo in ipairs(self.vehicles) do
		vehicleInfo.used = 0
	end
	
	-- Create playerIdToVehicleSelector.
	for playerId , racer in pairs(self.race.playerIdToRacer) do
		self.playerIdToVehicleSelector[playerId] = VehicleSelector(self , racer)
	end
	
	self:EventSubscribe("PreTick")
end

function StateVehicleSelection:End()
	for playerId , vehicleSelector in pairs(self.playerIdToVehicleSelector) do
		vehicleSelector:ApplyToRacer()
		vehicleSelector:Destroy()
	end
	
	self:Destroy()
end

function StateVehicleSelection:ChooseAvailableVehicle()
	local firstIndex = math.random(1 , #self.vehicles)
	local firstTry = self.vehicles[firstIndex]
	if firstTry.used < firstTry.available then
		return firstTry , firstIndex
	end
	
	for index , vehicleInfo in ipairs(self.vehicles) do
		if vehicleInfo.used < vehicleInfo.available then
			return vehicleInfo , index
		end
	end
	
	error("No available model id. This should never happen.")
end

-- Race callbacks

function StateVehicleSelection:RacerLeave(racer)
	local vehicleSelector = self.playerIdToVehicleSelector[racer.player:GetId()]
	vehicleSelector:Destroy()
	self.playerIdToVehicleSelector[racer.player:GetId()] = nil
end

-- Events

function StateVehicleSelection:PreTick()
	if self.timer:GetSeconds() >= self.race.vehicleSelectionSeconds then
		self.race:SetState("StateStartingGrid")
	end
end
