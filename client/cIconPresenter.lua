class("IconPresenter")

function IconPresenter:__init(icons , totalTime , initialwaitTime)
	EGUSM.SubscribeUtility.__init(self)
	
	self.icons = icons
	self.timePerIcon = totalTime / #self.icons
	self.initialwaitTime = initialwaitTime
	self.coroutine = coroutine.create(self.Proc)
	
	for index , icon in ipairs(self.icons) do
		icon:SetVisible(false)
	end
	
	self:EventSubscribe("Render")
end

-- Coroutine functions

function IconPresenter:Proc()
	local intervalDelay = 0.1
	
	if self.initialwaitTime then
		coroutine.sleep(self.initialwaitTime)
	end
	
	for index , icon in ipairs(self.icons) do
		self:PresentIcon(index , self.timePerIcon - intervalDelay)
		coroutine.sleep(intervalDelay)
	end
end

function IconPresenter:PresentIcon(index , time)
	local icon = self.icons[index]
	icon:SetVisible(true)
	
	local startSize = 0.16
	local endSize = 0.08
	local startPosition = Vector2(0 , -0.1)
	local endPosition = Vector2(0.925 - (index - 1) * endSize * 1.8 , -0.8)
	local waitTime = time * 0.75
	local moveTime = time - waitTime
	
	-- Large and centered
	icon:SetUseRelative(true)
	icon:SetIsCentered(true)
	icon:SetPosition(startPosition)
	icon:SetSize(startSize)
	
	coroutine.sleep(waitTime)
	
	-- Moving and shrinking
	local timer = Timer()
	while timer:GetSeconds() < moveTime do
		local x = timer:GetSeconds() / moveTime
		x = math.pow(x , 0.75)
		icon:SetPosition(math.lerp(startPosition , endPosition , x))
		icon:SetSize(math.lerp(startSize , endSize , x))
		
		coroutine.yield()
	end
	
	-- End position and size.
	icon:SetPosition(endPosition)
	icon:SetSize(endSize)
	icon:SetText(nil)
end

-- Events

function IconPresenter:Render()
	local result , errorMessage = coroutine.resume(self.coroutine , self)
	if errorMessage then
		error(errorMessage)
	end
	
	if coroutine.status(self.coroutine) == "dead" then
		self:EventUnsubscribe("Render")
	end
end
