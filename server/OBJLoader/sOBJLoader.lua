OBJLoader.cache = {}

OBJLoader.Error = function(text)
	error("[OBJLoader] "..text)
end

--     awesome line # What an awesome line!
--            |
--            v
-- awesome line
OBJLoader.TrimCommentsFromLine = function(line)
	line = string.gsub(line , "%s*#.*" , "")
	return line
end

OBJLoader.Load = function(path)
	-- Remove ".obj" from path, if possible.
	if path:sub(path:len() - 3) == ".obj" then
		path = path:sub(1 , path:len() - 4)
	end
	
	local cachedMesh = OBJLoader.cache[path]
	if cachedMesh then
		return cachedMesh
	end
	
	-- This will be returned at the end.
	local mesh = {}
	mesh.name = path
	mesh.vertices = {}
	mesh.triangleData = {} -- Each item is a table, {{v1 , v2 , v3} , colorIndex}
	mesh.colors = {}
	
	--
	-- Get colors from material file (not required).
	--
	
	local file , error = io.open(path..".mtl" , "r")
	
	local colorNameToIndex = {}
	
	if error then
		-- Use default color.
		table.insert(
			mesh.colors ,
			Color(200 , 200 , 200)
		)
	else
		local numColors = 1
		
		local lineNumber = 0
		for line in file:lines() do
			lineNumber = lineNumber + 1
			line = OBJLoader.TrimCommentsFromLine(line)
			
			-- If this line has stuff in it.
			if line:len() ~= 0 then
				-- Split the line up into words (by spaces).
				local words = {}
				for word in string.gmatch(line, "[^%s]+") do
					table.insert(words , word)
				end
				
				if words[1] == "newmtl" then
					colorNameToIndex[words[2] or 0] = numColors
					numColors = numColors + 1
				elseif words[1] == "Kd" then
					table.insert(
						mesh.colors ,
						Color(
							tonumber(words[2]) * 255 ,
							tonumber(words[3]) * 255,
							tonumber(words[4]) * 255
						)
					)
				end
			end -- if line:len() ~= 0 then
		end -- for line in file:lines() do
	end -- if error then
	
	file , error = io.open(path..".obj" , "r")
	if error then
		OBJLoader.Error(error)
		return
	end
	
	local currentColorIndex = 1
	
	local lineNumber = 0
	for line in file:lines() do
		lineNumber = lineNumber + 1
		line = OBJLoader.TrimCommentsFromLine(line)
		
		-- If this line has stuff in it.
		if line:len() ~= 0 then
			-- Split the line up into words (by spaces).
			local words = {}
			for word in string.gmatch(line, "[^%s]+") do
				table.insert(words , word)
			end
			
			if words[1] == "v" then
				table.insert(
					mesh.vertices ,
					Vector3(tonumber(words[2]) ,	tonumber(words[3]) , tonumber(words[4]))
				)
			elseif words[1] == "vn" then
				-- Normals are unused.
			elseif words[1] == "usemtl" then
				currentColorIndex = colorNameToIndex[words[2] or 0]
			elseif words[1] == "f" then
				-- Triangle index//Triangle normal
				local ConvertWord = function(word)
					local slashPosition = word:find("/")
					local vert = word:sub(1 , slashPosition - 1)
					local normal = word:sub(slashPosition + 2 , word:len())
					return vert , normal
				end
				
				local vert1 , normal1 = ConvertWord(words[2])
				local vert2 , normal2 = ConvertWord(words[3])
				local vert3 , normal3 = ConvertWord(words[4])
				
				local triangle1 = {}
				triangle1[1] =	{
					tonumber(string.format("%i" , vert1)) ,
					tonumber(string.format("%i" , vert2)) ,
					tonumber(string.format("%i" , vert3))
				}
				triangle1[2] = currentColorIndex
				table.insert(mesh.triangleData , triangle1)
				
				if words[5] then
					vert1 , normal1 = ConvertWord(words[2])
					vert2 , normal2 = ConvertWord(words[4])
					vert3 , normal3 = ConvertWord(words[5])
					
					local triangle2 = {}
					triangle2[1] =	{
						tonumber(string.format("%i" , vert1)) ,
						tonumber(string.format("%i" , vert2)) ,
						tonumber(string.format("%i" , vert3))
					}
					triangle2[2] = currentColorIndex
					table.insert(mesh.triangleData , triangle2)
				end
			end
		end -- if line:len() ~= 0 then
	end -- for line in file:lines() do
	
	OBJLoader.cache[path] = mesh
	
	return mesh
end

OBJLoader.Request = function(modelPath , player)
	local mesh = OBJLoader.Load(modelPath)
	if mesh then
		Network:Send(player , "OBJLoaderReceive" , mesh)
	else
		OBJLoader.Error("Error: couldn't load model: "..modelPath or "invalid path")
	end
end

Network:Subscribe("OBJLoaderRequest" , OBJLoader.Request)
