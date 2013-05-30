
settingsCE.debugLevel = 2

local debugLevel = settingsCE.debugLevel

function CourseEditor:__init()
	
	if debugLevel >= 2 then
		print("CourseEditor:__init")
	end
	
	CourseEditor.instance = self
	
	-- Commands table, defined in cCourseEditorCommands.lua.
	self.commands = {}
	self:DefineCommands()
	
	self.course = Course()
	
	self.currentTool = nil
	self.currentToolName = ""
	
	self.mainMenu = CEMainMenu(self)
	
	self.events = {}
	self.networkEvents = {}
	
	local EventSub = function(name , funcName)
		table.insert(
			self.events ,
			Events:Subscribe(name , self , self[funcName])
		)
	end
	local NetworkSub = function(name , funcName)
		table.insert(
			self.networkEvents ,
			Network:Subscribe(name , self , self[funcName])
		)
	end
	
	EventSub("LocalPlayerChat" , "LocalPlayerChat")
	
	NetworkSub("CEDestroyCourseEditor" , "Destroy")
	NetworkSub("CEReplaceCourse" , "ReplaceCourse")
	NetworkSub("CESetCourseInfo" , "SetCourseInfo")
	NetworkSub("CEAddCP" , "AddCP")
	NetworkSub("CERemoveCP" , "RemoveCP")
	NetworkSub("CEAddSpawn" , "AddSpawn")
	NetworkSub("CERemoveSpawn" , "RemoveSpawn")
	
end

function CourseEditor:Destroy()
	
	if debugLevel >= 2 then
		print("CourseEditor:Destroy()")
	end
	
	CourseEditor.instance = nil
	
	self:SetTool("None")
	
	self.course:Destroy()
	
	self.mainMenu:Destroy()
	
	-- Unsubscribe from all events.
	for n , event in ipairs(self.events) do
		Events:Unsubscribe(event)
	end
	-- Unsubscribe from all network events.
	for n , networkEvent in ipairs(self.networkEvents) do
		Network:Unsubscribe(networkEvent)
	end
	
end

function CourseEditor:SetTool(toolClassName)
	
	if debugLevel >= 2 then
		print("Tool changed to " , toolClassName)
	end
	
	-- Call Destroy() on the base class, Tool. Also call Destroy on inherited class, if it exists.
	-- Not sure if this is the best way to do it, but oh well.
	if self.currentTool then
		if self.currentTool.Destroy then
			self.currentTool:Destroy()
		end
		Tool.Destroy(self.currentTool)
		self.currentTool = nil
	end
	
	-- Create the tool if it exists.
	if _G[toolClassName] then
		self.currentTool = _G[toolClassName]()
		self.currentToolName = toolClassName
	end
	
end

--
-- Events
--

function CourseEditor:LocalPlayerChat(args)
	
	-- Course editor commands.
	local msg = args.text
	
	-- We only want /ce commands.
	if msg:sub(1 , 4) ~= settingsCE.commandNameShort.." " then
		return true
	end
	
	msg = msg:sub(5)
	
	-- Split the message up into words (by spaces) and add them to args.
	for word in string.gmatch(msg, "[^%s]+") do
		table.insert(args , word)
	end
	
	local functionName = args[1]
	if not functionName then
		return true
	end
	
	table.remove(args , 1)
	
	-- Convert to lowercase.
	functionName = functionName:lower()
	
	local func = self.commands[functionName]
	
	-- Make sure command exists.
	if not func then
		return true
	end
	
	func(args)
	
	return false
	
end

--
-- Network
--

function CourseEditor:ReplaceCourse(courseInfo)
	
	self.course:Destroy()
	
	self.course = Course.Demarshal(courseInfo)
	
end

function CourseEditor:SetCourseInfo(courseInfo)
	
	self.course.name = courseInfo.name
	self.course.type = courseInfo.type
	self.course.numLaps = courseInfo.numLaps
	self.course.timeLimitSeconds = courseInfo.timeLimitSeconds
	self.course.prizeMoney = courseInfo.prizeMoney
	
end

function CourseEditor:AddCP(checkpointInfo)
	
	local checkpoint = CourseCheckpoint.Demarshal(self.course , checkpointInfo)
	
	table.insert(self.course.checkpoints , checkpoint)
	
end

function CourseEditor:RemoveCP(editorId)
	
	local didRemove = false
	
	for index , checkpoint in ipairs(self.course.checkpoints) do
		if checkpoint.courseEditorId == editorId then
			checkpoint:Destroy()
			table.remove(self.course.checkpoints , index)
			didRemove = true
			break
		end
	end
	
	if didRemove == false then
		Client:ChatMessage("DIDN'T REMOVE WTFM8: id = "..editorId , Color(255 , 255 , 255))
	end
	
end

function CourseEditor:AddSpawn(spawnInfo)
	
	local spawn = CourseSpawn.Demarshal(self.course , spawnInfo)
	
	table.insert(self.course.spawns , spawn)
	
end

function CourseEditor:RemoveSpawn(editorId)
	
	local didRemove = false
	
	for index , spawn in ipairs(self.course.spawns) do
		if spawn.courseEditorId == editorId then
			spawn:Destroy()
			table.remove(self.course.spawns , index)
			didRemove = true
			break
		end
	end
	
	if didRemove == false then
		Client:ChatMessage("DIDN'T REMOVE WTFM8: id = "..editorId , Color(255 , 255 , 255))
	end
	
end

--
-- Global subscriptions
--

Network:Subscribe("CreateCourseEditor" , function() CourseEditor() end)
