class("StateVehicleSelection")

-- TODO: Different garages for vehicle type (cars, boats, planes) and perhaps course location.
StateVehicleSelection.garagePosition = Vector3(-6902.009277, 207.25, -10532.0)
StateVehicleSelection.garageAngle = Angle(math.tau * 0.5 , 0 , 0)

function StateVehicleSelection:__init(race) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	self.spawns = self.race.course.spawns
	self.timer = Timer()
	self.playerIdToVehicleSelector = {}
	-- Array of tables; each table has the following:
	--    modelId = number ,
	--    templates = array of strings ,
	--    available = number ,
	--    used = number
	self.vehicles = Copy(self.race.course.vehicleInfos)
	
	-- If this race has more players than spawns, add that many extra to each vehicle.
	local extraVehicles = 0
	if self.race.numPlayers > #self.spawns then
		extraVehicles = self.race.numPlayers - #self.spawns
	end
	
	-- Add the 'used' variable to each vehicle info and change the available counts, if necessary.
	for index , vehicleInfo in ipairs(self.vehicles) do
		vehicleInfo.used = 0
		vehicleInfo.available = vehicleInfo.available + extraVehicles
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
