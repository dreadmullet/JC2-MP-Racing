Events:Subscribe("TestMap" , function(args)
	if args.mapType ~= "Racing" then
		return
	end
	
	local map = MapEditor.LoadFromMarshalledMap(args.marshalledMap)
	
	RaceManagerEvent.CreateRaceFromEvent{
		players = args.players ,
		map = map ,
		quickStart = true ,
	}
end)
