class("Light" , MapEditor.Objects)

function MapEditor.Objects.Light:__init(objectData) ; MapEditor.Object.__init(self , objectData)
	self.light = ClientLight.Create{
		position = objectData.position ,
		color = objectData.properties.color ,
		multiplier = objectData.properties.multiplier ,
		radius = objectData.properties.radius ,
		constant_attenuation = objectData.properties.constant_attenuation ,
		linear_attenuation = objectData.properties.linear_attenuation ,
		quadratic_attenuation = objectData.properties.quadratic_attenuation ,
	}
end

function MapEditor.Objects.Light:OnDestroy()
	self.light:Remove()
end
