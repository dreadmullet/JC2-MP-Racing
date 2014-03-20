class("RaceBase")
	class("Race")
	class("Spectate")

-- Race states
class("StateStartingGrid")
class("StateRacing")
class("StateFinished")

class("RaceMenu")

class("LargeMessage")
class("OrbitCamera")

RaceGUI = {}

parachuteActions = {}
parachuteActions[Action.ActivateParachuteThrusters] = true
parachuteActions[Action.ExitToStuntposParachute] = true
parachuteActions[Action.ParachuteOpenClose] = true
parachuteActions[Action.ParachuteLandOnVehicle] = true
parachuteActions[Action.StuntposToParachute] = true
parachuteActions[Action.DeployParachuteWhileReelingAction] = true

-- When this is 0, input is normal. When it's above 0, input is suspended.
-- * It is up to implementations of input to abide by the value.
-- * Any text boxes should increment it on focus and decrement it on blur.
inputSuspensionValue = 0
