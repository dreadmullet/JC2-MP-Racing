OBJLoader.Type = {
	Single = 1 ,
	Multiple = 2 ,
	MultipleDepthSorted = 3 ,
}

OBJLoader.cachedRequests = {}

OBJLoader.Error = function(text)
	error("[OBJLoader] "..text)
end

-- extra1/extra2 are like Events:Subscribe; provide it a function or an instance and function.
-- args is a table which supports the following elements:
-- * string           path (required)
-- * OBJLoader.Type   type (default: Single)
-- * boolean          is2D (default: false)
OBJLoader.Request = function(args , extra1 , extra2)
	if
		extra1 == nil or
		type(args) ~= "table" or
		type(args.path) ~= "string"
	then
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
	
	local cachedRequest = OBJLoader.cachedRequests[args.path]
	if cachedRequest then
		if cachedRequest.isFinished then
			cachedRequest:ForceCallback(onLoadCallback , onLoadCallbackInstance)
		else
			cachedRequest:AddCallback(onLoadCallback , onLoadCallbackInstance)
		end
	else
		OBJLoader.cachedRequests[args.path] = OBJLoader.MeshRequester(
			args , onLoadCallback , onLoadCallbackInstance
		)
	end
end
