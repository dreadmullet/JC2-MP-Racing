MapEditor.LoadFromFile = function(path)
	local file , openError = io.open(path , "r")
	
	if openError then
		error("Cannot load "..tostring(path)..": "..openError)
	end
	
	local jsonString = file:read("*a")
	
	file:close()
	
	local marshalledMap = MapEditor.JSON:decode(jsonString)
	
	return MapEditor.LoadFromMarshalledMap(marshalledMap)
end

-- This converts the raw, marshalled map into a more convenient table:
--    * object ids are converted into objects.
--    * object position/angle are turned into a Vector3 and Angle.
--    * Array objects are applied.
MapEditor.LoadFromMarshalledMap = function(map)
	local objectIdToObject = {}
	local objectIdCounter = 1
	local objectHash = FNV("Object")
	local colorHash = FNV("Color")
	
	-- Converts object ids to objects and marshalled colors to Colors.
	local ProcessProperties = function(properties)
		local isTable , typeHash , value
		for name , data in pairs(properties) do
			isTable = data[1] == 1
			typeHash = data[2]
			value = data[3]
			
			if typeHash == objectHash then
				if isTable then
					for index , objectId in ipairs(value) do
						if objectId ~= -1 then
							value[index] = objectIdToObject[objectId]
						else
							value = nil
						end
					end
				else
					if value ~= -1 then
						value = objectIdToObject[value]
					else
						value = nil
					end
				end
			elseif typeHash == colorHash then
				if isTable then
					for index , v in ipairs(value) do
						value[index] = Color(v[1] , v[2] , v[3] , v[4])
					end
				else
					value = Color(value[1] , value[2] , value[3] , value[4])
				end
			end
			
			properties[name] = value
		end
	end
	
	-- Convert object position/angle to actual Vector3s and Angles.
	for objectIdSometimes , object in pairs(map.objects) do
		if object.id >= objectIdCounter then
			objectIdCounter = object.id + 1
		end
		
		objectIdToObject[object.id] = object
		
		object.position = Vector3(
			object.position[1] ,
			object.position[2] ,
			object.position[3]
		)
		object.angle = Angle(
			object.angle[1] ,
			object.angle[2] ,
			object.angle[3] ,
			object.angle[4]
		)
	end
	
	-- Call ProcessProperties on all object properties, as well as the map properties.
	for objectIdSometimes , object in pairs(map.objects) do
		ProcessProperties(object.properties)
	end
	ProcessProperties(map.properties)
	
	-- After-processing of certain objects.
	for objectIdSometimes , object in pairs(map.objects) do
		if object.type == "Array" then
			local sourceObject = object.properties.sourceObject
			if sourceObject then
				local position = sourceObject.position
				local angle = sourceObject.angle
				local offsetPosition = Vector3(
					object.properties.offsetX ,
					object.properties.offsetY ,
					object.properties.offsetZ
				)
				local offsetAngle = Angle(
					math.rad(object.properties.offsetYaw) ,
					math.rad(object.properties.offsetPitch) ,
					math.rad(object.properties.offsetRoll)
				)
				local relativeOffsetPosition = Vector3(
					object.properties.relativeOffsetX ,
					object.properties.relativeOffsetY ,
					object.properties.relativeOffsetZ
				)
				local relativeOffsetAngle = Angle(
					math.rad(object.properties.relativeOffsetYaw) ,
					math.rad(object.properties.relativeOffsetPitch) ,
					math.rad(object.properties.relativeOffsetRoll)
				)
				
				local Next = function()
					position = position + angle * relativeOffsetPosition
					angle = angle * relativeOffsetAngle
					
					position = position + offsetPosition
					angle = offsetAngle * angle
				end
				
				for n = 1 , object.properties.count do
					Next()
					
					local newObject = {
						id = objectIdCounter ,
						type = sourceObject.type ,
						position = position ,
						angle = angle ,
						isClientSide = sourceObject.isClientSide ,
						properties = sourceObject.properties ,
					}
					objectIdCounter = objectIdCounter + 1
					
					map.objects[newObject.id] = newObject
				end
			end
		end
	end
	
	return map
end
