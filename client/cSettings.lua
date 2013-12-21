
-- Seed random generator.
math.randomseed(os.time())
math.random()

settings.debugLevel = 2

settings.countDownNumMessages = 3
settings.countDownInterval = 2

settings.blockedInputsRacing = {
	Action.FireLeft , -- Blocks firing weapons on foot.
	Action.FireRight , -- Blocks firing weapons on foot.
	Action.McFire , -- Blocks firing one-handed weapons on bike/ATV.
	Action.VehicleFireLeft , -- Blocks firing vehicle weapons.
	Action.VehicleFireRight , -- Blocks firing vehicle weapons.
	Action.NextWeapon , -- Blocks switching weapons.
	Action.PrevWeapon , -- Blocks switching weapons.
}
settings.blockedInputsStartingGrid = {
	Action.FireLeft ,
	Action.FireRight ,
	Action.McFire ,
	Action.VehicleFireLeft ,
	Action.VehicleFireRight ,
	Action.NextWeapon ,
	Action.PrevWeapon ,
	-- Action.Accelerate , -- Selectively disabled in StateStartingGrid depending on vehicle type.
	Action.Reverse ,
	Action.HeliIncAltitude ,
	Action.HeliDecAltitude ,
	Action.PlaneIncTrust ,
	Action.PlaneDecTrust ,
	-- Action.BoatForward , -- These two don't even do anything.
	-- Action.BoatBackward ,
}
settings.blockedInputsStartingGridOnFoot = {
	Action.FireLeft ,
	Action.FireRight ,
	Action.NextWeapon ,
	Action.PrevWeapon ,
	Action.MoveForward ,
	Action.MoveBackward ,
	Action.MoveLeft ,
	Action.MoveRight ,
	Action.FireGrapple ,
	Action.Jump ,
	Action.Evade ,
	Action.Kick ,
}
settings.blockedInputsInVehicle = {
	-- Action.UseItem ,
	Action.StuntJump ,
	Action.ParachuteOpenClose ,
}

-- Make sure everyone doesn't send their distance at the same time.
settings.sendCheckpointDistanceInterval = 0.4 + math.random() * 0.027

settings.gamemodeName = "Racing"
settings.gamemodeDescription = [[
The Racing gamemode lets you race other players in a variety of races, using vehicles from sports cars to buses to planes. It comes with a fully-featured GUI, letting you focus on the race.
 
Command list:
   "/race" - Begins a race.
 
Earning money: You receive $10000 for winning a race. Each following finisher receives 75% of the last finisher (2nd place receives $7500, for example).
 
Known issues:
During races, sometimes the checkpoint arrow will be invisible. You can probably fix this by reconnecting to the server (press ~ to open the console and enter "reconnect").
]]

----------------------------------------------------------------------------------------------------
-- GUI
----------------------------------------------------------------------------------------------------

settings.textColor = Color(228 , 142 , 56 , 255)
settings.shadowColor = Color(0 , 0 , 0 , 255)

settings.targetArrowFlashNum = 3
settings.targetArrowFlashInterval = 7

settings.nextCheckpointArrowColor = Color(228 , 142 , 56 , 128)

-- Normalized positions.
settings.lapLabelPos = Vector2(0.33 , -0.58)
settings.lapLabelSize = TextSize.Large
settings.lapCounterPos = Vector2(0.33 , -0.68)
settings.lapCounterSize = TextSize.Huge

settings.racePosLabel = "Pos"
settings.racePosLabelPos = Vector2(-0.33 , -0.58)
settings.racePosLabelSize = TextSize.Large
settings.racePosPos = Vector2(-0.33 , -0.68)
settings.racePosSize = TextSize.Huge

settings.timerLabelsStart = Vector2(0.95 , -0.39)
settings.timerLabelsSize = TextSize.Default

settings.minimapCheckpointColor1 = Color(245 , 25 , 19)
settings.minimapCheckpointColor2 = Color(245 , 100 , 19 , 112)
settings.minimapCheckpointColorGrey1 = Color(180 , 170 , 150 , 255) -- Inside
settings.minimapCheckpointColorGrey2 = Color(130 , 70 , 60 , 220) -- Border

-- Normalized.
settings.leaderboardPos = Vector2(-0.95 , -0.39)
settings.leaderboardTextSize = TextSize.Default
settings.leaderboardMaxPlayers = 8
settings.maxPlayerNameLength = 16

settings.largeMessageTextSize = TextSize.Huge
settings.largeMessageBlendRatio = 0.1
settings.largeMessagePos = Vector2(0 , -0.2)
