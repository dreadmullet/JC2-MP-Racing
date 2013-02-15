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
		Vector2(0.5 * Render.Width - textSize.x*0.5 , textSize.y*0 + 3) ,
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
	
	-- Compensate position for change in FOV.
	local z = -8.25
	local y = 3
	local vehicle = LocalPlayer:GetVehicle()
	if vehicle then
		z = z + vehicle:GetLinearVelocity():Length() / 25
		y = y + vehicle:GetLinearVelocity():Length() / 350
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
	
	local label
	local count
	local total
	
	-- If the course is a circuit, draw the laps.
	-- If the course is linear, draw checkpoint counter.
	if self.courseInfo.type == "circuit" then
		label = "Lap"
		count = self.lapCount
		total = self.courseInfo.laps
	elseif self.courseInfo.type == "linear" then
		label = "CP"
		count = self.targetCheckpoint - 1
		total = #self.checkpoints
	end
	
	-- "Lap/Checkpoint" label
	DrawText(
		NormVector2(Settings.lapLabelPos.x , Settings.lapLabelPos.y) ,
		label ,
		Settings.textColor ,
		Settings.lapLabelSize ,
		"center"
	)
	-- Counter (ie "1/3")
	DrawText(
		NormVector2(Settings.lapCounterPos.x , Settings.lapCounterPos.y) ,
		string.format("%i/%i" , count , total) ,
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
	
	for n = 1 , math.min(#self.leaderboard , Settings.leaderboardMaxPlayers) do
		local playerId = self.leaderboard[n]
		local playerInfo = self.playerIdToInfo[playerId]
		local playerName = playerInfo.name
		
		-- Clamp their name length.
		playerName = playerName:sub(1 , Settings.maxPlayerNameLength)
		local playerNameWidth = Render:GetTextWidth(playerName , Settings.leaderboardTextSize)
		
		DrawText(
			currentPos ,
			Utility.NumberToPlaceString(n) ,
			Settings.textColor ,
			Settings.leaderboardTextSize ,
			"left"
		)
		DrawText(
			currentPos + Vector2(textWidth * 2 , 0) ,
			string.format("%s" , playerName) ,
			playerInfo.color ,
			Settings.leaderboardTextSize ,
			"left"
		)
		-- If this is us, draw an arrow.
		if playerId == LocalPlayer:GetId() then
			DrawText(
				currentPos + Vector2(textWidth * -1 , 0) ,
				"»" ,
				Settings.textColor ,
				Settings.leaderboardTextSize ,
				"left"
			)
			DrawText(
				currentPos + Vector2(textWidth * 2.5 + playerNameWidth , 0) ,
				"«" ,
				Settings.textColor ,
				Settings.leaderboardTextSize ,
				"left"
			)
		end
		
		-- Always draw ther players' position tag, for now.
		if Settings.useNametags == false and playerId ~= LocalPlayer:GetId() then
			self:DrawPositionTag(playerId , n)
		end
		
		currentPos.y = currentPos.y + textHeight + 2
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

-- Draws position tag above someone. ("1st", for example)
function Race:DrawPositionTag(playerId , position)
	
	local worldPos
	
	local player = Player.GetById(playerId)
	if not IsValid(player) then
		return
	end
	
	local vehicle = player:GetVehicle()
	if IsValid(vehicle) then
		worldPos = vehicle:GetPosition()
	else
		worldPos = player:GetPosition()
	end
	
	local worldPos = worldPos + Vector(0 , 2 , 0)
	local screenPos , onScreen = Render:WorldToScreen(worldPos)
	if not onScreen then
		return
	end
	
	local size = "Default"
	
	local scale = 1
	if position == 1 then
		scale = 1.25
	end
	
	DrawText(
		screenPos ,
		Utility.NumberToPlaceString(position) ,
		player:GetColor() ,
		size ,
		"center" ,
		scale
	)
	
end
