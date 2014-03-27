----------------------------------------------------------------------------------------------------
-- Some terminology used here:
--
-- * 'model' - A collection of meshes. OBJLoader.Load returns a model. Not to be confused with the
-- client Model class.
--
-- * 'mesh' - A table of vertices and triangle indices sent to the client, where they turn it into
-- something renderable. OBJLoader.LoadMesh returns a mesh.
----------------------------------------------------------------------------------------------------

OBJLoader = {}

OBJLoader.cache = {}

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
	
	-- If this model is cached, return it instead of reimporting the .obj file.
	local cachedModel = OBJLoader.cache[path]
	if cachedModel then
		return cachedModel
	end
	
	local model = {}
	model.vertices = {}
	model.meshes = {}
	model.colors = {}
	
	--
	-- Parse the .mtl for texture data.
	--
	
	local file , error = io.open(path..".mtl" , "r")
	
	local colorNameToIndex = {}
	
	if error then
		-- Use magenta.
		table.insert(
			model.colors ,
			Color(255 , 0 , 255)
		)
	else
		local numColors = 0
		
		for line in file:lines() do
			line = OBJLoader.TrimCommentsFromLine(line)
			
			-- If this line has stuff in it.
			if line:len() ~= 0 then
				-- Split the line up into words (by spaces).
				local words = line:split(" ")
				
				if words[1] == "newmtl" then
					numColors = numColors + 1
					colorNameToIndex[words[2]] = numColors
				elseif words[1] == "Kd" then
					model.colors[numColors] = Color(
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
		return nil , error
	end
	
	local mesh = nil
	local meshName = nil
	local currentColorIndex = 1
	
	for line in file:lines() do
		line = OBJLoader.TrimCommentsFromLine(line)
		
		-- If this line has stuff in it.
		if line:len() ~= 0 then
			-- Split the line up into words (by spaces).
			local words = line:split(" ")
			
			if words[1] == "o" then
				-- Add the previous mesh to the model.
				if mesh then
					model.meshes[meshName] = mesh
				end
				-- Create the new mesh.
				mesh = {}
				meshName = line:sub(words[1]:len() + 2)
				mesh.triangleData = {} -- Each item is a table, {v1 , v2 , v3 , colorIndex}
			elseif words[1] == "v" then
				local vertex = Vector3(tonumber(words[2]) ,	tonumber(words[3]) , tonumber(words[4]))
				table.insert(model.vertices , vertex)
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
				table.insert(mesh.triangleData , {vert1 , vert2 , vert3 , currentColorIndex})
				
				-- If there is a 5th word, then it's a quad, not a triangle.
				if words[5] then
					local vert1 = ConvertWord(words[2])
					local vert2 = ConvertWord(words[4])
					local vert3 = ConvertWord(words[5])
					table.insert(mesh.triangleData , {vert1 , vert2 , vert3 , currentColorIndex})
				end
				-- If there is a 6th word, then it's an n-gon, which...yeah, not happening.
				if words[6] then
					return nil , "N-gons are not supported"
				end
			end
		end 
	end
	
	if mesh then
		model.meshes[meshName] = mesh
	end
	
	OBJLoader.cache[path] = model
	
	return model
end

OBJLoader.Request = function(modelPath , player)
	-- Check arguments from client.
	if type(modelPath) ~= "string" then
		return
	end
	-- Try to load the model.
	local model , errorMessage = OBJLoader.Load(modelPath)
	if model == nil then
		warn("[OBJLoader] Could not load "..modelPath..": "..tostring(errorMessage))
		return
	end
	-- Send them the mesh data.
	local args = {
		modelData = model ,
		modelPath = modelPath ,
	}
	Network:Send(player , "OBJLoaderReceive" , args)
end

Network:Subscribe("OBJLoaderRequest" , OBJLoader.Request)
