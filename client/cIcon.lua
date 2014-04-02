class("Icon")

Icon.Type = {
	Enabled = 1 ,
	Disabled = 2
}

Icon.frameEnabledModel = nil
Icon.frameDisabledModel = nil

Icon.colorEnabled = Color(42 , 128 , 12)
Icon.colorDisabled = Color(128 , 8 , 2)

function Icon:__init(objName) ; EGUSM.SubscribeUtility.__init(self)
	self.objName = objName
	self.iconModels = nil
	self.position = Vector2(0 , 0)
	self.size = Vector2(64 , 64)
	self.type = Icon.Type.Enabled
	self.text = nil
	self.isVisible = true
	-- I'm not sure if non-relative works at this point.
	self.useRelative = false
	self.isCentered = false
	
	local args = {
		path = self.objName ,
		type = OBJLoader.Type.MultipleDepthSorted ,
		is2D = true ,
	}
	OBJLoader.Request(args , self , self.ReceiveIconModels)
	
	-- Get the enabled and disabled frame models. They're static, but it's convenient to get them
	-- here.
	args.path = "Models/IconFrameEnabled"
	args.type = OBJLoader.Type.Single
	OBJLoader.Request(args , function(model) Icon.frameEnabledModel = model end)
	args.path = "Models/IconFrameDisabled"
	OBJLoader.Request(args , function(model) Icon.frameDisabledModel = model end)
	
	self:EventSubscribe("Render")
end

function Icon:SetPosition(position)
	self.position = position
end

function Icon:SetSize(size)
	self.size = Vector2(size , size)
end

function Icon:SetType(iconType)
	self.type = iconType
end

function Icon:SetText(text)
	self.text = text
end

function Icon:SetVisible(visible)
	self.isVisible = visible
end

function Icon:SetUseRelative(useRelative)
	self.useRelative = useRelative
end

function Icon:SetIsCentered(isCentered)
	self.isCentered = isCentered
end

function Icon:ReceiveIconModels(models , name)
	self.iconModels = models
end

-- Events

function Icon:Render()
	if Game:GetState() ~= GUIState.Game or self.isVisible == false then
		return
	end
	
	-- Setup transform
	
	local transform = Transform2()
	local translation = self.position
	local scale = self.size
	if self.useRelative then
		translation = NormVector2(translation)
		scale = scale * Render.Height
	end
	if self.isCentered then
		translation = translation - scale / 2
	end
	transform:Translate(translation)
	transform:Scale(scale)
	Render:SetTransform(transform)
	
	-- Models
	
	local DrawModels = function()
		if self.iconModels then
			for index , model in ipairs(self.iconModels) do
				model:Draw()
			end
		end
	end
	
	if self.type == Icon.Type.Enabled then
		local color = Copy(Icon.colorEnabled)
		color.a = 128
		Render:FillArea(Vector2(0.05 , 0.05) , Vector2(0.9 , 0.9) , color)
		DrawModels()
		if Icon.frameEnabledModel then Icon.frameEnabledModel:Draw() end
	elseif self.type == Icon.Type.Disabled then
		local color = Copy(Icon.colorDisabled)
		color.a = 112
		Render:FillArea(Vector2(0.05 , 0.05) , Vector2(0.9 , 0.9) , color)
		DrawModels()
		if Icon.frameDisabledModel then Icon.frameDisabledModel:Draw() end
	end
	
	-- Text
	
	if self.text then
		local fontSize = 12
		local scale = 1
		if self.useRelative then
			fontSize = TextSize.VeryLarge
			scale = 0.15 / TextSize.VeryLarge
		end
		
		transform:Translate(Vector2(0 , 1.04))
		
		if self.isCentered then
			local textWidth = Render:GetTextWidth(self.text , fontSize) * scale
			transform:Translate(Vector2((1 - textWidth) * 0.5 , 0))
		end
		Render:SetTransform(transform)
		
		local color
		if self.type == Icon.Type.Enabled then
			color = Icon.colorEnabled
		elseif self.type == Icon.Type.Disabled then
			color = Icon.colorDisabled
		end
		
		color = math.lerp(color , Color.White , 0.5)
		color.a = 220
		
		Render:DrawText(Vector2() , self.text , Color.Black , fontSize , scale)
		
		transform:Translate(Vector2(0.011 , 0.011))
		Render:SetTransform(transform)
		
		Render:DrawText(Vector2() , self.text , color , fontSize , scale)
	end
	
	Render:ResetTransform()
end
