----------------------------------------------------------------------------------------------------
-- These elements are drawn every frame during the starting grid state.
----------------------------------------------------------------------------------------------------

-- Gets and also increments position.
function Race:StartingGridTextPos()
	
	local textHeight = Render:GetTextHeight("|" , settings.startingGridTextSize)
	
	local previous = self.startingGridTextPos
	self.startingGridTextPos = Vector2(
		self.startingGridTextPos.x ,
		self.startingGridTextPos.y + textHeight
	)
	return previous
	
end

function Race:DrawStartingGridBackground()
	
	local lastTextPos = self.startingGridTextPos
	
	local textHeight = Render:GetTextHeight("|" , settings.startingGridTextSize)
	
	-- Reset startingGridTextPos
	self.startingGridTextPos = (
		NormVector2(
			settings.startingGridBackgroundTopRight.x ,
			settings.startingGridBackgroundTopRight.y
		) +
		Vector2(
			-settings.startingGridBackgroundSize.x * Render.Width + settings.padding ,
			textHeight * 0.5 + settings.padding
		)
	)
	
	local pos = (
		NormVector2(
			settings.startingGridBackgroundTopRight.x ,
			settings.startingGridBackgroundTopRight.y
		) +
		Vector2(
			-settings.startingGridBackgroundSize.x * Render.Width ,
			0
		)
	)
	
	-- Set the height of this box to match the text rendered in it last frame.
	local height = lastTextPos.y - self.startingGridTextPos.y
	height = height + Render:GetTextHeight("|" , settings.startingGridTextSize) * 0.5
	
	local borderSize = 3
	
	Render:FillArea(
		pos ,
		Vector2(settings.startingGridBackgroundSize.x * Render.Width ,	height) ,
		settings.backgroundAltColor
	)
	Render:FillArea(
		pos + Vector2(borderSize , borderSize) ,
		Vector2(
			settings.startingGridBackgroundSize.x * Render.Width + settings.padding - borderSize*2 ,
			height + settings.padding - borderSize*2
		) ,
		settings.backgroundColor
	)
	
end

function Race:DrawCourseName()
	
	DrawText(
		self:StartingGridTextPos() ,
		self.courseInfo.name ,
		settings.textColor ,
		settings.startingGridTextSize
	)
	
end

function Race:DrawCourseType()
	
	DrawText(
		self:StartingGridTextPos() ,
		self.courseInfo.type ,
		settings.textColor ,
		settings.startingGridTextSize
	)
	
end

function Race:DrawCourseLength()
	
	DrawText(
		self:StartingGridTextPos() ,
		self.courseLength.."m" ,
		settings.textColor ,
		settings.startingGridTextSize
	)
	
end

function Race:DrawCourseAuthors()
	
	local authorsString = ""
	if #self.courseInfo.authors == 1 then
		authorsString = "Author: "
	else
		authorsString = "Authors: "
	end
	authorsString = authorsString..table.concat(self.courseInfo.authors , ", ")
	
	DrawText(
		self:StartingGridTextPos() ,
		authorsString ,
		settings.textColor ,
		settings.startingGridTextSize
	)
	
end
