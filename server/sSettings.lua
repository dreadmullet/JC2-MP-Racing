
debug = {}
-- Helps with testing starting grids.
-- debug.alwaysMaxPlayers = true

settings.debugLevel = 1

settings.raceManager = RaceManagerJoinable

settings.coursesPath = "courses/"

settings.statsCommitInterval = 10 -- Seconds

settings.prizeMoneyDefault = 10000
settings.prizeMoneyMultiplier = 0.75

-- If you're using an admin manager script, plug it in here. Or just make your own list.
settings.GetIsAdmin = function(player)
	return player:GetSteamId() == SteamId("STEAM_0:1:12633239")
end
