class("RaceBase")
	class("Race")
	class("Spectate")

-- Race states
class("StateNone")
class("StateAddPlayers")
class("StateStartingGrid")
class("StateRacing")
class("StateFinished")
class("StateTerminate")

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
