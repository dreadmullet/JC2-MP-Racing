
function Race:DebugUpdate()
	
	-- Only run if debugLevel is 1 or more.
	if debugLevel <= 0 then
		return
	end
	
	-- Check to see if the camera position is not where it should be.
	local camDist = Vector.Distance(Camera:GetPosition() , LocalPlayer:GetPosition())
	if camDist >= 50 then
		self.debug.camPosStreak = self.debug.camPosStreak + 1
		if self.debug.camPosStreak >= 60 then
			print("Warning: Camera:GetPosition() is returning whacky values. Blame Philpax.")
			print(camDist , "m")
			self.debug.camPosStreak = 0
		end
	else
		self.debug.camPosStreak = 0
	end
	
end


--
-- Network events.
--

function Race:DebugRacePosTracker(args)
	
	local racePosTracker = args[1]
	local playerIdToCheckpointDistanceSqr = args[2]
	
	print()
	print("racePosTracker = ")
	Utility.PrintTable(racePosTracker)
	print()
	print("playerIdToCheckpointDistanceSqr = ")
	Utility.PrintTable(playerIdToCheckpointDistanceSqr)
	print()
	
end
