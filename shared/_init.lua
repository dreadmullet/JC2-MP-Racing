
RaceModules = {}

sleep = function(seconds)
	local timer = Timer()
	while timer:GetSeconds() < seconds do
		coroutine.yield()
	end
end

-- Returns the index of the first value found, otherwise nil.
table.find = function(t , valueToFind)
	for index , value in ipairs(t) do
		if value == valueToFind then
			return index
		end
	end
	
	return nil
end

table.erase = function(t , valueToRemove)
	for index , value in ipairs(t) do
		if value == valueToRemove then
			table.remove(t , index)
			return true
		end
	end
	
	return false
end

table.sortrandom = function(t)
	local randomIndex
	for index = #t , 2 , -1 do
		randomIndex = math.random(index)
		t[index] , t[randomIndex] = t[randomIndex] , t[index]
	end
end
