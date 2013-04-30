
-- This class, on construction, will fancily draw large text near the center of the screen for a
-- specified duration.
LargeMessage.messageCount = 0
function LargeMessage:__init(message , durationSeconds)
	
	self.message = message
	self.durationSeconds = durationSeconds
	
	self.timer = Timer()
	
	self.renderEventSub = Events:Subscribe("Render" , self , self.Draw)
	
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
			math.clamp(durationRatio / Settings.largeMessageBlendRatio , 0 , 1)
		)
	elseif durationRatio >= 1 - Settings.largeMessageBlendRatio then
		alpha = math.lerp(
			255 ,
			0 ,
			math.clamp(
				(
					(durationRatio - (1 - Settings.largeMessageBlendRatio)) /
					Settings.largeMessageBlendRatio
				) ,
				0 ,
				1
			)
		)
	end
	
	local color = Copy(Settings.textColor)
	color.a = alpha
	
	DrawText(
		NormVector2(Settings.largeMessagePos.x , Settings.largeMessagePos.y) ,
		self.message ,
		color ,
		Settings.largeMessageTextSize ,
		"center"
	)
	
end

function LargeMessage:Destroy()
	
	LargeMessage.messageCount = LargeMessage.messageCount - 1
	Events:Unsubscribe(self.renderEventSub)
	
end
