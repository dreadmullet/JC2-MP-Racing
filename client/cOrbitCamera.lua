
function OrbitCamera:__init()
	-- Public properties
	self.targetPosition = Vector3(0 , 0 , 0)
	self.minPitch = math.rad(-89)
	self.maxPitch = math.rad(89)
	self.minDistance = 1
	self.maxDistance = 1000000
	self.collision = false
	self.sensitivityRot = 0.15
	self.sensitivityZoom = 0.035
	
	self.position = Vector3(0 , 10000 , 0)
	self.angle = Angle(0 , math.rad(-89) , 0)
	self.distance = 50
	self.angleBuffer = self.angle
	self.distanceDeltaBuffer = 0
	
	self.eventCalcView = Events:Subscribe("CalcView" , self , self.CalcView)
	self.eventLocalPlayerInput = Events:Subscribe("LocalPlayerInput" , self , self.LocalPlayerInput)
	self.eventMouseScroll = Events:Subscribe("MouseScroll" , self , self.MouseScroll)
	self.eventPreTick = Events:Subscribe("PreTick" , self , self.PreClientTick)
end

function OrbitCamera:Destroy()
	Events:Unsubscribe(self.eventCalcView)
	Events:Unsubscribe(self.eventLocalPlayerInput)
	Events:Unsubscribe(self.eventMouseScroll)
	Events:Unsubscribe(self.eventPreTick)
end

function OrbitCamera:UpdateDistance()
	local distanceDelta = self.distanceDeltaBuffer
	self.distanceDeltaBuffer = 0
	
	-- Clamp the distance to sane values
	self.distance = self.distance *
		math.pow(10 , 1 + -distanceDelta * self.sensitivityZoom) / 10
	self.distance = math.clamp(self.distance , self.minDistance , self.maxDistance)
end

function OrbitCamera:UpdatePosition()
	cameraDirection = (self.angle * Vector3(0 , 0 , 1))
	if self.collision then
		-- Raycast test so the camera doesn't go into geometry.
		local result = Physics:Raycast(self.targetPosition , cameraDirection , 0 , self.distance)
		self.position = self.targetPosition + cameraDirection * result.distance
		-- If the raycast hit.
		if result.distance ~= self.distance then
			self.position = self.position + result.normal * 0.25
		end
	else
		self.position = self.targetPosition + cameraDirection * self.distance
	end
	
	-- If angle isn't set here, it acts strangely, as if something is delayed by a frame. I have no
	-- idea why this works.
	self.angle = Angle.FromVectors(Vector3(0 , 0 , 1) , cameraDirection)
	self.angle.roll = 0
end

function OrbitCamera:UpdateAngle()
	self.angle = self.angleBuffer
end

-- Events

function OrbitCamera:CalcView()
	Camera:SetPosition(self.position)
	Camera:SetAngle(self.angle)
	
	-- Disable our player.
	return false
end

function OrbitCamera:LocalPlayerInput(args)
	local RotateYaw = function(value)
		self.angleBuffer.yaw = self.angleBuffer.yaw + value * self.sensitivityRot
	end
	local RotatePitch = function(value)
		self.angleBuffer.pitch = self.angleBuffer.pitch + value * self.sensitivityRot
		self.angleBuffer.pitch = math.clamp(self.angleBuffer.pitch , self.minPitch , self.maxPitch)
	end
	
	if args.input == Action.LookRight then
		RotateYaw(-args.state)
	elseif args.input == Action.LookLeft then
		RotateYaw(args.state)
	elseif args.input == Action.LookUp then
		RotatePitch(-args.state)
	elseif args.input == Action.LookDown then
		RotatePitch(args.state)
	end
	
	-- Update inputs for gamepads.
	if Game:GetSetting(GameSetting.GamepadInUse) then
		if args.input == Action.EquipTwohanded then
			self.distanceDeltaBuffer = args.state
		elseif args.input == Action.EquipBlackMarketBeacon then
			self.distanceDeltaBuffer = -args.state
		end
	end
end

function OrbitCamera:MouseScroll(args)
	self.distanceDeltaBuffer = args.delta
end

function OrbitCamera:PreClientTick()
	self:UpdateAngle()
	self:UpdateDistance()
	self:UpdatePosition()
end
