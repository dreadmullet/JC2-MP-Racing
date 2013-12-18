
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
			Vector3(-X , -Y , Z) ,
			Vector3(X , -Y , Z) ,
			Vector3(X , -Y , -Z)
		} ,
		{
			Vector3(-X , -Y , Z) ,
			Vector3(X , -Y , -Z) ,
			Vector3(-X , -Y , -Z)
		} ,
		{
			Vector3(-X*arrowHeadWidthMult , -Y , -Z) ,
			Vector3(X*arrowHeadWidthMult , -Y , -Z) ,
			Vector3(0 , -Y , -Z - arrowHead)
		} ,
		-- Top
		{
			Vector3(-X , Y , Z) ,
			Vector3(X , Y , Z) ,
			Vector3(X , Y , -Z)
		} ,
		{
			Vector3(-X , Y , Z) ,
			Vector3(X , Y , -Z) ,
			Vector3(-X , Y , -Z)
		} ,
		{
			Vector3(-X*arrowHeadWidthMult , Y , -Z) ,
			Vector3(X*arrowHeadWidthMult , Y , -Z) ,
			Vector3(0 , Y , -Z - arrowHead)
		} ,
		-- Back
		{
			Vector3(-X , -Y , Z) ,
			Vector3(X , -Y , Z) ,
			Vector3(X , Y , Z)
		} ,
		{
			Vector3(-X , -Y , Z) ,
			Vector3(X , Y , Z) ,
			Vector3(-X , Y , Z)
		} ,
		-- Front
		{
			Vector3(-X*arrowHeadWidthMult , -Y , -Z) ,
			Vector3(X*arrowHeadWidthMult , -Y , -Z) ,
			Vector3(X*arrowHeadWidthMult , Y , -Z)
		} ,
		{
			Vector3(-X*arrowHeadWidthMult , -Y , -Z) ,
			Vector3(X*arrowHeadWidthMult , Y , -Z) ,
			Vector3(-X*arrowHeadWidthMult , Y , -Z)
		} ,
		-- Left
		{
			Vector3(-X , -Y , Z) ,
			Vector3(-X , -Y , -Z) ,
			Vector3(-X , Y , -Z)
		} ,
		{
			Vector3(-X , -Y , Z) ,
			Vector3(-X , Y , -Z) ,
			Vector3(-X , Y , Z)
		} ,
		-- Right
		{
			Vector3(X , -Y , Z) ,
			Vector3(X , -Y , -Z) ,
			Vector3(X , Y , -Z)
		} ,
		{
			Vector3(X , -Y , Z) ,
			Vector3(X , Y , -Z) ,
			Vector3(X , Y , Z)
		} ,
		-- Front left
		{
			Vector3(-X*arrowHeadWidthMult , -Y , -Z) ,
			Vector3(-X*arrowHeadWidthMult , Y , -Z) ,
			Vector3(0 , Y , -Z - arrowHead)
		} ,
		{
			Vector3(-X*arrowHeadWidthMult , -Y , -Z) ,
			Vector3(0 , -Y , -Z - arrowHead) ,
			Vector3(0 , Y , -Z - arrowHead)
		} ,
		-- Front right
		{
			Vector3(X*arrowHeadWidthMult , -Y , -Z) ,
			Vector3(X*arrowHeadWidthMult , Y , -Z) ,
			Vector3(0 , Y , -Z - arrowHead)
		} ,
		{
			Vector3(X*arrowHeadWidthMult , -Y , -Z) ,
			Vector3(0 , -Y , -Z - arrowHead) ,
			Vector3(0 , Y , -Z - arrowHead)
		}
	}
	
end
-- Flat version. Just in case the solid version is horribly slow.
do
	
	local X = arrowWidth
	local Z = arrowLength
	
	Models.arrowTrianglesFast = {
		{
			Vector3(-X , 0 , Z) ,
			Vector3(X , 0 , Z) ,
			Vector3(X , 0 , -Z)
		} ,
		{
			Vector3(-X , 0 , Z) ,
			Vector3(X , 0 , -Z) ,
			Vector3(-X , 0 , -Z)
		} ,
		{
			Vector3(-X*arrowHeadWidthMult , 0 , -Z) ,
			Vector3(X*arrowHeadWidthMult , 0 , -Z) ,
			Vector3(0 , 0 , -Z - arrowHead)
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
			Vector3(0 , -Y , Z + arrowHead*0.25) ,
			Vector3(0 , Y , Z + arrowHead*0.25) ,
			Vector3(0 , Y , -Z)
		} ,
		{
			Vector3(0 , -Y , Z + arrowHead*0.25) ,
			Vector3(0 , Y , -Z) ,
			Vector3(0 , -Y , -Z)
		} ,
		{
			Vector3(0 , -Y*arrowHeadWidthMult , -Z) ,
			Vector3(0 , Y*arrowHeadWidthMult , -Z) ,
			Vector3(0 , 0 , -Z - arrowHead*0.5)
		} ,
	}
	
end
