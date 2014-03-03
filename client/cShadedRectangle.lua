
ShadedRectangle = {}

ShadedRectangle.Create = function(...)
	local baseRect = BaseWindow.Create(...)
	
	local darkRect = Rectangle.Create(baseRect)
	darkRect:SetSizeAutoRel(Vector2.One)
	
	local lightRect = Rectangle.Create(darkRect)
	lightRect:SetHeightAutoRel(0.25)
	lightRect:SetDock(GwenPosition.Top)
	
	baseRect:SetDataObject("darkRect" , darkRect)
	baseRect:SetDataObject("lightRect" , lightRect)
	
	function baseRect:SetColor(color)
		local colorLight = math.lerp(color , Color.White , 0.1)
		colorLight.a = color.a
		
		local darkRect = self:GetDataObject("darkRect")
		darkRect:SetColor(color)
		
		local lightRect = self:GetDataObject("lightRect")
		lightRect:SetColor(colorLight)
	end
	
	baseRect:SetColor(Color.Gray)
	
	return baseRect
end
