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
	if map.version ~= MapEditor.version then
		local errorMessage = string.format(
			"Map version mismatch: expected version %s, map is version %s" ,
			tostring(MapEditor.version) ,
			tostring(map.version)
		)
		error(errorMessage)
		return
	end
	
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
							value[index] = MapEditor.NoObject
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
	-- Populate objectIdToObject.
	for index , object in pairs(map.objects) do
		if object.id >= objectIdCounter then
			objectIdCounter = object.id + 1
		end
		
		objectIdToObject[object.id] = object
		
		object.localPosition = Vector3(
			object.localPosition[1] ,
			object.localPosition[2] ,
			object.localPosition[3]
		)
		object.localAngle = Angle(
			object.localAngle[1] ,
			object.localAngle[2] ,
			object.localAngle[3] ,
			object.localAngle[4]
		)
		
		object.children = {}
	end
	
	-- Change parent ids to actual objects and populate object children.
	-- Call ProcessProperties on all object properties, as well as the map properties.
	for index , object in pairs(map.objects) do
		if object.parent then
			object.parent = objectIdToObject[object.parent]
			table.insert(object.parent.children , object)
		end
		
		ProcessProperties(object.properties)
	end
	ProcessProperties(map.properties)
	
	-- Calculates global position and angle: start at any top-level objects (those without parents) 
	-- and recursively iterate through their children to calculate their global transforms.
	local RecursivelyCalculateTransform
	RecursivelyCalculateTransform = function(object)
		if object.parent then
			object.angle = object.parent.angle * object.localAngle
			object.position = object.parent.position + object.parent.angle * object.localPosition
		else
			object.angle = object.localAngle
			object.position = object.localPosition
		end
		
		for index , child in ipairs(object.children) do
			RecursivelyCalculateTransform(child)
		end
	end
	for index , object in pairs(map.objects) do
		local isTopLevel = object.parent == nil
		if isTopLevel then
			RecursivelyCalculateTransform(object)
		end
	end
	
	-- Post-processing of certain objects.
	-- newObjects is used because we can't add to map.objects while in the loop or it may skip some
	-- objects.
	local newObjects = {}
	local PostProcessObject
	PostProcessObject = function(object)
		if object.type == "Array" then
			for index , arrayChild in ipairs(object.children) do
				local position = arrayChild.position
				local angle = arrayChild.angle
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
					
					local CopyObject
					CopyObject = function(sourceObject , parent)
						local newObject = {
							id = objectIdCounter ,
							type = sourceObject.type ,
							isClientSide = sourceObject.isClientSide ,
							properties = sourceObject.properties ,
							parent = parent ,
							children = {} ,
						}
						
						if parent then
							newObject.angle = parent.angle * sourceObject.localAngle
							newObject.position = parent.position + parent.angle * sourceObject.localPosition
						else
							newObject.position = position
							newObject.angle = angle
						end
						
						objectIdCounter = objectIdCounter + 1
						
						table.insert(newObjects , newObject)
						
						for index , child in ipairs(sourceObject.children) do
							table.insert(newObject.children , CopyObject(child , newObject))
						end
						
						return newObject
					end
					
					CopyObject(arrayChild , nil)
				end
			end
		end
	end
	for index , object in pairs(map.objects) do
		PostProcessObject(object)
	end
	
	-- Apply newObjects. The while loop is because, in post processing, the new object can create
	-- more new objects, which themselves can create new objects. Fun stuff.
	while #newObjects > 0 do
		local newObjectsCopy = newObjects
		newObjects = {}
		for index , newObject in ipairs(newObjectsCopy) do
			map.objects[newObject.id] = newObject
			PostProcessObject(newObject)
		end
	end
	
	-- Change parent and children to use ids.
	-- Remove local position/angle and parent/children from objects. Once client-side map editor code
	-- has moving stuff, it should probably only send local position/angle, but I'm keeping it simple
	-- for now.
	for index , object in pairs(map.objects) do
		object.localPosition = nil
		object.localAngle = nil
		
		if object.parent then
			object.parent = object.parent.id
		end
		for index , child in ipairs(object.children) do
			object.children[index] = child.id
		end
	end
	
	return map
end
