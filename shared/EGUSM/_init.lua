
EGUSM = {}

EGUSMClass = function(name)
	class(name)
	EGUSM[name] = _G[name]
	_G[name] = nil
end

EGUSMClass("SubscribeUtility")
	EGUSMClass("StateMachine")
		EGUSMClass("PlayerManager")
