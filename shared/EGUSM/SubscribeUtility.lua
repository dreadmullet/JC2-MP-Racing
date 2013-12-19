
function EGUSM.SubscribeUtility:__init()
	-- Expose functions.
	self.EventSubscribe = EGUSM.SubscribeUtility.EventSubscribe
	self.NetworkSubscribe = EGUSM.SubscribeUtility.NetworkSubscribe
	self.EventUnsubscribe = EGUSM.SubscribeUtility.EventUnsubscribe
	self.NetworkUnsubscribe = EGUSM.SubscribeUtility.NetworkUnsubscribe
	self.EventUnsubscribeAll = EGUSM.SubscribeUtility.EventUnsubscribeAll
	self.NetworkUnsubscribeAll = EGUSM.SubscribeUtility.NetworkUnsubscribeAll
	self.Destroy = EGUSM.SubscribeUtility.Destroy
	
	-- Each element is like {eventName , event}.
	self.subscribeUtilityEventSubs = {}
	self.subscribeUtilityNetSubs = {}
end

function EGUSM.SubscribeUtility:EventSubscribe(eventName , optionalFunction)
	local eventSub = Events:Subscribe(eventName , self , optionalFunction or self[eventName])
	table.insert(self.subscribeUtilityEventSubs , {eventName , eventSub})
	return eventSub
end

function EGUSM.SubscribeUtility:NetworkSubscribe(netName , optionalFunction)
	local eventSub = Network:Subscribe(netName , self , optionalFunction or self[netName])
	table.insert(self.subscribeUtilityNetSubs , {netName , eventSub})
	return eventSub
end

function EGUSM.SubscribeUtility:EventUnsubscribe(eventName)
	for index , pair in ipairs(self.subscribeUtilityEventSubs) do
		if pair[1] == eventName then
			Events:Unsubscribe(pair[2])
            self.subscribeUtilityEventSubs[index] = nil
			break
		end
	end
end

function EGUSM.SubscribeUtility:NetworkUnsubscribe(netName)
	for index , pair in ipairs(self.subscribeUtilityNetSubs) do
		if pair[1] == netName then
			Network:Unsubscribe(pair[2])
            self.subscribeUtilityNetSubs[index] = nil
			break
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

function EGUSM.SubscribeUtility:Destroy()
	self:EventUnsubscribeAll()
	self:NetworkUnsubscribeAll()
end
