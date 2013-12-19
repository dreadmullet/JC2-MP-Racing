
function Spectator:__init(race , player) ; RacerBase.__init(self , race , player)
	local args = {}
	args.version = settings.version
	args.checkpointPositions = self.race.checkpointPositions
	Network:Send(self.player , "SpectateInitialise" , args)
end

function Spectator:Remove()
	Network:Send(self.player , "SpectateTerminate")
end
