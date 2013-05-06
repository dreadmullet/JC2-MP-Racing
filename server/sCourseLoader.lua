
-- Datablock names and their default values.

class("INFO")
function INFO:__init()
	self.datablockType = "INFO"

	self.name = "unnamed course"
	self.type = "linear"
	self.laps = 1
	self.lapTimeMinutes = 0
	self.lapTimeSeconds = 0
	self.hourStart = 10
	self.hourFinish = 14
	self.checkpointRadiusMult = 1
	self.weatherSeverity = -1 -- -1 = random
	self.constantCheckpointOffset = {}
	self.authors = {}
end

class("STARTGRID")
function STARTGRID:__init()
	self.datablockType = "STARTGRID"

	self.path = {} -- Cubically interped curve that the vehicles spawn along.
	self.width = 12
	self.numVehiclesPerRow = 2
	self.rowSpacing = 24
	self.vehicles = {}
	self.vehicleTemplates = {}
	self.vehicleDecals = {}
	self.fixedVehicleRotation = Angle()
end

class("CHECKPOINT")
function CHECKPOINT:__init()
	self.datablockType = "CHECKPOINT"

	self.position = Vector(0 , 0 , 0)
	self.vehicles = {}
end

----------------------------------------------------------------------------------------------------
-- CourseFileLoader
----------------------------------------------------------------------------------------------------

CourseLoader = {}

CourseLoader.Load = function(name)
	
	if settings.debugLevel >= 2 then
		print("Loading course file: "..name)
	end
	
	local path = settings.coursesPath..name..".course"
	
	hasError = false
	
	local PrintError = function(message)
		print()
		print("*ERROR*")
		print(path..": "..message)
		print()
		hasError = true
	end
	
	local PrintWarning = function(message)
		print()
		print("*WARNING*")
		print(path..": "..message)
		print()
	end
	
	--
	-- Make sure file exists.
	--
	if path == nil then
		print()
		print("*ERROR*")
		print("Course path is nil!")
		print()
		return nil
	end
	local tempFile , tempFileError = io.open(path , "r")
	if tempFile then
		io.close(tempFile)
	else
		print()
		print("*ERROR*")
		print(tempFileError)
		print()
		return nil
	end
	
	-- Final data retrieved from file.
	-- Includes instances of classes above.
	local datablocks = {}
	
	-- This will be added to datablocks multiple times.
	-- It is set to a new instance of a class above when
	-- a line with only capital letters is found.
	local currentDatablock = nil
	
	local lineNum = 0
	
	--
	-- Loop through all lines in the file, getting datablocks.
	--
	for line in io.lines(path) do
		lineNum = lineNum + 1
		line = CourseLoader.TrimCommentsFromLine(line)
	
		-- Make sure that the current line has stuff in it.
		if string.find(line , "%S") then
			
			
			-- If this line is entirely capital letters, change currentDatablock.
			if string.find(line , "%u") and not string.find(line , "%U") then
	
				-- TODO: error checking
	
				-- Add currentDatablock to datablocks if it's not null.
				if currentDatablock then
					table.insert(datablocks , currentDatablock)
				end
	
				-- Instantiate a class with name of line.
				currentDatablock = _G[line]() -- Lua less than three.
	
			-- Otherwise, add values to currentDatablock.
			elseif currentDatablock ~= nil then
				-- Split variable name and variable.
				local varName , rest = CourseLoader.TrimNameValueFromLine(line)
				-- Add the variable to the current datablock.
				if varName and rest then
					-- *** Special cases ***
					if
						currentDatablock.datablockType == "STARTGRID" and
						varName == "path"
					then
						table.insert(
							currentDatablock.path ,
							CourseLoader.Cast(
								rest ,
								"table"
							)
						)
					elseif
						currentDatablock.datablockType == "INFO" and
						varName == "author"
					then
						table.insert(
							currentDatablock.authors ,
							rest
						)
					elseif
						currentDatablock.datablockType == "CHECKPOINT" and
						varName == "vehicle"
					then
						table.insert(
							currentDatablock.vehicles ,
							rest
						)
					elseif
						currentDatablock.datablockType == "STARTGRID" and
						varName == "vehicle"
					then
						table.insert(
							currentDatablock.vehicles ,
							tonumber(rest)
						)
					elseif
						currentDatablock.datablockType == "STARTGRID" and
						varName == "vehicleTemplate"
					then
						table.insert(
							currentDatablock.vehicleTemplates ,
							rest
						)
					elseif
						currentDatablock.datablockType == "STARTGRID" and
						varName == "vehicleDecal"
					then
						table.insert(
							currentDatablock.vehicleDecals ,
							rest
						)
					else -- *** Generic cases *** Just add the variable.
						currentDatablock[varName] = CourseLoader.Cast(
							rest ,
							type(currentDatablock[varName])
						)
					end
				else
					print()
					print("*PARSE ERROR*")
					print(
						"CourseFileLoader"..
						": "..
						path..
						":"
					)
					print(lineNum..": "..'"'..line..'"')
					print()
					return nil
				end
	
			end
	
	
		end -- if string.find(line , "%S") then
	
	end -- for line in io.lines(path) do
	
	-- Add currentDatablock to datablocks if it's not null.
	if currentDatablock then
		table.insert(datablocks , currentDatablock)
	end
	
	--
	-- Take datablocks and turn it into a Course to return at the end.
	--
	local course = Course()
	local startGrids = {}
	for n=1 , #datablocks do
		if datablocks[n].datablockType == "CHECKPOINT" then
			local cp = CourseCheckpoint(course)
			table.insert(course.checkpoints , cp)
			cp.index = #course.checkpoints
			cp.position = datablocks[n].position
			cp.validVehicles = datablocks[n].vehicles
		elseif datablocks[n].datablockType == "STARTGRID" then
			table.insert(startGrids , datablocks[n])
		elseif datablocks[n].datablockType == "INFO" then
			local info = datablocks[n]
			course.name = info.name
			course.type = info.type
			course.numLaps = info.laps
			local lapTimeSeconds = info.lapTimeMinutes * 60 + info.lapTimeSeconds
			course.timeLimitSeconds = settings.timeLimitFunc(lapTimeSeconds , info.laps)
			course.weatherSeverity = info.weatherSeverity
		end
	end
	
	-- Loop through startGrids and generate course.spawns.
	for index , startGrid in pairs(startGrids) do
			-- Get rough length first.
		local lengthRough = 0 -- Net distance between straight lines.
		local length = 0 -- Estimated distance along the interpolated curve.
		for n = 1 , #startGrid.path - 1 do
			lengthRough = (
				lengthRough +
				Vector.Distance(startGrid.path[n] , startGrid.path[n+1])
			)
		end
		
		local numSamples = math.floor(lengthRough / 8) -- Per line.
		local previousPoint = startGrid.path[1]
		local nextPoint = {}
		local sectionLengths = {}
		-- Like above, but divided by total length. Used in GetPointOnCurve.
		-- The last element should always be 1.0.
		for a = 1 , #startGrid.path - 1 do
			sectionLengths[a] = 0
			for b = 1 , numSamples do
				nextPoint = Utility.VectorCuberp(
					startGrid.path[a-1] ,
					startGrid.path[a+0] ,
					startGrid.path[a+1] ,
					startGrid.path[a+2] ,
					b / numSamples
				)
				sectionLengths[a] = (
					sectionLengths[a] +
					Vector.Distance(
						previousPoint ,
						nextPoint
					)
				)
				previousPoint = nextPoint
			end
			length = length + sectionLengths[a]
		end
		
		local sectionDivides = {}
		-- Get sectionDivides from sectionLengths.
		local currentLength = 0
		for n=1 , #sectionLengths do
			currentLength = currentLength + sectionLengths[n]
			sectionDivides[n] = currentLength / length
		end
		
			-- x should be between 0 and 1.
		local GetPointOnCurve = function(x)
			
			for n = 1 , #sectionDivides do
				-- print("SDs - "..self.sectionDivides[n])
				if x <= sectionDivides[n] then
					return Utility.VectorCuberp(
						startGrid.path[n-1] ,
						startGrid.path[n+0] ,
						startGrid.path[n+1] ,
						startGrid.path[n+2] ,
						(
							(x - (sectionDivides[n - 1] or 0)) /
							(sectionDivides[n] - (sectionDivides[n - 1] or 0))
						)
					)
				end
			end
			
			print("This code shouldn't ever be reached!")
			assert(false)
			
		end
		
		-- This is the function used to get the vehicle's positions.
		-- x and y should be between 0 and 1.
		local GetPoint = function(x , y)
			
			local curvePos = GetPointOnCurve(y)
			-- We need the vector pointing right. This is found by
			-- rotating the direction of the forward vector by 90 degrees.
			local forward = {}
			local right = {}
			if y > 0.5 then
				forward = GetPointOnCurve(y - 0.02)
				if not curvePos then
					print("y = "..y) -- 0.769
				end
				forward = curvePos - forward
			else
				forward = GetPointOnCurve(y + 0.02)
				forward = forward - curvePos
			end
			forward = forward:Normalized()
			-- forward rotated by 90 degrees to the right.
			right = Vector(forward.z , forward.y , -forward.x)
			-- Get angle from forward vector.
			local angle = Angle.FromVectors(Vector(0 , 0 , 1) , forward)
			angle.roll = 0
			
			return curvePos + right * (startGrid.width * 0.5 * (x * 2 - 1)) ,	angle
			
		end
		
		local intervalX = 1 / (startGrid.numVehiclesPerRow - 1)
		local numRows = length / startGrid.rowSpacing
		local intervalY = 1 / numRows
		
		if startGrid.numVehiclesPerRow == 1 then
			intervalX = 2
		end
		
		-- Set up course.spawns.
		for y = 0 , 1 , intervalY do
			for x = 0 , 1 , intervalX do
				if startGrid.numVehiclesPerRow == 1 then
					x = 0.5
				end
				local position , angle = GetPoint(x , y)
				local spawn = CourseSpawn(course)
				spawn.position = position
				spawn.angle = angle
				spawn.modelIds = startGrid.vehicles
				spawn.templates = startGrid.vehicleTemplates
				spawn.decals = startGrid.vehicleDecals
				table.insert(course.spawns , spawn)
			end
		end
		
	end -- for index , startGrid in pairs(startGrids) do
	
	if settings.debugLevel >= 2 then
		print("Course loaded: "..course.name)
	end
	
	return course
	
end

----------------------------------------------------------------------------------------------------
-- Utility functions
----------------------------------------------------------------------------------------------------

-- name Awesome Course Name # What an awesome Course name!
-- 				|
-- 				v
-- "name Awesome Course Name"
CourseLoader.TrimCommentsFromLine = function(line)

	-- Holy balls, patterns are awesome.
	line = string.gsub(line , "%s*#.*" , "")
	
	-- *nix compatability.
	line = string.gsub(line, "\r", "")
	line = string.gsub(line, "\n", "")
	
	return line

end

-- name Awesome Course Name
-- 			|
-- 			v
-- "name" , "Awesome Course Name"
CourseLoader.TrimNameValueFromLine = function(line)

	local a , b = string.find(line , "%s+")

	if a and b then
		return string.sub(line , 1 , a-1) , string.sub(line , b+1)
	else
		-- error
		return nil
	end

end

-- Takes a string and converts it to a value.
--
-- Examples:
--
-- Cast("This is an awesome string!" , "string") --> "This is an awesome string!"
-- Cast("42" , "number") --> 42
-- Cast("-31.5, 17, 1.0005" , "table") --> {-31.5 , 17 , 1.0005}
--
CourseLoader.Cast = function(input , type)

	if type == "number" then
		return tonumber(input)
	end

	if type == "string" then
		return input
	end

	-- Return a vector or quat when the number of elements match.
	if type == "table" or type == "userdata" then
		local elementArray = {}
		for word in string.gmatch(input , "[^, ]+") do
			table.insert(elementArray , tonumber(word))
		end

		if #elementArray == 3 then
			return Vector(elementArray[1] , elementArray[2] , elementArray[3])
		elseif #elementArray == 4 then
			return Angle(
				elementArray[1] ,
				elementArray[2] ,
				elementArray[3] ,
				elementArray[4]
			)
		else
			return elementArray
		end
	end
	
end
