
function EGUSM.PlayerManager:__init() ; EGUSM.StateMachine.__init(self)
	-- Expose functions.
	self.AddPlayer = EGUSM.PlayerManager.AddPlayer
	self.RemovePlayer = EGUSM.PlayerManager.RemovePlayer
	self.HasPlayer = EGUSM.PlayerManager.HasPlayer
	self.GetPlayerCount = EGUSM.PlayerManager.GetPlayerCount
	self.IteratePlayers = EGUSM.PlayerManager.IteratePlayers
	self.Destroy = EGUSM.PlayerManager.Destroy
	
	-- Key: Player id
	-- Value: true
	self.playerManagerPlayers = {}
	self.playerManagerPlayerCount = 0
	self.playerManagerIsRunning = true
	
	self:EventSubscribe("PlayerQuit" , EGUSM.PlayerManager.PlayerQuit)
	self:EventSubscribe("ModuleUnload" , EGUSM.PlayerManager.ModuleUnload)
end

function EGUSM.PlayerManager:AddPlayer(player)
	-- Return out if the player is already part of us.
	if self.playerManagerPlayers[player:GetId()] then
		return
	end
	
	self.playerManagerPlayers[player:GetId()] = true
	self.playerManagerPlayerCount = self.playerManagerPlayerCount + 1
	
	if self.ManagedPlayerJoin then
		self:ManagedPlayerJoin(player)
	end
end

function EGUSM.PlayerManager:RemovePlayer(player)
	-- Return out if the player is not part of us.
	if self.playerManagerPlayers[player:GetId()] == nil then
		return
	end
	
	self.playerManagerPlayers[player:GetId()] = nil
	self.playerManagerPlayerCount = self.playerManagerPlayerCount - 1
	
	if self.ManagedPlayerLeave then
		self:ManagedPlayerLeave(player)
	end
end

function EGUSM.PlayerManager:HasPlayer(player)
	return self.playerManagerPlayers[player:GetId()] ~= nil
end

function EGUSM.PlayerManager:GetPlayerCount()
	return self.playerManagerPlayerCount
end

function EGUSM.PlayerManager:IteratePlayers(func)
	for playerId , alwaysTrue in pairs(self.playerManagerPlayers) do
		func(Player.GetById(playerId))
	end
end

function EGUSM.PlayerManager:Destroy()
	-- Return out if we've already terminated.
	if self.playerManagerIsRunning == false then
		return
	end
	self.playerManagerIsRunning = false
	
	if self.PlayerManagerTerminate then
		self:PlayerManagerTerminate()
	end
	
	for playerId , alwaysTrue in pairs(self.playerManagerPlayers) do
		self:RemovePlayer(Player.GetById(playerId))
	end
	
	EGUSM.StateMachine.Destroy(self)
end

-- Events

function EGUSM.PlayerManager:PlayerQuit(args)
	self:RemovePlayer(args.player)
end

function EGUSM.PlayerManager:ModuleUnload(args)
	self:Destroy()
end
