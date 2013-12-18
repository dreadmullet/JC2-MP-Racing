
if false then
	NetworkDebug = {}
	
	if Server then
		NetworkDebug.Send = function(network , player , name , argument)
			print("[Network] "..name.." sent to "..tostring(player))
			Network:_Send(player , name , argument)
		end
	else
		NetworkDebug.Send = function(network , name , argument)
			print("[Network] "..name.." sent")
			Network:_Send(name , argument)
		end	
	end
	
	NetworkDebug.Broadcast = function(network , name , argument)
		print("[Network] "..name.." broadcast")
		Network:_Broadcast(player , name , argument)
	end
	
	Network._Send = Network.Send
	Network.Send = NetworkDebug.Send
	Network._Broadcast = Network.Broadcast
	Network.Broadcast = NetworkDebug.Broadcast
end
