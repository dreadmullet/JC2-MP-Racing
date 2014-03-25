class("StateVehicleSelection")

-- TODO: Different garages for vehicle type (cars, boats, planes) and perhaps course location.
StateVehicleSelection.garagePosition = Vector3(-6902.009277, 207.25, -10532.0)
StateVehicleSelection.garageAngle = Angle(math.tau * 0.5 , 0 , 0)

function StateVehicleSelection:__init(race) ; EGUSM.SubscribeUtility.__init(self)
	self.race = race
	self.spawns = self.race.course.spawns
	self.timer = Timer()
	self.playerIdToVehicleSelector = {}
	-- Array of tables: {templates = array of strings , available = number , used = number}
	self.vehicles = {}
	
	-- Populate temporary vehicles map.
	local vehicles = {}
	for index , courseSpawn in ipairs(self.spawns) do
		-- Map to help with removing duplicate model ids.
		local modelIds = {}
		for index , modelId in ipairs(courseSpawn.modelIds) do
			-- If there are no templates, make a blank one.
			if #courseSpawn.templates == 0 then
				courseSpawn.templates = {"."}
			end
			
			if vehicles[modelId] then
				vehicles[modelId].templates[courseSpawn.templates[index]] = true
				if modelIds[modelId] == nil then
					vehicles[modelId].available = vehicles[modelId].available + 1
					modelIds[modelId] = true
				end
			else
				vehicles[modelId] = {
					templates = {[courseSpawn.templates[index]] = true} ,
					available = 1 ,
				}
				modelIds[modelId] = true
			end
		end
	end
	-- Translate vehicles (map) into self.vehicles (array).
	for modelId , vehicleInfo in pairs(vehicles) do
		local templates = {}
		for template , alwaysTrue in pairs(vehicleInfo.templates) do
			table.insert(templates , template)
		end
		
		local vehicleInfo = {
			modelId = modelId ,
			templates = templates ,
			available = vehicleInfo.available ,
			used = 0 ,
		}
		table.insert(self.vehicles , vehicleInfo)
	end
	
	-- Create playerIdToVehicleSelector.
	for playerId , racer in pairs(self.race.playerIdToRacer) do
		self.playerIdToVehicleSelector[playerId] = VehicleSelector(self , racer)
	end
	
	self:EventSubscribe("PreTick")
end

function StateVehicleSelection:End()
	for playerId , vehicleSelector in pairs(self.playerIdToVehicleSelector) do
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
	if self.timer:GetSeconds() >= settings.vehicleSelectionSeconds then
		for playerId , vehicleSelector in pairs(self.playerIdToVehicleSelector) do
			vehicleSelector:ApplyToRacer()
		end
		
		self.race:SetState("StateStartingGrid")
	end
end
