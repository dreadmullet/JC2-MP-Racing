
debug = {}
-- Helps with testing starting grids.
-- debug.alwaysMaxPlayers = true
-- debug.dontRemoveIfOutOfVehicle = true
debug.oneLap = true

settings = {}

settings.tempDLC = true
settings.forceCourse = ""

settings.debugLevel = 1

settings.name = "JC2-MP-Racing"
settings.version = "0.8.1"
if settings.debugLevel > 1 then
	settings.version = settings.version.." (debug)"
end

settings.raceManager = "RaceManagerMode"

settings.coursesPath = "courses/"

settings.textColor = Color(250 , 157 , 133 , 255) -- Light red-orange.

settings.playerModelIds = {60 , 65 , 69}
settings.playerModelIdAdmin = 100

settings.startingGridWaitSeconds = 11
settings.outOfVehicleMaxSeconds = 20
settings.prizeMoneyDefault = 10000
settings.prizeMoneyMultiplier = 0.75
settings.playerFinishRemoveDelay = 12
settings.lapsMult = 1
if debug.oneLap then settings.lapsMult = 0 end

settings.admins = {
	SteamId("76561197985532207") , -- dreadmullet
}

settings.courseEditorEnabled = false

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
