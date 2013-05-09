----------------------------------------------------------------------------------------------------
-- Represents a single editor instance, which contains a course and players (usually one).
----------------------------------------------------------------------------------------------------

settingsCE.baseWorldId = 200
settingsCE.characterModelId = 89
-- Prevents players from spamming checkpoints etc. More settings are defined in 
-- shared/sharedCourseEditor.lua.
settingsCE.actionRateSeconds = 0.5

-- key: World id
-- value: Instance of CourseEditor
CourseEditor.courseEditors = {}
-- Course editor instances have their stuff going on in their own world, and it is assigned to this
-- world id on creation, and the counter is incremented.
CourseEditor.worldCounter = settingsCE.baseWorldId


function CourseEditor:__init(name)
	
	print("CourseEditor created: "..name)
	
	self.name = name
	
	self.worldId = CourseEditor.worldCounter
	CourseEditor.worldCounter = CourseEditor.worldCounter + 1
	
	-- Add ourselves to table containing all other CourseEditors
	CourseEditor.courseEditors[self.worldId] = self
	
	-- Key: Player id
	-- Value: Player info table
	self.players = {}
	-- Commands table, defined in sCourseEditorCommands.lua.
	self.commands = {}
	self:DefineCommands()
	
	self.course = Course()
	self.idCounter = 1
	
	self.numTicks = 0
	-- Controls how often some functions in Update are ran.
	self.auxUpdateTick = self.worldId - settingsCE.baseWorldId
	
	self.events = {}
	local EventSub = function(name)
		table.insert(
			self.events ,
			Events:Subscribe(name , self , self[name])
		)
	end
	EventSub("PostServerTick")
	EventSub("PlayerQuit")
	EventSub("PlayerChat")
	EventSub("ModuleUnload")
	
	self.networkEvents = {}
	self:SubscribeNetworkEvents()
	
	self:CleanWorld()
	
end

function CourseEditor:HasPlayer(player)
	
	return self.players[player:GetId()] ~= nil
	
end

function CourseEditor:AddPlayer(player)
	
	-- Make sure this player is in the default world.
	if player:GetWorldId() ~= -1 then
		return
	end
	
	-- Make sure this player is not in our editor already.
	if self.players[player:GetId()] then
		return
	end
	
	local playerInfo = {}
	-- Store their old weapons, and clear their weapons.
	playerInfo.previousWeapons = player:GetInventory()
	player:ClearInventory()
	playerInfo.originalPosition = player:GetPosition()
	
	playerInfo.previousModel = player:GetModelId()
	
	-- Player info table is empty for now.
	self.players[player:GetId()] = playerInfo
	
	player:SetWorldId(self.worldId)
	
	-- Set their model.
	player:SetModelId(settingsCE.characterModelId)
	
	self:MessageEditor(player:GetName().." has joined the course editor.")
	
	-- Make the client instantiate a CourseEditor on their side.
	Network:Send(player , "CreateCourseEditor")
	-- Give the player our course.
	Network:Send(player , "ReplaceCourse" , self.course:Marshal())
	
end

-- Returns true if player was removed.
function CourseEditor:RemovePlayer(player , reason)
	
	reason = reason or "No reason."
	
	local playerInfo = self.players[player:GetId()]
	
	-- Make sure this player exists.
	if playerInfo == nil then
		return false
	end
	
	-- Reset their position.
	player:SetPosition(playerInfo.originalPosition)
	
	self.players[player:GetId()] = nil
	
	-- Put them back into the default world.
	player:SetWorldId(-1)
	
	-- Give them their old weapons back.
	for n , weaponId in pairs(playerInfo.previousWeapons) do
		player:GiveWeapon(n , weaponId)
	end
	-- Set their model to their previous model.
	player:SetModelId(playerInfo.previousModel)
	
	self:MessagePlayer(player , "You left the course editor. ("..reason..")")
	self:MessageEditor(
		player:GetName().." has left the course editor. ("..reason..")"
	)
	
	-- Make the client destroy their CourseEditor.
	Network:Send(player , "CEDestroyCourseEditor")
	
	return true
	
end

-- Checks to see if player left our world for some reason.
function CourseEditor:CheckPlayerWorlds()
	
	-- print("Checking player worlds! world = " , self.worldId)
	
	self:IteratePlayers(
		function(player)
			if player:GetWorldId() ~= self.worldId then
				self:RemovePlayer(player , "Incorrect world id.")
				return true
			end
		end
	)
	
end

function CourseEditor:MessagePlayer(player , message)
	
	player:SendChatMessage("[Course Editor] "..message , settingsCE.chatColorPlayer)
	
end

function CourseEditor:MessageEditor(message)
	
	self:IteratePlayers(
		function(player)
			player:SendChatMessage("[Course Editor] "..message , settingsCE.chatColorEditor)
		end
	)
	
	print("[Course Editor "..self.worldId.."] "..message)
	
end

-- Lua less than three.
function CourseEditor:IteratePlayers(func)
	
	for playerId , playerInfo in pairs(self.players) do
		func(Player.GetById(playerId))
	end
	
end

function CourseEditor:HasPlayer(player)
	
	return self.players[player:GetId()] ~= nil
	
end

-- Precaution if there were any errors before.
function CourseEditor:CleanWorld()
	
	for vehicle in Server:GetVehicles() do
		if vehicle:GetWorldId() == self.worldId then
			vehicle:Remove()
		end
	end
	
	for cp in Server:GetCheckpoints() do
		if cp:GetWorldId() == self.worldId then
			cp:Remove()
		end
	end
	
end

function CourseEditor:NetworkSend(name , args)
	
	self:IteratePlayers(
		function(player)
			Network:Send(player , name , args)
		end
	)
	
end

function CourseEditor:Destroy()
	
	print("Destroying course editor: "..self.name)
	
	-- Remove all players.
	self:IteratePlayers(
		function(player)
			self:RemovePlayer(player , "Destroying editor.")
		end
	)
	
	-- Unsubscribe from all events.
	for n , event in ipairs(self.events) do
		Events:Unsubscribe(event)
	end
	for n , networkEvent in ipairs(self.networkEvents) do
		Network:Unsubscribe(networkEvent)
	end
	
end

--
-- Editing functions
--

function CourseEditor:AddCP(position)
	
	-- local spawnArgs = {}
	-- spawnArgs.position = position
	-- spawnArgs.create_trigger = false
	-- spawnArgs.create_checkpoint = true
	-- spawnArgs.create_indicator = false
	-- spawnArgs.world = self.worldId
	-- spawnArgs.enabled = true
	-- local id = Checkpoint.Create(spawnArgs):GetId()
	
	-- Add to course.
	local checkpoint = CourseCheckpoint(self.course)
	checkpoint.position = position
	checkpoint.index = #self.course.checkpoints + 1
	checkpoint.courseEditorId = self.idCounter
	self.idCounter = self.idCounter + 1
	table.insert(self.course.checkpoints , checkpoint)
	
	-- Add to clients' course.
	self:NetworkSend("CEAddCP" , checkpoint:Marshal())
	
end

function CourseEditor:RemoveCP(position)
	
	local cpClosest = nil
	-- This initial value is also the minimum distance.
	local distanceClosest = 50
	
	for index , checkpoint in ipairs(self.course.checkpoints) do
		local distance = (checkpoint.position - position):Length()
		if distance < distanceClosest then
			cpClosest = checkpoint
			distanceClosest = distance
		end
	end
	
	if cpClosest then
		-- Remove from course.
		table.remove(self.course.checkpoints , cpClosest.index)
		-- Fix the index variable for each other checkpoint.
		for n = cpClosest.index , #self.course.checkpoints do
			self.course.checkpoints[n].index = n
		end
		-- Also remove from clients' course.
		self:NetworkSend("CERemoveCP" , cpClosest.courseEditorId)
	end
	
end

function CourseEditor:AddSpawn(position , angle , modelIds)
	
	local spawn = CourseSpawn()
	spawn.position = position
	spawn.angle = angle
	spawn.modelIds = modelIds
	spawn.courseEditorId = self.idCounter
	self.idCounter = self.idCounter + 1
	table.insert(self.course.spawns , spawn)
	
	-- Add to clients' course.
	self:NetworkSend("CEAddSpawn" , spawn:Marshal())
	
end

function CourseEditor:RemoveSpawn(position)
	
	local spawnClosest = nil
	-- This initial value is also the minimum distance.
	local distanceClosest = 50
	local removeIndex = -1
	
	for index , spawn in ipairs(self.course.spawns) do
		local distance = (spawn.position - position):Length()
		if distance < distanceClosest then
			spawnClosest = spawn
			distanceClosest = distance
			removeIndex = index
		end
	end
	
	if spawnClosest then
		-- Remove from course.
		table.remove(self.course.spawns , removeIndex)
		-- Also remove from clients' course.
		self:NetworkSend("CERemoveSpawn" , spawnClosest.courseEditorId)
	end
	
end

----------------------------------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------------------------------

function CourseEditor:PostServerTick()
	
	if self.numTicks % (#CourseEditor.courseEditors + 5) == self.auxUpdateTick then
		self:CheckPlayerWorlds()
	end
	
	self.numTicks = self.numTicks + 1
	
end

function CourseEditor:PlayerChat(args)
	
	-- Make sure this player is part of this editor.
	if not self:HasPlayer(args.player) then
		return true
	end
	
	-- Course editor commands.
	local player = args.player
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
		return false
	end
	
	table.remove(args , 1)
	
	-- Convert to lowercase.
	functionName = functionName:lower()
	
	local func = self.commands[functionName]
	
	-- Make sure command exists.
	if not func then
		return false
	end
	
	func(args)
	
	return false
	
end

function CourseEditor:PlayerQuit(args)
	
	if self:HasPlayer(args.player) then
		self:RemovePlayer(args.player , "Disconnected.")
	end
	
end

function CourseEditor:ModuleUnload()
	
	self:Destroy()
	
end
