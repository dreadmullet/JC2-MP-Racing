
class("RaceManagerBase")
	class("RaceManagerMode")
	class("RaceManagerJoinable")

class("Race")

class("RacerBase")
	class("Racer")
	class("Spectator")

-- Race states
class("StateStartingGrid")
class("StateRacing")

class("CourseManager")
class("Course")
class("CourseCheckpoint")
class("CourseSpawn")
class("CourseLoader")

Stats = {}

math.randomseed(os.time())
math.tau = math.pi * 2
