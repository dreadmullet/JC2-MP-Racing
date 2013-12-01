class("Test")

local Class = function(name)
	class(name)
	OBJLoader[name] = _G[name]
	_G[name] = nil
end

Class("MeshRequester")
