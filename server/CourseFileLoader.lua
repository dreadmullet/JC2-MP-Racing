CourseFileLoader = {}
local M = CourseFileLoader


--------------------------------------------------------------------------------
-- Config variables.
--------------------------------------------------------------------------------

-- Minimum distance between cars. This only applies when the maximum number of
-- players have joined. With fewer players, it is much less cramped.
-- Todo: make this a percentage. A padding of 8m between planes is ridiculous.
local startGridPaddingXRatio = 1.5
local startGridPaddingYRatio = 2.75



local commentChar = '#'

local thisTitle = "CourseFileLoader"

-- Prints a lot of stuff.
-- 0 means no printing except for errors.
-- 1 is very reasonable for normal use.
-- 3 prints a big wall of text.
-- Max level: 3
local debugLevel = 1





-- Course class, this will be returned on Load.
-- Lots of these are first set to tables, but become classes (userdata). Ehh...
class("Course")
function Course:__init()
	self.info = {} -- all course types; INFO
	self.startGrids = {} -- all course types; table of STARTGRIDs
	self.startFinish = nil -- circuit only; STARTFINISH
	self.checkpoints = {} -- all course types; table of CHECKPOINTs
	self.finish = nil -- linear only; FINISH

	self.maxPlayers = 0 -- rows * cars per row
	-- Vectors from automatically placed grid spots.
	-- Key: Vector
	-- Value: index of startGrids
	self.gridPositions = {}
	self.skydiveHeight = 500 -- Racers are spawned this high above the starting grid at first.
	self.startGridPaddingX = 3
	self.startGridPaddingY = 10
	
end


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
end

class("STARTGRID")
function STARTGRID:__init()
	self.datablockType = "STARTGRID"

	self.path = {} -- Cubically interped curve that the vehicles spawn along.
	self.angle = Angle() -- Computed after load.
	self.width = 12
	self.vehicle = 91 -- Titus ZJ by default? Sure.
	self.vehicleWidth = 2
	self.vehicleLength = 4
	self.vehicleTemplate = ""
	self.vehicleDecal = ""
	self.maxRows = 0 -- Computed after load.
	self.maxVehiclesPerRow = 0 -- Computed after load.
end

class("STARTFINISH")
function STARTFINISH:__init()
	self.datablockType = "STARTFINISH"

	self.position = Vector(0 , 0 , 0)
end

class("CHECKPOINT")
function CHECKPOINT:__init()
	self.datablockType = "CHECKPOINT"

	self.position = Vector(0 , 0 , 0)
end

class("FINISH")
function FINISH:__init()
	self.datablockType = "FINISH"

	self.position = Vector(0 , 0 , 0)
end







M.Load = function(path)

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



	if debugLevel >= 1 then
		print("Loading course file: "..path)
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
		line = M.TrimCommentsFromLine(line)

		if debugLevel >= 3 then
			print(line)
		end

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
				local varName , rest = M.TrimNameValueFromLine(line)
				-- Add the variable to the current datablock.
				if varName and rest then
					-- *** Special cases ***
					if
						currentDatablock.datablockType == "STARTGRID" and
						varName == "path"
					then
						table.insert(
							currentDatablock.path ,
							M.Cast(
								rest ,
								"table"
							)
						)
					else -- *** Generic cases *** Just add the variable.
						currentDatablock[varName] = M.Cast(
							rest ,
							type(currentDatablock[varName])
						)
					end
				else
					print()
					print("*PARSE ERROR*")
					print(
						thisTitle..
						": "..
						path..
						":"
					)
					print(lineNum..": "..'"'..line..'"')
					print()
					return nil
				end

			end


		end

	end

	-- Add currentDatablock to datablocks if it's not null.
	if currentDatablock then
		table.insert(datablocks , currentDatablock)
	end

	if debugLevel >= 3 then
		print()
		print("datablocks = ")
		Utility.PrintTable(datablocks)
		print()
	end


	--
	-- Take datablocks and turn it into a Course to return at the end.
	--

	local course = Course()

	for n=1 , #datablocks do
		if datablocks[n].datablockType == "CHECKPOINT" then
			table.insert(course.checkpoints , datablocks[n])
		elseif datablocks[n].datablockType == "STARTGRID" then
			table.insert(course.startGrids , datablocks[n])
		elseif datablocks[n].datablockType == "STARTFINISH" then
			course.startFinish = datablocks[n]
		elseif datablocks[n].datablockType == "FINISH" then
			course.finish = datablocks[n]
		elseif datablocks[n].datablockType == "INFO" then
			course.info = datablocks[n]
		end
	end

	-- Set up some stuff.
	for k,sg in ipairs(course.startGrids) do

		-- Estimate startgrids' length by stepping along the interpolated path.
		-- Cubic interpolation! Fun.

		-- Get rough length first.
		local lengthRough = 0 -- Net distance between straight lines.
		sg.length = 0 -- Estimated distance along the interpolated curve.
		for n=1 , #sg.path - 1 do
			lengthRough = (
				lengthRough +
				Vector.Distance(sg.path[n] , sg.path[n+1])
			)
		end

		local numSamples = math.floor(lengthRough / 8) -- Per line.
		local previousPoint = sg.path[1]
		local nextPoint = {}
		sg.sectionLengths = {}
		-- Like above, but divided by total length. Used in sg.GetPointOnCurve.
		-- The last element should always be 1.0.
		sg.sectionDivides = {}
		for a=1 , #sg.path - 1 do
			sg.sectionLengths[a] = 0
			for b=1 , numSamples do
				nextPoint = Utility.VectorCuberp(
					sg.path[a-1] ,
					sg.path[a+0] ,
					sg.path[a+1] ,
					sg.path[a+2] ,
					b / numSamples
				)
				sg.sectionLengths[a] = (
					sg.sectionLengths[a] +
					Vector.Distance(
						previousPoint ,
						nextPoint
					)
				)
				previousPoint = nextPoint
			end
			sg.length = sg.length + sg.sectionLengths[a]
		end
		
		--
		-- Instance functions.
		--

		-- Get sectionDivides from sectionLengths.
		local currentLength = 0
		for n=1 , #sg.sectionLengths do
			currentLength = currentLength + sg.sectionLengths[n]
			sg.sectionDivides[n] = currentLength / sg.length
		end

		-- x should be between 0 and 1.
		sg.GetPointOnCurve = function(self , x)

			for n=1 , #self.sectionDivides do
				-- print("SDs - "..self.sectionDivides[n])
				if x <= self.sectionDivides[n] then
					return Utility.VectorCuberp(
						self.path[n-1] ,
						self.path[n+0] ,
						self.path[n+1] ,
						self.path[n+2] ,
						(
							(x - (self.sectionDivides[n - 1] or 0)) /
							(self.sectionDivides[n] - (self.sectionDivides[n - 1] or 0))
						)
					)
				end
			end
			
			print("This code shouldn't ever be reached!")
			assert(false)

		end

		-- test
--~ 		for n=1 , 10 do
--~ 			Utility.PrintTable(sg.GetPointOnCurve(n / 10))
--~ 			print()
--~ 		end

		-- This is the function used to get the vehicle's positions.
		-- x and y should be between 0 and 1.
		sg.GetPoint = function(self , x , y)

			local curvePos = self:GetPointOnCurve(y)

			-- We need the vector pointing right. This is found by
			-- rotating the direction of the forward vector by 90 degrees.
			local forward = {}
			local right = {}
			if y > 0.5 then
				forward = self:GetPointOnCurve(y - 0.02)
				if not curvePos then
					print("y = "..y) -- 0.769
				end
				forward = curvePos - forward
			else
				forward = self:GetPointOnCurve(y + 0.02)
				forward = forward - curvePos
			end
			forward = forward:Normalized()
			-- forward rotated by 90 degrees to the right.
			right = Vector(forward.z , forward.y , -forward.x)
			-- Get angle from forward vector.
			local angle = Angle.FromVectors(Vector(0 , 0 , 1) , forward)
			angle.roll = 0
			
			return curvePos + right * (self.width * 0.5 * (x * 2 - 1)) ,
				angle

		end

	end


	-- Calculate padding from vehicle size. (???)
	
	

	-- Get max players for this course and set up maxRows and maxVehiclesPerRow.
	course.maxPlayers = 0
	for k,sg in ipairs(course.startGrids) do
		sg.startGridPaddingX = sg.vehicleWidth * startGridPaddingXRatio
		sg.startGridPaddingY = sg.vehicleLength * startGridPaddingYRatio
		-- Algebra ftw.
		sg.maxVehiclesPerRow =
			(sg.width + sg.startGridPaddingX) /
			(sg.vehicleWidth + sg.startGridPaddingX)
		sg.maxVehiclesPerRow = math.floor(sg.maxVehiclesPerRow)

		sg.maxRows =
			(sg.length + sg.startGridPaddingY) /
			(sg.vehicleLength + sg.startGridPaddingY)
		sg.maxRows = math.floor(sg.maxRows)

		sg.maxPlayers = sg.maxRows * sg.maxVehiclesPerRow

		course.maxPlayers = course.maxPlayers + sg.maxPlayers

	end

	-- Get skydivePosition.
	course.skydivePos = Vector(0 , 0 , 0)
	for k,sg in pairs(course.startGrids) do
		course.skydivePos = course.skydivePos + sg.path[1]
	end
	course.skydivePos = course.skydivePos * (1 / #course.startGrids)
	course.skydivePos = course.skydivePos +	Vector(0 , course.skydiveHeight , 0)

	-- Weather.
	-- If weather is -1 (default), then randomize the weather.
	-- Also, power the 0-1 value, so there's less chance of rain.
	if course.info.weatherSeverity == -1 then
		course.info.weatherSeverity = (math.random() ^ 2) * 2.1
	end
	
	if debugLevel >= 3 then
		-- print("course =")
		-- Utility.PrintTable(course)
	end
	
	-- Add constant offset to checkpoints.
	if type(course.info.constantCheckpointOffset) == "userdata" then
		for n = 1 , #course.checkpoints do
			course.checkpoints[n].position = (
				course.checkpoints[n].position +
				course.info.constantCheckpointOffset
			)
		end
		if course.info.type == "circuit" then
			course.startFinish.position = (
				course.startFinish.position +
				course.info.constantCheckpointOffset
			)
		elseif course.info.type == "linear" then
			course.finish.position = (
				course.finish.position +
				course.info.constantCheckpointOffset
			)
		end
	end
	
	--
	-- Error checking.
	--

	if #course.startGrids == 0 then
		PrintError("No STARTGRID")
	end

	if course.info.type == "circuit" and #course.checkpoints == 0 then
		PrintError("Circuits need at least one CHECKPOINT")
	end
	
	if course.info.type == "linear" then
		if course.startFinish then
			PrintWarning("Course type is linear, but has STARTFINISH")
		end
		if course.finish == nil then
			PrintWarning("Course type is linear, but lacks FINISH")
		end
	elseif course.info.type == "circuit" then
		if course.finish then
			PrintWarning("Course type is circuit, but has FINISH")
		end
		if course.startFinish == nil then
			PrintWarning("Course type is circuit, but lacks STARTFINISH")
		end
	end


	--
	-- Finally, return the course if loading succeeded.
	--

	if hasError then
		return nil
	else
		if debugLevel >= 1 then
			print("Course file successfully loaded!")
		end
		return course
	end

end


-- name Awesome Course Name # What an awesome Course name!
-- 				|
-- 				v
-- "name Awesome Course Name"
M.TrimCommentsFromLine = function(line)

	-- Holy balls, patterns are awesome.
	line = string.gsub(line , "%s*#.*" , "")
	
	line = string.gsub(line, "\r", "")
	line = string.gsub(line, "\n", "")
	
	return line

end

-- name Awesome Course Name
-- 			|
-- 			v
-- "name" , "Awesome Course Name"
M.TrimNameValueFromLine = function(line)

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
M.Cast = function(input , type)

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
