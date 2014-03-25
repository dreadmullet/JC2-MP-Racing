
debug = {}
-- Helps with testing starting grids.
-- debug.alwaysMaxPlayers = true

settings.debugLevel = 1

settings.raceManager = RaceManagerJoinable

settings.coursesPath = "courses/"

settings.statsCommitInterval = 10 -- Seconds

settings.prizeMoneyDefault = 10000
settings.prizeMoneyMultiplier = 0.75
settings.lapsMult = 1
if debug.oneLap then settings.lapsMult = 0 end
