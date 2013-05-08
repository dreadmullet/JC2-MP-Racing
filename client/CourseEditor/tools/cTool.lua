
-- key: Nice-looking name.
-- value: Class name that will be instantiated.
CourseEditor.globals.tools = {}
local T = CourseEditor.globals.tools
T["None"] = "None"
T["Object Spawner"] = "ObjectSpawner"
T["Checkpoint Spawner"] = "CheckpointSpawner"
T["Vehicle Spawner"] = "VehicleSpawner"

function Tool:__init()
	
	if CourseEditor.settings.debugLevel >= 2 then
		print("Tool:__init")
	end
	
	self.isEnabled = true
	
	self.inputs = {}
	
	self.events = {}
	table.insert(
		self.events ,
		Events:Subscribe("LocalPlayerInput" , self , Tool.Input)
	)
	table.insert(
		self.events ,
		Events:Subscribe("PreClientTick" , self , Tool.ManageInput)
	)
	
end

function Tool:Destroy()
	
	if CourseEditor.settings.debugLevel >= 2 then
		print("Tool:Destroy")
	end
	
	-- Unsubscribe from all events.
	for n , event in ipairs(self.events) do
		Events:Unsubscribe(event)
	end
	
end


--
-- Input
--

function Tool:Input(args)
	
	if not self.isEnabled then
		return
	end
	
	for inputName , inputInfo in pairs(self.inputs) do
		-- If this input is currently being pressed.
		if args.input == inputInfo.action then
			
			inputInfo.isPressed = true
			
			-- No reason to continue. Block the input.
			return false
			
		end
	end
	
end

function Tool:ManageInput()
	
	for inputName , inputInfo in pairs(self.inputs) do
		
		-- Previous input was different; either we started pressing it or we stopped pressing it.
		if inputInfo.isPressed ~= inputInfo.isPressedPrevious then
			if inputInfo.isPressed then
				
				local inputNamePressed = inputName.."Pressed"
				if self[inputNamePressed] then
					self[inputNamePressed](self)
				end
			else -- Otherwise, call inputNameUnpressed.
				local inputNameUnpressed = inputName.."Unpressed"
				if self[inputNameUnpressed] then
					self[inputNameUnpressed](self)
				end
			end
		end
		
		-- Fire the input every frame.
		if self[inputName] then
			self[inputName](self)
		end
		
		inputInfo.isPressedPrevious = inputInfo.isPressed
		inputInfo.isPressed = false
		
	end
	
end

function Tool:AddInput(callName , action)
	
	self.inputs[callName] = {
		["action"] = action ,
		["isPressed"] = false ,
		["isPressedPrevious"] = false
	}
	
end
