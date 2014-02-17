----------------------------------------------------------------------------------------------------
-- All database interactions are done here.
----------------------------------------------------------------------------------------------------

Stats.version = 2

-- Logs time elapsed for each function.
Stats.debug = true
-- Print to console as well.
Stats.debugPrint = true
Stats.timer = nil
Stats.logFile = nil

-- Minimum interval that a client is allowed to request, to prevent spam.
Stats.requestLimitSeconds = 1.8
-- Map that helps with preventing request spam.
-- Key: player id
-- Value: timer
Stats.requests = {}

-- Used to commit everything in a transaction every so often (settings.statsCommitInterval).
Stats.sqlCommands = {}
Stats.sqlCommitTimer = Timer()

----------------------------------------------------------------------------------------------------
-- Utility
----------------------------------------------------------------------------------------------------

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
	if Stats.logFile then
		Stats.logFile:write(os.date("%c").." | "..message.."\n")
		Stats.logFile:flush()
		
		if Stats.debugPrint then
			print("[Stats] "..message)
		end
	end
end

Stats.GetTableExists = function(tableName)
	local query = SQL:Query("select name from sqlite_master where type = 'table' and name = (?)")
	query:Bind(1 , tableName)
	local results = query:Execute()
	
	return results[1] ~= nil
end

-- Returns false if they are spamming requests and should be refused.
Stats.CheckSpam = function(player)
	local timer = Stats.requests[player:GetId()]
	if timer ~= nil and timer:GetSeconds() < Stats.requestLimitSeconds then
		warn(player:GetName().." is requesting stats too quickly!")
		return false
	end
	
	Stats.requests[player:GetId()] = Timer()
	
	return true
end

----------------------------------------------------------------------------------------------------
-- Stats
----------------------------------------------------------------------------------------------------

Stats.Init = function()
	if Stats.debug then
		Stats.logFile , openError = io.open("Stats.log" , "a+")
		if Stats.logFile then
			Stats.logFile:write("\n")
		else
			warn("Cannot open Stats.log. (Are permissions set correctly?) "..openError)
			Stats.debug = false
		end
	end
	
	Stats.DebugTimerStart()
	
	local hasDatabase = Stats.GetTableExists("RaceResults")
	if hasDatabase then
		local oldVersion
		local hasVersion = Stats.GetTableExists("RaceVersion")
		if hasVersion then
			oldVersion = SQL:Query("select Version from RaceVersion"):Execute()[1].Version
		else
			oldVersion = 0
		end
		
		-- Philpax sucks, SQL always returns a string.
		oldVersion = tonumber(oldVersion)
		
		if oldVersion ~= Stats.version then
			Stats.UpdateFromOldVersion(oldVersion)
		end
	end
	
	Stats.CreateTables()
	
	Stats.DebugTimerEnd("Init")
	
	Events:Subscribe("PostTick" , Stats.PostTick)
end

Stats.CreateTables = function()
	-- RacePlayers
	SQL:Execute(
		"create table if not exists "..
		"RacePlayers("..
			"SteamId  integer primary key ,"..
			"Name     text ,"..
			"PlayTime integer default 0 ,".. -- Seconds
			"Starts   integer default 0 ,"..
			"Finishes integer default 0 ,"..
			"Wins     integer default 0"..
		")"
	)
	-- RaceResults
	SQL:Execute(
		"create table if not exists "..
		"RaceResults("..
			"Id                 integer primary key autoincrement ,"..
			"SteamId            integer ,"..
			"Place              integer ,".. -- -1 means DNF
			"CourseFileNameHash integer ,"..
			"Vehicle            integer ,".. -- Vehicle model id
			"BestTime           integer ,".. -- Milliseconds
			"foreign key(SteamId) references RacePlayers(SteamId)"..
		")"
	)
	SQL:Execute("create index if not exists RaceResultsSteamId on RaceResults(SteamId)")
	SQL:Execute(
		"create index if not exists RaceResultsCourseFileNameHash "..
		"on RaceResults(CourseFileNameHash)"
	)
	SQL:Execute("create index if not exists RaceResultsBestTime on RaceResults(BestTime)")
	-- RaceCourses
	SQL:Execute(
		"create table if not exists "..
		"RaceCourses("..
			"FileNameHash integer primary key ,"..
			"Name         text default 'Invalid course name' ,"..
			"TimesPlayed  integer default 0 ,"..
			"VotesUp      integer default 0 ,"..
			"VotesDown    integer default 0"..
		")"
	)
	-- Version
	SQL:Execute(
		"create table if not exists "..
		"RaceVersion("..
			"Version integer primary key"..
		")"
	)
	local command = SQL:Command("insert or ignore into RaceVersion(Version) values(?)")
	command:Bind(1 , Stats.version)
	command:Execute()
end

Stats.AddPlayer = function(racer)
	Stats.DebugTimerStart()
	
	local command = SQL:Command("insert or ignore into RacePlayers(SteamId , Name) values(?,?)")
	command:Bind(1 , racer.steamId)
	command:Execute()
	
	command = SQL:Command("update RacePlayers set Name = (?) where SteamId = (?)")
	command:Bind(1 , racer.name)
	command:Bind(2 , racer.steamId)
	table.insert(Stats.sqlCommands , command)
	
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
	
	-- Add to RaceResults.
	
	local vehicleId = racer.assignedVehicleId
	-- Vehicle model id of -1 means on-foot. -2 means no assigned vehicle.
	local vehicleModelId = -2
	if vehicleId >= 0 then
		local vehicle = Vehicle.GetById(vehicleId)
		if IsValid(vehicle) then
			vehicleModelId = vehicle:GetModelId()
		end
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
	command:Bind(4 , vehicleModelId)
	command:Bind(5 , bestTime)
	table.insert(Stats.sqlCommands , command)
	
	-- Update RacePlayers with player stats (starts, finishes, and wins).
	
	local playerStats = Stats.GetPersonalStats(racer.steamId)
	playerStats.Starts = playerStats.Starts + 1
	if place >= 1 then
		playerStats.Finishes = playerStats.Finishes + 1
	end
	if place == 1 then
		playerStats.Wins = playerStats.Wins + 1
	end
	
	command = SQL:Command(
		"update RacePlayers set Starts = (?) , Finishes = (?) , Wins = (?) where SteamId = (?)"
	)
	command:Bind(1 , playerStats.Starts)
	command:Bind(2 , playerStats.Finishes)
	command:Bind(3 , playerStats.Wins)
	command:Bind(4 , racer.steamId)
	table.insert(Stats.sqlCommands , command)
	
	Stats.DebugTimerEnd("AddRaceResult")
end

Stats.AddCourse = function(course)
	Stats.DebugTimerStart()
	
	local command = SQL:Command(
		"insert or ignore into RaceCourses(FileNameHash) values(?)"
	)
	command:Bind(1 , FNV(course.fileName))
	table.insert(Stats.sqlCommands , command)
	
	command = SQL:Command(
		"update RaceCourses set Name = (?) where FileNameHash = (?)"
	)
	command:Bind(1 , course.name)
	command:Bind(2 , FNV(course.fileName))
	table.insert(Stats.sqlCommands , command)
	
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
	table.insert(Stats.sqlCommands , command)
	
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

Stats.PlayerExit = function(racer)
	Stats.DebugTimerStart()
	
	local command = SQL:Command(
		"update RacePlayers set PlayTime = (?) where SteamId = (?)"
	)
	command:Bind(1 , racer.playTime)
	command:Bind(2 , racer.steamId)
	table.insert(Stats.sqlCommands , command)
	
	Stats.DebugTimerEnd("PlayerExit")
end

Stats.GetPersonalStats = function(steamId)
	local stats = {}
	
	local query = SQL:Query(
		"select PlayTime , Starts , Finishes , Wins from RacePlayers where SteamId = (?)"
	)
	query:Bind(1 , steamId)
	local results = query:Execute()
	
	return results[1]
end

----------------------------------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------------------------------

Stats.PostTick = function()
	if Stats.sqlCommitTimer:GetSeconds() > settings.statsCommitInterval then
		Stats.sqlCommitTimer:Restart()
		
		if #Stats.sqlCommands ~= 0 then
			local transaction = SQL:Transaction()
			for index , command in ipairs(Stats.sqlCommands) do
				command:Execute()
			end
			Stats.sqlCommands = {}
			transaction:Commit()
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Network
----------------------------------------------------------------------------------------------------

Stats.RequestPersonalStats = function(unused , player)
	if Stats.CheckSpam(player) == false then
		return
	end
	
	Network:Send(player , "ReceivePersonalStats" , Stats.GetPersonalStats(player:GetSteamId().id))
end

Network:Subscribe("RequestPersonalStats" , Stats.RequestPersonalStats)
