class("StaticObject" , MapEditor.Objects)

function MapEditor.Objects.StaticObject:__init(...) ; MapEditor.Object.__init(self , ...)
	self.staticObject = nil
	self.isEnabled = false
	self.requiredRangeSqr = 500 * 500
	
	self:SetEnabled(false)
end

function MapEditor.Objects.StaticObject:OnUpdate()
	local distanceSqr = Vector3.DistanceSqr(Camera:GetPosition() , self.position)
	local isWithinRange = distanceSqr <= self.requiredRangeSqr
	
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
		
		local collision = model:gsub("-", "_lod1-"):gsub("%.lod", "_col.pfx")
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
