
class("DelayedFunction")
function DelayedFunction:__init(func , delay , ...)
	self.func = func
	self.delay = delay
	self.args = table.pack(...)
	
	self.timer = Timer()
	self.event = Events:Subscribe("PreTick" , self , self.Update)
end

function DelayedFunction:Update()
	if self.timer:GetSeconds() >= self.delay then
		self.func(table.unpack(self.args))
		self:Destroy()
	end
end

function DelayedFunction:Destroy()
	Events:Unsubscribe(self.event)
end
