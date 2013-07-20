
Minimap = {}
local M = Minimap


function M.DrawTargetCheckpoint(pos)
	
	Render:FillArea(pos + Vector2(-4 , -4) , Vector2(2 , 2) , settings.minimapCheckpointColor2)
	Render:FillArea(pos + Vector2(3 , -4) , Vector2(2 , 2) , settings.minimapCheckpointColor2)
	Render:FillArea(pos + Vector2(3 , 3) , Vector2(2 , 2) , settings.minimapCheckpointColor2)
	Render:FillArea(pos + Vector2(-4 , 3) , Vector2(2 , 2) , settings.minimapCheckpointColor2)
	
	Render:FillArea(pos + Vector2(-5 , -2) , Vector2(2 , 5) , settings.minimapCheckpointColor2)
	Render:FillArea(pos + Vector2(4 , -2) , Vector2(2 , 5) , settings.minimapCheckpointColor2)
	Render:FillArea(pos + Vector2(-2 , -5) , Vector2(5 , 2) , settings.minimapCheckpointColor2)
	Render:FillArea(pos + Vector2(-2 , 4) , Vector2(5 , 2) , settings.minimapCheckpointColor2)
	
	
	Render:FillArea(pos + Vector2(-5 , -1) , Vector2(1 , 3) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(5 , -1) , Vector2(1 , 3) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(-1 , -5) , Vector2(3 , 1) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(-1 , 5) , Vector2(3 , 1) , settings.minimapCheckpointColor1)
	
	Render:FillArea(pos + Vector2(-4 , -3) , Vector2(1 , 2) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(4 , -3) , Vector2(1 , 2) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(-4 , 2) , Vector2(1 , 2) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(4 , 2) , Vector2(1 , 2) , settings.minimapCheckpointColor1)
	
	Render:FillArea(pos + Vector2(-3 , -4) , Vector2(2 , 1) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(2 , -4) , Vector2(2 , 1) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(-3 , 4) , Vector2(2 , 1) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(2 , 4) , Vector2(2 , 1) , settings.minimapCheckpointColor1)
	
end

function M.DrawNextTargetCheckpoint(pos)
	
	Render:FillArea(pos + Vector2(-2 , -2) , Vector2(2 , 2) , settings.minimapCheckpointColor2)
	Render:FillArea(pos + Vector2(1 , -2) , Vector2(2 , 2) , settings.minimapCheckpointColor2)
	Render:FillArea(pos + Vector2(-2 , 1) , Vector2(2 , 2) , settings.minimapCheckpointColor2)
	Render:FillArea(pos + Vector2(1 , 1) , Vector2(2 , 2) , settings.minimapCheckpointColor2)
	
	Render:FillArea(pos + Vector2(-1 , -2) , Vector2(3 , 1) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(-1 , 2) , Vector2(3 , 1) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(-2 , -1) , Vector2(1 , 3) , settings.minimapCheckpointColor1)
	Render:FillArea(pos + Vector2(2 , -1) , Vector2(1 , 3) , settings.minimapCheckpointColor1)
	
end

function M.DrawGreyCheckpoint(pos)
	
	Render:FillArea(pos + Vector2(-3 , -3) , Vector2(7 , 7) , settings.minimapCheckpointColorGrey2)
	Render:FillArea(pos + Vector2(-2 , -2) , Vector2(5 , 5) , settings.minimapCheckpointColorGrey1)
	
end


