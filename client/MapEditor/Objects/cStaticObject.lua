class("StaticObject" , MapEditor.Objects)

function MapEditor.Objects.StaticObject:__init(...) ; MapEditor.Object.__init(self , ...)
	self.staticObject = nil
	self.isEnabled = false
	self.visibleRangeSqr = self.data.properties.visibleRange * self.data.properties.visibleRange
	
	self:SetEnabled(false)
end

function MapEditor.Objects.StaticObject:OnUpdate()
	local distanceSqr = Vector3.DistanceSqr(Camera:GetPosition() , self.position)
	local isWithinRange = distanceSqr <= self.visibleRangeSqr
	
	if self.isEnabled then
		if isWithinRange == false then
			self:SetEnabled(false)
		end
	else
		if isWithinRange == true then
			self:SetEnabled(true)
		end
	end
end

function MapEditor.Objects.StaticObject:SetEnabled(enabled)
	if self.isEnabled == enabled then
		return
	end
	
	-- Hopefully this fixes broken collision that happens a lot.
	if self.isEnabled and LocalPlayer:IsTeleporting() then
		return
	end
	
	self.isEnabled = enabled
	
	if self.isEnabled then
		local model = self.data.properties.model
		
		local collision
		if self.data.properties.collisionEnabled == true then
			collision = self.GetCollision(model)
		end
		
		self.staticObject = ClientStaticObject.Create{
			position = self.position ,
			angle = self.angle ,
			model = model ,
			collision = collision ,
		}
	else
		if self.staticObject then
			self.staticObject:Remove()
			self.staticObject = nil
		end
	end
end

function MapEditor.Objects.StaticObject:OnDestroy()
	self:SetEnabled(false)
end

MapEditor.Objects.StaticObject.collisionFixes = {
	["general.bl/go200-a1.lod"] =              "general.blz/go200_lod1-a_col.pfx" ,
	["general.blz/go200-a1.lod"] =             "general.blz/go200_lod1-a_col.pfx" ,
}

MapEditor.Objects.StaticObject.vegetationKeywords = {
	"vegetation_0" ,
	"vegetation_1" ,
	"vegetation_2" ,
	"vegetation_3" ,
	"/jungle_" ,
}

MapEditor.Objects.StaticObject.GetCollision = function(model)
	-- Try to get the collision path from collisionFixes above because Avalanche is terrible at
	-- naming things.
	local collisionFix = MapEditor.Objects.StaticObject.collisionFixes[model]
	if collisionFix then
		return collisionFix
	end
	-- Otherwise, calculate the collision path depending on if the model is vegetation or not
	-- because Avalanche is terrible at naming things.
	local isVegetation = false
	for index , keyword in ipairs(MapEditor.Objects.StaticObject.vegetationKeywords) do
		if model:find(keyword , 1 , true) then
			isVegetation = true
			break
		end
	end
	if isVegetation then
		return model:gsub(".lod" , "_COL.pfx")
	else
		return model:gsub("-" , "_lod1-"):gsub("%.lod" , "_col.pfx")
	end
end
