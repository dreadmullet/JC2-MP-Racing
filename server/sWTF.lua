
WTF.RandomiseCourseVehicles = function(course)
	
	local modelIds = {}
	for n = 1 , 10 do
		table.insert(modelIds , VehicleList.SelectRandom().modelId)
	end
	
	for index , spawn in ipairs(course.spawns) do
		spawn.modelIds = modelIds
		spawn.templates = {}
		spawn.decals = {}
	end
	
end

WTF.RandomiseCheckpointActions = function(course)
	
	local names = {}
	table.insert(names , "ActionSpinout")
	table.insert(names , "ActionJump")
	table.insert(names , "ActionTeleportUp")
	table.insert(names , "ActionSpawnBus")
	table.insert(names , "ActionReverseDirection")
	table.insert(names , "ActionRespawnAsPinkTukTuk")
	
	for index , cp in ipairs(course.checkpoints) do
		local chance = 0.3333
		if math.random() < chance then
			local nameToUse = table.randomvalue(names)
			table.insert(cp.actions , nameToUse)
		end
	end
	
end
