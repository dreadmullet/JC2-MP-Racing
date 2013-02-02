
local C = {}


C.printcps = function(args)
	
	for cp in Server:GetCheckpoints() do
		print()
		print("CHECKPOINT")
		print("position " , cp:GetPosition())
	end
	
end






-- Lua less than three.
RaceEditorChat = function(args)
	
	local player = args.player
    local msg = args.text

	-- We only want /commands.
	if msg:sub(1 , 1) ~= "/" or msg:len() == 1 then
		return true
	end
	
	msg = msg:sub(2)
	
	-- Split the message up into words (by spaces) and add them to args.
    for word in string.gmatch(msg, "[^%s]+") do
        table.insert(args , word)
    end
	
	local functionName = args[1]
	
	-- Make sure functionName exists
	if functionName == nil then
		return
	end
	
	table.remove(args , 1)
	
	-- Convert to lowercase.
	functionName = functionName:lower()
	
	-- Make sure command exists and is a function.
	if not C[functionName] or type(C[functionName]) ~= "function" then
		return false
	end
	
	C[functionName](args)
	
	return false
	
end

Events:Subscribe("PlayerChat" , RaceEditorChat)
