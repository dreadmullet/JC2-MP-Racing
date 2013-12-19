
function RacerBase:__init(race , player , index)
	self.Update = RacerBase.Update
	
	self.race = race
	self.player = player
	-- This helps with calling Racer:Update only one player per tick.
	self.updateOffset = index
	self.playerId = player:GetId()
	self.name = player:GetName()
	self.steamId = player:GetSteamId().id
end

function RacerBase:Update()
	-- TODO: the actual fuck
	local finishedPlayerIds = {}
	for index , racer in ipairs(self.race.finishedRacers) do
		table.insert(finishedPlayerIds , racer.playerId)
	end
	
	Network:Send(
		self.player ,
		"UpdateRacePositions" ,
		{
			self.race.state.racePosTracker ,
			self.race.state.currentCheckpoint ,
			finishedPlayerIds
		}
	)
end
