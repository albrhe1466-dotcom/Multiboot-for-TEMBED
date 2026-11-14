--!strict
-- WorldBuilder
-- Front-Page 2026 Quality Map & Showroom Architecture for One Speed Car
-- 1. UNBLOCKED STAGE 1: Giant 65-stud open archway straight into the Stage 1 speedway track
-- 2. 3D PHYSICAL LEADERBOARDS: Giant golden SurfaceGui leaderboards on South Wall directly behind spawn
-- 3. 5 ANIMATED TREADMILLS: Animated scrolling chevron conveyor belts with spinning rollers
-- 4. REAL SUPERCAR SHOWROOM: Showroom supercars on tiered turntables (NO spiders)
-- 5. GIANT MAP: 260x260 stud green grass arena, stone walkways, high brown checkered walls
-- 6. COLOSSAL TSUNAMI & YELLOW STUDDED VICTORY PAD: Touching awards +1 Win, NO checkpoints!

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local CarBuilder = require(script.Parent.CarBuilder)

local WorldBuilder = {}

local function createPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = if canCollide == nil then true else canCollide
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addBillboardText(
	parent: Instance,
	text: string,
	subText: string?,
	textColor: Color3,
	offset: Vector3,
	sizeStuds: Vector2?
): BillboardGui
	local bg = Instance.new("BillboardGui")
	bg.Name = "InfoBillboard"
	bg.Adornee = parent
	bg.Size = UDim2.fromScale(if sizeStuds then sizeStuds.X else 12, if sizeStuds then sizeStuds.Y else 4)
	bg.StudsOffset = offset
	bg.AlwaysOnTop = false
	bg.MaxDistance = 280
	bg.Parent = parent

	local mainLbl = Instance.new("TextLabel")
	mainLbl.Name = "MainLabel"
	mainLbl.Size = if subText then UDim2.fromScale(1, 0.58) else UDim2.fromScale(1, 1)
	mainLbl.BackgroundTransparency = 1
	mainLbl.Text = text
	mainLbl.TextColor3 = textColor
	mainLbl.TextStrokeColor3 = Color3.fromRGB(15, 15, 22)
	mainLbl.TextStrokeTransparency = 0
	mainLbl.TextScaled = true
	mainLbl.Font = Enum.Font.FredokaOne
	mainLbl.Parent = bg

	if subText then
		local subLbl = Instance.new("TextLabel")
		subLbl.Name = "SubLabel"
		subLbl.Position = UDim2.fromScale(0, 0.58)
		subLbl.Size = UDim2.fromScale(1, 0.42)
		subLbl.BackgroundTransparency = 1
		subLbl.Text = subText
		subLbl.TextColor3 = Color3.fromRGB(240, 240, 250)
		subLbl.TextStrokeColor3 = Color3.fromRGB(15, 15, 22)
		subLbl.TextStrokeTransparency = 0
		subLbl.TextScaled = true
		subLbl.Font = Enum.Font.FredokaOne
		subLbl.Parent = bg
	end
	return bg
end

-- =========================================================
-- 1. TREADMILLS BUILDER (5 Flagship Tiers from Photo 1)
-- =========================================================
local function buildTreadmill(parent: Instance, info: any, originCF: CFrame): Model
	local tm = Instance.new("Model")
	tm.Name = "Treadmill_" .. tostring(info.id)
	tm:SetAttribute("TreadmillId", info.id)
	tm:SetAttribute("SpeedGain", info.speedGain or 1)
	tm:SetAttribute("RebirthReq", info.rebirthReq or 0)
	tm:SetAttribute("TierName", info.name)

	-- Base chassis
	local base = createPart(tm, "Base", Vector3.new(12.0, 1.6, 17.0), originCF * CFrame.Angles(math.rad(10), 0, 0), info.color, info.material)

	-- The running belt
	local belt = createPart(
		tm,
		"Belt",
		Vector3.new(8.6, 0.5, 15.4),
		originCF * CFrame.Angles(math.rad(10), 0, 0) * CFrame.new(0, 0.8, 0.2),
		if info.id == 5 then Color3.fromRGB(24, 18, 22) else Color3.fromRGB(38, 34, 42),
		Enum.Material.SmoothPlastic
	)
	belt:SetAttribute("TreadmillId", info.id)
	belt:SetAttribute("SpeedGain", info.speedGain or 1)
	belt:SetAttribute("RebirthReq", info.rebirthReq or 0)
	belt:AddTag("TreadmillBelt")

	local beltDirection = (originCF * CFrame.Angles(math.rad(10), 0, 0)).LookVector
	belt.AssemblyLinearVelocity = -beltDirection * (info.beltSpeed or 20)

	-- Animated Surface Texture on top of belt
	local beltTexture = Instance.new("Texture")
	beltTexture.Name = "BeltConveyorTexture"
	beltTexture.Texture = "rbxassetid://135400582" -- Arrow pattern
	beltTexture.Face = Enum.NormalId.Top
	beltTexture.StudsPerTileU = 8
	beltTexture.StudsPerTileV = 4
	beltTexture.Color3 = info.accentColor
	beltTexture.Transparency = 0.35
	beltTexture.Parent = belt

	-- End cylindrical Rollers (spinning in sync with the belt)
	local rollF = createPart(
		tm,
		"RollerFront",
		Vector3.new(1.2, 8.6, 1.2),
		originCF * CFrame.Angles(math.rad(10), 0, 0) * CFrame.new(0, 0.75, -7.4) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(180, 185, 195),
		Enum.Material.Metal
	)
	rollF.Shape = Enum.PartType.Cylinder
	rollF:SetAttribute("IsRoller", true)

	local rollB = createPart(
		tm,
		"RollerBack",
		Vector3.new(1.2, 8.6, 1.2),
		originCF * CFrame.Angles(math.rad(10), 0, 0) * CFrame.new(0, 0.75, 7.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(180, 185, 195),
		Enum.Material.Metal
	)
	rollB.Shape = Enum.PartType.Cylinder
	rollB:SetAttribute("IsRoller", true)

	-- Glowing V-Chevrons on belt (>>>) (Image 1)
	local chevronFolder = Instance.new("Folder")
	chevronFolder.Name = "Chevrons"
	chevronFolder.Parent = tm

	for row = 1, 6 do
		local zOff = -5.8 + (row - 1) * 2.3
		for _, side in { -1, 1 } do
			local chev = createPart(
				chevronFolder,
				"Chevron_" .. tostring(row) .. "_" .. tostring(side),
				Vector3.new(2.9, 0.24, 0.65),
				originCF
					* CFrame.Angles(math.rad(10), 0, 0)
					* CFrame.new(side * 1.45, 1.05, zOff)
					* CFrame.Angles(0, side * math.rad(28), 0),
				info.accentColor,
				Enum.Material.Neon,
				false
			)
			chev:SetAttribute("Row", row)
			chev:SetAttribute("Side", side)
			chev:SetAttribute("BaseZ", zOff)
			chev:AddTag("TreadmillChevron")
		end
	end

	-- Alternating Striped Side Rails (Image 1)
	for _, side in { -1, 1 } do
		for seg = 1, 7 do
			local stripeColor = if seg % 2 == 0 then info.accentColor else info.color
			createPart(
				tm,
				"Rail_" .. tostring(side) .. "_" .. tostring(seg),
				Vector3.new(1.4, 2.0, 2.4),
				originCF * CFrame.Angles(math.rad(10), 0, 0) * CFrame.new(side * 5.2, 0.65, -6.8 + (seg - 1) * 2.3),
				stripeColor,
				info.material
			)
		end
	end

	-- Front Console Arch + Monitor (Image 1)
	createPart(tm, "ConsoleBar", Vector3.new(11.8, 1.8, 1.8), originCF * CFrame.new(0, 4.4, -7.0), info.color, info.material)
	for _, side in { -1, 1 } do
		createPart(tm, "Post_" .. tostring(side), Vector3.new(1.6, 4.6, 1.6), originCF * CFrame.new(side * 5.2, 2.3, -7.0), info.color, info.material)
		local orb = createPart(tm, "Orb_" .. tostring(side), Vector3.new(2.0, 2.0, 2.0), originCF * CFrame.new(side * 5.2, 5.5, -7.0), info.accentColor, Enum.Material.Neon)
		orb.Shape = Enum.PartType.Ball
	end

	local screenFrame = createPart(tm, "MonitorFrame", Vector3.new(5.6, 3.4, 0.9), originCF * CFrame.new(0, 6.5, -7.0), Color3.fromRGB(18, 20, 26), Enum.Material.SmoothPlastic)
	local screenFace = createPart(tm, "MonitorScreen", Vector3.new(5.0, 2.8, 0.28), originCF * CFrame.new(0, 6.5, -6.5), info.color, Enum.Material.Neon)
	screenFace:SetAttribute("BaseColor", info.color)

	local sgui = Instance.new("SurfaceGui")
	sgui.Face = Enum.NormalId.Front
	sgui.CanvasSize = Vector2.new(256, 160)
	sgui.Parent = screenFace

	local boltIcon = Instance.new("TextLabel")
	boltIcon.Size = UDim2.fromScale(1, 1)
	boltIcon.BackgroundTransparency = 1
	boltIcon.Text = "⚡"
	boltIcon.TextColor3 = if info.id == 5 then Color3.fromRGB(255, 30, 30) else Color3.fromRGB(25, 25, 30)
	boltIcon.Font = Enum.Font.FredokaOne
	boltIcon.TextScaled = true
	boltIcon.Parent = sgui

	-- Built-in Particles on Belt
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Color = ColorSequence.new(info.accentColor, Color3.fromRGB(255, 255, 255))
	sparks.Rate = 0
	sparks.Speed = NumberRange.new(8, 16)
	sparks.SpreadAngle = Vector2.new(45, 45)
	sparks.Lifetime = NumberRange.new(0.3, 0.6)
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sparks.LightEmission = 1
	sparks.Parent = belt

	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Dust"
	dust.Color = ColorSequence.new(Color3.fromRGB(210, 210, 220))
	dust.Rate = 0
	dust.Speed = NumberRange.new(4, 8)
	dust.SpreadAngle = Vector2.new(30, 30)
	dust.Lifetime = NumberRange.new(0.4, 0.8)
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2.5) })
	dust.EmissionDirection = Enum.NormalId.Back
	dust.Parent = belt

	-- Glowing Aura for Top Tier (Tier 5 / Admin Speed)
	if info.id == 5 then
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "Aura"
		aura.Color = ColorSequence.new(Color3.fromRGB(255, 30, 40), Color3.fromRGB(255, 200, 50))
		aura.Rate = 0
		aura.Speed = NumberRange.new(6, 14)
		aura.SpreadAngle = Vector2.new(60, 60)
		aura.Lifetime = NumberRange.new(0.4, 0.9)
		aura.LightEmission = 1
		aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
		aura.Parent = belt
	end

	-- Built-in Sounds
	local spinSnd = Instance.new("Sound")
	spinSnd.Name = "SpinUpSound"
	spinSnd.SoundId = "rbxassetid://3406813517"
	spinSnd.Volume = 0.55
	spinSnd.Parent = belt

	local dingSnd = Instance.new("Sound")
	dingSnd.Name = "DingSound"
	dingSnd.SoundId = "rbxassetid://18192219147"
	dingSnd.Volume = 0.45
	dingSnd.Parent = belt

	-- Proximity Prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "🏃 Train Speed"
	prompt.ObjectText = info.name
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt.Parent = belt

	local reqText = if (info.rebirthReq or 0) > 0 then "🔒 " .. tostring(info.rebirthReq) .. " Rebirths" else "✅ Beginner Free"
	addBillboardText(
		screenFrame,
		info.name,
		"+" .. tostring(info.speedGain or 1) .. " Speed/step | " .. reqText,
		info.accentColor,
		Vector3.new(0, 3.4, 0),
		Vector2.new(15, 4.2)
	)

	tm.PrimaryPart = belt
	tm.Parent = parent
	return tm
end

-- =========================================================
-- 2. TIERED SUPERCAR SHOWROOM PEDESTALS (Real Cars, NO Spiders)
-- =========================================================
local function buildSupercarPedestal(parent: Instance, carId: number, cframe: CFrame): Model
	local carInfo = GameConfig.CARS[carId] or GameConfig.CARS[1]
	local m = Instance.new("Model")
	m.Name = "Pedestal_" .. tostring(carId)

	-- Turntable Base
	createPart(m, "PedestalBase", Vector3.new(13.0, 1.4, 15.0), cframe, Color3.fromRGB(30, 34, 44), Enum.Material.SmoothPlastic)
	createPart(m, "NeonRing", Vector3.new(13.4, 0.35, 15.4), cframe * CFrame.new(0, 0.55, 0), carInfo.trimColor or Color3.fromRGB(56, 189, 248), Enum.Material.Neon)

	-- Pristine anchored showroom supercar (NO spider legs)
	local carModel = CarBuilder.buildDisplayCar(cframe * CFrame.new(0, 2.2, 0), carId)
	carModel.Parent = m

	-- Plaque in front
	local plaque = createPart(m, "Plaque", Vector3.new(8.5, 2.0, 0.6), cframe * CFrame.new(0, 1.3, -7.2) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(18, 20, 26), Enum.Material.SmoothPlastic)

	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(400, 100)
	sg.Parent = plaque

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0.52, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = tostring(carId) .. ". " .. string.upper(carInfo.name)
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextScaled = true
	nameLbl.Parent = sg

	local statLbl = Instance.new("TextLabel")
	statLbl.Size = UDim2.new(1, 0, 0.48, 0)
	statLbl.Position = UDim2.fromScale(0, 0.52)
	statLbl.BackgroundTransparency = 1
	statLbl.Text = string.format("⚡ %gx Speed | 🏆 %s Wins", carInfo.speedMult, GameConfig.formatNumber(carInfo.winsReq))
	statLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	statLbl.Font = Enum.Font.FredokaOne
	statLbl.TextScaled = true
	statLbl.Parent = sg

	-- Equip Touch Pad
	local equipPad = createPart(m, "EquipPad", Vector3.new(5.2, 0.3, 3.2), cframe * CFrame.new(0, 0.2, -8.8), Color3.fromRGB(45, 220, 95), Enum.Material.Neon)
	equipPad:SetAttribute("CarId", carId)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "🚗 Equip " .. carInfo.name
	prompt.ObjectText = tostring(carInfo.speedMult) .. "x Speed"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = equipPad

	m.PrimaryPart = equipPad
	m.Parent = parent
	return m
end

-- =========================================================
-- 3. 3D PHYSICAL SURFACEGUI LEADERBOARDS (Behind Spawn on South Wall)
-- =========================================================
local function buildPhysicalLeaderboard(parent: Instance, title: string, category: string, cframe: CFrame, headerColor: Color3): Model
	local m = Instance.new("Model")
	m.Name = "Leaderboard_" .. category

	-- Outer wooden/gold frame
	createPart(m, "Backboard", Vector3.new(24, 28, 2.0), cframe, Color3.fromRGB(25, 28, 38), Enum.Material.SmoothPlastic)
	createPart(m, "NeonBorder", Vector3.new(24.6, 28.6, 0.4), cframe * CFrame.new(0, 0, -0.4), headerColor, Enum.Material.Neon)
	local dispPart = createPart(m, "DisplayPart", Vector3.new(22.8, 26.8, 0.25), cframe * CFrame.new(0, 0, 1.0), Color3.fromRGB(16, 18, 26), Enum.Material.SmoothPlastic)

	local sg = Instance.new("SurfaceGui")
	sg.Name = "BoardGui"
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(540, 680)
	sg.Parent = dispPart

	-- Header
	local hdr = Instance.new("Frame")
	hdr.Size = UDim2.new(1, 0, 0, 72)
	hdr.BackgroundColor3 = headerColor
	hdr.BorderSizePixel = 0
	hdr.Parent = sg

	local uic = Instance.new("UICorner")
	uic.CornerRadius = UDim.new(0, 14)
	uic.Parent = hdr

	local hdrText = Instance.new("TextLabel")
	hdrText.Size = UDim2.fromScale(1, 1)
	hdrText.BackgroundTransparency = 1
	hdrText.Text = title
	hdrText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hdrText.Font = Enum.Font.FredokaOne
	hdrText.TextSize = 34
	hdrText.Parent = hdr

	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(15, 15, 20)
	st.Thickness = 2.5
	st.Parent = hdrText

	-- Scroll/List of Top Players
	local list = Instance.new("Frame")
	list.Name = "RowsContainer"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(0, 84)
	list.Size = UDim2.new(1, 0, 1, -94)
	list.Parent = sg

	local uill = Instance.new("UIListLayout")
	uill.Padding = UDim.new(0, 8)
	uill.SortOrder = Enum.SortOrder.LayoutOrder
	uill.Parent = list

	-- Benchmark Top Competitors
	local mockData = {
		{ name = "Nawaf2011871", val = (category == "Wins" and "5,700") or (category == "Rebirths" and "6") or "2,300,000" },
		{ name = "BassamKing7079", val = (category == "Wins" and "6,000") or (category == "Rebirths" and "5") or "3,200,000" },
		{ name = "ilovesatan1112", val = (category == "Wins" and "2,200") or (category == "Rebirths" and "5") or "520,500" },
		{ name = "LOFEO19997", val = (category == "Wins" and "171") or (category == "Rebirths" and "4") or "219,000" },
		{ name = "Tlata013", val = (category == "Wins" and "45") or (category == "Rebirths" and "2") or "2,100" },
		{ name = "Azorie991", val = (category == "Wins" and "12") or (category == "Rebirths" and "1") or "213" },
		{ name = "nic21300", val = (category == "Wins" and "2") or (category == "Rebirths" and "0") or "30" },
	}

	for i, data in ipairs(mockData) do
		local row = Instance.new("Frame")
		row.Name = "Row_" .. i
		row.Size = UDim2.new(1, -12, 0, 52)
		row.Position = UDim2.fromOffset(6, 0)
		row.BackgroundColor3 = (i == 1 and Color3.fromRGB(60, 48, 16)) or Color3.fromRGB(28, 32, 44)
		row.BackgroundTransparency = 0.2
		row.LayoutOrder = i
		row.Parent = list

		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 10)
		rc.Parent = row

		local rSt = Instance.new("UIStroke")
		local pc = (i == 1 and Color3.fromRGB(255, 215, 0)) or (i == 2 and Color3.fromRGB(205, 215, 230)) or (i == 3 and Color3.fromRGB(214, 140, 72))
		rSt.Color = pc or Color3.fromRGB(56, 189, 248)
		rSt.Thickness = pc and 2 or 1
		rSt.Transparency = pc and 0.1 or 0.6
		rSt.Parent = row

		local rankLabel = Instance.new("TextLabel")
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = (i == 1 and "👑 1") or ("#" .. i)
		rankLabel.TextColor3 = pc or Color3.fromRGB(160, 170, 190)
		rankLabel.Font = Enum.Font.FredokaOne
		rankLabel.TextSize = 24
		rankLabel.Size = UDim2.fromOffset(70, 52)
		rankLabel.Position = UDim2.fromOffset(12, 0)
		rankLabel.TextXAlignment = Enum.TextXAlignment.Left
		rankLabel.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = data.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.TextSize = 22
		nameLabel.Size = UDim2.new(1, -240, 1, 0)
		nameLabel.Position = UDim2.fromOffset(85, 0)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local valLabel = Instance.new("TextLabel")
		valLabel.BackgroundTransparency = 1
		valLabel.Text = data.val
		valLabel.TextColor3 = pc or Color3.fromRGB(56, 189, 248)
		valLabel.Font = Enum.Font.FredokaOne
		valLabel.TextSize = 24
		valLabel.AnchorPoint = Vector2.new(1, 0)
		valLabel.Position = UDim2.new(1, -16, 0, 0)
		valLabel.Size = UDim2.fromOffset(140, 52)
		valLabel.TextXAlignment = Enum.TextXAlignment.Right
		valLabel.Parent = row
	end

	m.PrimaryPart = dispPart
	m.Parent = parent
	return m
end

-- =========================================================
-- 4. MAIN BUILDALL
-- =========================================================
function WorldBuilder.buildAll()
	local oldWorld = Workspace:FindFirstChild("OneSpeedCarWorld")
	if oldWorld then oldWorld:Destroy() end

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Position = Vector3.new(0, -35, 0)
		baseplate.Transparency = 1
		baseplate.CanCollide = false
	end

	local world = Instance.new("Folder")
	world.Name = "OneSpeedCarWorld"
	world.Parent = Workspace

	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "Hub"
	hubFolder.Parent = world

	-- 1. GIANT OPEN-AIR LOBBY ARENA (260 x 260 studs)
	-- Lush green grass floor (matching Image 4)
	createPart(hubFolder, "LobbyGrass", Vector3.new(260, 4, 260), CFrame.new(0, -2, 25), Color3.fromRGB(115, 204, 76), Enum.Material.Grass)

	-- Checkered Stone Walkway Paths (Image 4)
	local walkwayFolder = Instance.new("Folder")
	walkwayFolder.Name = "StoneWalkways"
	walkwayFolder.Parent = hubFolder

	-- Main Central Path leading straight through the archway into STAGE 1
	for i = 1, 38 do
		local z = 120 - (i - 1) * 6.5
		local col = if i % 2 == 0 then Color3.fromRGB(240, 245, 255) else Color3.fromRGB(218, 225, 238)
		createPart(walkwayFolder, "PathTile_" .. i, Vector3.new(22, 0.4, 6.3), CFrame.new(0, 0.2, z), col, Enum.Material.Cobblestone)
	end

	-- East & West Crosswalks
	createPart(walkwayFolder, "CrosswalkWest", Vector3.new(90, 0.35, 16), CFrame.new(-45, 0.2, 45), Color3.fromRGB(230, 235, 245), Enum.Material.Cobblestone)
	createPart(walkwayFolder, "CrosswalkEast", Vector3.new(90, 0.35, 16), CFrame.new(45, 0.2, 45), Color3.fromRGB(230, 235, 245), Enum.Material.Cobblestone)

	-- Perimeter Walls: High brown checkerboard squares with green grass trim (Image 4)
	local wallFolder = Instance.new("Folder")
	wallFolder.Name = "PerimeterWalls"
	wallFolder.Parent = hubFolder

	local c1 = Color3.fromRGB(170, 110, 70)
	local c2 = Color3.fromRGB(145, 90, 55)

	-- South Wall (Behind Spawn)
	for row = 1, 4 do
		for col = 1, 13 do
			local wallCol = if (row + col) % 2 == 0 then c1 else c2
			local x = -130 + (col - 0.5) * 20
			local y = (row - 0.5) * 10
			createPart(wallFolder, "SW_" .. row .. "_" .. col, Vector3.new(20, 10, 6), CFrame.new(x, y, 155), wallCol, Enum.Material.WoodPlanks)
		end
	end
	createPart(wallFolder, "SW_Trim", Vector3.new(262, 3, 8), CFrame.new(0, 41.5, 155), Color3.fromRGB(115, 204, 76), Enum.Material.Grass)

	-- West Wall (Left side)
	for row = 1, 4 do
		for col = 1, 13 do
			local wallCol = if (row + col) % 2 == 0 then c1 else c2
			local z = 155 - (col - 0.5) * 20
			local y = (row - 0.5) * 10
			createPart(wallFolder, "WW_" .. row .. "_" .. col, Vector3.new(6, 10, 20), CFrame.new(-130, y, z), wallCol, Enum.Material.WoodPlanks)
		end
	end
	createPart(wallFolder, "WW_Trim", Vector3.new(8, 3, 262), CFrame.new(-130, 41.5, 25), Color3.fromRGB(115, 204, 76), Enum.Material.Grass)

	-- East Wall (Right side)
	for row = 1, 4 do
		for col = 1, 13 do
			local wallCol = if (row + col) % 2 == 0 then c1 else c2
			local z = 155 - (col - 0.5) * 20
			local y = (row - 0.5) * 10
			createPart(wallFolder, "EW_" .. row .. "_" .. col, Vector3.new(6, 10, 20), CFrame.new(130, y, z), wallCol, Enum.Material.WoodPlanks)
		end
	end
	createPart(wallFolder, "EW_Trim", Vector3.new(8, 3, 262), CFrame.new(130, 41.5, 25), Color3.fromRGB(115, 204, 76), Enum.Material.Grass)

	-- 2. HUB SPAWN LOCATION
	local existingSpawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if existingSpawn then existingSpawn:Destroy() end
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "HubSpawn"
	spawnLoc.Size = Vector3.new(16, 1.2, 16)
	spawnLoc.CFrame = CFrame.new(0, 1.2, 115)
	spawnLoc.Anchored = true
	spawnLoc.Color = Color3.fromRGB(56, 189, 248)
	spawnLoc.Material = Enum.Material.Neon
	spawnLoc.Parent = hubFolder
	addBillboardText(spawnLoc, "🏎️ ONE SPEED CAR", "RUN ON TREADMILLS • RACE THE TSUNAMI SPEEDWAY!", Color3.fromRGB(255, 235, 60), Vector3.new(0, 7, 0), Vector2.new(18, 4.5))

	-- 3. 3D PHYSICAL LEADERBOARDS ON SOUTH WALL DIRECTLY BEHIND SPAWN
	local lbFolder = Instance.new("Folder")
	lbFolder.Name = "PhysicalLeaderboards"
	lbFolder.Parent = hubFolder

	-- Left board: TOP SPEED (facing North)
	buildPhysicalLeaderboard(lbFolder, "⚡ TOP SPEED", "Speed", CFrame.new(-32, 16, 151), Color3.fromRGB(56, 189, 248))
	-- Center board: TOP WINS (facing North)
	buildPhysicalLeaderboard(lbFolder, "🏆 MOST WINS", "Wins", CFrame.new(0, 16, 151), Color3.fromRGB(255, 215, 0))
	-- Right board: TOP REBIRTHS (facing North)
	buildPhysicalLeaderboard(lbFolder, "🔄 MOST REBIRTHS", "Rebirths", CFrame.new(32, 16, 151), Color3.fromRGB(220, 70, 240))

	-- 4. THE 5 FLAGSHIP TREADMILLS (Photo 1)
	local treadmillsFolder = Instance.new("Folder")
	treadmillsFolder.Name = "Treadmills"
	treadmillsFolder.Parent = world

	local tms = {
		{ id = 1, name = "1. Wooden Runner", color = Color3.fromRGB(165, 105, 55), accentColor = Color3.fromRGB(220, 170, 110), speedGain = 1, rebirthReq = 0, beltSpeed = 14, material = Enum.Material.WoodPlanks },
		{ id = 2, name = "2. Golden Spark", color = Color3.fromRGB(255, 205, 25), accentColor = Color3.fromRGB(255, 242, 130), speedGain = 3, rebirthReq = 1, beltSpeed = 20, material = Enum.Material.Metal },
		{ id = 3, name = "3. Cyan Volt", color = Color3.fromRGB(0, 220, 245), accentColor = Color3.fromRGB(160, 248, 255), speedGain = 10, rebirthReq = 3, beltSpeed = 28, material = Enum.Material.Metal },
		{ id = 4, name = "4. Pink Candy Hyper", color = Color3.fromRGB(255, 75, 175), accentColor = Color3.fromRGB(255, 190, 235), speedGain = 30, rebirthReq = 5, beltSpeed = 36, material = Enum.Material.SmoothPlastic },
		{ id = 5, name = "5. Admin Red Surge", color = Color3.fromRGB(210, 25, 35), accentColor = Color3.fromRGB(255, 45, 45), speedGain = 100, rebirthReq = 7, beltSpeed = 46, material = Enum.Material.Neon },
	}

	-- Line them up side by side in the Western Training Zone (Image 1)
	for i, tmInfo in ipairs(tms) do
		local xPos = -95 + (i - 1) * 16.5
		local tmCF = CFrame.new(xPos, 1.4, 45) * CFrame.Angles(0, math.rad(180), 0)
		buildTreadmill(treadmillsFolder, tmInfo, tmCF)
	end

	-- 5. TIERED SUPERCAR SHOWROOM PEDESTALS (East side, Images 4 & 5)
	local showroomFolder = Instance.new("Folder")
	showroomFolder.Name = "CarShowcases"
	showroomFolder.Parent = world

	-- Tiered Platform steps
	createPart(showroomFolder, "ShowroomStep1", Vector3.new(28, 1.4, 150), CFrame.new(65, 0.7, 45), Color3.fromRGB(45, 48, 60), Enum.Material.SmoothPlastic)
	createPart(showroomFolder, "ShowroomStep2", Vector3.new(18, 2.8, 150), CFrame.new(88, 1.4, 45), Color3.fromRGB(35, 38, 48), Enum.Material.SmoothPlastic)

	for cId = 1, 6 do
		local zPos = 105 - (cId - 1) * 24.0
		local xPos = if cId <= 3 then 65 else 88
		local yPos = if cId <= 3 then 1.4 else 2.8
		buildSupercarPedestal(showroomFolder, cId, CFrame.new(xPos, yPos, zPos) * CFrame.Angles(0, math.rad(-90), 0))
	end

	-- 6. GRAND BUILDING FACADE & UNBLOCKED ENTRANCE TO STAGE 1 (Image 4)
	local buildingFolder = Instance.new("Folder")
	buildingFolder.Name = "BuildingFacade"
	buildingFolder.Parent = hubFolder

	-- Left Building Wing (X: -130 to -32.5 = 97.5 studs wide)
	createPart(buildingFolder, "WingLeft", Vector3.new(98, 52, 12), CFrame.new(-81, 26, -100), Color3.fromRGB(225, 185, 155), Enum.Material.Brick)
	createPart(buildingFolder, "RoofTrimL", Vector3.new(102, 4, 16), CFrame.new(-81, 52, -100), Color3.fromRGB(245, 240, 230), Enum.Material.SmoothPlastic)

	-- Right Building Wing (X: 32.5 to 130 = 97.5 studs wide)
	createPart(buildingFolder, "WingRight", Vector3.new(98, 52, 12), CFrame.new(81, 26, -100), Color3.fromRGB(225, 185, 155), Enum.Material.Brick)
	createPart(buildingFolder, "RoofTrimR", Vector3.new(102, 4, 16), CFrame.new(81, 52, -100), Color3.fromRGB(245, 240, 230), Enum.Material.SmoothPlastic)

	-- Archway Header spanning across top from Y = 36 to 52 (leaves a massive 64-stud wide × 36-stud high OPEN ENTRANCE!)
	createPart(buildingFolder, "ArchHeader", Vector3.new(68, 16, 12), CFrame.new(0, 44, -100), Color3.fromRGB(235, 195, 165), Enum.Material.Brick)
	createPart(buildingFolder, "RoofTrimMid", Vector3.new(72, 4, 16), CFrame.new(0, 52, -100), Color3.fromRGB(245, 240, 230), Enum.Material.SmoothPlastic)

	-- Windows on Left and Right wings
	for floor = 1, 3 do
		local yWin = 12 + (floor - 1) * 12
		for _, side in { -1, 1 } do
			for col = 1, 3 do
				local xWin = side * (45 + (col - 1) * 26)
				createPart(buildingFolder, "Win_" .. floor .. "_" .. side .. "_" .. col, Vector3.new(12, 7.5, 0.4), CFrame.new(xWin, yWin, -93.8), Color3.fromRGB(165, 225, 255), Enum.Material.Glass)
			end
		end
	end

	-- Giant Outlined 3D / Floating Text for STAGE 1 (Image 4) - High above open entrance!
	local stage1Sign = createPart(buildingFolder, "Stage1Sign", Vector3.new(46, 10, 1), CFrame.new(0, 36, -93), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic, false)
	stage1Sign.Transparency = 1
	local s1Bg = Instance.new("BillboardGui")
	s1Bg.Name = "Stage1Billboard"
	s1Bg.Adornee = stage1Sign
	s1Bg.Size = UDim2.fromScale(42, 14)
	s1Bg.StudsOffset = Vector3.new(0, 1, 0)
	s1Bg.AlwaysOnTop = false
	s1Bg.MaxDistance = 400
	s1Bg.Parent = stage1Sign

	local s1Title = Instance.new("TextLabel")
	s1Title.Size = UDim2.fromScale(1, 0.6)
	s1Title.BackgroundTransparency = 1
	s1Title.Text = "STAGE 1"
	s1Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	s1Title.TextStrokeColor3 = Color3.fromRGB(18, 32, 64)
	s1Title.TextStrokeTransparency = 0
	s1Title.Font = Enum.Font.FredokaOne
	s1Title.TextScaled = true
	s1Title.Parent = s1Bg

	local s1Sub = Instance.new("TextLabel")
	s1Sub.Position = UDim2.fromScale(0, 0.6)
	s1Sub.Size = UDim2.fromScale(1, 0.4)
	s1Sub.BackgroundTransparency = 1
	s1Sub.Text = "Recommended Level 1"
	s1Sub.TextColor3 = Color3.fromRGB(255, 255, 255)
	s1Sub.TextStrokeColor3 = Color3.fromRGB(18, 32, 64)
	s1Sub.TextStrokeTransparency = 0
	s1Sub.Font = Enum.Font.FredokaOne
	s1Sub.TextScaled = true
	s1Sub.Parent = s1Bg

	-- Roof STAGE 2 Sign (Image 4)
	local s2Sign = createPart(buildingFolder, "Stage2Sign", Vector3.new(30, 8, 1), CFrame.new(0, 58, -100), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic, false)
	s2Sign.Transparency = 1
	addBillboardText(s2Sign, "STAGE 2", "Recommended Level 5 • +2 WINS 🏆", Color3.fromRGB(255, 240, 60), Vector3.new(0, 2, 0), Vector2.new(30, 8))

	-- Direction Sign
	local dirSign = createPart(buildingFolder, "DirSign", Vector3.new(14, 4.5, 0.6), CFrame.new(24, 4.5, -88) * CFrame.Angles(0, math.rad(-15), 0), Color3.fromRGB(250, 235, 195), Enum.Material.WoodPlanks)
	addBillboardText(dirSign, "DRIVE FORWARD ⬆️", "ENTER STAGE 1 SPEEDWAY", Color3.fromRGB(20, 22, 28), Vector3.new(0, 0, 0), Vector2.new(14, 4))

	-- 7. THE 15 GIANT STAGES SPEEDWAY (Over 2,600 studs of thrilling racing!)
	local stagesFolder = Instance.new("Folder")
	stagesFolder.Name = "Stages"
	stagesFolder.Parent = world

	local trackWidth = 56
	local STAGE_DATA = {
		{ id = 1, name = "SPEEDWAY SPRINT", length = 150, color = Color3.fromRGB(0, 220, 255), reward = 1, hazardType = "sprint" },
		{ id = 2, name = "CANDY BOULDER RUSH", length = 160, color = Color3.fromRGB(255, 90, 160), reward = 2, hazardType = "boulder" },
		{ id = 3, name = "FOAMING TSUNAMI WAVE", length = 180, color = Color3.fromRGB(40, 160, 245), reward = 3, hazardType = "tsunami" },
		{ id = 4, name = "NEON NITRO BOOSTERS", length = 160, color = Color3.fromRGB(50, 230, 110), reward = 4, hazardType = "nitro" },
		{ id = 5, name = "LASER SWEEPER BEAMS", length = 160, color = Color3.fromRGB(245, 45, 55), reward = 5, hazardType = "laser" },
		{ id = 6, name = "GRAVITY INCLINE SPEEDWAY", length = 160, color = Color3.fromRGB(255, 200, 40), reward = 6, hazardType = "ramp" },
		{ id = 7, name = "MOLTEN LAVA TRACK", length = 160, color = Color3.fromRGB(255, 110, 30), reward = 7, hazardType = "lava" },
		{ id = 8, name = "TOXIC ACID CRUSHERS", length = 160, color = Color3.fromRGB(120, 245, 40), reward = 8, hazardType = "acid" },
		{ id = 9, name = "TWIN TSUNAMI SURGE", length = 180, color = Color3.fromRGB(20, 180, 240), reward = 9, hazardType = "twin_tsunami" },
		{ id = 10, name = "THUNDERBOLT HIGHWAY", length = 180, color = Color3.fromRGB(80, 220, 255), reward = 10, hazardType = "thunder" },
		{ id = 11, name = "CYBER GLITCH GRID", length = 180, color = Color3.fromRGB(180, 60, 240), reward = 12, hazardType = "cyber" },
		{ id = 12, name = "METEOR SHOWER SPEEDWAY", length = 180, color = Color3.fromRGB(245, 60, 40), reward = 15, hazardType = "meteor" },
		{ id = 13, name = "HYPER SONIC TUNNEL", length = 200, color = Color3.fromRGB(0, 245, 200), reward = 20, hazardType = "tunnel" },
		{ id = 14, name = "TITAN GAUNTLET", length = 200, color = Color3.fromRGB(255, 140, 50), reward = 25, hazardType = "pendulum" },
		{ id = 15, name = "GALAXY VOID FINALE", length = 260, color = Color3.fromRGB(255, 215, 0), reward = 50, hazardType = "galaxy_finale" },
	}

	local currentZ = -100 -- Entrance starts at Z = -100

	for stageIdx, stg in ipairs(STAGE_DATA) do
		local stageFolder = Instance.new("Folder")
		stageFolder.Name = "Stage_" .. tostring(stg.id)
		stageFolder.Parent = stagesFolder

		local segCenterZ = currentZ - stg.length / 2
		local segCF = CFrame.new(0, 1.2, segCenterZ)

		-- 1. Smooth asphalt track floor
		local floorMat = if stg.id == 15 then Enum.Material.Glass else (if stg.id % 2 == 0 then Enum.Material.Concrete else Enum.Material.SmoothPlastic)
		local floorColor = if stg.id == 15 then Color3.fromRGB(18, 14, 32) else Color3.fromRGB(34, 38, 48)
		local trackFloor = createPart(stageFolder, "TrackFloor", Vector3.new(trackWidth, 2.5, stg.length), segCF * CFrame.new(0, -1.25, 0), floorColor, floorMat)

		-- 2. Neon guide rails on both sides
		createPart(stageFolder, "RailL", Vector3.new(2.4, 3.5, stg.length), segCF * CFrame.new(-trackWidth / 2 - 1.2, 0.5, 0), stg.color, Enum.Material.Neon)
		createPart(stageFolder, "RailR", Vector3.new(2.4, 3.5, stg.length), segCF * CFrame.new(trackWidth / 2 + 1.2, 0.5, 0), stg.color, Enum.Material.Neon)

		-- 3. High brown checkerboard walls along speedway
		local wallMat = if stg.id == 15 then Enum.Material.SmoothPlastic else Enum.Material.WoodPlanks
		local wallCol = if stg.id == 15 then Color3.fromRGB(35, 24, 55) else Color3.fromRGB(150, 95, 60)
		createPart(stageFolder, "WallL", Vector3.new(4, 32, stg.length), segCF * CFrame.new(-trackWidth / 2 - 4, 15, 0), wallCol, wallMat)
		createPart(stageFolder, "WallR", Vector3.new(4, 32, stg.length), segCF * CFrame.new(trackWidth / 2 + 4, 15, 0), wallCol, wallMat)

		-- 4. Overhead Gateway Arch at Stage Entrance
		local archZ = currentZ - 2
		local archModel = Instance.new("Model")
		archModel.Name = "GatewayArch"
		archModel.Parent = stageFolder

		createPart(archModel, "PillarL", Vector3.new(4, 28, 4), CFrame.new(-trackWidth / 2 - 1, 14, archZ), stg.color, Enum.Material.Neon)
		createPart(archModel, "PillarR", Vector3.new(4, 28, 4), CFrame.new(trackWidth / 2 + 1, 14, archZ), stg.color, Enum.Material.Neon)
		createPart(archModel, "Beam", Vector3.new(trackWidth + 8, 4.5, 4.5), CFrame.new(0, 27, archZ), Color3.fromRGB(24, 26, 36), Enum.Material.SmoothPlastic)

		local gateSign = createPart(archModel, "SignPart", Vector3.new(44, 9, 1), CFrame.new(0, 27, archZ + 2.5), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic, false)
		gateSign.Transparency = 1
		local bg = Instance.new("BillboardGui")
		bg.Name = "GatewayBillboard"
		bg.Adornee = gateSign
		bg.Size = UDim2.fromScale(36, 8)
		bg.AlwaysOnTop = false
		bg.MaxDistance = 350
		bg.Parent = gateSign

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.fromScale(1, 0.6)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = string.format("STAGE %d • %s", stg.id, stg.name)
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.TextStrokeColor3 = Color3.fromRGB(15, 18, 25)
		titleLbl.TextStrokeTransparency = 0
		titleLbl.Font = Enum.Font.FredokaOne
		titleLbl.TextScaled = true
		titleLbl.Parent = bg

		local subLbl = Instance.new("TextLabel")
		subLbl.Position = UDim2.fromScale(0, 0.6)
		subLbl.Size = UDim2.fromScale(1, 0.4)
		subLbl.BackgroundTransparency = 1
		subLbl.Text = string.format("🏆 +%d WINS • KEEP DRIVING FORWARD OR TAKE SIDE EXIT!", stg.reward)
		subLbl.TextColor3 = stg.color
		subLbl.TextStrokeColor3 = Color3.fromRGB(15, 18, 25)
		subLbl.TextStrokeTransparency = 0
		subLbl.Font = Enum.Font.FredokaOne
		subLbl.TextScaled = true
		subLbl.Parent = bg

		-- 5. SIDE VICTORY FINISH BAY (Placed on LEFT or RIGHT side, NEVER IN CENTER!)
		-- Player can take side exit to claim win & return to hub, OR stay in center to keep racing forward!
		local sideSign = if stg.id % 2 == 0 then -1 else 1
		local bayX = sideSign * (trackWidth / 2 + 15)
		local bayZ = currentZ - stg.length + 18

		local bayModel = Instance.new("Model")
		bayModel.Name = "SideVictoryBay"
		bayModel.Parent = stageFolder

		-- Side Bay Platform Floor
		createPart(bayModel, "BayFloor", Vector3.new(24, 2.5, 30), CFrame.new(bayX, 0, bayZ), Color3.fromRGB(30, 34, 46), Enum.Material.SmoothPlastic)
		createPart(bayModel, "BayTrim", Vector3.new(24.8, 0.4, 30.8), CFrame.new(bayX, 1.3, bayZ), stg.color, Enum.Material.Neon)

		-- Yellow Studded Finish Pad (Photo 3)
		createPart(bayModel, "BaseBlock", Vector3.new(16, 1.4, 16), CFrame.new(bayX, 1.9, bayZ), Color3.fromRGB(22, 22, 26), Enum.Material.SmoothPlastic)
		local winPad = createPart(bayModel, "WinPad", Vector3.new(13.5, 1.6, 13.5), CFrame.new(bayX, 3.2, bayZ), Color3.fromRGB(255, 235, 0), Enum.Material.Plastic)
		winPad.TopSurface = Enum.SurfaceType.Studs
		winPad:SetAttribute("IsWinPad", true)
		winPad:SetAttribute("StageId", stg.id)
		winPad:SetAttribute("WinReward", stg.reward)

		-- Floating Billboard: "+X Wins 🏆" (Photo 3)
		local winBg = Instance.new("BillboardGui")
		winBg.Name = "WinBillboard"
		winBg.Adornee = winPad
		winBg.Size = UDim2.fromScale(12, 4.5)
		winBg.StudsOffset = Vector3.new(0, 6.5, 0)
		winBg.AlwaysOnTop = false
		winBg.MaxDistance = 220
		winBg.Parent = winPad

		local wLbl = Instance.new("TextLabel")
		wLbl.Size = UDim2.fromScale(1, 1)
		wLbl.BackgroundTransparency = 1
		wLbl.Text = string.format("+%d Win%s 🏆", stg.reward, if stg.reward > 1 then "s" else "")
		wLbl.TextColor3 = Color3.fromRGB(255, 240, 60)
		wLbl.TextStrokeColor3 = Color3.fromRGB(18, 20, 25)
		wLbl.TextStrokeTransparency = 0
		wLbl.Font = Enum.Font.FredokaOne
		wLbl.TextScaled = true
		wLbl.Parent = winBg

		-- Confetti celebration particles on win pad
		local cP = Instance.new("ParticleEmitter")
		cP.Name = "Confetti"
		cP.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 160)),
			ColorSequenceKeypoint.new(1, stg.color),
		})
		cP.Rate = 25
		cP.Speed = NumberRange.new(14, 24)
		cP.SpreadAngle = Vector2.new(45, 45)
		cP.Lifetime = NumberRange.new(1.0, 1.8)
		cP.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0.3) })
		cP.Parent = winPad

		-- Neon Beacon
		local beacon = createPart(bayModel, "Beacon", Vector3.new(3, 3, 3), CFrame.new(bayX, 9, bayZ), stg.color, Enum.Material.Neon)
		beacon.Shape = Enum.PartType.Ball

		-- 6. STAGE HAZARDS & UNIQUE ARCHITECTURE
		if stg.hazardType == "boulder" then
			local b1 = createPart(stageFolder, "RollingCandyBoulder_1", Vector3.new(16, 16, 16), CFrame.new(-14, 9, currentZ - 50), Color3.fromRGB(245, 75, 120), Enum.Material.SmoothPlastic, true)
			b1.Shape = Enum.PartType.Ball
			b1:SetAttribute("Hazard", true)
			local b2 = createPart(stageFolder, "RollingCandyBoulder_2", Vector3.new(16, 16, 16), CFrame.new(14, 9, currentZ - 110), Color3.fromRGB(255, 140, 40), Enum.Material.SmoothPlastic, true)
			b2.Shape = Enum.PartType.Ball
			b2:SetAttribute("Hazard", true)

		elseif stg.hazardType == "tsunami" or stg.hazardType == "twin_tsunami" then
			-- 45-Stud Colossal Foaming Tsunami Wave
			local tsunami = createPart(stageFolder, "TsunamiWave", Vector3.new(trackWidth + 6, 48, 18), CFrame.new(0, 24, currentZ - 90), Color3.fromRGB(30, 160, 230), Enum.Material.Glass, true)
			tsunami.Transparency = 0.32
			tsunami:SetAttribute("Hazard", true)
			tsunami:SetAttribute("BaseStartZ", currentZ - stg.length + 30)
			tsunami:SetAttribute("BaseEndZ", currentZ - 20)
			createPart(stageFolder, "WaveCrest", Vector3.new(trackWidth + 8, 5, 8), CFrame.new(0, 47, currentZ - 90), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, false)

			-- Safe gaps on sides
			for _, side in { -1, 1 } do
				createPart(stageFolder, "SafeBay_" .. side, Vector3.new(22, 2.5, 36), CFrame.new(side * (trackWidth / 2 + 14), 0, currentZ - 90), Color3.fromRGB(34, 197, 94), Enum.Material.Neon)
			end

		elseif stg.hazardType == "nitro" then
			-- Neon green nitro booster strips
			for nb = 1, 3 do
				local nitroStrip = createPart(stageFolder, "NitroBooster_" .. nb, Vector3.new(22, 0.4, 18), CFrame.new(0, 1.4, currentZ - 35 * nb), Color3.fromRGB(45, 245, 95), Enum.Material.Neon, false)
				nitroStrip.AssemblyLinearVelocity = Vector3.new(0, 0, -180)
				nitroStrip:SetAttribute("Nitro", true)
			end

		elseif stg.hazardType == "laser" then
			-- Spinning Laser Sweeper
			local laserBase = createPart(stageFolder, "LaserCenter", Vector3.new(4, 8, 4), CFrame.new(0, 4, currentZ - 80), Color3.fromRGB(25, 25, 30), Enum.Material.Metal)
			local laserBeam = createPart(stageFolder, "LaserBeam", Vector3.new(trackWidth + 4, 1.4, 1.4), CFrame.new(0, 3.5, currentZ - 80), Color3.fromRGB(255, 35, 45), Enum.Material.Neon, true)
			laserBeam:SetAttribute("Hazard", true)

		elseif stg.hazardType == "lava" then
			-- Molten lava fissures
			for lf = 1, 4 do
				local lavaPart = createPart(stageFolder, "LavaCrack_" .. lf, Vector3.new(trackWidth - 4, 0.6, 12), CFrame.new(0, 1.3, currentZ - 35 * lf), Color3.fromRGB(255, 95, 20), Enum.Material.Neon, true)
				lavaPart:SetAttribute("Hazard", true)
			end

		elseif stg.hazardType == "galaxy_finale" then
			-- Grand Stage 15 Finale Plaza at the end of the speedway!
			local finishZ = currentZ - stg.length + 25
			local grandPodium = Instance.new("Model")
			grandPodium.Name = "GrandFinalePodium"
			grandPodium.Parent = stageFolder

			-- Giant Golden Trophy on rotating pedestal
			createPart(grandPodium, "PodiumRing", Vector3.new(38, 2.5, 38), CFrame.new(0, 2, finishZ), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
			local grandWinPad = createPart(grandPodium, "WinPad", Vector3.new(28, 2.0, 28), CFrame.new(0, 4, finishZ), Color3.fromRGB(255, 235, 0), Enum.Material.Plastic)
			grandWinPad.TopSurface = Enum.SurfaceType.Studs
			grandWinPad:SetAttribute("IsWinPad", true)
			grandWinPad:SetAttribute("StageId", 15)
			grandWinPad:SetAttribute("WinReward", 50)

			-- Colossal Trophy Billboard
			local grandBg = Instance.new("BillboardGui")
			grandBg.Name = "GrandBillboard"
			grandBg.Adornee = grandWinPad
			grandBg.Size = UDim2.fromScale(26, 8)
			grandBg.StudsOffset = Vector3.new(0, 10, 0)
			grandBg.AlwaysOnTop = false
			grandBg.MaxDistance = 450
			grandBg.Parent = grandWinPad

			local gText = Instance.new("TextLabel")
			gText.Size = UDim2.fromScale(1, 1)
			gText.BackgroundTransparency = 1
			gText.Text = "👑 GRAND FINALE • +50 WINS 🏆"
			gText.TextColor3 = Color3.fromRGB(255, 235, 60)
			gText.TextStrokeColor3 = Color3.fromRGB(15, 18, 25)
			gText.TextStrokeTransparency = 0
			gText.Font = Enum.Font.FredokaOne
			gText.TextScaled = true
			gText.Parent = grandBg
		end

		currentZ = currentZ - stg.length
	end

	return world
end

return WorldBuilder
