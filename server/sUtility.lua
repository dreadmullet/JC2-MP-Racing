-- Utility is defined in sharedUtility.lua.
local M = Utility

-----------------------
-- Utility functions --
-----------------------

-- Compares simple arrays. Not recursive.
M.CompareArrays = function(a1 , a2)

    -- make sure they're both tables
	if type(a1) ~= "table" or type(a2) ~= "table" then
		return false
	end

	-- make sure they have the same length
    if #a1 ~= #a2 then
        return false
    end

	-- compare the elements
    for i=1 , #a1 do
        if a1[i] ~= a2[i] then
            return false
        end
    end

    return true

end

-- Like above, but recursive by one level.
M.CompareArrays2 = function(a1 , a2)

	-- make sure they're both tables
	if type(a1) ~= "table" or type(a2) ~= "table" then
		return false
	end

	-- make sure they have the same length
    if #a1 ~= #a2 then
        return false
    end

	-- compare the elements
    for x=1 , #a1 do
		if type(a1[x]) == "table" and type(a2[x]) == "table" then
			if #a1[x] ~= #a2[x] then
				return false
			end
			if #a1[x] ~= #a2[x] then
				for y=1 , #a1[x] do
					if a1[x][y] ~= a2[x][y] then
						return false
					end
				end
			end
		else
			if a1[i] ~= a2[i] then
				return false
			end
		end

    end

    return true

end

-- Compares two tables in full, including recursion.
-- The only missing functionality might be tables as keys.
-- This could be more efficient, I think.
M.CompareTables = function(t1 , t2)

    if (not t1) or (not t2) then
        return false
    end

    for key,value in pairs(t1) do
        if type(value) == "table" then
            if not CompareTables(t1[key] , t2[key]) then
                return false
            end
        else
            if t1[key] ~= t2[key] then
                return false
            end
        end
    end

    for key,value in pairs(t2) do
        if type(value) == "table" then
            if not CompareTables(t1[key] , t2[key]) then
                return false
            end
        else
            if t1[key] ~= t2[key] then
                return false
            end
        end
    end

    return true

end

-- copies a table with all values copied directly
M.CopyTableShallow = function(t)

	local tCopy = {}

	for key,value in pairs(t) do
		tCopy[key] = value
    end

	return tCopy

end

-- should work with anything, except maybe tables as keys
M.CopyTable = function(t , copiedTables)

	-- this will be returned as the copied table
	local tCopy = {}
	-- helps with tables that reference other tables
	-- that reference the fist table, etc
	-- key = old table that has been copied
	-- value new table
	if not copiedTables then copiedTables = {} end
	copiedTables[t] = tCopy

	for key,value in pairs(t) do
        if type(value) == "table" then
			if copiedTables[value] then
				tCopy[key] = copiedTables[value]
			else
				tCopy[key] = CopyTable(value , copiedTables)
			end
        else
            tCopy[key] = value
        end
    end

	return tCopy

end


-- these are tabs, such as 4 spaces
local tabPhrase = "    "

-- simulates a tab thing for type info
local typeStringTabLength = 8

-- prints a table, in full
-- should be called using PrintTable(tableToCall)
-- depth and tableList are used internally
	-- depth helps with tabs.
	-- tableList is a list that contains all of the tables that
	-- have already been printed, so that it doesn't
	-- form an infinite loop of printing tables.
M.PrintTable = function(t , depth , tableList)

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
		tab = tab..tabPhrase
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
			string.rep(" " , typeStringTabLength - string.len(type))
		if type == "table" then
			print(tab.."TABLE: "..key)
			if tableList[value] then
				print(tab.."(already printed)")
			else
				M.PrintTable(value , depth + 1 , tableList)
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

-- Similar to above, but only prints the keys on one line.
M.PrintTableKeys = function(t)

	local keysString = ""

	for key,value in pairs(t) do
		keysString = keysString..tostring(key).." , "
	end

	keysString = keysString:sub(1 , keysString:len() - 3)

	print(keysString)

end

M.Clamp = function(x , min , max)

	local returnValue = x

	if returnValue < min then returnValue = min end
	if returnValue > max then returnValue = max end

	return returnValue

end

-- Cubic Interpolation (Hermite)
-- Optimize this.
M.Cuberp = function(v0 , v1 , v2 , v3 , x)

	if v0 == nil then v0 = v1 end
	if v3 == nil then v3 = v2 end

	local a0 = -0.5*v0 + 1.5*v1 - 1.5*v2 + 0.5*v3
	local a1 = v0 - 2.5*v1 + 2*v2 - 0.5*v3
	local a2 = -0.5*v0 + 0.5*v2
	local a3 = v1

	return a0*x^3 + a1*x^2 + a2*x + a3

end



M.VectorCuberp = function(v0 , v1 , v2 , v3 , x)

	-- todo: make distances between points less wonky at the ends.
	if v0 == nil then v0 = v1 end
	if v3 == nil then v3 = v2 end

	return Vector(
		M.Cuberp(v0.x , v1.x , v2.x , v3.x , x) ,
		M.Cuberp(v0.y , v1.y , v2.y , v3.y , x) ,
		M.Cuberp(v0.z , v1.z , v2.z , v3.z , x)
	)


end

M.CastFromString = function(string , type)
	
	if type == "string" then
		return string
	elseif type == "number" then
		return tonumber(string)
	elseif type == "boolean" then
		string = string:lower()
		if string == "true" then
			return true
		elseif string == "false" then
			return false
		end
	end
	
	return nil
	
end

-- name Awesome Course Name # What an awesome Course name!
-- 				|
-- 				v
-- "name Awesome Course Name"
M.TrimCommentsFromLine = function(line)

	-- Holy balls, patterns are awesome.
	line = string.gsub(line , "%s*#.*" , "")
	
	-- *nix compatability.
	line = string.gsub(line, "\r", "")
	line = string.gsub(line, "\n", "")
	
	return line

end
