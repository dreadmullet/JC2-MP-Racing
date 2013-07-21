----------------------------------------------------------------------------------------------------
-- Manages backward compatibility. If a database from an old Racing version is loaded, it is
-- converted to use the new version. In theory, /all/ database versions are compatible with the
-- newest version of Racing.
----------------------------------------------------------------------------------------------------

Stats.UpdateFromOldVersion = function(oldVersion)
	
	print("Updating database...")
	local timer = Timer()
	
	-- This is /the entire database/ marshalled into a table.
	local database
	if oldVersion == 0 then
		database = Stats.UpdateFromV0()
	end
	
	print(".")
	
	-- Drop all tables.
	local transaction = SQL:Transaction()
	SQL:Execute("drop table if exists RacePlayers")
	SQL:Execute("drop table if exists RaceResults")
	SQL:Execute("drop table if exists RaceCourses")
	SQL:Execute("drop table if exists RaceVersion")
	transaction:Commit()
	
	print(".")
	
	-- Recreate the database.
	
	Stats.CreateTables()
	
	local transaction = SQL:Transaction()
	
	-- RacePlayers
	for index , racePlayer in ipairs(database.RacePlayers) do
		local command = SQL:Command("insert into RacePlayers values(?,?,?)")
		command:Bind(1 , racePlayer.SteamId)
		command:Bind(2 , racePlayer.Name)
		command:Bind(3 , racePlayer.PlayTime)
		command:Execute()
	end
	print(".")
	-- RaceResults
	for index , raceResult in ipairs(database.RaceResults) do
		local command = SQL:Command(
			"insert into RaceResults(SteamId , Place , CourseFileNameHash , Vehicle , BestTime) "..
			"values(?,?,?,?,?)"
		)
		command:Bind(1 , raceResult.SteamId)
		command:Bind(2 , raceResult.Place)
		command:Bind(3 , raceResult.CourseFileNameHash)
		command:Bind(4 , raceResult.Vehicle)
		command:Bind(5 , raceResult.BestTime)
		command:Execute()
	end
	print(".")
	-- RaceCourses
	for index , raceCourse in ipairs(database.RaceCourses) do
		local command = SQL:Command(
			"insert into RaceCourses values(?,?,?,?,?)"
		)
		command:Bind(1 , raceCourse.FileNameHash)
		command:Bind(2 , raceCourse.Name)
		command:Bind(3 , raceCourse.TimesPlayed)
		command:Bind(4 , raceCourse.VotesUp)
		command:Bind(5 , raceCourse.VotesDown)
		command:Execute()
	end
	
	print(".")
	
	transaction:Commit()
	
	print("Done. Time elapsed: "..string.format("%.3f" , timer:GetSeconds()).." seconds")
	
end

Stats.UpdateFromV0 = function(oldDatabase)
	
	if oldDatabase == nil then
		oldDatabase = {}
		oldDatabase.RacePlayers = SQL:Query("select * from RacePlayers"):Execute()
		oldDatabase.RaceResults = SQL:Query("select * from RaceResults"):Execute()
		oldDatabase.RaceCourses = SQL:Query("select * from RaceCourses"):Execute()
	end
	
	local returnDatabase = {}
	returnDatabase.RacePlayers = oldDatabase.RacePlayers
	for index , racePlayer in ipairs(returnDatabase.RacePlayers) do
		racePlayer.PlayTime = racePlayer.Playtime
		racePlayer.Playtime = nil
	end
	returnDatabase.RaceResults = oldDatabase.RaceResults
	returnDatabase.RaceCourses = oldDatabase.RaceCourses
	
	return returnDatabase
	
end
