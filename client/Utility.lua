Utility = {}
local M = Utility

local tabPhrase = "    "

local typeStringTabLength = 8
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

