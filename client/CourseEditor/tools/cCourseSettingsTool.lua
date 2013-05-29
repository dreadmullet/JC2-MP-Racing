
function CourseSettings:__init()
	
	Tool.__init(self)
	
	self.course = nil
	
end

function CourseSettings:CreateWindowElements(toolWindow)
	
	local spacingY = settingsCE.gui.toolWindow.elementHeight / 0.75
	local currentY = 0
	local leftX = 0
	local rightX = 1 - settingsCE.gui.toolWindow.elementWidth
	
	self.numLapsEditBox = Editbox.Create("GWEN/Editbox" , "EditBox"..PhilpaxSucks , toolWindow)
	PhilpaxSucks = PhilpaxSucks + 1
	self.numLapsEditBox:SetText(tostring(self.course.numLaps))
	self.numLapsEditBox:SetPositionRel(Vector2(leftX , currentY))
	self.numLapsEditBox:SetSizeRel(
		Vector2(settingsCE.gui.toolWindow.elementWidth , settingsCE.gui.toolWindow.elementHeight)
	)
	self.numLapsEditBox:Subscribe("TextChanged" , self , self.NumLapsChanged)
	
	self.numLapsLabel = Window.Create(
		"GWEN/StaticText" ,
		"NumLapsLabel"..PhilpaxSucks ,
		toolWindow
	)
	PhilpaxSucks = PhilpaxSucks + 1
	self.numLapsLabel:SetText("Laps")
	self.numLapsLabel:SetPositionRel(Vector2(rightX , currentY))
	currentY = currentY + spacingY
	self.numLapsLabel:SetSizeRel(
		Vector2(settingsCE.gui.toolWindow.elementWidth , settingsCE.gui.toolWindow.elementHeight)
	)
	
	currentY = currentY + spacingY
	
end

function CourseSettings:NumLapsChanged(args)
	
	local text = args.window:GetText()
	if GetIsValidLapsString(text) then
		self.numLapsLabel:SetText(Color(0 , 255 , 0):ToCEGUIString().."Laps")
		self.course.numLaps = tonumber(text)
	else
		self.numLapsLabel:SetText(Color(255 , 0 , 0):ToCEGUIString().."Laps")
	end
	
end


GetIsValidLapsString = function(text)
	
	local number = tonumber(text)
	
	if number ~= nil and number > 0 then
		return true
	end
	
	return false
	
end
