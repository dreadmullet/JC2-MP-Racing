
RaceModules = {}

sleep = function(seconds)
	local timer = Timer()
	while timer:GetSeconds() < seconds do
		coroutine.yield()
	end
end
