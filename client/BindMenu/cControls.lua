Controls = {}

-- Array of tables.
-- Example values:
-- {name = "Jump"   , type = "Action"         , value = 44  , valueString = "SoundHornSiren"}
-- {name = "Boost"  , type = "Key"            , value = 160 , valueString = "LShift"}
-- {name = "Camera" , type = "MouseButton"    , value = 3   , valueString = "Mouse3"}
-- {name = "Camera" , type = "MouseWheel"     , value = 1   , valueString = "Mouse wheel up"}
-- {name = "Camera" , type = "MouseMovement"  , value = ">" , valueString = "Mouse right"}
-- Also, every control has a 'state' member, which is between 0 and 1 for most inputs.
Controls.controls = {}
Controls.held = {}
-- Map of all actions pressed. Resets every frame.
Controls.actionsBuffer = {}
Controls.mousePosition = Vector2(0 , 0)
Controls.mouseDelta = Vector2(0 , 0)
Controls.mouseControls = {}

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
--     Controls.Add("Respawn", "Mouse left")
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
	local alreadyExists = false
	-- If a control with this name already exists, modify it.
	for index , control in ipairs(Controls.controls) do
		if control.name == controlToSet.name then
			-- If the old control was type MouseMovement, remove it from Controls.mouseControls.
			if control.type == "MouseMovement" then
				table.remove(Controls.mouseControls , table.find(Controls.mouseControls , control) or 0)
			end
			
			Controls.controls[index] = controlToSet
			
			alreadyExists = true
			break
		end
	end
	
	-- If its type is MouseMovement, add it to Controls.mouseControls.
	if controlToSet.type == "MouseMovement" then
		table.insert(Controls.mouseControls , controlToSet)
	end
	
	if alreadyExists == false then
		table.insert(Controls.controls , controlToSet)
	end
end

Controls.Remove = function(controlName)
	for index , control in ipairs(Controls.controls) do
		if control.name == controlName then
			if control.type == "MouseMovement" then
				table.remove(Controls.mouseControls , table.find(Controls.mouseControls , control) or 0)
			end
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
			table.remove(Controls.held , table.find(Controls.held , control) or 0)
			Events:Fire("ControlUp" , control)
			break
		end
	end
end

-- Events

Controls.LocalPlayerInput = function(args)
	Controls.actionsBuffer[args.input] = args.state
	
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
		for action , state in pairs(Controls.actionsBuffer) do
			if action == actionToRemove then
				goto continue
			end
		end
		
		-- If we make it here, it means the action has been unpressed.
		
		Controls.Up{control.type , control.value}
		
		::continue::
	end
	
	-- Mouse movement.
	if #Controls.mouseControls > 0 then
		local oldMouseDelta = Controls.mouseDelta
		local newMouseDelta = Mouse:GetPosition() - Controls.mousePosition
		-- X
		if oldMouseDelta.x <= 0 and newMouseDelta.x > 0 then
			Controls.Down{"MouseMovement" , ">"}
		end
		if oldMouseDelta.x > 0 and newMouseDelta.x <= 0 then
			Controls.Up{"MouseMovement" , ">"}
		end
		if oldMouseDelta.x >= 0 and newMouseDelta.x < 0 then
			Controls.Down{"MouseMovement" , "<"}
		end
		if oldMouseDelta.x < 0 and newMouseDelta.x >= 0 then
			Controls.Up{"MouseMovement" , "<"}
		end
		-- Y
		if oldMouseDelta.y <= 0 and newMouseDelta.y > 0 then
			Controls.Down{"MouseMovement" , "v"}
		end
		if oldMouseDelta.y > 0 and newMouseDelta.y <= 0 then
			Controls.Up{"MouseMovement" , "v"}
		end
		if oldMouseDelta.y >= 0 and newMouseDelta.y < 0 then
			Controls.Down{"MouseMovement" , "^"}
		end
		if oldMouseDelta.y < 0 and newMouseDelta.y >= 0 then
			Controls.Up{"MouseMovement" , "^"}
		end
		-- If the mouse isn't visible, force it to the center of the screen so it doesn't hit the
		-- edges of the window.
		if Mouse:GetVisible() then
			Controls.mousePosition = Mouse:GetPosition()
		else
			Controls.mousePosition = Render.Size / 2
			Mouse:SetPosition(Controls.mousePosition)
		end
		Controls.mouseDelta = newMouseDelta
	end
	
	-- Set the state of every control to 0.
	for index , control in ipairs(Controls.controls) do
		control.state = 0
	end
	
	-- Fire the ControlHeld event for all of our held controls.
	local SetState = function(control)
		if control.type == "Action" then
			control.state = Controls.actionsBuffer[control.value] or 1
		elseif control.type == "Key" then
			control.state = 1
		elseif control.type == "MouseButton" then
			control.state = 1
		elseif control.type == "MouseMovement" then
			if control.value == ">" then
				control.state = Controls.mouseDelta.x
			elseif control.value == "<" then
				control.state = -Controls.mouseDelta.x
			elseif control.value == "v" then
				control.state = Controls.mouseDelta.y
			elseif control.value == "^" then
				control.state = -Controls.mouseDelta.y
			end
		end
	end
	for index , control in ipairs(Controls.held) do
		for index , c in ipairs(Controls.controls) do
			if c == control then
				SetState(control)
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
