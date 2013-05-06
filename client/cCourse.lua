----------------------------------------------------------------------------------------------------
-- Made mostly for use with the course editor.
----------------------------------------------------------------------------------------------------

function Course:__init()
	
	self.name = "unnamed course"
	self.type = "linear"
	self.checkpoints = {}
	self.spawns = {}
	self.numLaps = 1
	
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
	
	for index , checkpointInfo in ipairs(courseInfo.checkpoints) do
		table.insert(course.checkpoints , CourseCheckpoint.Demarshal(course , checkpointInfo))
	end
	for index , spawnInfo in ipairs(courseInfo.spawns) do
		table.insert(course.spawns , CourseSpawn.Demarshal(course , spawnInfo))
	end
	
	return course
	
end
