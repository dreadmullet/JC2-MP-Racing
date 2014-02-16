Utility = {}

-- these are tabs, such as 4 spaces
Utility.tabPhrase = "    "

-- simulates a tab thing for type info
Utility.typeStringTabLength = 8

-- prints a table, in full
-- should be called using PrintTable(tableToCall)
-- depth and tableList are used internally
	-- depth helps with tabs.
	-- tableList is a list that contains all of the tables that
	-- have already been printed, so that it doesn't
	-- form an infinite loop of printing tables.
Utility.PrintTable = function(t , depth , tableList)
	-- Error checking against arguments.
	if t == nil then
		print("nil")
		return
	end
	
	if type(t) ~= "table" then
		print("Not a table")
		return
	end
	
	-- helps with adding tabs
	if not depth then depth = 0 end
	local tab = ""
	for i=1 , depth do
		tab = tab..Utility.tabPhrase
	end
	
	-- if tableList is nil, make it
	if not tableList then tableList = {} end
	
	-- add t to tableList
	tableList[t] = true
	
	for key,value in pairs(t) do
		-- If this check isn't in place it will error.
		if type(key) == "table" then
			local keysString = ""
			for k,v in pairs(key) do
				keysString = keysString..tostring(k).." , "
			end
			keysString = keysString:sub(1 , keysString:len() - 3)
			key = "TABLE: {"..keysString.."}"
		end
		local type = type(value)
		local typeString = "("..
			type..
			")"..
			string.rep(" " , Utility.typeStringTabLength - string.len(type))
		if type == "table" then
			print(tab.."TABLE: "..key)
			if tableList[value] then
				print(tab.."(already printed)")
			else
				Utility.PrintTable(value , depth + 1 , tableList)
			end
		elseif type == "boolean" then
			if value then
				print(tab..typeString..key.." = true")
			else
				print(tab..typeString..key.." = false")
			end
		else
			-- other types
			if type == "number" or type == "string" then
				print(tab..typeString..key.." = "..value)
			else
				print(tab.."(UNKNOWN TYPE) "..type.." - "..key)
			end
		end
	end
end

Utility.NumberToPlaceString = function(number)
	if number == 1 then
		return string.format("%i%s" , 1 , "st")
	elseif number == 2 then
		return string.format("%i%s" , 2 , "nd")
	elseif number == 3 then
		return string.format("%i%s" , 3 , "rd")
	else
		return string.format("%i%s" , number , "th")
	end
end

-- Returns hours, minutes, seconds, hundredths
Utility.SplitSeconds = function(totalSeconds)
	local hours = math.floor(totalSeconds / 3600)
	totalSeconds = totalSeconds - hours * 3600
	local minutes = math.floor(totalSeconds / 60)
	totalSeconds = totalSeconds - minutes * 60
	local seconds = math.floor(totalSeconds)
	local hundredths = math.floor((totalSeconds - seconds) * 100 + 0.5)
	
	if seconds >= 60 then
		minutes = minutes + 1
		seconds = seconds - 60
	end
	
	if hundredths >= 100 then
		seconds = seconds + 1
		hundredths = hundredths - 100
	end
	
	return hours , minutes , seconds , hundredths
end

Utility.LapTimeString = function(totalSeconds)
	if totalSeconds == nil then
		return "N/A"
	end
	
	local hours , minutes , seconds , hundredths = Utility.SplitSeconds(totalSeconds)
	
	return string.format("%.2i:%.2i.%.2i" , minutes , seconds , hundredths)
end
