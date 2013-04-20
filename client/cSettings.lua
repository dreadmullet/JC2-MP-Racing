
Settings = {}

-- Seed random generator.
math.randomseed(os.time())
math.random()

----------------
-- Racing
----------------

Settings.blockedInputs = {
	Action.FireLeft , -- Blocks firing weapons on foot.
	Action.FireRight , -- Blocks firing weapons on foot.
	Action.McFire , -- Blocks firing one-handed weapons on bike/ATV.
	Action.VehicleFireLeft , -- Blocks firing vehicle weapons.
	Action.VehicleFireRight , -- Blocks firing vehicle weapons.
	Action.NextWeapon , -- Blocks switching weapons.
	Action.PrevWeapon , -- Blocks switching weapons.
	-- Action.StuntJump , -- Prevents people from riding on cars and hopping on people's bikes.
}
-- Make sure everyone doesn't send their distance at the same time.
Settings.sendCheckpointDistanceInterval = 0.4 + math.random() * 0.027

Settings.gamemodeName = "Racing"

Settings.gamemodeDescription = [[
The Racing gamemode lets you race other players in a variety of races, using vehicles from sports cars to buses to planes. It comes with a fully-featured GUI, letting you focus on the race.
 
Command list:
   "/race" - Begins a race, if the race is accepting players.
   "/race quality high" - (default)
   "/race quality low" - Lowers quality of GUI; makes checkpoint arrow flat and removes minimap icons. This won't affect your framerate much, only use it if you're desperate.
 
Known issues:
During races, sometimes the checkpoint arrow will be invisible. You can probably fix this by reconnecting to the server (press ~ to open the console and enter "reconnect").
]]


----------------
-- GUI
----------------

Settings.backgroundColor = Color(38 , 26 , 15 , 110)
Settings.backgroundAltColor = Color(5 , 6 , 12 , 90)
Settings.textColor = Color(228 , 142 , 56 , 255)
Settings.shadowColor = Color(0 , 0 , 0 , 255)

-- Normalized.
Settings.startingGridBackgroundTopRight = Vector2(0.88 , -0.92)
-- Normalized.
Settings.startingGridBackgroundSize = Vector2(0.35 , 0.105)
Settings.startingGridTextSize = "Large"

Settings.padding = 6

Settings.checkpointArrowFlashNum = 3
Settings.checkpointArrowFlashInterval = 7
Settings.checkpointArrowColor = Color(204 , 54 , 51)
-- Settings.checkpointArrowColorActivated = Color(56 , 200 , 45)
Settings.checkpointArrowColorActivated = Color(0 , 0 , 0 , 0)

Settings.nextCheckpointArrowColor = Color(228 , 142 , 56 , 255)

-- Normalized positions.
Settings.lapLabelPos = Vector2(0.33 , -0.58)
Settings.lapLabelSize = "Large"
Settings.lapCounterPos = Vector2(0.33 , -0.68)
Settings.lapCounterSize = "Huge"

Settings.racePosLabel = "Pos"
Settings.racePosLabelPos = Vector2(-0.33 , -0.58)
Settings.racePosLabelSize = "Large"
Settings.racePosPos = Vector2(-0.33 , -0.68)
Settings.racePosSize = "Huge"

Settings.minimapCheckpointColor1 = Color(245 , 25 , 19)
Settings.minimapCheckpointColor2 = Color(245 , 100 , 19 , 112)
Settings.minimapCheckpointColorGrey1 = Color(180 , 170 , 150 , 255) -- Inside
Settings.minimapCheckpointColorGrey2 = Color(130 , 70 , 60 , 220) -- Border

-- Normalized.
Settings.leaderboardPos = Vector2(-0.95 , -0.39)
Settings.leaderboardTextSize = "Default"
Settings.leaderboardMaxPlayers = 8
Settings.maxPlayerNameLength = 16

Settings.largeMessageTextSize = "Huge"
Settings.largeMessageBlendRatio = 0.1
Settings.largeMessagePos = Vector2(0 , -0.2)

-- 0 = default
-- -1 = No minimap icons and low quality checkpoint arrow.
Settings.guiQuality = 0

Settings.useNametags = false










