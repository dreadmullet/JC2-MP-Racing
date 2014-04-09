
function EGUSM.SubscribeUtility:__init()
	-- Expose functions.
	
	self.EventSubscribe = EGUSM.SubscribeUtility.EventSubscribe
	self.NetworkSubscribe = EGUSM.SubscribeUtility.NetworkSubscribe
	self.NetSubscribe = self.NetworkSubscribe
	self.ConsoleSubscribe = EGUSM.SubscribeUtility.ConsoleSubscribe
	
	self.EventUnsubscribe = EGUSM.SubscribeUtility.EventUnsubscribe
	self.NetworkUnsubscribe = EGUSM.SubscribeUtility.NetworkUnsubscribe
	self.NetUnsubscribe = self.NetworkUnsubscribe
	self.ConsoleUnsubscribe = EGUSM.SubscribeUtility.ConsoleUnsubscribe
	
	self.EventUnsubscribeAll = EGUSM.SubscribeUtility.EventUnsubscribeAll
	self.NetworkUnsubscribeAll = EGUSM.SubscribeUtility.NetworkUnsubscribeAll
	self.NetUnsubscribeAll = self.NetworkUnsubscribeAll
	self.ConsoleUnsubscribeAll = EGUSM.SubscribeUtility.ConsoleUnsubscribeAll
	
	self.Destroy = EGUSM.SubscribeUtility.Destroy
	self.UnsubscribeAll = self.Destroy
	
	-- Each element is like {eventName , event}.
	self.subscribeUtilityEventSubs = {}
	self.subscribeUtilityNetSubs = {}
	self.subscribeUtilityConsoleSubs = {}
end

function EGUSM.SubscribeUtility:EventSubscribe(eventName , optionalFunction)
	local eventSub = Events:Subscribe(eventName , self , optionalFunction or self[eventName])
	table.insert(self.subscribeUtilityEventSubs , {eventName , eventSub})
end

function EGUSM.SubscribeUtility:NetworkSubscribe(netName , optionalFunction)
	local eventSub = Network:Subscribe(netName , self , optionalFunction or self[netName])
	table.insert(self.subscribeUtilityNetSubs , {netName , eventSub})
end

function EGUSM.SubscribeUtility:ConsoleSubscribe(name , optionalFunction)
	local eventSub = Console:Subscribe(name , self , optionalFunction or self[name])
	table.insert(self.subscribeUtilityConsoleSubs , {name , eventSub})
end

function EGUSM.SubscribeUtility:EventUnsubscribe(eventName)
	for n = #self.subscribeUtilityEventSubs , 1 , -1 do
		local pair = self.subscribeUtilityEventSubs[n]
		if pair[1] == eventName then
			Events:Unsubscribe(pair[2])
			table.remove(self.subscribeUtilityEventSubs , n)
		end
	end
end

function EGUSM.SubscribeUtility:NetworkUnsubscribe(netName)
	for n = #self.subscribeUtilityNetSubs , 1 , -1 do
		local pair = self.subscribeUtilityNetSubs[n]
		if pair[1] == netName then
			Network:Unsubscribe(pair[2])
			table.remove(self.subscribeUtilityNetSubs , n)
		end
	end
end

function EGUSM.SubscribeUtility:ConsoleUnsubscribe(name)
	for n = #self.subscribeUtilityConsoleSubs , 1 , -1 do
		local pair = self.subscribeUtilityConsoleSubs[n]
		if pair[1] == name then
			Console:Unsubscribe(pair[2])
			table.remove(self.subscribeUtilityConsoleSubs , n)
		end
	end
end

function EGUSM.SubscribeUtility:EventUnsubscribeAll()
	for index , pair in ipairs(self.subscribeUtilityEventSubs) do
		Events:Unsubscribe(pair[2])
	end
	self.subscribeUtilityEventSubs = {}
end

function EGUSM.SubscribeUtility:NetworkUnsubscribeAll()
	for index , pair in ipairs(self.subscribeUtilityNetSubs) do
		Network:Unsubscribe(pair[2])
	end
	self.subscribeUtilityNetSubs = {}
end

function EGUSM.SubscribeUtility:ConsoleUnsubscribeAll()
	for index , pair in ipairs(self.subscribeUtilityConsoleSubs) do
		Console:Unsubscribe(pair[2])
	end
	self.subscribeUtilityConsoleSubs = {}
end

function EGUSM.SubscribeUtility:Destroy()
	self:EventUnsubscribeAll()
	self:NetworkUnsubscribeAll()
	self:ConsoleUnsubscribeAll()
end
