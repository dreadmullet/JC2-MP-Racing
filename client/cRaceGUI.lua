----------------------------------------------------------------------------------------------------
-- Functions that race states call to draw the GUI.
----------------------------------------------------------------------------------------------------

-- Draw version at the top right.
RaceGUI.DrawVersion = function(version)
	
	local textSize = Vector2(
		Render:GetTextWidth(version , TextSize.Default) ,
		Render:GetTextHeight(version , TextSize.Default)
	)
	DrawText(
		Vector2(0.875 * Render.Width , textSize.y * 0.5 + 1) ,
		"JC2-MP-Racing "..version ,
		settings.textColor ,
		TextSize.Default ,
		"right"
	)
	
end

-- Draw small course name at the top.
function RaceGUI.DrawCourseName(courseName)
	
	local textSize = Vector2(
		Render:GetTextWidth(courseName , TextSize.Default) ,
		Render:GetTextHeight(courseName , TextSize.Default)
	)
	
	DrawText(
		Vector2(0.5 * Render.Width , textSize.y * 0.5 + 1) ,
		courseName ,
		settings.textColor ,
		TextSize.Default ,
		"center"
	)
	
end

-- Draws a 3D arrow at the top of the screen that points to the target checkpoint.
function RaceGUI.DrawCheckpointArrow(args)
	
	local angleCP = Angle.FromVectors(
		Vector(0 , 0 , -1) ,
		args.checkpointPosition - LocalPlayer:GetPosition()
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
	
	local triangles = Models.arrowTriangles
	
	local color = settings.checkpointArrowColor
	local maxValue = settings.checkpointArrowFlashNum * settings.checkpointArrowFlashInterval * 2
	if
		args.checkpointArrowValue < maxValue and
		math.floor(args.numTicks / settings.checkpointArrowFlashInterval) % 2 == 0
	then
		color = settings.checkpointArrowColorActivated
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

function RaceGUI.DrawLapCounter(args)
	
	local label
	local count
	local total
	
	-- If the course is a circuit, draw the laps.
	-- If the course is linear, draw checkpoint counter.
	if args.courseType == "Circuit" then
		label = "Lap"
		count = args.currentLap
		total = args.totalLaps
	elseif args.courseType == "Linear" then
		label = "CP"
		count = args.targetCheckpoint - 1
		total = args.numCheckpoints
	end
	
	if args.isFinished then
		count = total
	end
	
	-- "Lap/Checkpoint" label
	DrawText(
		NormVector2(settings.lapLabelPos.x , settings.lapLabelPos.y) ,
		label ,
		settings.textColor ,
		settings.lapLabelSize ,
		"center"
	)
	-- Counter (ie "1/3")
	DrawText(
		NormVector2(settings.lapCounterPos.x , settings.lapCounterPos.y) ,
		string.format("%i/%i" , count , total) ,
		settings.textColor ,
		settings.lapCounterSize ,
		"center"
	)
	
end

function RaceGUI.DrawRacePosition(args)
	
	-- "Pos" label
	DrawText(
		NormVector2(settings.racePosLabelPos.x , settings.racePosLabelPos.y) ,
		settings.racePosLabel ,
		settings.textColor ,
		settings.racePosLabelSize ,
		"center"
	)
	-- Race position (ie "5/21")
	DrawText(
		NormVector2(settings.racePosPos.x , settings.racePosPos.y) ,
		string.format("%i/%i" , args.position , args.numPlayers) ,
		settings.textColor ,
		settings.racePosSize ,
		"center"
	)
	
end

function RaceGUI.DrawTimers(args)
	
	local currentY = settings.timerLabelsStart.y
	local advanceY = Render:GetTextHeight("|" , settings.timerLabelsSize) / (Render.Size.y) * 2
	local leftX = (
		settings.timerLabelsStart.x -
		(Render:GetTextWidth("-00:00:00" , settings.timerLabelsSize) / Render.Width) * 2
	)
	
	local AddLine = function(label , value)
		DrawText(
			NormVector2(leftX , currentY) ,
			label ,
			settings.textColor ,
			settings.timerLabelsSize ,
			"right"
		)
		DrawText(
			NormVector2(settings.timerLabelsStart.x , currentY) ,
			value ,
			settings.textColor ,
			settings.timerLabelsSize ,
			"right"
		)
		currentY = currentY + advanceY
	end
	
	AddLine(
		args.recordTimePlayerName..":" ,
		Utility.LapTimeString(args.recordTime)
	)
	
	if args.courseType == "Circuit" then
		AddLine("Previous:" , Utility.LapTimeString(args.previousTime))
	end
	AddLine("Current:" , Utility.LapTimeString(args.currentTime))
	
end

function RaceGUI.DrawLeaderboard(args)
	
	local currentPos = NormVector2(settings.leaderboardPos.x , settings.leaderboardPos.y)
	local textHeight = Render:GetTextHeight("W" , settings.leaderboardTextSize)
	local textWidth = Render:GetTextWidth("W" , settings.leaderboardTextSize)
	
	for n = 1 , math.min(#args.leaderboard , settings.leaderboardMaxPlayers) do
		local playerId = args.leaderboard[n]
		local playerInfo = args.playerIdToInfo[playerId]
		local playerName = playerInfo.name
		
		-- Clamp their name length.
		playerName = playerName:sub(1 , settings.maxPlayerNameLength)
		local playerNameWidth = Render:GetTextWidth(playerName , settings.leaderboardTextSize)
		
		DrawText(
			currentPos ,
			Utility.NumberToPlaceString(n) ,
			settings.textColor ,
			settings.leaderboardTextSize ,
			"left"
		)
		DrawText(
			currentPos + Vector2(textWidth * 2 , 0) ,
			string.format("%s" , playerName) ,
			playerInfo.color ,
			settings.leaderboardTextSize ,
			"left"
		)
		-- If this is us, draw an arrow.
		if playerId == LocalPlayer:GetId() then
			DrawText(
				currentPos + Vector2(textWidth * -1 , 0) ,
				"»" ,
				settings.textColor ,
				settings.leaderboardTextSize ,
				"left"
			)
			DrawText(
				currentPos + Vector2(textWidth * 2.5 + playerNameWidth , 0) ,
				"«" ,
				settings.textColor ,
				settings.leaderboardTextSize ,
				"left"
			)
		end
		
		currentPos.y = currentPos.y + textHeight + 2
	end
	
end

function RaceGUI.DrawPositionTags(args)
	
	for index , playerId in ipairs(args.leaderboard) do
		if playerId ~= LocalPlayer:GetId() then
			RaceGUI.DrawPositionTag(playerId , index)
		end
	end
	
end

function RaceGUI.DrawMinimapIcons(args)
	
	for n = 1 , #args.checkpoints do
		local pos , success = Render:WorldToMinimap(args.checkpoints[n])
		if success then
			
			pos = Vector2(math.floor(pos.x + 0.5) , math.floor(pos.y + 0.5))
			local nextCheckpoint = args.targetCheckpoint + 1
			-- Check if target checkpoint is the start/finish.
			if args.targetCheckpoint == #args.checkpoints then
				-- If this is the last lap, don't draw CP after it.
				if args.courseType == "Circuit" and args.currentLap >= args.numLaps then
					nextCheckpoint = 0
				else
					nextCheckpoint = 1
				end
			end
			if n == args.targetCheckpoint then
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
function RaceGUI.DrawPositionTag(playerId , position)
	
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
	screenPos = screenPos + Vector2(0 , -24)
	
	local size = TextSize.Default
	
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

function RaceGUI.DrawNextCheckpointArrow(args)
	
	-- Don't draw for finish lines.
	if args.targetCheckpoint == #args.checkpoints then
		if args.courseType == "Linear" then
			return
		elseif
			args.courseType == "Circuit" and
			args.numLaps == args.currentLap
		then
			return
		end
	end
	
	local nextCheckpointIndex = args.targetCheckpoint + 1
	-- Check if target checkpoint is the start/finish.
	if
		args.courseType == "Circuit" and
		args.targetCheckpoint == #args.checkpoints
	then
		nextCheckpointIndex = 1
	end
	
	local cpTarget = args.checkpoints[args.targetCheckpoint]
	local cpNext = args.checkpoints[nextCheckpointIndex]
	
	local angle = Angle.FromVectors(
		Vector(0 , 0 , -1) ,
		(cpNext - cpTarget):Normalized()
	)
	angle.roll = 0
	
	local triangles = Models.nextCPArrowTriangles
	
	local distance = Vector.Distance(Camera:GetPosition() , cpTarget)
	
	local color = Copy(settings.nextCheckpointArrowColor)
	local alpha = (140 - distance) / 140 -- From 0 to 1
	alpha = 1 - alpha -- magic
	alpha = alpha ^ 4
	alpha = 1 - alpha
	alpha = alpha * 512 -- From 0 to 512
	alpha = math.clamp(alpha , 0 , color.a) -- From 0 to color's alpha.
	
	local dotMod = Vector.Dot(
		(cpTarget - Camera:GetPosition()):Normalized() ,
		(cpNext - cpTarget):Normalized()
	)
	dotMod = math.clamp(dotMod , 0 , 1) ^ 1.5 -- 0 to 1
	dotMod = math.clamp(dotMod - 0.6 , 0 , 0.4) -- 0 to 0.4
	dotMod = dotMod * 2.5 -- 0 to 1
	dotMod = 1 - dotMod -- 0 to 1
	
	color.a = alpha * dotMod
	
	local pos = cpTarget + Vector(0 , 1.5 , 0)
	
	for n = 1 , #triangles do
		Render:FillTriangle(
			angle * triangles[n][1] + cpTarget ,
			angle * triangles[n][2] + cpTarget ,
			angle * triangles[n][3] + cpTarget ,
			color
		)
	end
	
end
