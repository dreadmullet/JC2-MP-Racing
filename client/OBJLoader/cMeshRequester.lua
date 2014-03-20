function OBJLoader.MeshRequester:__init(modelPath , type , callback , callbackInstance)
	self.modelPath = modelPath
	self.type = type
	self.callback = callback
	self.callbackInstance = callbackInstance
	
	Network:Send("OBJLoaderRequest" , modelPath)
	self.sub = Network:Subscribe("OBJLoaderReceive" , self , self.Receive)
end

function OBJLoader.MeshRequester:Receive(args)
	if args.modelPath ~= self.modelPath then
		return
	end
	
	local mesh = args.mesh
	
	-- Convert the OBJLoader.Mesh into a table of vertices.
	local vertices = {}
	for n = 1 , #mesh.triangleData do
		local vertIndices = mesh.triangleData[n][1]
		local colorIndex = mesh.triangleData[n][2]
		if self.type == "2D" then
			local vert1 = mesh.vertices[vertIndices[1]]
			local vert2 = mesh.vertices[vertIndices[2]]
			local vert3 = mesh.vertices[vertIndices[3]]
			table.insert(vertices , Vertex(Vector2(vert1.x , vert1.z) , mesh.colors[colorIndex]))
			table.insert(vertices , Vertex(Vector2(vert2.x , vert2.z) , mesh.colors[colorIndex]))
			table.insert(vertices , Vertex(Vector2(vert3.x , vert3.z) , mesh.colors[colorIndex]))
		else
			local vert1 = mesh.vertices[vertIndices[1]]
			local vert2 = mesh.vertices[vertIndices[2]]
			local vert3 = mesh.vertices[vertIndices[3]]
			table.insert(vertices , Vertex(vert1 , mesh.colors[colorIndex]))
			table.insert(vertices , Vertex(vert2 , mesh.colors[colorIndex]))
			table.insert(vertices , Vertex(vert3 , mesh.colors[colorIndex]))
		end
	end
	-- Create the model.
	local model = Model.Create(vertices)
	model:SetTopology(Topology.TriangleList)
	if self.type == "2D" then
		model:Set2D(true)
	end
	-- Call our callback function with the model.
	if self.callbackInstance then
		self.callback(self.callbackInstance , model , mesh.name)
	else
		self.callback(model , mesh.name)
	end
	-- Unsubscribe from our network event.
	Network:Unsubscribe(self.sub)
end
