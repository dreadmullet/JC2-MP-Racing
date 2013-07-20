
RenderModel = function(model , pos , angle , color)
	
	for n = 1 , #model do
		if #model[n] == 3 then
			Render:FillTriangle(
				angle * model[n][1] + pos ,
				angle * model[n][2] + pos ,
				angle * model[n][3] + pos ,
				color
			)
		elseif #model[n] == 2 then
			Render:DrawLine(
				angle * model[n][1] + pos ,
				angle * model[n][2] + pos ,
				color
			)
		end
	end
	
end

Models = {}

-- Checkpoint pointer arrow.
local arrowWidth = 0.18
local arrowLength = 0.58
local arrowHead = 0.70
local arrowHeadWidthMult = 3
local arrowHeight = 0.0375
do
	
	local X = arrowWidth
	local Y = arrowHeight
	local Z = arrowLength
	
	Models.arrowTriangles = {
		-- Bottom
		{
			Vector(-X , -Y , Z) ,
			Vector(X , -Y , Z) ,
			Vector(X , -Y , -Z)
		} ,
		{
			Vector(-X , -Y , Z) ,
			Vector(X , -Y , -Z) ,
			Vector(-X , -Y , -Z)
		} ,
		{
			Vector(-X*arrowHeadWidthMult , -Y , -Z) ,
			Vector(X*arrowHeadWidthMult , -Y , -Z) ,
			Vector(0 , -Y , -Z - arrowHead)
		} ,
		-- Top
		{
			Vector(-X , Y , Z) ,
			Vector(X , Y , Z) ,
			Vector(X , Y , -Z)
		} ,
		{
			Vector(-X , Y , Z) ,
			Vector(X , Y , -Z) ,
			Vector(-X , Y , -Z)
		} ,
		{
			Vector(-X*arrowHeadWidthMult , Y , -Z) ,
			Vector(X*arrowHeadWidthMult , Y , -Z) ,
			Vector(0 , Y , -Z - arrowHead)
		} ,
		-- Back
		{
			Vector(-X , -Y , Z) ,
			Vector(X , -Y , Z) ,
			Vector(X , Y , Z)
		} ,
		{
			Vector(-X , -Y , Z) ,
			Vector(X , Y , Z) ,
			Vector(-X , Y , Z)
		} ,
		-- Front
		{
			Vector(-X*arrowHeadWidthMult , -Y , -Z) ,
			Vector(X*arrowHeadWidthMult , -Y , -Z) ,
			Vector(X*arrowHeadWidthMult , Y , -Z)
		} ,
		{
			Vector(-X*arrowHeadWidthMult , -Y , -Z) ,
			Vector(X*arrowHeadWidthMult , Y , -Z) ,
			Vector(-X*arrowHeadWidthMult , Y , -Z)
		} ,
		-- Left
		{
			Vector(-X , -Y , Z) ,
			Vector(-X , -Y , -Z) ,
			Vector(-X , Y , -Z)
		} ,
		{
			Vector(-X , -Y , Z) ,
			Vector(-X , Y , -Z) ,
			Vector(-X , Y , Z)
		} ,
		-- Right
		{
			Vector(X , -Y , Z) ,
			Vector(X , -Y , -Z) ,
			Vector(X , Y , -Z)
		} ,
		{
			Vector(X , -Y , Z) ,
			Vector(X , Y , -Z) ,
			Vector(X , Y , Z)
		} ,
		-- Front left
		{
			Vector(-X*arrowHeadWidthMult , -Y , -Z) ,
			Vector(-X*arrowHeadWidthMult , Y , -Z) ,
			Vector(0 , Y , -Z - arrowHead)
		} ,
		{
			Vector(-X*arrowHeadWidthMult , -Y , -Z) ,
			Vector(0 , -Y , -Z - arrowHead) ,
			Vector(0 , Y , -Z - arrowHead)
		} ,
		-- Front right
		{
			Vector(X*arrowHeadWidthMult , -Y , -Z) ,
			Vector(X*arrowHeadWidthMult , Y , -Z) ,
			Vector(0 , Y , -Z - arrowHead)
		} ,
		{
			Vector(X*arrowHeadWidthMult , -Y , -Z) ,
			Vector(0 , -Y , -Z - arrowHead) ,
			Vector(0 , Y , -Z - arrowHead)
		}
	}
	
end
-- Flat version. Just in case the solid version is horribly slow.
do
	
	local X = arrowWidth
	local Z = arrowLength
	
	Models.arrowTrianglesFast = {
		{
			Vector(-X , 0 , Z) ,
			Vector(X , 0 , Z) ,
			Vector(X , 0 , -Z)
		} ,
		{
			Vector(-X , 0 , Z) ,
			Vector(X , 0 , -Z) ,
			Vector(-X , 0 , -Z)
		} ,
		{
			Vector(-X*arrowHeadWidthMult , 0 , -Z) ,
			Vector(X*arrowHeadWidthMult , 0 , -Z) ,
			Vector(0 , 0 , -Z - arrowHead)
		} ,
	}
	
end

-- Checkpoint
do
	
	local Y = 0.75
	local Z = 1.35
	local arrowHead = 3.75
	
	Models.nextCPArrowTriangles = {
		{
			Vector(0 , -Y , Z + arrowHead*0.25) ,
			Vector(0 , Y , Z + arrowHead*0.25) ,
			Vector(0 , Y , -Z)
		} ,
		{
			Vector(0 , -Y , Z + arrowHead*0.25) ,
			Vector(0 , Y , -Z) ,
			Vector(0 , -Y , -Z)
		} ,
		{
			Vector(0 , -Y*arrowHeadWidthMult , -Z) ,
			Vector(0 , Y*arrowHeadWidthMult , -Z) ,
			Vector(0 , 0 , -Z - arrowHead*0.5)
		} ,
	}
	
end

----------------------------------------------------------------------------------------------------
-- Course editor
----------------------------------------------------------------------------------------------------

-- Object spawner gizmo, used for the course editor.
do
	
	local radius = 1
	local height = 3.5
	local numSegments = 7
	
	local segmentAngle = (math.pi*2) / numSegments
	
	Models.objectSpawnerGizmo = {}
	for n = 0 , numSegments - 1 do
		local angle1 = segmentAngle * n
		local angle2 = segmentAngle * (n + 1)
		table.insert(
			Models.objectSpawnerGizmo ,
			{
				Vector(0 , 0 , 0) ,
				Vector(math.cos(angle1) * radius , height , math.sin(angle1) * radius) ,
				Vector(math.cos(angle2) * radius , height , math.sin(angle2) * radius)
			}
		)
	end
	
end

-- Used for the course editor's checkpoint spawner gizmo.
do
	
	local radius = 9.5
	local numSegments = 13
	
	local segmentAngle = (math.pi*2) / numSegments
	
	Models.checkpoint = {}
	for n = 0 , numSegments - 1 do
		
		local angle1 = segmentAngle * n
		local angle2 = segmentAngle * (n + 1)
		local angleMid = math.lerp(angle1 , angle2 , 0.5)
		
		local pos1 = Angle.AngleAxis(angle1 , Vector(0 , 0 , -1)) * Vector(radius , 0 , 0)
		local pos2 = Angle.AngleAxis(angleMid , Vector(0 , 0 , -1)) * Vector(radius*1.15 , 0 , 0)
		local pos3 = Angle.AngleAxis(angle2 , Vector(0 , 0 , -1)) * Vector(radius , 0 , 0)
		
		table.insert(
			Models.checkpoint ,
			{
				pos1 ,
				pos2 ,
				pos3
			}
		)
		
	end
	
end

-- Vehicle spawn gizmo.
do
	
	local width = 3
	local length = 5.25
	local height = 0.3333
	
	Models.vehicleSpawn = {}
	
	local Line = function(a , b)
		table.insert(
			Models.vehicleSpawn ,
			{a , b , b + Vector(0 , height , 0)}
		)
		table.insert(
			Models.vehicleSpawn ,
			{a , a + Vector(0 , height , 0) , b + Vector(0 , height , 0)}
		)
	end
	
	-- Create the box.
	Line(
		Vector(width * -0.5 , 0 , length * 0.5) ,
		Vector(width * -0.5 , 0 , length * -0.5)
	)
	Line(
		Vector(width * -0.5 , 0 , length * -0.5) ,
		Vector(width * 0.5 , 0 , length * -0.5)
	)
	Line(
		Vector(width * 0.5 , 0 , length * -0.5) ,
		Vector(width * 0.5 , 0 , length * 0.5)
	)
	Line(
		Vector(width * 0.5 , 0 , length * 0.5) ,
		Vector(width * -0.5 , 0 , length * 0.5)
	)
	-- Create the arrow.
	Line(
		Vector(0 , 1 , length * 0.3333) ,
		Vector(0 , 1 , length * -0.3333)
	)
	Line(
		Vector(0 , 1 , length * -0.3333) ,
		Vector(width * 0.3333 , 1 , length * -0.075)
	)
	Line(
		Vector(0 , 1 , length * -0.3333) ,
		Vector(width * -0.3333 , 1 , length * -0.075)
	)
	
end
