
function EGUSM.StateMachine:__init(stateName) ; EGUSM.SubscribeUtility.__init(self)
	-- Expose functions.
	self.SetState = EGUSM.StateMachine.SetState
	self.Destroy = EGUSM.StateMachine.Destroy
	
	self.stateName = ""
	self.state = nil
	
	if stateName then
		self:SetState(stateName)
	end
end

function EGUSM.StateMachine:Destroy()
	self:SetState(nil)
	EGUSM.SubscribeUtility.Destroy(self)
end

function EGUSM.StateMachine:SetState(stateName , ...)
	-- Debug printing.
	if EGUSM.debug then
		EGUSM.Print("Setting state to "..(stateName or "nil"))
	end
	-- Remove current state.
	if self.state and self.state.End then
		self.state:End()
	end
	-- Create new state.
	if stateName then
		local stateConstructor = _G[stateName]
		self.state = stateConstructor(self , ...)
	end
end
