
debug = {}
-- Helps with testing starting grids.
-- debug.alwaysMaxPlayers = true
-- debug.dontRemoveIfOutOfVehicle = true
-- debug.quickRaceStart = true
-- debug.oneLap = true

settings = {}

settings.debugLevel = 1

settings.name = "JC2-MP-Racing"
settings.description = "Race cars and shit."
settings.version = "0.7.3"
if settings.debugLevel > 1 then
	settings.version = settings.version.." (debug)"
end

settings.coursesPath = "courses/"

settings.doPublicRaces = true

settings.textColorGlobal = Color(250 , 157 , 133 , 255) -- Light red-orange.
settings.textColorLocal =  Color(255 , 80 , 36 , 255) -- Full red-orange.

-- The first race created starts at this id; other races have higher Ids. When the first race
-- finishes, its id becomes usable again.
settings.worldIdBase = 10
settings.playerModelIds = {60 , 65 , 69}
settings.playerModelIdAdmin = 100

settings.startingGridWaitSeconds = 11
settings.outOfVehicleMaxSeconds = 20
settings.vehicleRepairAmount = 0.05
settings.prizeMoneyDefault = 10000
settings.prizeMoneyMultiplier = 0.75
settings.playerFinishRemoveDelay = 12
settings.lapsMult = 1
if debug.oneLap then settings.lapsMult = 0 end

-- Public races
settings.command = "/race"
settings.raceJoinWaitSeconds = 110
if debug.quickRaceStart then settings.raceJoinWaitSeconds = 2 end

settings.admins = {
	SteamID("76561197985532207") , -- dreadmullet
}

settings.WTF = false

settings.courseEditorEnabled = false

settings.timeLimitFunc = function(lapTimeSeconds , numLaps)
	
	return 60 + lapTimeSeconds * numLaps * 4
	
end
settings.numLapsFunc = function(race , courseLaps)
	
	local lapsMultPlayers = (race.numPlayers / race.maxPlayers)
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
