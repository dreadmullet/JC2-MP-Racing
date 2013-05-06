
CourseCheckpoint.color = Color(220 , 20 , 15 , 180)
CourseCheckpoint.maxDistanceSquared = 400 * 400

function CourseCheckpoint:__init(course)
	
	self.course = course
	self.index = -1
	self.position = nil
	self.radius = 12.05
	-- nil = Allow all vehicles and on-foot.
	-- {} -- Allow all vehicles but not on-foot.
	-- {0} = Only allow on-foot.
	self.validVehicles = nil
	-- When racer enters checkpoint, this function of ours is called. One argument: racer.
	self.action = ""
	
	self.gizmoColor = Copy(CourseCheckpoint.color)
	
	self.renderEvent = Events:Subscribe("Render" , self , self.Render)
	
end

function CourseCheckpoint:Render()
	
	-- Don't draw while in menus.
	if not Client:InState(GUIState.Game) then
		return
	end
	
	-- Only render if close enough.
	local distanceSquared = (Camera:GetPosition() - self.position):LengthSqr()
	if distanceSquared <= CourseCheckpoint.maxDistanceSquared then
		local angle = Camera:GetAngle()
		RenderModel(Models.checkpoint , self.position , angle , self.gizmoColor)
	end
	
end

function CourseCheckpoint:Destroy()
	
	Events:Unsubscribe(self.renderEvent)
	
end


function CourseCheckpoint.Demarshal(course , checkpointInfo)
	
	local checkpoint = CourseCheckpoint()
	
	checkpoint.courseEditorId = checkpointInfo.courseEditorId
	checkpoint.position = checkpointInfo.position
	checkpoint.radius = checkpointInfo.radius
	checkpoint.validVehicles = checkpointInfo.validVehicles
	checkpoint.action = checkpointInfo.action
	
	return checkpoint
	
end
