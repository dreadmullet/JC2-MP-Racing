OBJLoader.cache = {}

OBJLoader.Error = function(text)
	return "[OBJLoader] "..text
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
	-- Parse the .mtl for texture data.
	--
	
	local file , error = io.open(path..".mtl" , "r")
	
	local colorNameToIndex = {}
	
	if error then
		-- Use magenta.
		table.insert(
			mesh.colors ,
			Color(255 , 0 , 255)
		)
	else
		local numColors = 0
		
		local lineNumber = 0
		for line in file:lines() do
			lineNumber = lineNumber + 1
			line = OBJLoader.TrimCommentsFromLine(line)
			
			-- If this line has stuff in it.
			if line:len() ~= 0 then
				-- Split the line up into words (by spaces).
				local words = line:split(" ")
				
				if words[1] == "newmtl" then
					numColors = numColors + 1
					colorNameToIndex[words[2]] = numColors
				elseif words[1] == "Kd" then
					mesh.colors[numColors] = Color(
						tonumber(words[2]) * 255 ,
						tonumber(words[3]) * 255 ,
						tonumber(words[4]) * 255
					)
				end
			end
		end
	end
	
	--
	-- Parse the .obj for mesh data.
	--
	
	file , error = io.open(path..".obj" , "r")
	if error then
		return OBJLoader.Error(error)
	end
	
	local currentColorIndex = 1
	
	local lineNumber = 0
	for line in file:lines() do
		lineNumber = lineNumber + 1
		line = OBJLoader.TrimCommentsFromLine(line)
		
		-- If this line has stuff in it.
		if line:len() ~= 0 then
			-- Split the line up into words (by spaces).
			local words = line:split(" ")
			
			if words[1] == "v" then
				table.insert(
					mesh.vertices ,
					Vector3(tonumber(words[2]) ,	tonumber(words[3]) , tonumber(words[4]))
				)
			elseif words[1] == "vn" then
				-- Normals are unused.
			elseif words[1] == "vt" then
				-- Texture coordinates are unused.
			elseif words[1] == "usemtl" then
				currentColorIndex = colorNameToIndex[words[2]]
			elseif words[1] == "f" then
				-- tri pos/uv/normal
				local ConvertWord = function(word)
					local vert , uv , normal
					
					local vertWords = word:split("/")
					
					vert = tonumber(vertWords[1])
					
					if vertWords[2] and vertWords[2]:len() > 0 then
						uv = tonumber(vertWords[2])
					end
					
					if vertWords[3] and vertWords[3]:len() > 0 then
						normal = tonumber(vertWords[3])
					end
					
					return vert , uv , normal
				end
				
				local vert1 = ConvertWord(words[2])
				local vert2 = ConvertWord(words[3])
				local vert3 = ConvertWord(words[4])
				
				local triangle1 = {}
				triangle1[1] =	{vert1 , vert2 , vert3}
				triangle1[2] = currentColorIndex
				table.insert(mesh.triangleData , triangle1)
				
				-- If there is a 5th word, then it means it's a quad, not a triangle.
				if words[5] then
					local vert1 = ConvertWord(words[2])
					local vert2 = ConvertWord(words[4])
					local vert3 = ConvertWord(words[5])
					
					local triangle2 = {}
					triangle2[1] = {vert1 , vert2 , vert3}
					triangle2[2] = currentColorIndex
					table.insert(mesh.triangleData , triangle2)
				end
				-- If there is a 6th word, then it means it's an n-gon, which...yeah, not happening.
				if words[6] then
					return OBJLoader.Error("N-gons are not supported")
				end
			end
		end 
	end
	
	OBJLoader.cache[path] = mesh
	
	return mesh
end

OBJLoader.Request = function(modelPath , player)
	-- Check arguments from client.
	if type(modelPath) ~= "string" then
		return
	end
	
	local args = {
		mesh = OBJLoader.Load(modelPath) ,
		modelPath = modelPath
	}
	if args.mesh then
		Network:Send(player , "OBJLoaderReceive" , args)
	else
		warn(OBJLoader.Error("Error: couldn't load model: "..modelPath or "invalid path"))
	end
end

Network:Subscribe("OBJLoaderRequest" , OBJLoader.Request)
