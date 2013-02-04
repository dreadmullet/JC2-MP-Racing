
--
-- Utility GUI functions.
--

NormX = function(x)
	
	return (x * 0.5 + 0.5) * Render.Width
	
end

NormY = function(y)
	
	return (y * 0.5 + 0.5) * Render.Height
	
end

-- Normalized coords to pixels. From -1 to 1.
NormVector2 = function(x , y)
	
	return Vector2(
		(x * 0.5 + 0.5) * Render.Width ,
		(y * 0.5 + 0.5) * Render.Height
	)
	
end

-- Draws shadowed, aligned text.
DrawText = function(pos , text , color , size , alignment , scale)
	
	if not text then
		print("Warning: trying to draw nil text! This should never happen!")
		print("pos = " , pos , ", color = " , color , ", size = " , size)
		text = "***ERROR***"
	end
	
	if not alignment then alignment = "left" end
	
	if alignment == "center" then
		pos = pos + Vector2(
			Render:GetTextWidth(text , size) * -0.5 ,
			Render:GetTextHeight(text , size) * -0.5
		)
	else -- "left"
		-- pos = pos + Vector2(
			-- 0 ,
			-- Render:GetTextHeight(text , size) * -0.5
		-- )
	end
	
	local shadowColor = Copy(Settings.shadowColor)
	shadowColor.a = color.a
	
	Render:DrawText(pos + Vector2(-1 , -1) , text , shadowColor , size , scale or 1)
	Render:DrawText(pos , text , color , size , scale or 1)
	
end

--
-- Drawing methods.
--

-- Draw version at the top right.
function Race:DrawVersion()
	
	local textSize = Vector2(
		Render:GetTextWidth(version , "Default") ,
		Render:GetTextHeight(version , "Default")
	)
	
	DrawText(
		Vector2(0.825 * Render.Width - textSize.x , textSize.y * 0 + 1) ,
		"JC2-MP-Racing "..version ,
		Settings.textColor ,
		"Default"
	)
	
end

function Race:ShowLargeMessage(args)
	
	LargeMessage(args[1] or "nil" , args[2] or 1.5)
	
end

-- This class, on construction, will fancily draw large text near the center of the screen for a
-- specified duration.
class("LargeMessage")
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





