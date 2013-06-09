
class("Race")
class("LargeMessage")

class("Course")
class("CourseCheckpoint")
class("CourseSpawn")

class("CourseEditor")

class("Tool")
	class("None")(Tool)
	class("BaseSpawner")(Tool)
		class("CheckpointSpawner")(BaseSpawner)
		class("VehicleSpawner")(BaseSpawner)
	class("CourseSettings")(Tool)
	class("LoadCourseTool")(Tool)

class("Object")
	class("CheckpointObject")(Object)

class("CEMainMenu")
