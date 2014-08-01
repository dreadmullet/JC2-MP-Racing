settings = {}

settings.spectatorRequestInterval = 2.5

settings.textColor = Color(228 , 142 , 56 , 255) -- Light red-orange.

settings.command = "race"

settings.respawnMinPeriod = 5
-- If you set this too low, some courses can be done faster by respawning at certain points.
settings.respawnDelay = 3.5

settings.vehicleSelectionSeconds = 22
settings.startingGridSeconds = 14

settings.lapsMult = 1

settings.numLapsFunc = function(numPlayers , maxPlayers , courseLaps)
	local lapsMultPlayers = math.min((numPlayers / maxPlayers) , 1)
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
