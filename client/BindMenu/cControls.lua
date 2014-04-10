Controls = {}

-- Array of tables.
-- Example values:
-- {name = "Jump"  , type = "Action" , value = 44  , valueString = "SoundHornSiren"}
-- {name = "Boost" , type = "Key"    , value = 160 , valueString = "LShift"        }
Controls.controls = {}
-- These three are arrays of tables. Similar to above, but [1] is type and [2] is value.
Controls.held = {}
-- Like above, but for all Actions.
Controls.actionsBuffer = {}

Controls.GetInputNameByControl = function(controlName)
	for index , control in ipairs(Controls.controls) do
		if control.name == controlName then
			return control.valueString
		end
	end
	
	return "UNASSIGNED"
end

-- This should be called to add or change controls. Used by BindMenu.
Controls.Set = function(controlToSet)
	-- If a control with this name already exists, modify it.
	for index , control in ipairs(Controls.controls) do
		if control.name == controlToSet.name then
			Controls.controls[index] = controlToSet
			return
		end
	end
	
	table.insert(Controls.controls , Copy(controlToSet))
end

Controls.Remove = function(controlName)
	for index , control in ipairs(Controls.controls) do
		if control.name == controlName then
			table.remove(Controls.controls , index)
			break
		end
	end
end

Controls.Down = function(controlInfo)
	-- If this is one of our controls, fire ControlDown.
	for index , control in ipairs(Controls.controls) do
		if control.type == controlInfo[1] and control.value == controlInfo[2] then
			Events:Fire("ControlDown" , control)
		end
	end
end

Controls.Up = function(controlInfo)
	-- If this is one of our controls, fire ControlUp.
	for index , control in ipairs(Controls.controls) do
		if control.type == controlInfo[1] and control.value == controlInfo[2] then
			Events:Fire("ControlUp" , control)
		end
	end
end

-- Events

Controls.LocalPlayerInput = function(args)
	table.insert(Controls.actionsBuffer , args.input)
	
	-- Make sure this action isn't held down.
	for index , controlInfo in ipairs(Controls.held) do
		if controlInfo[1] == "Action" and controlInfo[2] == args.input then
			return true
		end
	end
	
	local controlInfo = {"Action" , args.input}
	Controls.Down(controlInfo)
	table.insert(Controls.held , controlInfo)
	
	return true
end

Controls.KeyDown = function(args)
	local key = args.key
	-- Make sure this key isn't held down.
	for index , controlInfo in ipairs(Controls.held) do
		if controlInfo[1] == "Key" and controlInfo[2] == key then
			return
		end
	end
	
	local controlInfo = {"Key" , key}
	Controls.Down(controlInfo)
	table.insert(Controls.held , controlInfo)
end

Controls.KeyUp = function(args)
	local key = args.key
	-- Make sure this key is held down.
	for index , controlInfo in ipairs(Controls.held) do
		if controlInfo[1] == "Key" and controlInfo[2] == key then
			table.remove(Controls.held , index)
			Controls.Up(controlInfo)
			return
		end
	end
end

Controls.InputPoll = function(args)
	-- Remove any Action from Controls.held if it wasn't held down this frame.
	for n = #Controls.held , 1 , -1 do
		local controlInfo = Controls.held[n]
		if controlInfo[1] ~= "Action" then
			goto continue -- May the programming gods have mercy.
		end
		
		local actionToRemove = controlInfo[2]
		for index , action in ipairs(Controls.actionsBuffer) do
			if action == actionToRemove then
				goto continue
			end
		end
		-- If we make it here, it means the action has been unpressed.
		
		table.remove(Controls.held , n)
		Controls.Up(controlInfo)
		
		::continue::
	end
	
	-- Fire the ControlHeld event for all of our controls.
	for index , controlInfo in ipairs(Controls.held) do
		for index , control in ipairs(Controls.controls) do
			if control.type == controlInfo[1] and control.value == controlInfo[2] then
				Events:Fire("ControlHeld" , control)
			end
		end
	end
	
	-- Clear the Action buffer.
	Controls.actionsBuffer = {}
end

Events:Subscribe("LocalPlayerInput" , Controls.LocalPlayerInput)
Events:Subscribe("KeyDown" , Controls.KeyDown)
Events:Subscribe("KeyUp" , Controls.KeyUp)
Events:Subscribe("InputPoll" , Controls.InputPoll)
