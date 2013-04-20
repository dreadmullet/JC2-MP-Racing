
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
	
	local Y = 1
	local Z = 1.825
	local arrowHead = 5
	
	Models.nextCPArrowTriangles = {
		{
			Vector(0 , -Y , Z + arrowHead*0.33) ,
			Vector(0 , Y , Z + arrowHead*0.33) ,
			Vector(0 , Y , -Z)
		} ,
		{
			Vector(0 , -Y , Z + arrowHead*0.33) ,
			Vector(0 , Y , -Z) ,
			Vector(0 , -Y , -Z)
		} ,
		{
			Vector(0 , -Y*arrowHeadWidthMult , -Z) ,
			Vector(0 , Y*arrowHeadWidthMult , -Z) ,
			Vector(0 , 0 , -Z - arrowHead*0.66)
		} ,
	}
	
end
