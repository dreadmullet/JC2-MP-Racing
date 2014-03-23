class("VehicleSelector")

function VehicleSelector:__init(state , racer) ; EGUSM.SubscribeUtility.__init(self)
	-- Expose functions.
	self.Destroy = VehicleSelector.Destroy
	
	self.state = state
	self.race = state.race
	self.spawns = state.race.course.spawns
	self.racer = racer
	self.world = World.Create()
	self.vehicleIndex = -1
	self.templateIndex = -1
	self.vehicle = nil
	self.color1 = self.racer.player:GetColor() * 0.85
	self.color2 = self.racer.player:GetColor()
	
	-- World
	self.world:SetTime(self.race.world:GetTime())
	self.world:SetWeatherSeverity(self.race.world:GetWeatherSeverity())
	self.racer.player:SetWorld(self.world)
	-- Vehicle info
	local vehicleInfo
	vehicleInfo , self.vehicleIndex = self.state:ChooseAvailableVehicle()
	self.templateIndex = math.random(1 , #vehicleInfo.templates)
	vehicleInfo.used = vehicleInfo.used + 1
	-- Spawn the vehicle
	self:SpawnVehicle()
	-- Send info to client.
	local args = {
		stateName = "StateVehicleSelection" ,
		vehicles = self.state.vehicles ,
		vehicleIndex = self.vehicleIndex ,
		templateIndex = self.templateIndex ,
		color1 = self.color1 ,
		color2 = self.color2 ,
		vehicleId = self.vehicle:GetId() ,
		garagePosition = StateVehicleSelection.garagePosition ,
		garageAngle = StateVehicleSelection.garageAngle ,
	}
	Network:Send(self.racer.player , "RaceSetState" , args)
	
	self:NetworkSubscribe("VehicleSelectionLoaded")
	self:NetworkSubscribe("VehicleSelected")
	self:NetworkSubscribe("VehicleTemplateSelected")
	self:NetworkSubscribe("VehicleSetColors")
end

function VehicleSelector:SpawnVehicle()
	if self.vehicle then
		self.vehicle:Remove()
	end
	
	local vehicleInfo = self.state.vehicles[self.vehicleIndex]
	self.vehicle = Vehicle.Create({
		model_id = vehicleInfo.modelId ,
		position = StateVehicleSelection.garagePosition ,
		angle = StateVehicleSelection.garageAngle ,
		template = vehicleInfo.templates[self.templateIndex] ,
		tone1 = self.color1 ,
		tone2 = self.color2 ,
		world = self.world ,
	})
end

function VehicleSelector:Destroy()
	local vehicleInfo = self.state.vehicles[self.vehicleIndex]
	vehicleInfo.used = vehicleInfo.used - 1
	
	self.world:Remove()
	
	EGUSM.SubscribeUtility.Destroy(self)
end

function VehicleSelector:ApplyToRacer()
	local vehicleInfo = self.state.vehicles[self.vehicleIndex]
	self.racer.vehicleInfo = {
		modelId = vehicleInfo.modelId ,
		template = vehicleInfo.templates[self.templateIndex] ,
		color1 = self.color1 ,
		color2 = self.color2 ,
	}
end

-- Network events

function VehicleSelector:VehicleSelectionLoaded(unused , player)
	if IsValid(self.racer.player) == false then
		EGUSM.Print("self.racer.player is not valid! I have no idea why this happens")
		EGUSM.Print("The actual player is "..tostring(player))
		EGUSM.Print("Removing them from the race. Sorry :(")
		self.state.race:RemovePlayer(player)
		return
	end
	if player ~= self.racer.player then
		return
	end
	
	-- Reset the vehicle's position in case it moved (to the client's perspective, anyway).
	self.vehicle:SetPosition(StateVehicleSelection.garagePosition)
	-- Acknowledge their initialization and give them the initial counts of vehicles.
	local vehicleUsages = {}
	for index , vehicleInfo in ipairs(self.state.vehicles) do
		table.insert(vehicleUsages , {modelId = vehicleInfo.modelId , count = vehicleInfo.used})
	end
	Network:Send(self.racer.player , "VehicleSelectionInitialize" , vehicleUsages)
end

function VehicleSelector:VehicleSelected(vehicleIndex , player)
	if player ~= self.racer.player then
		return
	end
	
	-- Check client arguments.
	if
		type(vehicleIndex) ~= "number" or
		vehicleIndex < 1 or
		vehicleIndex > #self.state.vehicles
	then
		return
	end
	local vehicleInfo = self.state.vehicles[vehicleIndex]
	if vehicleInfo.used == vehicleInfo.available then
		return
	end
	
	local oldVehicleInfo = self.state.vehicles[self.vehicleIndex]
	oldVehicleInfo.used = oldVehicleInfo.used - 1
	
	self.vehicleIndex = vehicleIndex
	self.templateIndex = 1
	
	vehicleInfo.used = vehicleInfo.used + 1
	
	self:SpawnVehicle()
	
	Network:Send(self.racer.player , "VehicleSelected" , vehicleIndex)
	
	local vehicleUsages = {
		{modelId = oldVehicleInfo.modelId , count = oldVehicleInfo.used} ,
		{modelId = vehicleInfo.modelId , count = vehicleInfo.used} ,
	}
	self.state.race:NetworkSendRace("ReceiveVehicleUsages" , vehicleUsages)
end

function VehicleSelector:VehicleTemplateSelected(templateIndex , player)
	if player ~= self.racer.player then
		return
	end
	
	-- Check client arguments.
	if
		type(templateIndex) ~= "number" or
		templateIndex < 1 or
		templateIndex > #self.state.vehicles[self.vehicleIndex].templates
	then
		return
	end
	
	self.templateIndex = templateIndex
	
	self:SpawnVehicle()
	
	Network:Send(self.racer.player , "VehicleTemplateSelected" , templateIndex)
end

function VehicleSelector:VehicleSetColors(colors , player)
	if player ~= self.racer.player then
		return
	end
	
	-- Check client arguments.
	if type(colors) ~= "table" then
		return
	end
	
	local color1 , color2 = colors[1] , colors[2]
	
	-- Check client arguments.
	if
		type(color1) ~= "userdata" or
		color1.__type ~= "Color" or
		type(color2) ~= "userdata" or
		color2.__type ~= "Color"
	then
		return
	end
	
	self.color1 , self.color2 = color1 , color2
	
	self.vehicle:SetColors(color1 , color2)
end
