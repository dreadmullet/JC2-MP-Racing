class("MapInstance" , MapEditor)

-- I borrowed this code from an ancient version of Racing, which was borrowed from when I was new at
-- Lua and playing around with tables. Let's hope me from 2 years ago wasn't an idiot.
MapEditor.MapInstance.CopyTable = function(t , copiedTables)
	-- this will be returned as the copied table
	local tCopy = {}
	-- helps with tables that reference other tables
	-- that reference the fist table, etc
	-- key = old table that has been copied
	-- value new table
	if not copiedTables then copiedTables = {} end
	copiedTables[t] = tCopy
	
	for key , value in pairs(t) do
		if type(value) == "table" then
			if copiedTables[value] then
				tCopy[key] = copiedTables[value]
			else
				tCopy[key] = MapEditor.MapInstance.CopyTable(value , copiedTables)
			end
		else
			tCopy[key] = value
		end
	end
	
	return tCopy
end

function MapEditor.MapInstance:__init(map)
	self.map = map
	-- Copy objects map to a more convenient type-to-object-array map.
	-- Key: object type
	-- Value: array of objects (with any object-type properties replaced with object ids)
	self.objectTypeToObjects = {}
	
	for prettySureThisIsNeverActuallyTheObjectId , object in pairs(self.map.objects) do
		if self.objectTypeToObjects[object.type] == nil then
			self.objectTypeToObjects[object.type] = {}
		end
		
		-- Eeeeuuuuuuurrrrrggghhh
		-- Deep copy the object and change any object properties to use the object id instead. So it's
		-- reverting part of the work of MapEditor.LoadFromMarshalledMap, but I don't know a nice way
		-- of keeping the old data or something.
		local copiedObject = self.CopyTable(object)
		for propertyName , propertyValue in ipairs(copiedObject.properties) do
			if type(propertyValue) == "table" then
				if propertyValue.id ~= nil then
					-- This property is an Object.
					copiedObject.properties[propertyName] = propertyValue.id
				elseif #propertyValue > 0 and propertyValue[1].id ~= nil then
					-- This property is a table of Objects.
					for index , object in ipairs(propertyValue) do
						propertyValue[index] = object.id
					end
				end
			end
		end
		
		-- Fix for Angle inaccuracy when sent to clients.
		local a = copiedObject.angle
		copiedObject.angle = {a.x , a.y , a.z , a.w}
		
		table.insert(self.objectTypeToObjects[object.type] , copiedObject)
	end
	
	self.clientObjects = {}
	for objectType , objects in pairs(self.objectTypeToObjects) do
		if objects[1].isClientSide then
			for index , object in ipairs(objects) do
				table.insert(self.clientObjects , object)
			end
		end
	end
	
	self.players = {}
end

function MapEditor.MapInstance:Destroy()
	-- Remove all of our players.
	for index , player in ipairs(self.players) do
		self:RemovePlayer(player)
	end
end

function MapEditor.MapInstance:AddPlayer(player)
	table.insert(self.players , player)
	
	Network:Send(player , "InitializeMapInstance" , self.clientObjects)
end

function MapEditor.MapInstance:RemovePlayer(player)
	local index = table.find(self.players , player)
	if index == nil then
		error("Cannot find player: "..tostring(player))
	end
	table.remove(self.players , index)
	
	Network:Send(player , "TerminateMapInstance")
end
