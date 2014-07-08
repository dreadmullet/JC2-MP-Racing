class("Object" , MapEditor)

function MapEditor.Object:__init(objectData)
	self.Destroy = MapEditor.Object.Destroy
	self.Update = MapEditor.Object.Update
	
	self.data = objectData
	self.position = self.data.position
	self.angle = self.data.angle
end

function MapEditor.Object:Destroy()
	if self.OnDestroy then
		self:OnDestroy()
	end
end

function MapEditor.Object:Update()
	if self.OnUpdate then
		self:OnUpdate()
	end
end
