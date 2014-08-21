settings.debugLevel = 1

-- settings.raceManager = RaceManagerMode

settings.coursesPath = "Courses/"

settings.statsCommitInterval = 10 -- Seconds

settings.prizeMoneyDefault = 10000
settings.prizeMoneyMultiplier = 0.75

settings.collisionChance = 1.0
settings.collisionChanceFunc = function()
	return math.random() >= 1 - settings.collisionChance
end

settings.admins = {
	SteamId("STEAM_0:1:12633239") ,
	SteamId("76561197960287930") ,
}
-- If you're using an admin manager script, plug it in here. Or just edit the list above.
settings.GetIsAdmin = function(player)
	return table.find(settings.admins , player:GetSteamId()) ~= nil
end
