Utility = {}
local M = Utility

math.tau = math.pi * 2

M.NumberToPlaceString = function(number)
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

M.LapTimeString = function(totalSeconds)
	if totalSeconds == nil then
		return "N/A"
	end
	
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
	
	return string.format("%.2i:%.2i.%.2i" , minutes , seconds , hundredths)
end

M.EventSubscribe = function(instance , functionName , optionalName)
	local sub = Events:Subscribe(functionName , instance , instance[optionalName or functionName])
	if instance.eventSubs == nil then
		instance.eventSubs = {}
	end
	table.insert(instance.eventSubs , sub)
	
	return sub
end

M.NetSubscribe = function(instance , functionName , optionalName)
	local sub = Network:Subscribe(functionName , instance , instance[optionalName or functionName])
	if instance.netSubs == nil then
		instance.netSubs = {}
	end
	table.insert(instance.netSubs , sub)
	
	return sub
end

M.EventUnsubscribeAll = function(instance)
	if instance.eventSubs then
		for index , sub in ipairs(instance.eventSubs) do
			if IsValid(sub) then
				Events:Unsubscribe(sub)
			end
		end
	end
end

M.NetUnsubscribeAll = function(instance)
	if instance.netSubs then
		for index , sub in ipairs(instance.netSubs) do
			if IsValid(sub) then
				Network:Unsubscribe(sub)
			end
		end
	end
end
