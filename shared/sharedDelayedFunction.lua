
class("DelayedFunction")
function DelayedFunction:__init(delay , func , firstArg)
	self.delay = delay
	self.func = func
	self.firstArg = firstArg
	self.timer = Timer()
	
	-- blargh
	if Server then
		self.event = Events:Subscribe("PreTick" , self , self.Update)
	else
		self.event = Events:Subscribe("PreTick" , self , self.Update)
	end
end

function DelayedFunction:Update()
	if self.timer:GetSeconds() >= self.delay then
		self.func(self.firstArg)
		self:Destroy()
	end
end

function DelayedFunction:Destroy()
	Events:Unsubscribe(self.event)
end
