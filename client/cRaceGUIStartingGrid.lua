----------------------------------------------------------------------------------------------------
-- These elements are drawn every frame during the starting grid state.
----------------------------------------------------------------------------------------------------

-- Gets and also increments position.
function Race:StartingGridTextPos()
	
	local textHeight = Render:GetTextHeight("|" , Settings.startingGridTextSize)
	
	local previous = self.startingGridTextPos
	self.startingGridTextPos = Vector2(
		self.startingGridTextPos.x ,
		self.startingGridTextPos.y + textHeight
	)
	return previous
	
end

function Race:DrawStartingGridBackground()
	
	local pos = (
		NormVector2(
			Settings.startingGridBackgroundTopRight.x ,
			Settings.startingGridBackgroundTopRight.y
		) +
		Vector2(
			-Settings.startingGridBackgroundSize.x * Render.Width ,
			0
		)
	)
	
	local borderSize = 3
	
	Render:FillArea(
		pos ,
		Settings.startingGridBackgroundSize.x * Render.Width ,
		Settings.startingGridBackgroundSize.y * Render.Height ,
		Settings.backgroundAltColor
	)
	Render:FillArea(
		pos + Vector2(borderSize , borderSize) ,
		Settings.startingGridBackgroundSize.x * Render.Width - borderSize*2 ,
		Settings.startingGridBackgroundSize.y * Render.Height - borderSize*2 ,
		Settings.backgroundColor
	)
	
end

function Race:DrawCourseName()
	
	local courseName = self.courseInfo.name or "INVALID COURSE NAME"
	local textWidth = Render:GetTextWidth("courseName" , Settings.startingGridTextSize)
	
	DrawText(
		self:StartingGridTextPos() ,
		courseName ,
		Settings.textColor ,
		Settings.startingGridTextSize
	)
	
end

function Race:DrawCourseType()
	
	local textWidth = Render:GetTextWidth("courseName" , Settings.startingGridTextSize)
	
	DrawText(
		self:StartingGridTextPos() ,
		self.courseInfo.type ,
		Settings.textColor ,
		Settings.startingGridTextSize
	)
	
end

function Race:DrawCourseLength()
	
	local textWidth = Render:GetTextWidth("courseName" , Settings.startingGridTextSize)
	
	DrawText(
		self:StartingGridTextPos() ,
		self.courseLength.."m" ,
		Settings.textColor ,
		Settings.startingGridTextSize
	)
	
end