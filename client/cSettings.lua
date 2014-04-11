math.randomseed(os.time())
math.random()

settings.debugLevel = 1

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
	Action.Reverse ,
	Action.HeliIncAltitude ,
	Action.HeliDecAltitude ,
	Action.PlaneIncTrust ,
	Action.PlaneDecTrust ,
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
	Action.StuntJump ,
	Action.ParachuteOpenClose ,
}

-- Make sure everyone doesn't send their distance at the same time.
settings.sendCheckpointDistanceInterval = 0.4 + math.random() * 0.027

settings.motdText =
	"Hello, and welcome to the server!\n"..
	"You can type /"..tostring(settings.command).." in chat to open this menu."

settings.gamemodeName = "JC2-MP-Racing"
settings.gamemodeDescription = [====[In publishing and graphic design, lorem ipsum[1] is a placeholder text commonly used to demonstrate the graphic elements of a document or visual presentation. By replacing the distraction of meaningful content with filler text of scrambled Latin it allows viewers to focus on graphical elements such as font, typography, and layout.

The lorem ipsum text is typically a mangled section of De finibus bonorum et malorum, a 1st-century BC Latin text by Cicero, with words altered, added, and removed that make it nonsensical, improper Latin.[1]

A variation of the common lorem ipsum text has been used during typesetting since the 1960s or earlier,[1] when it was popularized by advertisements for Letraset transfer sheets. It was introduced to the Digital Age by Aldus Corporation in the mid-1980s, which employed it in graphics and word processing templates for its breakthrough desktop publishing program, PageMaker for the Apple Macintosh.[1]]====]

----------------------------------------------------------------------------------------------------
-- GUI
----------------------------------------------------------------------------------------------------

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
