----------------------------------------------------------------------------------------------------
-- These elements are drawn every frame during the racing state,.
----------------------------------------------------------------------------------------------------

-- Draw small course name at the top.
function Race:DrawCourseNameRace()
	
	local courseName = self.courseInfo.name or "INVALID COURSE NAME"
	
	local textSize = Vector2(
		Render:GetTextWidth(courseName , "Default") ,
		Render:GetTextHeight(courseName , "Default")
	)
	
	DrawText(
		Vector2(0.5 * Render.Width - textSize.x*0.5 , textSize.y * 0 + 3) ,
		courseName ,
		Settings.textColor ,
		"Default" ,
		"left"
	)
	
end

-- Draws a 3D arrow at the top of the screen that points to the target checkpoint.
function Race:DrawCheckpointArrow()
	
	-- print("Drawing checkpoint arrow!")
	
	local maxValue = Settings.checkpointArrowFlashNum*2 * Settings.checkpointArrowFlashInterval
	
	-- Always try to increment the value.
	self.checkpointArrowActivationValue = self.checkpointArrowActivationValue + 1
	-- Always clamp, too.
	if self.checkpointArrowActivationValue > maxValue then
		self.checkpointArrowActivationValue = maxValue
	end
	
	local angleCP = Angle.FromVectors(
		Vector(0 , 0 , -1) ,
		self.checkpoints[self.targetCheckpoint] - LocalPlayer:GetPosition()
	)
	angleCP.roll = 0
	
	local z = -8.25
	local y = 3
	local vehicle = LocalPlayer:GetVehicle()
	if vehicle then
		z = z + vehicle:GetLinearVelocity():Length() / 20
		y = y + vehicle:GetLinearVelocity():Length() / 300
	end
	local pos = Camera:GetPosition() + Camera:GetAngle() * Vector(0 , y , z)
	
	-- Set what model to draw based on Settings.guiQuality.
	local triangles
	if Settings.guiQuality == 0 then
		triangles = Models.arrowTriangles
	elseif Settings.guiQuality == -1 then
		triangles = Models.arrowTrianglesFast
	end
	
	local color = Settings.checkpointArrowColor
	if
		self.checkpointArrowActivationValue < maxValue and
		math.floor(self.numTicksRace / Settings.checkpointArrowFlashInterval) % 2 == 0
	then
		color = Settings.checkpointArrowColorActivated
	end
	
	for n = 1 , #triangles do
		Render:FillTriangle(
			angleCP * triangles[n][1] + pos ,
			angleCP * triangles[n][2] + pos ,
			angleCP * triangles[n][3] + pos ,
			color
		)
	end
	
end

function Race:DrawLapCounter()
	
	-- Make sure the course is a circuit.
	if self.courseInfo.type ~= "circuit" then
		return
	end
	
	-- "Lap" label
	DrawText(
		NormVector2(Settings.lapLabelPos.x , Settings.lapLabelPos.y) ,
		Settings.lapLabel ,
		Settings.textColor ,
		Settings.lapLabelSize ,
		"center"
	)
	-- Counter (ie "1/3")
	DrawText(
		NormVector2(Settings.lapCounterPos.x , Settings.lapCounterPos.y) ,
		string.format("%i/%i" , self.lapCount , self.courseInfo.laps) ,
		Settings.textColor ,
		Settings.lapCounterSize ,
		"center"
	)
	
	
end

function Race:DrawRacePosition()
	
	-- "Pos" label
	DrawText(
		NormVector2(Settings.racePosLabelPos.x , Settings.racePosLabelPos.y) ,
		Settings.racePosLabel ,
		Settings.textColor ,
		Settings.racePosLabelSize ,
		"center"
	)
	-- Race position (ie "5/21")
	DrawText(
		NormVector2(Settings.racePosPos.x , Settings.racePosPos.y) ,
		string.format("%i/%i" , self.racePosition , self.playerCount) ,
		Settings.textColor ,
		Settings.racePosSize ,
		"center"
	)
	
end

function Race:DrawLeaderboard()
	
	local currentPos = NormVector2(Settings.leaderboardPos.x , Settings.leaderboardPos.y)
	local textHeight = Render:GetTextHeight("W" , Settings.leaderboardTextSize)
	local textWidth = Render:GetTextWidth("W" , Settings.leaderboardTextSize)
	
	for n = 1 , #self.leaderboard do
		local player = Player.GetById(self.leaderboard[n])
		
		if player then
			local playerName = player:GetName()
			
			-- Clamp their name length.
			playerName = playerName:sub(1 , Settings.maxPlayerNameLength)
			
			DrawText(
				currentPos ,
				string.format("%i." , n) ,
				Settings.textColor ,
				Settings.leaderboardTextSize ,
				"left"
			)
			DrawText(
				currentPos + Vector2(textWidth * 2 , 0) ,
				string.format("%s" , playerName) ,
				player:GetColor() ,
				Settings.leaderboardTextSize ,
				"left"
			)
			currentPos.y = currentPos.y + textHeight + 2
		else
			-- print("Player from GetById is nil! This should never happen!")
		end
	end
	
end

function Race:DrawMinimapIcons()
	
	-- Don't draw minimap icons if quality is too low.
	if Settings.guiQuality < 0 then
		return
	end
	
	for n = 1 , #self.checkpoints do
		local pos , success = Render:WorldToMinimap(self.checkpoints[n])
		if success then
			
			pos = Vector2(math.floor(pos.x + 0.5) , math.floor(pos.y + 0.5))
			local nextCheckpoint = self.targetCheckpoint + 1
			-- Check if target checkpoint is the start/finish.
			if self.targetCheckpoint == #self.checkpoints then
				-- If this is the last lap, don't draw CP after it.
				if self.courseInfo.type == "circuit" and self.lapCount >= self.courseInfo.laps then
					nextCheckpoint = 0
				else
					nextCheckpoint = 1
				end
			end
			if n == self.targetCheckpoint then
				Minimap.DrawTargetCheckpoint(pos)
			elseif n == nextCheckpoint then
				Minimap.DrawNextTargetCheckpoint(pos)
			else
				Minimap.DrawGreyCheckpoint(pos)
			end
			
		end
	end
	
end
