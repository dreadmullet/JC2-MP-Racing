----------------------------------------------------------------------------------------------------
-- Both Racer and Spectator inherit from this.
----------------------------------------------------------------------------------------------------
class("RacerBase")

function RacerBase:__init(race , player)
	self.Update = RacerBase.Update
	
	self.race = race
	self.player = player
	self.playerId = player:GetId()
	self.name = player:GetName()
	self.steamId = player:GetSteamId().id
end

function RacerBase:Update(racePosInfo)
	Network:Send(self.player , "UpdateRacePositions" , racePosInfo)
end
