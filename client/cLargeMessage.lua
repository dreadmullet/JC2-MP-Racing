
-- This class, on construction, will fancily draw large text near the center of the screen for a
-- specified duration.
LargeMessage.messageCount = 0
function LargeMessage:__init(message , durationSeconds) ; EGUSM.SubscribeUtility.__init(self)
	-- Fix for SubscribeUtility.Destroy.
	self.Destroy = LargeMessage.Destroy
	
	self.message = message
	self.durationSeconds = durationSeconds
	
	self.timer = Timer()
	self.exists = true
	
	self:EventSubscribe("Render")
	
	LargeMessage.messageCount = LargeMessage.messageCount + 1
end

function LargeMessage:Draw()
	local timerSeconds = self.timer:GetSeconds()
	
	-- Forget about us if there is more than one message showing.
	if LargeMessage.messageCount >= 2 then
		self:Destroy()
		return
	end
	
	-- Forget about us if our time is up.
	if timerSeconds >= self.durationSeconds then
		self:Destroy()
		return
	end
	
	local durationRatio = timerSeconds / self.durationSeconds
	
	local alpha = 255
	if durationRatio <= 0.1 then
		alpha = math.lerp(
			0 ,
			255 ,
			math.clamp(durationRatio / settings.largeMessageBlendRatio , 0 , 1)
		)
	elseif durationRatio >= 1 - settings.largeMessageBlendRatio then
		alpha = math.lerp(
			255 ,
			0 ,
			math.clamp(
				(
					(durationRatio - (1 - settings.largeMessageBlendRatio)) /
					settings.largeMessageBlendRatio
				) ,
				0 ,
				1
			)
		)
	end
	
	local color = Copy(settings.textColor)
	color.a = alpha
	
	DrawText(
		NormVector2(settings.largeMessagePos.x , settings.largeMessagePos.y) ,
		self.message ,
		color ,
		settings.largeMessageTextSize ,
		"center"
	)
end

function LargeMessage:Destroy()
	if self.exists then
		LargeMessage.messageCount = LargeMessage.messageCount - 1
		EGUSM.SubscribeUtility.Destroy(self)
		self.exists = false
	end
end

function LargeMessage:Render()
	if Game:GetState() == GUIState.Game then
		self:Draw()
	end
end
