
CourseSpawn.color = Color(40 , 160 , 180 , 180)
CourseSpawn.maxDistanceSquared = 400 * 400

function CourseSpawn:__init(course)
	
	self.course = course
	self.position = nil
	self.angle = nil
	self.modelIds = {}
	
	self.gizmoColor = Copy(CourseSpawn.color)
	
	self.renderEvent = Events:Subscribe("Render" , self , self.Render)
	
end

function CourseSpawn:Render()
	
	-- Don't draw while in menus.
	if Client:GetState() ~= GUIState.Game then
		return
	end
	
	-- Only render if close enough.
	local distanceSquared = (Camera:GetPosition() - self.position):LengthSqr()
	if distanceSquared <= CourseSpawn.maxDistanceSquared then
		RenderModel(Models.vehicleSpawn , self.position , self.angle , self.gizmoColor)
	end
	
end

function CourseSpawn:Destroy()
	
	Events:Unsubscribe(self.renderEvent)
	
end


function CourseSpawn.Demarshal(course , spawnInfo)
	
	local spawn = CourseSpawn(course)
	
	spawn.courseEditorId = spawnInfo.courseEditorId
	spawn.position = spawnInfo.position
	spawn.angle = spawnInfo.angle
	spawn.modelIds = spawnInfo.modelIds
	
	return spawn
	
end
