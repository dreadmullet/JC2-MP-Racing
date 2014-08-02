----------------------------------------------------------------------------------------------------
-- Both Racer and Spectator inherit from this.
----------------------------------------------------------------------------------------------------
class("RacerBase")

function RacerBase:__init(race , player)
	self.Update = RacerBase.Update
	self.Remove = RacerBase.Remove
	
	self.race = race
	self.player = player
	self.playerId = player:GetId()
	self.name = player:GetName()
	self.steamId = player:GetSteamId().id
	
	-- Disable collisions, if applicable.
	if self.race.vehicleCollisions then
		self.player:EnableCollision(CollisionGroup.Vehicle)
	else
		self.player:DisableCollision(CollisionGroup.Vehicle)
	end
	-- Always disable player collisions.
	self.player:DisableCollision(CollisionGroup.Player)
	
	-- Initialize map editor client-side things for our player.
	self.race.mapInstance:AddPlayer(self.player)
end

function RacerBase:Update(racePosInfo)
	Network:Send(self.player , "UpdateRacePositions" , racePosInfo)
end

function RacerBase:Remove()
	-- Reenable collisions, if applicable.
	if self.race.vehicleCollisions then
		self.player:DisableCollision(CollisionGroup.Vehicle)
	else
		self.player:EnableCollision(CollisionGroup.Vehicle)
	end
	self.player:EnableCollision(CollisionGroup.Player)
	
	-- Clean up map editor client-side things for our player.
	self.race.mapInstance:RemovePlayer(self.player)
	
	self.player:SetWorld(DefaultWorld)
end
