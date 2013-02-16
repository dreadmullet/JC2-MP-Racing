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
	
	local lastTextPos = self.startingGridTextPos
	
	-- Reset startingGridTextPos
	self.startingGridTextPos = (
		NormVector2(
			Settings.startingGridBackgroundTopRight.x ,
			Settings.startingGridBackgroundTopRight.y
		) +
		Vector2(
			-Settings.startingGridBackgroundSize.x * Render.Width + Settings.padding ,
			Settings.padding
		)
	)
	
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
	
	-- Set the height of this box to match the text rendered in it last frame.
	local height = lastTextPos.y - self.startingGridTextPos.y
	height = height + Render:GetTextHeight("|" , Settings.startingGridTextSize) * 0.5
	
	local borderSize = 3
	
	Render:FillArea(
		pos ,
		Settings.startingGridBackgroundSize.x * Render.Width ,
		height ,
		Settings.backgroundAltColor
	)
	Render:FillArea(
		pos + Vector2(borderSize , borderSize) ,
		Settings.startingGridBackgroundSize.x * Render.Width + Settings.padding - borderSize*2 ,
		height + Settings.padding - borderSize*2 ,
		Settings.backgroundColor
	)
	
end

function Race:DrawCourseName()
	
	DrawText(
		self:StartingGridTextPos() ,
		self.courseInfo.name ,
		Settings.textColor ,
		Settings.startingGridTextSize
	)
	
end

function Race:DrawCourseType()
	
	DrawText(
		self:StartingGridTextPos() ,
		self.courseInfo.type ,
		Settings.textColor ,
		Settings.startingGridTextSize
	)
	
end

function Race:DrawCourseLength()
	
	DrawText(
		self:StartingGridTextPos() ,
		self.courseLength.."m" ,
		Settings.textColor ,
		Settings.startingGridTextSize
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
		Settings.textColor ,
		Settings.startingGridTextSize
	)
	
end
