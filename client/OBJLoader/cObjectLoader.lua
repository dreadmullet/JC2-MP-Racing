OBJLoader.Type = {
	Single = 1 ,
	Multiple = 2 ,
}

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
	
	OBJLoader.MeshRequester(args , onLoadCallback , onLoadCallbackInstance)
end
