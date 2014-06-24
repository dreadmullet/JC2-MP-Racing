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

-- This converts the raw, marshalled map into a more convenient table: object ids are converted into
-- objects, and object position/angle are turned into a Vector3 and Angle.
MapEditor.LoadFromMarshalledMap = function(map)
	local objectIdToObject = {}
	local objectHash = FNV("Object")
	local colorHash = FNV("Color")
	
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
	
	for objectIdSometimes , object in pairs(map.objects) do
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
	
	for objectIdSometimes , object in pairs(map.objects) do
		ProcessProperties(object.properties)
	end
	
	ProcessProperties(map.properties)
	
	return map
end
