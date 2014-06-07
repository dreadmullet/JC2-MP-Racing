class("MeshRequester" , OBJLoader)

function OBJLoader.MeshRequester:__init(args , callback , callbackInstance)
	self.modelPath = args.path
	self.type = args.type or OBJLoader.Type.Single
	self.is2D = args.is2D or false
	self.callbacks = {}
	self.models = {}
	self.depths = {}
	self.modelCount = 0
	self.isFinished = false
	self.result = nil
	
	self:AddCallback(callback , callbackInstance)
	
	if self.is2D == false and self.type == OBJLoader.Type.MultipleDepthSorted then
		error("[OBJLoader] Cannot be 3D and MultipleDepthSorted!")
	end
	
	Network:Send("OBJLoaderRequest" , self.modelPath)
	self.sub = Network:Subscribe("OBJLoaderReceive" , self , self.Receive)
end

function OBJLoader.MeshRequester:Receive(args)
	if args.modelPath ~= self.modelPath then
		return
	end
	
	Network:Unsubscribe(self.sub)
	
	local modelData = args.modelData
	
	-- Create the Models from the models. The choice of variable names wasn't well thought out...
	for modelName , mesh in pairs(modelData.meshes) do
		local vertices = {}
		local depthsBuffer = 0
		-- Convert the mesh into a table of vertices, which will be turned into a Model.
		for index , triangleData in ipairs(mesh.triangleData) do
			local color = modelData.colors[triangleData[4]]
			if self.is2D then
				local vert1 = modelData.vertices[triangleData[1]]
				local vert2 = modelData.vertices[triangleData[2]]
				local vert3 = modelData.vertices[triangleData[3]]
				table.insert(vertices , Vertex(Vector2(vert1.x , vert1.z) , color))
				table.insert(vertices , Vertex(Vector2(vert2.x , vert2.z) , color))
				table.insert(vertices , Vertex(Vector2(vert3.x , vert3.z) , color))
				
				if self.type == OBJLoader.Type.MultipleDepthSorted then
					depthsBuffer = depthsBuffer + vert1.y + vert2.y + vert3.y
				end
			else
				local vert1 = modelData.vertices[triangleData[1]]
				local vert2 = modelData.vertices[triangleData[2]]
				local vert3 = modelData.vertices[triangleData[3]]
				table.insert(vertices , Vertex(vert1 , color))
				table.insert(vertices , Vertex(vert2 , color))
				table.insert(vertices , Vertex(vert3 , color))
			end
		end
		
		local model = Model.Create(vertices)
		model:SetTopology(Topology.TriangleList)
		model:Set2D(self.is2D)
		
		if self.type == OBJLoader.Type.Multiple then
			self.models[modelName] = model
		else
			table.insert(self.models , model)
		end
		
		if self.type == OBJLoader.Type.MultipleDepthSorted then
			local averageZ = depthsBuffer / #vertices
			table.insert(self.depths , averageZ)
		end
		
		self.modelCount = self.modelCount + 1
	end
	
	if self.type == OBJLoader.Type.MultipleDepthSorted then
		local buffer = {}
		for index , model in ipairs(self.models) do
			local info = {
				model = model ,
				depth = self.depths[index]
			}
			table.insert(buffer , info)
		end
		
		local SortByDepth = function(a , b)
			return a.depth < b.depth
		end
		table.sort(buffer , SortByDepth)
		
		self.models = {}
		for index , t in ipairs(buffer) do
			table.insert(self.models , t.model)
		end
	end
	
	if self.type == OBJLoader.Type.Single then
		if self.modelCount > 1 then
			warn("[OBJLoader] Type is Single but there are "..self.modelCount.." meshes!")
		end
		
		for modelName , model in pairs(self.models) do
			self.result = model
			break
		end
	elseif self.type == OBJLoader.Type.Multiple then
		self.result = self.models
	elseif self.type == OBJLoader.Type.MultipleDepthSorted then
		self.result = self.models
	end
	
	for index , callback in ipairs(self.callbacks) do
		self:ForceCallback(callback.func , callback.instance)
	end
	
	self.isFinished = true
end

function OBJLoader.MeshRequester:AddCallback(func , instance)
	table.insert(self.callbacks , {func = func , instance = instance})
end

function OBJLoader.MeshRequester:ForceCallback(func , instance)
	if instance then
		func(instance , self.result , self.modelPath)
	else
		func(self.result , self.modelPath)
	end
end
