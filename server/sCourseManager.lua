
-- Each CourseManager is tied to a course manifest.
function CourseManager:__init(manifestPath)
	
	self.manifestPath = manifestPath
	self.courseNames = {}
	self.numCourses = 0
	
	self:LoadManifest()
	
end

function CourseManager:LoadCourseRandom()
	
	return CourseLoader.Load(table.randomvalue(self.courseNames))
	
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
	self.numCourses = 0

	-- Loop through each line in the manifest.
	for line in io.lines(path) do
		-- Trim comments.
		line = CourseLoader.TrimCommentsFromLine(line)
		-- Make sure this line has stuff in it.
		if string.find(line , "%S") then
			-- Add the entire line, sans comments, to self.courseNames
			table.insert(self.courseNames , line)
			self.numCourses = self.numCourses + 1
		end
	end

	if settings.debugLevel >= 1 then
		print("Course manifest loaded - "..self.numCourses.." courses found")
	end

end
