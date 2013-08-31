----------------------------------------------------------------------------------------------------
-- Race is waiting for people to type "/race" (or whatever) to join.
----------------------------------------------------------------------------------------------------

function StateAddPlayers:__init(race)
	
	self.race = race
	self.timer = Timer()
	
	local joinString = settings.command
	if not self.race.isPublic then
		joinString = joinString.." "..self.race.name
	end
	local cols = "enabled"
	if self.race.vehicleCollisions == false then
		cols = "disabled"
	end
	race:MessageServer(
		"A race is about to begin! ("..
		race.course.name..
		", collisions "..cols..") To join, type "..
		joinString
	)
	
	Utility.EventSubscribe(self , "PlayerChat")
	
end

function StateAddPlayers:Run()
	
	if self.race.numPlayers == 0 then
		self.timer:Restart()
	else
		if self.timer:GetSeconds() > settings.raceJoinWaitSeconds then
			self.race:MessageServer(
				"Time elapsed; starting race with "..
				self.race.numPlayers..
				" players."
			)
			self.race:SetState("StateStartingGrid")
		end
	end
	
end

function StateAddPlayers:End()
	
	Utility.EventUnsubscribeAll(self)
	
end

function StateAddPlayers:RacerJoin(racer)
	
	self.race:NetworkSendRace("SetPlayerCount" , self.race.numPlayers)
	
end


function StateAddPlayers:PlayerChat(args)
	
	-- If the race is public, it's not our hands; it's handled by the RaceManager.
	if self.race.isPublic then
		return
	end
	
	-- Split the message up into words (by spaces).
	local words = {}
	for word in string.gmatch(args.text , "[^%s]+") do
		table.insert(words , word)
	end
	
	if	words[1] == settings.command then
		if words[2] == nil and self.race:HasPlayer(args.player) then
			self.race:RemovePlayer(
				args.player ,
				"You have been removed from the next race."
			)
			
			return false
		elseif
			words[2] == self.race.name
		then
			self.race:JoinPlayer(args.player)
		end
		
		return false
	end
	
	-- It's up to other scripts to block /commands.
	return true
	
end
