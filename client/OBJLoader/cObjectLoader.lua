OBJLoader.Error = function(text)
	error("[OBJLoader] "..text)
end

OBJLoader.Request = function(modelPath , extra1 , extra2)
	return OBJLoader.RequestInternal(modelPath , "3D" , extra1 , extra2)
end

OBJLoader.Request2D = function(modelPath , extra1 , extra2)
	return OBJLoader.RequestInternal(modelPath , "2D" , extra1 , extra2)
end

-- extra1/extra2 are like Events:Subscribe; provide it a function or an instance and function.
OBJLoader.RequestInternal = function(modelPath , type , extra1 , extra2)
	if extra1 == nil then
		OBJLoader.Error("Error: bad parameters")
	end
	
	local onLoadCallback = nil
	local onLoadCallbackInstance = nil
	if extra2 then
		onLoadCallback = extra2
		onLoadCallbackInstance = extra1
	else
		onLoadCallback = extra1
	end
	
	OBJLoader.MeshRequester(modelPath , type , onLoadCallback , onLoadCallbackInstance)
end
