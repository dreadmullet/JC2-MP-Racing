class("MapInstance" , MapEditor)

function MapEditor.MapInstance:__init(objectsData)
	MapEditor.mapInstance = self
	
	self.objects = {}
	
	-- Create all of our objects.
	for index , objectData in ipairs(objectsData) do
		local classType = MapEditor.Objects[objectData.type]
		if classType then
			table.insert(self.objects , classType(objectData))
		else
			warn("Cannot create map editor object of type "..tostring(objectData.type))
		end
	end
	
	self.objectIndex = 1
	
	self.tickSub = Events:Subscribe("PreTick" , self , self.PreTick)
	self.terminateSub = Network:Subscribe("TerminateMapInstance" , self , self.Terminate)
end

-- Events

function MapEditor.MapInstance:PreTick()
	if #self.objects == 0 then
		return
	end
	
	-- Iterate over a few of our objects each frame.
	for n = 1 , math.min(15 , #self.objects) do
		self.objectIndex = self.objectIndex - 1
		if self.objectIndex < 1 then
			self.objectIndex = #self.objects
		end
		
		local object = self.objects[self.objectIndex]
		object:Update()
	end
end

function MapEditor.MapInstance:Terminate()
	-- Destroy all of our objects.
	for index , object in ipairs(self.objects) do
		object:Destroy()
	end
	
	MapEditor.mapInstance = nil
	
	Events:Unsubscribe(self.tickSub)
	Network:Unsubscribe(self.terminateSub)
end

Network:Subscribe("InitializeMapInstance" , function(objects)
	if MapEditor.mapInstance then
		error("A map editor instance already exists!")
	end
	
	MapEditor.MapInstance(objects)
end)
