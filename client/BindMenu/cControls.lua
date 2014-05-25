Controls = {}

-- Array of tables.
-- Example values:
-- {name = "Jump"   , type = "Action"         , value = 44  , valueString = "SoundHornSiren"}
-- {name = "Boost"  , type = "Key"            , value = 160 , valueString = "LShift"}
-- {name = "Camera" , type = "MouseButton"    , value = 3   , valueString = "Mouse3"}
-- {name = "Camera" , type = "MouseWheel"     , value = 1   , valueString = "Mouse wheel up"}
-- {name = "Camera" , type = "MouseMovement"  , value = ">" , valueString = "Mouse right"}
Controls.controls = {}
Controls.held = {}
-- Like above, but for all Actions.
Controls.actionsBuffer = {}
Controls.mousePosition = Vector2(0 , 0)
Controls.mouseDelta = Vector2(0 , 0)

Controls.GetInputNameByControl = function(controlName)
	for index , control in ipairs(Controls.controls) do
		if control.name == controlName then
			return control.valueString
		end
	end
	
	return "UNASSIGNED"
end

Controls.Get = function(controlName)
	for index , control in ipairs(Controls.controls) do
		if control.name == controlName then
			return control
		end
	end
	
	return nil
end

Controls.GetIsHeld = function(controlName)
	for index , control in ipairs(Controls.held) do
		if control.name == controlName then
			return true
		end
	end
	
	return false
end

-- Examples:
--     Controls.Add("Respawn", "R")
--     Controls.Add("Respawn", "Reload")
--     Controls.Add("Respawn", "Mouse3")
--     Controls.Add("Respawn", "Mouse wheel up")
--     Controls.Add("Respawn", "Mouse up")
--     Controls.Add("Respawn", nil)
Controls.Add = function(name , defaultControl)
	local control = {}
	
	if defaultControl == nil then
		control.type = "Unassigned"
		control.value = -1
	elseif Action[defaultControl] then
		control.type = "Action"
		control.value = Action[defaultControl]
	elseif VirtualKey[defaultControl] or defaultControl:len() == 1 then
		control.type = "Key"
		control.value = VirtualKey[defaultControl] or string.byte(defaultControl:upper())
	elseif defaultControl:sub(1 , 11) == "Mouse wheel" then
		local remaining = defaultControl:sub(12)
		if remaining == " up" then
			control.type = "MouseWheel"
			control.value = 1
		elseif remaining == " down" then
			control.type = "MouseWheel"
			control.value = -1
		else
			error("Invalid default mouse wheel: "..tostring(defaultControl))
		end
	elseif defaultControl:sub(1 , 5) == "Mouse" then
		if defaultControl:sub(6 , 6) == " " then
			control.type = "MouseMovement"
			control.value = ({
				right = ">" ,
				left  = "<" ,
				down  = "v" ,
				up    = "^" ,
			})[defaultControl:sub(7)]
			
			if control.value == nil then
				error("Invalid default mouse movement: "..tostring(defaultControl))
			end
		else
			local number = tonumber(defaultControl:sub(6))
			if number then
				control.type = "MouseButton"
				control.value = number
			else
				error("Invalid default mouse button: "..tostring(defaultControl))
			end
		end
	else
		error("default control is not a valid Action, Key, or mouse button")
	end
	
	control.name = name
	control.valueString = defaultControl or "Unassigned"
	
	Controls.Set(control)
	
	return control
end

Controls.Set = function(controlToSet)
	-- If a control with this name already exists, modify it.
	for index , control in ipairs(Controls.controls) do
		if control.name == controlToSet.name then
			Controls.controls[index] = controlToSet
			return
		end
	end
	
	table.insert(Controls.controls , controlToSet)
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
	-- If this is one of our controls, add it to Controls.held and fire ControlDown.
	for index , control in ipairs(Controls.controls) do
		if control.type == controlInfo[1] and control.value == controlInfo[2] then
			Events:Fire("ControlDown" , control)
			table.insert(Controls.held , control)
			break
		end
	end
end

Controls.Up = function(controlInfo)
	-- If this is one of our controls, remove it from Controls.held and fire ControlUp.
	for index , control in ipairs(Controls.controls) do
		if control.type == controlInfo[1] and control.value == controlInfo[2] then
			table.remove(Controls.held , table.find(Controls.held , control))
			Events:Fire("ControlUp" , control)
			break
		end
	end
end

-- Events

Controls.LocalPlayerInput = function(args)
	table.insert(Controls.actionsBuffer , args.input)
	
	-- Make sure this action isn't held down.
	for index , control in ipairs(Controls.held) do
		if control.type == "Action" and control.value == args.input then
			return true
		end
	end
	
	local controlInfo = {"Action" , args.input}
	Controls.Down(controlInfo)
	
	return true
end

Controls.KeyDown = function(args)
	-- Make sure this key isn't held down.
	for index , control in ipairs(Controls.held) do
		if control.type == "Key" and control.value == args.key then
			return
		end
	end
	
	local controlInfo = {"Key" , args.key}
	Controls.Down(controlInfo)
end

Controls.KeyUp = function(args)
	-- Make sure this key is held down.
	for index , control in ipairs(Controls.held) do
		if control.type == "Key" and control.value == args.key then
			Controls.Up{control.type , control.value}
			return
		end
	end
end

Controls.MouseDown = function(args)
	-- Make sure this mouse button isn't held down.
	for index , control in ipairs(Controls.held) do
		if control.type == "MouseButton" and control.value == args.button then
			return
		end
	end
	
	Controls.Down{"MouseButton" , args.button}
end

Controls.MouseUp = function(args)
	-- Make sure this mouse button is held down.
	for index , control in ipairs(Controls.held) do
		if control.type == "MouseButton" and control.value == args.button then
			Controls.Up{"MouseButton" , args.button}
			return
		end
	end
end

Controls.MouseScroll = function(args)
	local value = math.clamp(args.delta , -1 , 1)
	
	-- The mouse wheel is an exception, it is instantly released.
	local controlInfo = {"MouseWheel" , value}
	Controls.Down(controlInfo)
	Controls.Up(controlInfo)
end

-- This should probably be PostTick or something, but it doesn't really matter.
Controls.InputPoll = function(args)
	-- Remove any Action from Controls.held if it wasn't held down this frame.
	for n = #Controls.held , 1 , -1 do
		local control = Controls.held[n]
		if control.type ~= "Action" then
			goto continue -- May the programming gods have mercy.
		end
		
		local actionToRemove = control.value
		for index , action in ipairs(Controls.actionsBuffer) do
			if action == actionToRemove then
				goto continue
			end
		end
		
		-- If we make it here, it means the action has been unpressed.
		
		Controls.Up{control.type , control.value}
		
		::continue::
	end
	
	-- Mouse movement.
	local newMouseDelta = Mouse:GetPosition() - Controls.mousePosition
	if Controls.mouseDelta.x == 0 then
		if newMouseDelta.x ~= 0 then
			if newMouseDelta.x > 0 then
				Controls.Down{"MouseMovement" , ">"}
			else
				Controls.Down{"MouseMovement" , "<"}
			end
		end
	elseif newMouseDelta.x == 0 then
		if newMouseDelta.x ~= 0 then
			if Controls.mouseDelta.x > 0 then
				Controls.Up{"MouseMovement" , ">"}
			else
				Controls.Up{"MouseMovement" , "<"}
			end
		end
	end
	if Controls.mouseDelta.y == 0 then
		if newMouseDelta.y ~= 0 then
			if newMouseDelta.y > 0 then
				Controls.Down{"MouseMovement" , "v"}
			else
				Controls.Down{"MouseMovement" , "^"}
			end
		end
	elseif newMouseDelta.y == 0 then
		if newMouseDelta.y ~= 0 then
			if Controls.mouseDelta.y > 0 then
				Controls.Up{"MouseMovement" , "v"}
			else
				Controls.Up{"MouseMovement" , "^"}
			end
		end
	end
	Controls.mouseDelta = newMouseDelta
	Controls.mousePosition = Mouse:GetPosition()
	
	-- Fire the ControlHeld event for all of our held controls.
	for index , control in ipairs(Controls.held) do
		for index , c in ipairs(Controls.controls) do
			if c == control then
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
Events:Subscribe("MouseDown" , Controls.MouseDown)
Events:Subscribe("MouseUp" , Controls.MouseUp)
Events:Subscribe("MouseScroll" , Controls.MouseScroll)
Events:Subscribe("InputPoll" , Controls.InputPoll)
