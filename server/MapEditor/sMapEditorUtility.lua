JSON = require("JSON")

MapEditor.LoadFromFile = function(path)
	local file , openError = io.open(path , "r")
	
	if openError then
		error("Cannot load "..tostring(path)..": "..openError)
	end
	
	local jsonString = file:read("*a")
	
	file:close()
	
	local marshalledMap = JSON:decode(jsonString)
	
	return MapEditor.LoadFromMarshalledMap(marshalledMap)
end

MapEditor.LoadFromMarshalledMap = function(map)
	local objectIdToObject = {}
	local objectHash = FNV("Object")
	
	local ProcessProperties = function(properties)
		local typeHash
		local value
		for name , data in pairs(properties) do
			typeHash = data[1]
			value = data[2]
			
			if typeHash == objectHash then
				if type(value) == "table" then
					for index , value in ipairs(value) do
						value = objectIdToObject[value]
					end
				else
					value = objectIdToObject[value]
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
