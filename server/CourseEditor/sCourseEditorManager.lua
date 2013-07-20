
function CourseEditorManager:__init(raceManager)
	
	self.raceManager = raceManager -- Because why not.
	
	-- Key: name
	-- Value: CourseEditor
	self.courseEditors = {}
	
	self.events = {}
	local EventSub = function(name)
		table.insert(
			self.events ,
			Events:Subscribe(name , self , self[name])
		)
	end
	EventSub("PlayerChat")
	
end

function CourseEditorManager:CreateCourseEditor(name)
	
	if not name then
		error("CourseEditor needs a name!")
	end
	
	-- Make sure course name doesn't already exist.
	if self.courseEditors[name] then
		return
	end
	
	local editor = CourseEditor(self , name)
	self.courseEditors[name] = editor
	
	return editor
	
end

function CourseEditorManager:HasPlayer(player)
	
	for name , editor in pairs(self.courseEditors) do
		if editor:HasPlayer(player) then
			return true
		end
	end
	
	return false
	
end

function CourseEditorManager:AddPlayer(player , editorName)
	
	-- Create the editor if it doesn't exist yet.
	if self.courseEditors[editorName] == nil then
		self:CreateCourseEditor(editorName)
	end
	
	local editor = self.courseEditors[editorName]
	editor:AddPlayer(player)
	
end

-- Attempts to remove player from all editors.
function CourseEditorManager:RemovePlayer(player , reason)
	
	for name , editor in pairs(self.courseEditors) do
		-- They are only removed if they exist in the editor.
		-- Returns true if they removed player.
		if editor:RemovePlayer(player , reason) then
			break
		end
	end
	
end

--
-- Events
--

function CourseEditorManager:PlayerChat(args)
	
	if settings.courseEditorEnabled == false then
		return
	end
	
	local text = args.text:lower()
	if text == settingsCE.commandName or text == settingsCE.commandNameShort then
		if self:HasPlayer(args.player) then
			self:RemovePlayer(args.player , "Left.")
		else
			self:AddPlayer(args.player , args.player:GetName())
		end
	end
	
end
