Controls = {}

-- Array of tables.
-- Example values:
-- {name = "Jump"  , type = "Action" , value = 44  , valueString = "SoundHornSiren"}
-- {name = "Boost" , type = "Key"    , value = 160 , valueString = "LShift"        }
Controls.controls = {}
-- These three are arrays of tables. Similar to above, but [1] is type and [2] is value.
Controls.held = {}

-- This should be called to add controls. Used by BindMenu.
Controls.Add = function(controlToAdd)
	-- Check for a duplicate
	for index , control in ipairs(Controls.controls) do
		if control.type == controlToAdd.type and control.value == controlToAdd.value then
			return
		end
	end
	
	table.insert(Controls.controls , Copy(controlToAdd))
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
	-- Make sure this key isn't held down.
	for index , controlInfo in ipairs(Controls.held) do
		if controlInfo[1] == "Action" and controlInfo[2] == args.input then
			return
		end
	end
	
	local controlInfo = {"Action" , args.input}
	Controls.Down(controlInfo)
	table.insert(Controls.held , controlInfo)
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
	-- Remove all actions from Controls.held if their state is 0.
	for n = #Controls.held , 1 , -1 do
		local controlInfo = Controls.held[n]
		if controlInfo[1] == "Action" and Input:GetValue(controlInfo[2]) == 0 then
			table.remove(Controls.held , n)
			Controls.Up(controlInfo)
		end
	end
	
	-- Fire the ControlHeld event for all of our controls.
	for index , controlInfo in ipairs(Controls.held) do
		for index , control in ipairs(Controls.controls) do
			if control.type == controlInfo[1] and control.value == controlInfo[2] then
				Events:Fire("ControlHeld" , control)
			end
		end
	end
end

Events:Subscribe("LocalPlayerInput" , Controls.LocalPlayerInput)
Events:Subscribe("KeyDown" , Controls.KeyDown)
Events:Subscribe("KeyUp" , Controls.KeyUp)
Events:Subscribe("InputPoll" , Controls.InputPoll)
