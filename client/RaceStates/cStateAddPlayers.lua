
function StateAddPlayers:__init(race , args)
	
	self.race = race
	self.numPlayers = -1
	self.maxPlayers = args.maxPlayers
	
	Utility.NetSubscribe(self , "SetPlayerCount")
	
end

function StateAddPlayers:Run()
	
	if Game:GetState() == GUIState.Game then
		-- DrawPlayerCount
		local args = {}
		args.numPlayers = self.numPlayers
		args.maxPlayers = self.maxPlayers
		RaceGUI.DrawPlayerCount(args)
	end
	
end

function StateAddPlayers:End()
	
	Utility.EventUnsubscribeAll(self)
	Utility.NetUnsubscribeAll(self)
	
end

function StateAddPlayers:SetPlayerCount(numPlayers)
	
	self.numPlayers = numPlayers
	
end
