settings = {}

settings.version = "0.9.1"

settings.spectatorRequestInterval = 3

settings.textColor = Color(228 , 142 , 56 , 255) -- Light red-orange.

settings.command = "race"

settings.minRespawnPeriod = 4

settings.vehicleSelectionSeconds = 22
settings.startingGridSeconds = 11

settings.lapsMult = 1

settings.numLapsFunc = function(numPlayers , maxPlayers , courseLaps)
	local lapsMultPlayers = (numPlayers / maxPlayers)
	lapsMultPlayers = lapsMultPlayers + 0.75
	-- Dilute the effect.
	lapsMultPlayers = math.lerp(1 , lapsMultPlayers , 0.7)
	-- Global laps multipier.
	local numLaps = courseLaps * settings.lapsMult
	-- Multiply laps and then round it.
	numLaps = math.ceil(numLaps * lapsMultPlayers - 0.5)
	-- Minimum laps of 1.
	if numLaps < 1 then
		numLaps = 1
	end
	
	return numLaps
end
