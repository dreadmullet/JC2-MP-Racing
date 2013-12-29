
debug = {}
-- Helps with testing starting grids.
-- debug.alwaysMaxPlayers = true

settings.debugLevel = 1

settings.version = "0.8.2"
if settings.debugLevel > 1 then
	settings.version = settings.version.." (debug)"
end

settings.raceManager = RaceManagerMode

settings.coursesPath = "courses/"

settings.textColor = Color(250 , 157 , 133 , 255) -- Light red-orange.

settings.startingGridWaitSeconds = 11
settings.prizeMoneyDefault = 10000
settings.prizeMoneyMultiplier = 0.75
settings.lapsMult = 0.75
if debug.oneLap then settings.lapsMult = 0 end

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
