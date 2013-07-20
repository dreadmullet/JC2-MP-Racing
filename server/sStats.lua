----------------------------------------------------------------------------------------------------
-- All database interactions are done here.
----------------------------------------------------------------------------------------------------

Stats = {}

-- Logs time elapsed for each function.
Stats.debug = true
Stats.timer = nil
Stats.logFile = nil

Stats.DebugTimerStart = function()
	
	if Stats.debug then
		Stats.timer = Timer()
	end
	
end

Stats.DebugTimerEnd = function(description)
	
	if Stats.debug then
		Stats.LogLine(
			description..
			" - "..
			string.format("%.3f" , Stats.timer:GetSeconds())..
			" seconds"
		)
	end
	
end

Stats.LogLine = function(message)
	
	Stats.logFile:write(os.date("%c").." | "..message.."\n")
	Stats.logFile:flush()
	
end

Stats.Init = function()
	
	if Stats.debug then
		Stats.logFile = io.open("Stats.log" , "a+")
		Stats.logFile:write("\n")
	end
	
	Stats.DebugTimerStart()
	
	-- RacePlayers
	SQL:Execute(
		"create table if not exists "..
		"RacePlayers("..
			"SteamId  integer primary key,"..
			"Name     text ,"..
			"Playtime integer default 0".. -- Seconds
		")"
	)
	
	-- RaceResults
	SQL:Execute(
		"create table if not exists "..
		"RaceResults("..
			"Id       integer primary key autoincrement ,"..
			"SteamId  integer ,"..
			"Place    integer ,".. -- -1 means DNF
			"CourseFileNameHash integer ,"..
			"Vehicle  integer ,".. -- Vehicle model id
			"BestTime integer ,".. -- Milliseconds
			"foreign key(SteamId) references RacePlayers(SteamId)"..
		")"
	)
	SQL:Execute("create index if not exists RaceResultsSteamId on RaceResults(SteamId)")
	SQL:Execute(
		"create index if not exists RaceResultsCourseFileNameHash on RaceResults(CourseFileNameHash)"
	)
	SQL:Execute("create index if not exists RaceResultsBestTime on RaceResults(BestTime)")
	
	-- RaceCourses
	SQL:Execute(
		"create table if not exists "..
		"RaceCourses("..
			"FileNameHash integer primary key ,"..
			"Name             text default 'Invalid course name' ,"..
			"TimesPlayed      integer default 0 ,"..
			"VotesUp          integer default 0 ,"..
			"VotesDown        integer default 0"..
		")"
	)
	
	Stats.DebugTimerEnd("Init")
	
end

Stats.AddPlayer = function(racer)
	
	Stats.DebugTimerStart()
	
	local command = SQL:Command("insert or ignore into RacePlayers(SteamId , Name) values(?,?)")
	command:Bind(1 , racer.steamId)
	command:Execute()
	
	command = SQL:Command("update RacePlayers set Name = (?) where SteamId = (?)")
	command:Bind(1 , racer.name)
	command:Bind(2 , racer.steamId)
	command:Execute()
	
	Stats.DebugTimerEnd("AddPlayer")
	
end

Stats.GetPlayerInfoFromSteamId = function(steamId)
	
	Stats.DebugTimerStart()
	
	local query = SQL:Query("select * from RacePlayers where SteamId = (?)")
	query:Bind(1 , steamId)
	local results = query:Execute()
	
	Stats.DebugTimerEnd("GetPlayerInfoFromSteamId")
	
	return results[1]
	
end

Stats.AddRaceResult = function(racer , place , course)
	
	Stats.DebugTimerStart()
	
	local vehicle = racer.assignedVehicleId
	-- Vehicle id of -1 means on-foot.
	if vehicle ~= -1 then
		vehicle = Vehicle.GetById(vehicle):GetModelId()
	end
	
	local bestTime
	if racer.bestTime == -1 then
		bestTime = (59 * 60 + 59 + 0.99) * 1000
	else
		bestTime = math.floor(racer.bestTime * 1000 + 0.5)
	end
	
	local command = SQL:Command(
		"insert into RaceResults(SteamId , Place , CourseFileNameHash , Vehicle , BestTime) "..
		"values(?,?,?,?,?)"
	)
	command:Bind(1 , racer.steamId)
	command:Bind(2 , place)
	command:Bind(3 , FNV(course.fileName))
	command:Bind(4 , vehicle)
	command:Bind(5 , bestTime)
	command:Execute()
	
	Stats.DebugTimerEnd("AddRaceResult")
	
end

Stats.AddCourse = function(course)
	
	Stats.DebugTimerStart()
	
	local command = SQL:Command(
		"insert or ignore into RaceCourses(FileNameHash) values(?)"
	)
	command:Bind(1 , FNV(course.fileName))
	command:Execute()
	
	command = SQL:Command(
		"update RaceCourses set Name = (?) where FileNameHash = (?)"
	)
	command:Bind(1 , course.name)
	command:Bind(2 , FNV(course.fileName))
	command:Execute()
	
	Stats.DebugTimerEnd("AddCourse")
	
end

-- Example: from 1 to 10 returns top 10 times.
-- Each item is {time = 123.45 , playerName = ""}
Stats.GetCourseRecords = function(course , from , to)
	
	Stats.DebugTimerStart()
	
	local count = to - from + 1
	
	local query = SQL:Query(
		"select * from RaceResults where CourseFileNameHash = (?) and Place > 0 "..
		"order by BestTime asc "..
		"limit "..string.format("%i" , math.floor(count + 0.5)).." "..
		"offset "..string.format("%i" , math.floor(from - 1 + 0.5))
	)
	query:Bind(1 , FNV(course.fileName))
	local results = query:Execute()
	
	local records = {}
	for index , result in ipairs(results) do
		local playerInfo = Stats.GetPlayerInfoFromSteamId(result.SteamId)
		
		local newRecord = {}
		newRecord.time = result.BestTime * 0.001
		newRecord.playerName = playerInfo.Name
		
		table.insert(records , newRecord)
	end
	
	Stats.DebugTimerEnd("GetCourseRecords")
	
	return records
	
end

Stats.RaceStart = function(race)
	
	Stats.DebugTimerStart()
	
	-- Increment RaceCourses.TimesPlayed.
	
	local query = SQL:Query("select TimesPlayed from RaceCourses where FileNameHash = (?)")
	query:Bind(1 , FNV(race.course.fileName))
	local results = query:Execute()
	
	local timesPlayed = results[1].TimesPlayed
	timesPlayed = timesPlayed + 1
	
	local command = SQL:Command(
		"update RaceCourses set TimesPlayed = (?) where FileNameHash = (?)"
	)
	command:Bind(1 , timesPlayed)
	command:Bind(2 , FNV(race.course.fileName))
	command:Execute()
	
	-- Get each racer's PlayTime.
	-- NOTE: This is probably inefficient. Would a transaction even work here?
	for id , racer in pairs(race.playerIdToRacer) do
		local query = SQL:Query("select PlayTime from RacePlayers where SteamId = (?)")
		query:Bind(1 , racer.steamId)
		local results = query:Execute()
		racer.playTime = results[1].PlayTime
	end
	
	Stats.DebugTimerEnd("RaceStart")
	
end
