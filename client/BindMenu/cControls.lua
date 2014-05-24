Controls = {}

-- Array of tables.
-- Example values:
-- {name = "Jump"   , type = "Action"         , value = 44  , valueString = "SoundHornSiren"}
-- {name = "Boost"  , type = "Key"            , value = 160 , valueString = "LShift"}
-- {name = "Camera" , type = "MouseButton"    , value = 3   , valueString = "Mouse3"}
-- {name = "Camera" , type = "MouseWheel"     , value = 1   , valueString = "Mouse wheel up"}
-- {name = "Camera" , type = "MouseMovement"  , value = ">" , valueString = "Mouse right"}
Controls.controls = {}
-- These three are arrays of tables. Similar to above, but [1] is type and [2] is value.
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
	local control = nil
	for index , c in ipairs(Controls.controls) do
		if c.name == controlName then
			control = c
		end
	end
	
	if control == nil then
		return false
	end
	
	for index , c in ipairs(Controls.held) do
		if c[2] == control.value and c[1] == control.type then
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
	-- Make sure this key isn't held down.
	for index , controlInfo in ipairs(Controls.held) do
		if controlInfo[1] == "Key" and controlInfo[2] == args.key then
			return
		end
	end
	
	local controlInfo = {"Key" , args.key}
	Controls.Down(controlInfo)
	table.insert(Controls.held , controlInfo)
end

Controls.KeyUp = function(args)
	-- Make sure this key is held down.
	for index , controlInfo in ipairs(Controls.held) do
		if controlInfo[1] == "Key" and controlInfo[2] == args.key then
			table.remove(Controls.held , index)
			Controls.Up(controlInfo)
			return
		end
	end
end

Controls.MouseDown = function(args)
	-- Make sure this mouse button isn't held down.
	for index , controlInfo in ipairs(Controls.held) do
		if controlInfo[1] == "MouseButton" and controlInfo[2] == args.button then
			return
		end
	end
	
	local controlInfo = {"MouseButton" , args.button}
	Controls.Down(controlInfo)
	table.insert(Controls.held , controlInfo)
end

Controls.MouseUp = function(args)
	-- Make sure this mouse button is held down.
	for index , controlInfo in ipairs(Controls.held) do
		if controlInfo[1] == "MouseButton" and controlInfo[2] == args.button then
			table.remove(Controls.held , index)
			Controls.Up(controlInfo)
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
	
	-- Mouse movement.
	local newMouseDelta = Mouse:GetPosition() - Controls.mousePosition
	if Controls.mouseDelta.x == 0 then
		if newMouseDelta.x ~= 0 then
			for index , control in ipairs(Controls.controls) do
				if control.type == "MouseMovement" then
					if
						(control.value == ">" and newMouseDelta.x > 0) or
						(control.value == "<" and newMouseDelta.x < 0)
					then
						Events:Fire("ControlDown" , control)
					end
				end
			end
		end
	elseif newMouseDelta.x == 0 then
		for index , control in ipairs(Controls.controls) do
			if control.type == "MouseMovement" then
				if
					(control.value == ">" and Controls.mouseDelta.x > 0) or
					(control.value == "<" and Controls.mouseDelta.x < 0)
				then
					Events:Fire("ControlUp" , control)
				end
			end
		end
	end
	if Controls.mouseDelta.y == 0 then
		if newMouseDelta.y ~= 0 then
			for index , control in ipairs(Controls.controls) do
				if control.type == "MouseMovement" then
					if
						(control.value == "v" and newMouseDelta.y > 0) or
						(control.value == "^" and newMouseDelta.y < 0)
					then
						Events:Fire("ControlDown" , control)
					end
				end
			end
		end
	elseif newMouseDelta.y == 0 then
		for index , control in ipairs(Controls.controls) do
			if control.type == "MouseMovement" then
				if
					(control.value == "v" and Controls.mouseDelta.y > 0) or
					(control.value == "^" and Controls.mouseDelta.y < 0)
				then
					Events:Fire("ControlUp" , control)
				end
			end
		end
	end
	Controls.mouseDelta = newMouseDelta
	Controls.mousePosition = Mouse:GetPosition()
	
	-- Fire the ControlHeld event for all of our held controls.
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
Events:Subscribe("MouseDown" , Controls.MouseDown)
Events:Subscribe("MouseUp" , Controls.MouseUp)
Events:Subscribe("MouseScroll" , Controls.MouseScroll)
Events:Subscribe("InputPoll" , Controls.InputPoll)
