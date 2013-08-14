
function StateAddPlayers:__init(race , args)
	
	self.race = race
	self.numPlayers = -1
	self.maxPlayers = args.maxPlayers
	
	Utility.NetSub(self , "SetPlayerCount")
	
end

function StateAddPlayers:Run()
	
	
	
end

function StateAddPlayers:End()
	
	Utility.EventUnsubscribeAll(self)
	Utility.NetUnsubscribeAll(self)
	
end

function StateAddPlayers:SetPlayerCount(numPlayers)
	
	self.numPlayers = numPlayers
	
	Chat:Print(
		string.format("%i/%i players" , self.numPlayers , self.maxPlayers) ,
		settings.textColor
	)
	
end
