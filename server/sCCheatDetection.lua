






class("CCheatDetection")
function CCheatDetection:__init(player , updateTick)
	
	-- if debugLevel >= 3 then
		-- print("[Racing Cheat Detection] CCheatDetection created for " , player:GetName() , ".")
	-- end
	
	self.player = player
	self.prevPosition = player:GetPosition()
	self.timer = Timer()
	self.maxSpeed = 500 / 3.6
	
	self.numDetections = 0
	self.maxDetections = 3
	
	-- Helps with making sure only one player is detected of cheats per tick.
	self.updateTick = updateTick
	
end

function CCheatDetection:Update()
	
	-- if debugLevel >= 3 then
		-- print("[Racing Cheat Detection] CCheatDetection updated for " , self.player:GetName() , ".")
	-- end
	
	local speed = (
		Vector.Distance(self.prevPosition , self.player:GetPosition()) /
		self.timer:GetSeconds()
	)
	
	-- print("[Racing Cheat Detection] " , self.player:GetName() , "'s speed is " , speed)
	
	if speed >= self.maxSpeed then
		self.numDetections = self.numDetections + 1
		print(
				"[Racing Cheat Detection] " ,
				self.player:GetName() ,
				" was detected. Speed: " ,
				speed * 3.6 ,
				" km/h."
			)
		if self.numDetections >= self.maxDetections then
			-- Silent kick? Probably for the best.
			RemovePlayer(self.player)
			print(
				"[Racing Cheat Detection] " ,
				self.player:GetName() ,
				" has been removed after " ,
				self.maxDetections ,
				" violations."
			)
		end
	end
	
	
	self.timer:Restart()
	self.prevPosition = self.player:GetPosition()
	
end







