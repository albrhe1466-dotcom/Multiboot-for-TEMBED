--!strict
-- CarBuilder
-- Builds real, sleek, physics-drivable sports roadsters and supercars based on Claude's architecture.
-- 4 proper round wheels with rims (no spider legs, no sticks), front wheel steering servos,
-- 4-wheel drive hinge motors, VehicleSeat, open cockpit with driver visible, windshield,
-- roll hoop, GT wing, headlights + SpotLight, taillights, dual exhausts with nitro flame particles,
-- neon underglow, and network ownership.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CarBuilder = {}

local activeCars = {}
local driveConnections = {}

local function newPart(model: Instance, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = false
	p.CanCollide = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	p.Parent = model
	return p
end

local function weld(a: BasePart, b: BasePart): WeldConstraint
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
	return w
end

function CarBuilder.buildCar(cf: CFrame, owner: Player?, carId: number?): (Model, VehicleSeat?)
	local cId = carId or 1
	local carCfg = GameConfig.CARS[cId] or GameConfig.CARS[1]
	local carColor = carCfg.bodyColor or Color3.fromRGB(225, 35, 55)
	local glowColor = carCfg.trimColor or Color3.fromRGB(0, 220, 255)
	local topSpeed = 70 + (carCfg.speedMult or 1) * 25
	local steerAngle = 28
	local driveTorque = 28000
	local coastTorque = 3000
	local forwardSign = -1
	local steerSign = -1

	local wheelRadius = 1.6
	local wheelWidth = 1.4

	local model = Instance.new("Model")
	model.Name = (owner and owner.Name or "Showroom") .. "_Car_" .. tostring(cId)
	model.Parent = workspace

	local function L(x: number, y: number, z: number, pitch: number?): CFrame
		return cf * CFrame.new(x, y, z) * CFrame.Angles(pitch and math.rad(pitch) or 0, 0, 0)
	end

	local dark = Color3.fromRGB(28, 28, 32)
	local silver = Color3.fromRGB(205, 212, 225)

	-- Chassis (Root part, front of the car points to -Z)
	local chassis = newPart(model, {
		Name = "Chassis",
		Size = Vector3.new(6, 0.9, 12.4),
		CFrame = L(0, 0, 0),
		Color = carColor,
		CanCollide = true,
		Massless = false,
	})
	model.PrimaryPart = chassis

	local function add(props: { [string]: any }): Part
		local p = newPart(model, props)
		weld(chassis, p)
		return p
	end

	-- Body panels
	add({ Name = "Hood", Size = Vector3.new(5.6, 0.5, 4.6), CFrame = L(0, 0.9, -4, -8), Color = carColor })
	add({ Name = "NoseBumper", Size = Vector3.new(5.6, 0.8, 0.8), CFrame = L(0, 0.1, -6.5), Color = carColor })
	add({ Name = "Splitter", Size = Vector3.new(6.2, 0.2, 1.2), CFrame = L(0, -0.45, -6.8), Color = dark, Material = Enum.Material.Metal })
	add({ Name = "RearDeck", Size = Vector3.new(5.6, 0.5, 3.4), CFrame = L(0, 0.8, 4.4), Color = carColor })
	add({ Name = "SillL", Size = Vector3.new(0.5, 0.9, 5.0), CFrame = L(-2.9, 0.7, 0.6), Color = carColor })
	add({ Name = "SillR", Size = Vector3.new(0.5, 0.9, 5.0), CFrame = L(2.9, 0.7, 0.6), Color = carColor })
	add({ Name = "Dashboard", Size = Vector3.new(5, 0.7, 1.2), CFrame = L(0, 1.0, -1.9), Color = dark })
	add({ Name = "SeatBack", Size = Vector3.new(2.4, 1.7, 0.5), CFrame = L(0, 1.3, 1.95), Color = dark })
	add({
		Name = "Windshield",
		Size = Vector3.new(5, 1.7, 0.15),
		CFrame = L(0, 2.0, -2.5, 30),
		Color = Color3.fromRGB(150, 210, 255),
		Transparency = 0.5,
		Material = Enum.Material.Glass,
	})

	-- Roll hoop bars
	add({ Name = "HoopL", Size = Vector3.new(0.35, 2.0, 0.35), CFrame = L(-2.2, 1.45, 2.4), Color = silver, Material = Enum.Material.Metal })
	add({ Name = "HoopR", Size = Vector3.new(0.35, 2.0, 0.35), CFrame = L(2.2, 1.45, 2.4), Color = silver, Material = Enum.Material.Metal })
	add({ Name = "HoopTop", Size = Vector3.new(4.75, 0.35, 0.35), CFrame = L(0, 2.45, 2.4), Color = silver, Material = Enum.Material.Metal })

	-- GT Wing / Spoiler
	add({ Name = "SpoilerSupL", Size = Vector3.new(0.3, 1.2, 0.5), CFrame = L(-2, 1.4, 5.5), Color = dark })
	add({ Name = "SpoilerSupR", Size = Vector3.new(0.3, 1.2, 0.5), CFrame = L(2, 1.4, 5.5), Color = dark })
	add({ Name = "Wing", Size = Vector3.new(6.4, 0.25, 1.5), CFrame = L(0, 2.1, 5.6), Color = carColor })
	add({ Name = "WingEndL", Size = Vector3.new(0.2, 0.8, 1.5), CFrame = L(-3.2, 2.2, 5.6), Color = dark })
	add({ Name = "WingEndR", Size = Vector3.new(0.2, 0.8, 1.5), CFrame = L(3.2, 2.2, 5.6), Color = dark })

	-- Headlights with SpotLight & Taillights
	for _, side in ipairs({ -1, 1 }) do
		local head = add({
			Name = "Headlight",
			Size = Vector3.new(1.2, 0.5, 0.2),
			CFrame = L(side * 2, 0.35, -6.95),
			Color = Color3.fromRGB(255, 244, 214),
			Material = Enum.Material.Neon,
		})
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Front
		spot.Range = 45
		spot.Angle = 55
		spot.Brightness = 2.2
		spot.Parent = head

		add({
			Name = "Taillight",
			Size = Vector3.new(1.4, 0.4, 0.2),
			CFrame = L(side * 2, 0.55, 6.3),
			Color = Color3.fromRGB(255, 30, 40),
			Material = Enum.Material.Neon,
		})
	end

	-- Dual Exhausts with Nitro Flame Particle Emitters
	local flames = {}
	for _, side in ipairs({ -1, 1 }) do
		local pipe = add({
			Name = "Exhaust",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.0, 0.7, 0.7),
			CFrame = cf * CFrame.new(side * 1.2, 0.3, 6.5) * CFrame.Angles(0, math.rad(90), 0),
			Color = silver,
			Material = Enum.Material.Metal,
		})
		local fx = Instance.new("ParticleEmitter")
		fx.Enabled = false
		fx.Rate = 55
		fx.Lifetime = NumberRange.new(0.15, 0.3)
		fx.Speed = NumberRange.new(12, 18)
		fx.SpreadAngle = Vector2.new(6, 6)
		fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		fx.Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 70, 20))
		fx.LightEmission = 1
		fx.EmissionDirection = Enum.NormalId.Right
		fx.Parent = pipe
		table.insert(flames, fx)
	end

	-- Neon Underglow
	local glow = add({
		Name = "Underglow",
		Size = Vector3.new(5.2, 0.12, 10.5),
		CFrame = L(0, -0.5, 0),
		Color = glowColor,
		Material = Enum.Material.Neon,
		Transparency = 0.15,
	})
	local glowLight = Instance.new("PointLight")
	glowLight.Color = glowColor
	glowLight.Range = 16
	glowLight.Brightness = 2
	glowLight.Parent = glow

	-- Saudi License Plate (for Lexus LX #3 and exotic cars)
	local plate = add({
		Name = "Plate",
		Size = Vector3.new(2.4, 0.9, 0.15),
		CFrame = L(0, 0.15, 6.4),
		Color = Color3.fromRGB(250, 250, 250),
	})
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.CanvasSize = Vector2.new(140, 50)
	sg.Parent = plate
	local pLbl = Instance.new("TextLabel")
	pLbl.Size = UDim2.fromScale(1, 1)
	pLbl.BackgroundTransparency = 1
	pLbl.Text = if cId == 3 then "KSA | Ù‚ ÙŠ Ø§ Ø³ 111" else "1 SPEED"
	pLbl.TextColor3 = Color3.fromRGB(20, 22, 28)
	pLbl.Font = Enum.Font.FredokaOne
	pLbl.TextScaled = true
	pLbl.Parent = sg

	-- VehicleSeat for Driver
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2.2, 0.8, 2.2)
	seat.CFrame = L(0, 0.85, 0.9)
	seat.Color = dark
	seat.Massless = true
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.TurnSpeed = 0
	seat.Parent = model
	weld(chassis, seat)

	-- 4 Proper Round Wheels with Alloy Rims (No sticks, no spider legs!)
	local motors, servos = {}, {}

	local function addWheel(px: number, py: number, pz: number, steers: boolean)
		local wp = cf * CFrame.new(px, py, pz)
		local tire = newPart(model, {
			Name = "Wheel",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(wheelWidth, wheelRadius * 2, wheelRadius * 2),
			CFrame = wp,
			Color = Color3.fromRGB(22, 22, 26),
			CanCollide = true,
			Massless = false,
			CustomPhysicalProperties = PhysicalProperties.new(1.2, 2.2, 0, 100, 1),
		})
		local rim = newPart(model, {
			Name = "Rim",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(wheelWidth + 0.1, wheelRadius * 1.25, wheelRadius * 1.25),
			CFrame = wp,
			Color = silver,
			Material = Enum.Material.Metal,
		})
		weld(tire, rim)
		local hubGlow = newPart(model, {
			Name = "HubGlow",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(wheelWidth + 0.2, wheelRadius * 0.5, wheelRadius * 0.5),
			CFrame = wp,
			Color = glowColor,
			Material = Enum.Material.Neon,
		})
		weld(tire, hubGlow)

		local tireAtt = Instance.new("Attachment")
		tireAtt.Parent = tire

		local motor = Instance.new("HingeConstraint")
		motor.ActuatorType = Enum.ActuatorType.Motor
		motor.MotorMaxTorque = driveTorque
		motor.MotorMaxAcceleration = 350
		motor.AngularVelocity = 0

		if steers then
			local knuckle = newPart(model, {
				Name = "Knuckle",
				Size = Vector3.new(0.8, 0.8, 0.8),
				CFrame = wp,
				Transparency = 1,
				Massless = false,
				CustomPhysicalProperties = PhysicalProperties.new(2, 0.3, 0, 1, 1),
			})
			local upright = CFrame.Angles(0, 0, math.rad(90))

			local chassisSteerAtt = Instance.new("Attachment")
			chassisSteerAtt.CFrame = CFrame.new(px, py, pz) * upright
			chassisSteerAtt.Parent = chassis
			local knuckleSteerAtt = Instance.new("Attachment")
			knuckleSteerAtt.CFrame = upright
			knuckleSteerAtt.Parent = knuckle

			local servo = Instance.new("HingeConstraint")
			servo.ActuatorType = Enum.ActuatorType.Servo
			servo.AngularSpeed = 6
			servo.ServoMaxTorque = 200000
			servo.TargetAngle = 0
			servo.Attachment0 = chassisSteerAtt
			servo.Attachment1 = knuckleSteerAtt
			servo.Parent = chassis
			table.insert(servos, servo)

			local knuckleSpinAtt = Instance.new("Attachment")
			knuckleSpinAtt.Parent = knuckle
			motor.Attachment0 = knuckleSpinAtt
			motor.Attachment1 = tireAtt
			motor.Parent = knuckle
		else
			local chassisSpinAtt = Instance.new("Attachment")
			chassisSpinAtt.CFrame = CFrame.new(px, py, pz)
			chassisSpinAtt.Parent = chassis
			motor.Attachment0 = chassisSpinAtt
			motor.Attachment1 = tireAtt
			motor.Parent = chassis
		end
		table.insert(motors, motor)
	end

	local wx = 3 + wheelWidth / 2 + 0.1
	addWheel(-wx, -0.2, -4.4, true)
	addWheel(wx, -0.2, -4.4, true)
	addWheel(-wx, -0.2, 4.4, false)
	addWheel(wx, -0.2, 4.4, false)

	-- Drive simulation loop
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			conn:Disconnect()
			return
		end
		local throttle = seat.ThrottleFloat
		local steer = seat.SteerFloat
		local av = forwardSign * throttle * (topSpeed / wheelRadius)
		local torque = (throttle == 0) and coastTorque or driveTorque
		for _, m in ipairs(motors) do
			m.AngularVelocity = av
			m.MotorMaxTorque = torque
		end
		for _, s in ipairs(servos) do
			s.TargetAngle = steerSign * steer * steerAngle
		end
		for _, fx in ipairs(flames) do
			fx.Enabled = math.abs(throttle) > 0.3
		end
	end)

	-- Network Ownership for smooth driving
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = seat.Occupant
		local plr = hum and Players:GetPlayerFromCharacter(hum.Parent)
		if plr then
			pcall(function() chassis:SetNetworkOwner(plr) end)
		else
			pcall(function() chassis:SetNetworkOwnershipAuto() end)
		end
	end)

	return model, seat
end

-- Builds anchored showroom display cars on pedestals (no spider legs!)
function CarBuilder.buildDisplayCar(cf: CFrame, carId: number): Model
	local cId = carId or 1
	local carCfg = GameConfig.CARS[cId] or GameConfig.CARS[1]
	local carColor = carCfg.bodyColor or Color3.fromRGB(225, 35, 55)
	local glowColor = carCfg.trimColor or Color3.fromRGB(0, 220, 255)

	local model = Instance.new("Model")
	model.Name = "ShowroomCar_" .. tostring(cId)

	local function addDisp(props: { [string]: any }): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = Enum.Material.SmoothPlastic
		for k, v in pairs(props) do
			(p :: any)[k] = v
		end
		p.Parent = model
		return p
	end

	local function L(x: number, y: number, z: number, pitch: number?): CFrame
		return cf * CFrame.new(x, y, z) * CFrame.Angles(pitch and math.rad(pitch) or 0, 0, 0)
	end

	local dark = Color3.fromRGB(28, 28, 32)
	local silver = Color3.fromRGB(205, 212, 225)

	local chassis = addDisp({ Name = "Chassis", Size = Vector3.new(6, 0.9, 12.4), CFrame = L(0, 0, 0), Color = carColor })
	model.PrimaryPart = chassis

	addDisp({ Name = "Hood", Size = Vector3.new(5.6, 0.5, 4.6), CFrame = L(0, 0.9, -4, -8), Color = carColor })
	addDisp({ Name = "NoseBumper", Size = Vector3.new(5.6, 0.8, 0.8), CFrame = L(0, 0.1, -6.5), Color = carColor })
	addDisp({ Name = "Splitter", Size = Vector3.new(6.2, 0.2, 1.2), CFrame = L(0, -0.45, -6.8), Color = dark, Material = Enum.Material.Metal })
	addDisp({ Name = "RearDeck", Size = Vector3.new(5.6, 0.5, 3.4), CFrame = L(0, 0.8, 4.4), Color = carColor })
	addDisp({ Name = "Windshield", Size = Vector3.new(5, 1.7, 0.15), CFrame = L(0, 2.0, -2.5, 30), Color = Color3.fromRGB(150, 210, 255), Transparency = 0.5, Material = Enum.Material.Glass })
	addDisp({ Name = "Wing", Size = Vector3.new(6.4, 0.25, 1.5), CFrame = L(0, 2.1, 5.6), Color = carColor })

	for _, side in ipairs({ -1, 1 }) do
		addDisp({ Name = "Headlight", Size = Vector3.new(1.2, 0.5, 0.2), CFrame = L(side * 2, 0.35, -6.95), Color = Color3.fromRGB(255, 244, 214), Material = Enum.Material.Neon })
		addDisp({ Name = "Taillight", Size = Vector3.new(1.4, 0.4, 0.2), CFrame = L(side * 2, 0.55, 6.3), Color = Color3.fromRGB(255, 30, 40), Material = Enum.Material.Neon })
	end

	-- 4 Round Wheels
	local wx = 3 + 1.4 / 2 + 0.1
	local wheelZ = 4.4
	for _, xSign in ipairs({ -1, 1 }) do
		for _, zSign in ipairs({ -1, 1 }) do
			local wp = cf * CFrame.new(xSign * wx, -0.2, zSign * wheelZ)
			addDisp({ Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 3.2, 3.2), CFrame = wp, Color = Color3.fromRGB(22, 22, 26) })
			addDisp({ Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 2.0, 2.0), CFrame = wp, Color = silver, Material = Enum.Material.Metal })
			addDisp({ Name = "HubGlow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 0.8, 0.8), CFrame = wp, Color = glowColor, Material = Enum.Material.Neon })
		end
	end

	-- Underglow
	addDisp({ Name = "Underglow", Size = Vector3.new(5.2, 0.12, 10.5), CFrame = L(0, -0.5, 0), Color = glowColor, Material = Enum.Material.Neon, Transparency = 0.2 })

	return model
end

function CarBuilder.spawnCarFor(player: Player, character: Model, carId: number?)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	if activeCars[player] then
		activeCars[player]:Destroy()
		activeCars[player] = nil
	end

	local cf = CFrame.new(root.Position + Vector3.new(0, 3.5, 0)) * root.CFrame.Rotation
	local car, seat = CarBuilder.buildCar(cf, player, carId or 1)
	activeCars[player] = car

	task.wait(0.12)
	if seat and humanoid and humanoid.Parent then
		seat:Sit(humanoid)
	end
	return car
end

-- Cleanup on remove
Players.PlayerRemoving:Connect(function(player)
	if activeCars[player] then
		activeCars[player]:Destroy()
		activeCars[player] = nil
	end
end)

return CarBuilder
