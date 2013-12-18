function RaceManagerBase:__init() ; EGUSM.PlayerManager.__init(self)
	-- Expose functions.
	self.Message = RaceManagerBase.Message
	
end

function RaceManagerBase:Message(message)
	Chat:Broadcast("[Racing] "..message , settings.textColor)
	print(message)
end
