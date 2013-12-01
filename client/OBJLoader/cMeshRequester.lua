function OBJLoader.MeshRequester:__init(modelPath , callback , callbackInstance)
	self.modelPath = modelPath
	self.callback = callback
	self.callbackInstance = callbackInstance
	
	Network:Send("OBJLoaderRequest" , modelPath)
	self.sub = Network:Subscribe("OBJLoaderReceive" , self , self.Receive)
end

function OBJLoader.MeshRequester:Receive(mesh)
	-- Convert the OBJLoader.Mesh into a Model.
	local vertices = {}
	for n = 1 , #mesh.triangleData do
		local triangleData = mesh.triangleData[n]
		local vert1 = mesh.vertices[triangleData[1][1]]
		local vert2 = mesh.vertices[triangleData[1][2]]
		local vert3 = mesh.vertices[triangleData[1][3]]
		table.insert(vertices , Vertex(vert1 , mesh.colors[triangleData[2]]))
		table.insert(vertices , Vertex(vert2 , mesh.colors[triangleData[2]]))
		table.insert(vertices , Vertex(vert3 , mesh.colors[triangleData[2]]))
	end
	local model = Model.Create(vertices)
	model:SetTopology(Topology.TriangleList)
	-- Call our callback function with the model.
	if self.callbackInstance then
		self.callback(self.callbackInstance , model , mesh.name)
	else
		self.callback(model , mesh.name)
	end
	-- Unsubscribe from our network event.
	Network:Unsubscribe(self.sub)
end
