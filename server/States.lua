----------------------------------------------------------------------------------------------------
-- States
----------------------------------------------------------------------------------------------------

SetState = function(stateName)
	
	if debugLevel >= 2 then
		print("State changed to "..stateName)
	end
	
	state = _G[stateName]()
	
end

-- Returns string name of current state.
GetState = function()
	
	return state.__type
	
end




