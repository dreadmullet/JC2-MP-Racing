----------------------------------------------------------------------------------------------------
-- All database interactions are done here.
----------------------------------------------------------------------------------------------------

Stats.version = 2

-- Logs time elapsed for each function.
Stats.debug = true
-- Print to console as well. This can get very spammy.
Stats.debugPrint = false
Stats.timer = nil
Stats.logFile = nil

-- Count per second that a client is allowed to request, to prevent spam.
Stats.requestLimitSeconds = 3
Stats.requestLimitCount = 3
-- Map that helps with preventing request spam.
-- Key: player id
-- Value: array of timers
Stats.requests = {}

-- Used to commit everything in a transaction every so often (settings.statsCommitInterval).
Stats.sqlCommands = {}
Stats.sqlCommitTimer = Timer()

-- Used to make rank requests faster. Updated with UpdateCache.
-- Contains arrays: PlayTime, Starts, Finishes, Wins
-- Each array goes from 0 to x, where x is the top value reached. For example, if the top person
--    has 500 wins, Wins will have 501 elements. The value of each element is the rank. So, if the
--    second best has 450 wins, there will be 50 elements with a value of 2. [500] is 1, while
--    [450] and above is 2. This will, of course, use a decent chunk of memory, but it's for
--    performance reasons, especially since SQL is blocking.
-- PlayTime is a multiple of 6 minutes. Or something. It's just to make it so the table doesn't have
--    an entry for every single second played, just one every 6 minute interval. For instance, 12
--    minutes, 37 seconds would be 2.
Stats.playerRankTables = nil
-- Updated with UpdateCache
Stats.courses = nil

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
	local timers = Stats.requests[player:GetId()]
	if timers then
		-- Expire any old timers.
		for n = #timers , 1 , -1 do
			if timers[n]:GetSeconds() > Stats.requestLimitSeconds then
				table.remove(timers , n)
			end
		end
	else
		timers = {}
		Stats.requests[player:GetId()] = timers
	end
	
	if #timers >= Stats.requestLimitCount then
		warn(player:GetName().." is requesting stats too quickly! "..player:GetIP())
		return false
	end
	
	table.insert(timers , Timer())
	
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
	
	Stats.UpdateCache()
	
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
	
	local playerStats = Stats.GetPersonalStats(racer.steamId).stats
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
Stats.GetCourseRecords = function(courseFileNameOrHash , from , to)
	Stats.DebugTimerStart()
	
	if type(courseFileNameOrHash) == "string" then
		courseFileNameOrHash = FNV(courseFileNameOrHash)
	end
	
	local count = to - from + 1
	
	local query = SQL:Query(
		"select * from RaceResults where CourseFileNameHash = (?) and Place > 0 "..
		"order by BestTime asc "..
		"limit "..string.format("%i" , math.floor(count + 0.5)).." "..
		"offset "..string.format("%i" , math.floor(from - 1 + 0.5))
	)
	query:Bind(1 , courseFileNameOrHash)
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
	local returnTable = {}
	
	local query = SQL:Query(
		"select PlayTime , Starts , Finishes , Wins from RacePlayers where SteamId = (?)"
	)
	query:Bind(1 , steamId)
	local result = query:Execute()[1]
	
	if result then
		returnTable.stats = {
			PlayTime = tonumber(result.PlayTime) ,
			Starts = tonumber(result.Starts) ,
			Finishes = tonumber(result.Finishes) ,
			Wins = tonumber(result.Wins)
		}
	else
		returnTable.stats = {
			PlayTime = 0 ,
			Starts = 0 ,
			Finishes = 0 ,
			Wins = 0
		}
	end
	
	local rankTables = Stats.playerRankTables
	
	-- Rounded to 6 minutes.
	local playTimeRounded = math.floor(returnTable.stats.PlayTime / 360)
	
	returnTable.ranks = {
		-- 'or 1' at the end should only happen if they're above the cached first place.
		PlayTime = rankTables.PlayTime[playTimeRounded] or 1 ,
		Starts = rankTables.Starts[returnTable.stats.Starts] or 1 ,
		Finishes = rankTables.Finishes[returnTable.stats.Finishes] or 1 ,
		Wins = rankTables.Wins[returnTable.stats.Wins] or 1
	}
	
	return returnTable
end

Stats.UpdateCache = function()
	Stats.DebugTimerStart()
	
	print("Updating stats cache...")
	
	Stats.courses = {}
	local query = SQL:Query("select * from RaceCourses")
	local results = query:Execute()
	for index , result in ipairs(results) do
		local course = {
			tonumber(result.FileNameHash) ,
			result.Name ,
			tonumber(result.TimesPlayed) ,
			tonumber(results.VotesUp) ,
			tonumber(results.VotesDown)
		}
		table.insert(Stats.courses , course)
	end
	
	Stats.playerRankTables = {}
	
	local query = SQL:Query("select PlayTime , Starts , Finishes , Wins from RacePlayers")
	local racePlayers = query:Execute()
	
	local GetSortedColumn = function(columnName)
		local query = SQL:Query(
			"select "..columnName.." from RacePlayers "..
			"order by "..columnName.." desc "
		)
		local results = query:Execute()
		
		local returnTable = {}
		if columnName == "PlayTime" then
			for index , result in ipairs(results) do
				table.insert(returnTable , math.floor(tonumber(result[columnName]) / 360))
			end
		else
			for index , result in ipairs(results) do
				table.insert(returnTable , tonumber(result[columnName]))
			end
		end
		
		return returnTable
	end
	
	-- Complicated brain-stuff, just assume it works.
	local Fill = function(name)
		Stats.playerRankTables[name] = {}
		
		local source = GetSortedColumn(name)
		local max = source[1] or 0 
		local t = Stats.playerRankTables[name]
		local currentRank = 1
		
		for n = max , 1 , -1 do
			t[n] = currentRank
			
			while source[currentRank] and n <= source[currentRank] do
				currentRank = currentRank + 1
			end
		end
		
		t[0] = currentRank
	end
	
	Fill("PlayTime")
	Fill("Starts")
	Fill("Finishes")
	Fill("Wins")
	
	print("Done")
	
	Stats.DebugTimerEnd("UpdateCache")
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

Stats.RequestCourseList = function(unused , player)
	if Stats.CheckSpam(player) == false then
		return
	end
	
	Network:Send(player , "ReceiveCourseList" , Stats.courses)
end

Stats.RequestCourseRecords = function(courseHash , player)
	if Stats.CheckSpam(player) == false then
		return
	end
	
	Network:Send(player , "ReceiveCourseRecords" , Stats.GetCourseRecords(courseHash , 1 , 10))
end

Network:Subscribe("RequestPersonalStats" , Stats.RequestPersonalStats)
Network:Subscribe("RequestCourseList" , Stats.RequestCourseList)
Network:Subscribe("RequestCourseRecords" , Stats.RequestCourseRecords)
