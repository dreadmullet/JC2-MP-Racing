OBJLoader.Error = function(text)
	error("[OBJLoader] "..text)
end

-- param2/param3 are like Events:Subscribe; provide it a function or an instance and function.
function OBJLoader.Request(modelPath , param2 , param3)
	if param2 == nil then
		OBJLoader.Error("Error: bad parameters")
	end
	
	local onLoadCallback = nil
	local onLoadCallbackInstance = nil
	if param3 then
		onLoadCallback = param3
		onLoadCallbackInstance = param2
	else
		onLoadCallback = param2
	end
	
	OBJLoader.MeshRequester(modelPath , onLoadCallback , onLoadCallbackInstance)
end
