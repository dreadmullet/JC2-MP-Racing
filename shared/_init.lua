
VehicleList = {}
settings = {}

RaceModules = {}
RaceModules.Class = function(name)
	class(name)
	RaceModules[name] = _G[name]
	_G[name] = nil
end
