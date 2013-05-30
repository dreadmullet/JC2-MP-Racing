----------------------------------------------------------------------------------------------------
-- Made mostly for use with the course editor.
----------------------------------------------------------------------------------------------------

function Course:__init()
	
	self.name = "Unnamed Course"
	self.type = "Invalid"
	self.checkpoints = {}
	self.spawns = {}
	self.numLaps = 1
	self.timeLimitSeconds = -1
	self.prizeMoney = -1
	
end

function Course:Destroy()
	
	for index , checkpoint in ipairs(self.checkpoints) do
		checkpoint:Destroy()
	end
	for index , spawn in ipairs(self.spawns) do
		spawn:Destroy()
	end
	
end

function Course.Demarshal(courseInfo)
	
	local course = Course()
	
	course.name = courseInfo.name
	course.type = courseInfo.type
	course.numLaps = courseInfo.numLaps
	course.timeLimitSeconds = courseInfo.timeLimitSeconds
	course.prizeMoney = courseInfo.prizeMoney
	
	for index , checkpointInfo in ipairs(courseInfo.checkpoints) do
		table.insert(course.checkpoints , CourseCheckpoint.Demarshal(course , checkpointInfo))
	end
	
	for index , spawnInfo in ipairs(courseInfo.spawns) do
		table.insert(course.spawns , CourseSpawn.Demarshal(course , spawnInfo))
	end
	
	return course
	
end
