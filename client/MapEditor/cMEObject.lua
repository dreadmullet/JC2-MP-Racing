class("Object" , MapEditor)

function MapEditor.Object:__init(objectData)
	self.Destroy = MapEditor.Object.Destroy
	-- self.Update = MapEditor.Object.Update
	-- self.SetEnabled = MapEditor.Object.SetEnabled
	
	self.data = objectData
	
	-- self.isEnabled = true
end

function MapEditor.Object:Destroy()
	if self.OnDestroy then
		self:OnDestroy()
	end
end

-- function MapEditor.Object:Update()
	-- if self.OnUpdate then
		-- self:OnUpdate()
	-- end
-- end

-- function MapEditor.Object:SetEnabled(enabled)
	-- if self.isEnabled == enabled then
		-- return
	-- end
	
	-- if self.isEnabled then
		-- if self.OnEnabled then
			-- self:OnEnabled()
		-- end
	-- else
		-- if self.OnDisabled then
			-- self:OnDisabled()
		-- end
	-- end
-- end
