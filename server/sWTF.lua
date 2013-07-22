
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
