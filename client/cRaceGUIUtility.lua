
NormX = function(x)
	return (x * 0.5 + 0.5) * Render.Width
end

NormY = function(y)
	return (y * 0.5 + 0.5) * Render.Height
end

-- Normalized coords to pixels. From -1 to 1.
NormVector2 = function(x , y)
	return Vector2(
		(x * 0.5 + 0.5) * Render.Width ,
		(y * 0.5 + 0.5) * Render.Height
	)
end

-- Draws shadowed, aligned text.
DrawText = function(pos , text , color , size , alignment , scale)
	if not text then
		print("Warning: trying to draw nil text! This should never happen!")
		print("pos = " , pos , ", color = " , color , ", size = " , size)
		text = "***ERROR***"
	end
	
	if not alignment then alignment = "left" end
	
	if alignment == "center" then
		pos = pos + Vector2(
			Render:GetTextWidth(text , size) * -0.5 ,
			Render:GetTextHeight(text , size) * -0.5
		)
	elseif alignment == "right" then
		pos = pos + Vector2(
			Render:GetTextWidth(text , size) * -1 ,
			Render:GetTextHeight(text , size) * -0.5
		)
	else -- "left"
		pos = pos + Vector2(
			0 ,
			Render:GetTextHeight(text , size) * -0.5
		)
	end
	
	local shadowColor = Copy(settings.shadowColor)
	shadowColor.a = color.a
	
	Render:DrawText(pos + Vector2(-1 , -1) , text , shadowColor , size , scale or 1)
	Render:DrawText(pos , text , color , size , scale or 1)
end
