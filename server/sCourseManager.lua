
-- Each CourseManager is tied to a course manifest.
function CourseManager:__init(manifestPath)
	self.manifestPath = manifestPath
	self.courseNames = {}
	
	self:LoadManifest()
end

function CourseManager:LoadCourseRandom()
	if #self.courseNames > 0 then
		return Course.Load(table.randomvalue(self.courseNames))
	else
		return error("No available courses!")
	end
end

function CourseManager:LoadManifest()
	local path = self.manifestPath
	
	-- File endings on *nix fix
	string.gsub(path, "\r", "")
	string.gsub(path, "\n", "")
	
	-- Make sure course manifest exists.
	local tempFile , tempFileError = io.open(path , "r")
	if tempFileError then
		print()
		print("*ERROR*")
		print(tempFileError)
		print()
		fatalError = true
		return
	else
		io.close(tempFile)
	end
	
	-- Erase courseNames if it's already been filled. This allows it to be updated just by
	-- calling this function again.
	self.courseNames = {}
	
	-- Loop through each line in the manifest.
	for line in io.lines(path) do
		-- Trim comments.
		line = Utility.TrimCommentsFromLine(line)
		-- Make sure this line has stuff in it.
		if string.find(line , "%S") then
			-- Add the entire line, sans comments, to self.courseNames
			table.insert(self.courseNames , line)
		end
	end
	
	if settings.debugLevel >= 1 then
		print("Course manifest loaded - "..#self.courseNames.." courses found")
	end
end

function CourseManager:RemoveCourse(courseNameToRemove)
	for index , courseName in ipairs(self.courseNames) do
		if courseNameToRemove == courseName then
			table.remove(self.courseNames , index)
			break
		end
	end
end
