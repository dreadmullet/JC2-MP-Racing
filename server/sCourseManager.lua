class("CourseManager")

-- Each CourseManager is tied to a course manifest.
function CourseManager:__init(manifestPath)
	self.manifestPath = manifestPath
	self.courseNames = {}
	
	self:LoadManifest()
	self:Randomize()
	
	self.currentIndex = 1
end

function CourseManager:GetRandomCourseName()
	return table.randomvalue(self.courseNames)
end

function CourseManager:LoadCourseSequential()
	if #self.courseNames > 0 then
		return Course.Load(self.courseNames[self.currentIndex])
	else
		return error("No available courses!")
	end
	
	self.currentIndex = self.currentIndex + 1
	if self.currentIndex > #self.courseNames then
		self.currentIndex = 1
		self:Randomize()
	end
end

function CourseManager:LoadCourseRandom()
	if #self.courseNames > 0 then
		return Course.Load(self:GetRandomCourseName())
	else
		return error("No available courses!")
	end
end

function CourseManager:Randomize()
	table.sortrandom(self.courseNames)
end

function CourseManager:LoadManifest()
	-- Make sure course manifest exists.
	local file , fileError = io.open(self.manifestPath , "r")
	if fileError then
		error("Error loading course manifest: "..fileError)
	end
	io.close(file)
	
	-- Erase courseNames if it's already been filled. This allows it to be updated just by
	-- calling this function again.
	self.courseNames = {}
	
	-- Loop through each line in the manifest.
	for line in io.lines(self.manifestPath) do
		-- Trim comments.
		line = Utility.TrimCommentsFromLine(line)
		-- Make sure this line has stuff in it.
		if string.find(line , "%S") then
			-- Add the entire line, sans comments, to self.courseNames
			table.insert(self.courseNames , line)
		end
	end
	
	print("Course manifest loaded - "..#self.courseNames.." courses found")
end

function CourseManager:RemoveCourse(courseNameToRemove)
	for index , courseName in ipairs(self.courseNames) do
		if courseNameToRemove == courseName then
			table.remove(self.courseNames , index)
			
			if self.currentIndex > index then
				if self.currentIndex > #self.courseNames then
					self.currentIndex = 1
					self:Randomize()
				else
					self.currentIndex = self.currentIndex - 1
				end
			end
			
			break
		end
	end
end
