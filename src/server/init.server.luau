local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarConfig = require(ReplicatedStorage.Shared.CarConfig)
local RaceConfig = require(ReplicatedStorage.Shared.RaceConfig)

-- Setup collision groups so cars don't collide with each other or with players
pcall(function()
	PhysicsService:RegisterCollisionGroup("Cars")
end)
pcall(function()
	PhysicsService:RegisterCollisionGroup("Players")
end)
PhysicsService:CollisionGroupSetCollidable("Cars", "Cars", false)
PhysicsService:CollisionGroupSetCollidable("Cars", "Players", false)
PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)

-------------------------------------------------
-- Remote Events
-------------------------------------------------
local function createRemote(name: string, className: string)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then return existing end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local RaceUpdateEvent = createRemote("RaceUpdateEvent", "RemoteEvent")
local CountdownEvent = createRemote("CountdownEvent", "RemoteEvent")
local SpeedUpdateEvent = createRemote("SpeedUpdateEvent", "RemoteEvent")
local RespawnEvent = createRemote("RespawnRequestEvent", "RemoteEvent")
local CarSelectEvent = createRemote("CarSelectEvent", "RemoteEvent")
local BoostEvent = createRemote("BoostEvent", "RemoteEvent")
local SoundEvent = createRemote("SoundEvent", "RemoteEvent")
local CrashEvent = createRemote("CrashEvent", "RemoteEvent")
local CrashResponseEvent = createRemote("CrashResponseEvent", "RemoteEvent")
local FlyEvent = createRemote("FlyEvent", "RemoteEvent")

-------------------------------------------------
-- Track Builder
-------------------------------------------------
-- Clean up old instances on hot-reload
if workspace:FindFirstChild("Track") then workspace.Track:Destroy() end
if workspace:FindFirstChild("Cars") then workspace.Cars:Destroy() end
if workspace:FindFirstChild("Clouds") then workspace.Clouds:Destroy() end
if workspace:FindFirstChild("Birds") then workspace.Birds:Destroy() end
if workspace:FindFirstChild("SkyBarriers") then workspace.SkyBarriers:Destroy() end

local trackFolder = Instance.new("Folder")
trackFolder.Name = "Track"
trackFolder.Parent = workspace

local checkpointsFolder = Instance.new("Folder")
checkpointsFolder.Name = "Checkpoints"
checkpointsFolder.Parent = trackFolder

local boostPadsFolder = Instance.new("Folder")
boostPadsFolder.Name = "BoostPads"
boostPadsFolder.Parent = trackFolder

-- Track shape: oval circuit defined by waypoints
local trackPoints = {
	-- Straight 1
	Vector3.new(0, 0, 0),
	Vector3.new(0, 0, -100),
	Vector3.new(0, 0, -200),
	-- Turn 1
	Vector3.new(30, 0, -250),
	Vector3.new(80, 0, -270),
	Vector3.new(130, 0, -250),
	-- Straight 2
	Vector3.new(160, 0, -200),
	Vector3.new(160, 0, -100),
	Vector3.new(160, 0, 0),
	-- Turn 2
	Vector3.new(130, 0, 50),
	Vector3.new(80, 0, 70),
	Vector3.new(30, 0, 50),
}

local function createPart(props: {[string]: any}): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		if key ~= "Parent" then
			(part :: any)[key] = value
		end
	end
	part.Parent = props.Parent or trackFolder
	return part
end

-- Build road segments between track points
local function buildTrack()
	local trackWidth = RaceConfig.TrackWidth
	local wallHeight = RaceConfig.WallHeight
	local wallThickness = RaceConfig.WallThickness
	local boostSegments = {}
	for _, seg in RaceConfig.BoostPadSegments do
		boostSegments[seg] = true
	end

	for i = 1, #trackPoints do
		local p1 = trackPoints[i]
		local p2 = trackPoints[(i % #trackPoints) + 1]

		local mid = (p1 + p2) / 2
		local diff = p2 - p1
		local length = diff.Magnitude
		local direction = diff.Unit

		-- Road surface
		createPart({
			Name = "Road_" .. i,
			Size = Vector3.new(trackWidth, 1, length),
			CFrame = CFrame.lookAt(mid + Vector3.new(0, -0.5, 0), mid + Vector3.new(0, -0.5, 0) + direction),
			Color = Color3.fromRGB(50, 50, 50),
			Material = Enum.Material.Asphalt,
		})

		-- Left wall
		local leftOffset = CFrame.lookAt(Vector3.zero, direction) * CFrame.new(-trackWidth / 2 - wallThickness / 2, 0, 0)
		local leftPos = mid + leftOffset.Position + Vector3.new(0, wallHeight / 2, 0)
		createPart({
			Name = "WallL_" .. i,
			Size = Vector3.new(wallThickness, wallHeight, length),
			CFrame = CFrame.lookAt(leftPos, leftPos + direction),
			Color = Color3.fromRGB(200, 200, 200),
			Material = Enum.Material.Concrete,
		})

		-- Right wall
		local rightOffset = CFrame.lookAt(Vector3.zero, direction) * CFrame.new(trackWidth / 2 + wallThickness / 2, 0, 0)
		local rightPos = mid + rightOffset.Position + Vector3.new(0, wallHeight / 2, 0)
		createPart({
			Name = "WallR_" .. i,
			Size = Vector3.new(wallThickness, wallHeight, length),
			CFrame = CFrame.lookAt(rightPos, rightPos + direction),
			Color = Color3.fromRGB(200, 200, 200),
			Material = Enum.Material.Concrete,
		})

		-- Checkpoints (invisible triggers)
		local checkpoint = Instance.new("Part")
		checkpoint.Name = "Checkpoint_" .. i
		checkpoint.Size = Vector3.new(trackWidth, 10, 3)
		checkpoint.CFrame = CFrame.lookAt(mid + Vector3.new(0, 4, 0), mid + Vector3.new(0, 4, 0) + direction)
		checkpoint.Anchored = true
		checkpoint.CanCollide = false
		checkpoint.Transparency = 1
		checkpoint.Parent = checkpointsFolder

		local index = Instance.new("IntValue")
		index.Name = "Index"
		index.Value = i
		index.Parent = checkpoint

		-- Boost pads on specific segments
		if boostSegments[i] then
			local boostPad = Instance.new("Part")
			boostPad.Name = "BoostPad_" .. i
			boostPad.Size = RaceConfig.BoostPadSize
			boostPad.CFrame = CFrame.lookAt(mid + Vector3.new(0, 0.2, 0), mid + Vector3.new(0, 0.2, 0) + direction)
			boostPad.Anchored = true
			boostPad.CanCollide = false
			boostPad.Color = Color3.fromRGB(0, 200, 255)
			boostPad.Material = Enum.Material.Neon
			boostPad.Transparency = 0.3
			boostPad.Parent = boostPadsFolder

			-- Arrow decals to show boost direction (using a bright stripe)
			local arrow1 = Instance.new("Part")
			arrow1.Name = "BoostArrow"
			arrow1.Size = Vector3.new(2, 0.35, 1)
			arrow1.CFrame = boostPad.CFrame * CFrame.new(0, 0.1, -2)
			arrow1.Anchored = true
			arrow1.CanCollide = false
			arrow1.Color = Color3.fromRGB(255, 255, 0)
			arrow1.Material = Enum.Material.Neon
			arrow1.Parent = boostPadsFolder

			local arrow2 = Instance.new("Part")
			arrow2.Name = "BoostArrow"
			arrow2.Size = Vector3.new(2, 0.35, 1)
			arrow2.CFrame = boostPad.CFrame * CFrame.new(0, 0.1, 0)
			arrow2.Anchored = true
			arrow2.CanCollide = false
			arrow2.Color = Color3.fromRGB(255, 255, 0)
			arrow2.Material = Enum.Material.Neon
			arrow2.Parent = boostPadsFolder

			local arrow3 = Instance.new("Part")
			arrow3.Name = "BoostArrow"
			arrow3.Size = Vector3.new(2, 0.35, 1)
			arrow3.CFrame = boostPad.CFrame * CFrame.new(0, 0.1, 2)
			arrow3.Anchored = true
			arrow3.CanCollide = false
			arrow3.Color = Color3.fromRGB(255, 255, 0)
			arrow3.Material = Enum.Material.Neon
			arrow3.Parent = boostPadsFolder
		end
	end

	-- Start/Finish line visual
	local startPos = trackPoints[1]
	local startDir = (trackPoints[2] - trackPoints[1]).Unit
	createPart({
		Name = "StartLine",
		Size = Vector3.new(trackWidth, 0.2, 3),
		CFrame = CFrame.lookAt(startPos + Vector3.new(0, 0.1, 0), startPos + Vector3.new(0, 0.1, 0) + startDir),
		Color = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.Neon,
	})

	-- Spawn platform (lobby area)
	createPart({
		Name = "SpawnPlatform",
		Size = Vector3.new(60, 1, 60),
		Position = Vector3.new(80, -0.5, 100),
		Color = Color3.fromRGB(80, 80, 80),
		Material = Enum.Material.Concrete,
	})
end

buildTrack()

-------------------------------------------------
-- Sky, Clouds & Birds
-------------------------------------------------
local Lighting = game:GetService("Lighting")

-- Sky atmosphere
local sky = Instance.new("Sky")
sky.SunAngularSize = 15
sky.MoonAngularSize = 10
sky.StarCount = 0
sky.CelestialBodiesShown = true
sky.Parent = Lighting

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.25
atmosphere.Color = Color3.fromRGB(199, 216, 238)
atmosphere.Decay = Color3.fromRGB(92, 120, 176)
atmosphere.Glare = 0.3
atmosphere.Haze = 1.5
atmosphere.Parent = Lighting

-- Clouds
local clouds = Instance.new("Clouds")
clouds.Cover = 0.55
clouds.Density = 0.3
clouds.Color = Color3.fromRGB(230, 235, 245)
clouds.Parent = workspace.Terrain

-- Cloud parts (floating white parts for extra visual depth)
local cloudsFolder = Instance.new("Folder")
cloudsFolder.Name = "Clouds"
cloudsFolder.Parent = workspace

local function createCloud(position: Vector3, size: Vector3)
	local cloud = Instance.new("Part")
	cloud.Name = "Cloud"
	cloud.Size = size
	cloud.Position = position
	cloud.Anchored = true
	cloud.CanCollide = false
	cloud.Color = Color3.fromRGB(245, 248, 255)
	cloud.Material = Enum.Material.SmoothPlastic
	cloud.Transparency = 0.4
	cloud.Shape = Enum.PartType.Ball
	cloud.CastShadow = false
	cloud.Parent = cloudsFolder
	return cloud
end

-- Scatter clouds across the sky above the track
local cloudPositions = {
	{ pos = Vector3.new(30, 120, -50), size = Vector3.new(60, 20, 40) },
	{ pos = Vector3.new(120, 140, -180), size = Vector3.new(80, 25, 50) },
	{ pos = Vector3.new(-20, 110, -250), size = Vector3.new(50, 18, 35) },
	{ pos = Vector3.new(180, 130, -100), size = Vector3.new(70, 22, 45) },
	{ pos = Vector3.new(80, 150, 30), size = Vector3.new(90, 28, 55) },
	{ pos = Vector3.new(50, 115, -150), size = Vector3.new(55, 16, 38) },
	{ pos = Vector3.new(140, 125, 20), size = Vector3.new(65, 20, 42) },
	{ pos = Vector3.new(-10, 135, -30), size = Vector3.new(75, 24, 48) },
}

-- Each cloud is a cluster of overlapping spheres
for _, cloudData in cloudPositions do
	local base = cloudData.pos
	local baseSize = cloudData.size
	-- Main body
	createCloud(base, baseSize)
	-- Side puffs
	createCloud(base + Vector3.new(baseSize.X * 0.4, -3, 5), baseSize * 0.7)
	createCloud(base + Vector3.new(-baseSize.X * 0.3, -2, -5), baseSize * 0.6)
	createCloud(base + Vector3.new(baseSize.X * 0.1, 4, -8), baseSize * 0.5)
end

-- Slowly drift clouds
task.spawn(function()
	while true do
		for _, cloud in cloudsFolder:GetChildren() do
			cloud.Position += Vector3.new(0.05, 0, 0.02)
			-- Wrap clouds around when they drift too far
			if cloud.Position.X > 300 then
				cloud.Position = Vector3.new(-100, cloud.Position.Y, cloud.Position.Z)
			end
		end
		task.wait(0.1)
	end
end)

-- Birds
local birdsFolder = Instance.new("Folder")
birdsFolder.Name = "Birds"
birdsFolder.Parent = workspace

local function createBird(startPosition: Vector3): Model
	local bird = Instance.new("Model")
	bird.Name = "Bird"

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1, 0.6, 1.5)
	body.Position = startPosition
	body.Anchored = true
	body.CanCollide = false
	body.Color = Color3.fromRGB(40, 40, 40)
	body.Material = Enum.Material.SmoothPlastic
	body.CastShadow = false
	body.Parent = bird

	-- Left wing
	local leftWing = Instance.new("Part")
	leftWing.Name = "LeftWing"
	leftWing.Size = Vector3.new(2.5, 0.15, 1.2)
	leftWing.Anchored = true
	leftWing.CanCollide = false
	leftWing.Color = Color3.fromRGB(30, 30, 30)
	leftWing.Material = Enum.Material.SmoothPlastic
	leftWing.CastShadow = false
	leftWing.Parent = bird
	leftWing.CFrame = body.CFrame * CFrame.new(-1.5, 0.2, 0)

	-- Right wing
	local rightWing = Instance.new("Part")
	rightWing.Name = "RightWing"
	rightWing.Size = Vector3.new(2.5, 0.15, 1.2)
	rightWing.Anchored = true
	rightWing.CanCollide = false
	rightWing.Color = Color3.fromRGB(30, 30, 30)
	rightWing.Material = Enum.Material.SmoothPlastic
	rightWing.CastShadow = false
	rightWing.Parent = bird
	rightWing.CFrame = body.CFrame * CFrame.new(1.5, 0.2, 0)

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(0.6, 0.6, 0.6)
	head.Anchored = true
	head.CanCollide = false
	head.Color = Color3.fromRGB(40, 40, 40)
	head.Material = Enum.Material.SmoothPlastic
	head.CastShadow = false
	head.Parent = bird
	head.CFrame = body.CFrame * CFrame.new(0, 0.2, -0.9)

	bird.PrimaryPart = body
	bird.Parent = birdsFolder

	return bird
end

-- Spawn several birds at different heights and positions
local birdData = {
	{ pos = Vector3.new(50, 80, -100), speed = 8, radius = 80 },
	{ pos = Vector3.new(100, 90, -200), speed = 6, radius = 60 },
	{ pos = Vector3.new(30, 70, -50), speed = 10, radius = 90 },
	{ pos = Vector3.new(150, 85, -150), speed = 7, radius = 70 },
	{ pos = Vector3.new(80, 95, 0), speed = 9, radius = 100 },
	{ pos = Vector3.new(60, 75, -220), speed = 5, radius = 50 },
}

local birds = {}
for _, data in birdData do
	local bird = createBird(data.pos)
	table.insert(birds, {
		model = bird,
		center = data.pos,
		speed = data.speed,
		radius = data.radius,
		angle = math.random() * math.pi * 2,
		wingAngle = 0,
		wingSpeed = 3 + math.random() * 2,
	})
end

-- Animate birds: fly in circles + flap wings
task.spawn(function()
	while true do
		local dt = task.wait(0.03)
		for _, birdInfo in birds do
			local bird = birdInfo.model
			if not bird or not bird.PrimaryPart then continue end

			-- Circular flight path
			birdInfo.angle += dt * birdInfo.speed * 0.02
			local x = birdInfo.center.X + math.cos(birdInfo.angle) * birdInfo.radius
			local z = birdInfo.center.Z + math.sin(birdInfo.angle) * birdInfo.radius
			local y = birdInfo.center.Y + math.sin(birdInfo.angle * 2) * 5 -- gentle up/down

			-- Face the direction of flight
			local nextX = birdInfo.center.X + math.cos(birdInfo.angle + 0.1) * birdInfo.radius
			local nextZ = birdInfo.center.Z + math.sin(birdInfo.angle + 0.1) * birdInfo.radius
			local lookTarget = Vector3.new(nextX, y, nextZ)
			local currentPos = Vector3.new(x, y, z)

			local bodyCF = CFrame.lookAt(currentPos, lookTarget)
			bird:PivotTo(bodyCF)

			-- Wing flapping
			birdInfo.wingAngle += dt * birdInfo.wingSpeed
			local flapAngle = math.sin(birdInfo.wingAngle * 5) * 25 -- degrees

			local leftWing = bird:FindFirstChild("LeftWing")
			local rightWing = bird:FindFirstChild("RightWing")
			if leftWing then
				leftWing.CFrame = bodyCF * CFrame.new(-1.5, 0.2, 0) * CFrame.Angles(0, 0, math.rad(flapAngle))
			end
			if rightWing then
				rightWing.CFrame = bodyCF * CFrame.new(1.5, 0.2, 0) * CFrame.Angles(0, 0, math.rad(-flapAngle))
			end
		end
	end
end)

-------------------------------------------------
-- Sky Barriers (hoverable rings and obstacles)
-------------------------------------------------
local skyBarriersFolder = Instance.new("Folder")
skyBarriersFolder.Name = "SkyBarriers"
skyBarriersFolder.Parent = workspace

-- Hoverable ring the player can fly through
local function createRing(position: Vector3, rotation: CFrame, ringColor: Color3, radius: number)
	local ringModel = Instance.new("Model")
	ringModel.Name = "SkyRing"

	-- Build the ring from segments (curved arch of parts)
	local segments = 16
	for i = 1, segments do
		local angle = (i / segments) * math.pi * 2
		local x = math.cos(angle) * radius
		local y = math.sin(angle) * radius

		local segment = Instance.new("Part")
		segment.Name = "RingSegment"
		segment.Size = Vector3.new(2, 2, 2)
		segment.Shape = Enum.PartType.Ball
		segment.Anchored = true
		segment.CanCollide = false
		segment.Color = ringColor
		segment.Material = Enum.Material.Neon
		segment.Transparency = 0.2
		segment.CastShadow = false

		local localPos = Vector3.new(x, y, 0)
		segment.CFrame = CFrame.new(position) * rotation * CFrame.new(localPos)
		segment.Parent = ringModel
	end

	-- Inner glow part (transparent center marker)
	local center = Instance.new("Part")
	center.Name = "RingCenter"
	center.Size = Vector3.new(radius * 2, radius * 2, 2)
	center.Anchored = true
	center.CanCollide = false
	center.Transparency = 0.85
	center.Color = ringColor
	center.Material = Enum.Material.ForceField
	center.CastShadow = false
	center.CFrame = CFrame.new(position) * rotation
	center.Parent = ringModel

	ringModel.Parent = skyBarriersFolder
	return ringModel
end

-- Floating barrier wall with a gap to fly through
local function createBarrierWall(position: Vector3, gapHeight: number, gapWidth: number, wallWidth: number, wallColor: Color3)
	local barrierModel = Instance.new("Model")
	barrierModel.Name = "SkyBarrier"

	local wallHeight = 40
	local totalWidth = wallWidth

	-- Left section (solid)
	local leftWidth = (totalWidth - gapWidth) / 2
	if leftWidth > 0 then
		local left = Instance.new("Part")
		left.Name = "BarrierLeft"
		left.Size = Vector3.new(leftWidth, wallHeight, 3)
		left.Position = position + Vector3.new(-gapWidth / 2 - leftWidth / 2, 0, 0)
		left.Anchored = true
		left.CanCollide = false
		left.Color = wallColor
		left.Material = Enum.Material.ForceField
		left.Transparency = 0.5
		left.CastShadow = false
		left.Parent = barrierModel
	end

	-- Right section (solid)
	local rightWidth = leftWidth
	if rightWidth > 0 then
		local right = Instance.new("Part")
		right.Name = "BarrierRight"
		right.Size = Vector3.new(rightWidth, wallHeight, 3)
		right.Position = position + Vector3.new(gapWidth / 2 + rightWidth / 2, 0, 0)
		right.Anchored = true
		right.CanCollide = false
		right.Color = wallColor
		right.Material = Enum.Material.ForceField
		right.Transparency = 0.5
		right.CastShadow = false
		right.Parent = barrierModel
	end

	-- Top section (above the gap)
	local topHeight = (wallHeight - gapHeight) / 2
	if topHeight > 0 then
		local top = Instance.new("Part")
		top.Name = "BarrierTop"
		top.Size = Vector3.new(gapWidth, topHeight, 3)
		top.Position = position + Vector3.new(0, gapHeight / 2 + topHeight / 2, 0)
		top.Anchored = true
		top.CanCollide = false
		top.Color = wallColor
		top.Material = Enum.Material.ForceField
		top.Transparency = 0.5
		top.CastShadow = false
		top.Parent = barrierModel
	end

	-- Bottom section (below the gap)
	if topHeight > 0 then
		local bottom = Instance.new("Part")
		bottom.Name = "BarrierBottom"
		bottom.Size = Vector3.new(gapWidth, topHeight, 3)
		bottom.Position = position + Vector3.new(0, -gapHeight / 2 - topHeight / 2, 0)
		bottom.Anchored = true
		bottom.CanCollide = false
		bottom.Color = wallColor
		bottom.Material = Enum.Material.ForceField
		bottom.Transparency = 0.5
		bottom.CastShadow = false
		bottom.Parent = barrierModel
	end

	-- Glowing border around the gap (guide for the player)
	local borderParts = {
		{ size = Vector3.new(gapWidth, 1, 1), offset = Vector3.new(0, gapHeight / 2, 0) },  -- top edge
		{ size = Vector3.new(gapWidth, 1, 1), offset = Vector3.new(0, -gapHeight / 2, 0) }, -- bottom edge
		{ size = Vector3.new(1, gapHeight, 1), offset = Vector3.new(-gapWidth / 2, 0, 0) }, -- left edge
		{ size = Vector3.new(1, gapHeight, 1), offset = Vector3.new(gapWidth / 2, 0, 0) },  -- right edge
	}

	for _, borderInfo in borderParts do
		local border = Instance.new("Part")
		border.Name = "GapBorder"
		border.Size = borderInfo.size
		border.Position = position + borderInfo.offset
		border.Anchored = true
		border.CanCollide = false
		border.Color = Color3.fromRGB(255, 255, 100)
		border.Material = Enum.Material.Neon
		border.Transparency = 0
		border.CastShadow = false
		border.Parent = barrierModel
	end

	barrierModel.Parent = skyBarriersFolder
	return barrierModel
end

-- Floating spinning obstacle
local function createSpinner(position: Vector3, armLength: number, spinColor: Color3)
	local spinner = Instance.new("Model")
	spinner.Name = "SkySpinner"

	-- Center hub
	local hub = Instance.new("Part")
	hub.Name = "Hub"
	hub.Shape = Enum.PartType.Ball
	hub.Size = Vector3.new(4, 4, 4)
	hub.Position = position
	hub.Anchored = true
	hub.CanCollide = false
	hub.Color = Color3.fromRGB(200, 200, 200)
	hub.Material = Enum.Material.Metal
	hub.CastShadow = false
	hub.Parent = spinner

	-- Two spinning arms
	local arm1 = Instance.new("Part")
	arm1.Name = "Arm1"
	arm1.Size = Vector3.new(armLength * 2, 3, 3)
	arm1.Position = position
	arm1.Anchored = true
	arm1.CanCollide = false
	arm1.Color = spinColor
	arm1.Material = Enum.Material.Neon
	arm1.Transparency = 0.3
	arm1.CastShadow = false
	arm1.Parent = spinner

	local arm2 = Instance.new("Part")
	arm2.Name = "Arm2"
	arm2.Size = Vector3.new(3, armLength * 2, 3)
	arm2.Position = position
	arm2.Anchored = true
	arm2.CanCollide = false
	arm2.Color = spinColor
	arm2.Material = Enum.Material.Neon
	arm2.Transparency = 0.3
	arm2.CastShadow = false
	arm2.Parent = spinner

	spinner.Parent = skyBarriersFolder
	return spinner
end

-- Place sky barriers along and above the track
-- Rings to fly through
createRing(Vector3.new(0, 50, -50), CFrame.Angles(0, 0, 0), Color3.fromRGB(0, 255, 100), 12)
createRing(Vector3.new(80, 60, -270), CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 100, 0), 14)
createRing(Vector3.new(160, 45, -100), CFrame.Angles(0, 0, 0), Color3.fromRGB(0, 150, 255), 10)
createRing(Vector3.new(80, 55, 70), CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 50, 255), 13)
createRing(Vector3.new(0, 65, -200), CFrame.Angles(0, 0, math.rad(15)), Color3.fromRGB(255, 255, 0), 11)
createRing(Vector3.new(160, 70, -200), CFrame.Angles(0, 0, math.rad(-10)), Color3.fromRGB(0, 255, 255), 12)

-- Barrier walls with gaps to fly through
createBarrierWall(Vector3.new(80, 55, -140), 15, 20, 60, Color3.fromRGB(255, 50, 50))
createBarrierWall(Vector3.new(40, 50, -250), 12, 18, 50, Color3.fromRGB(50, 100, 255))
createBarrierWall(Vector3.new(120, 60, 30), 14, 22, 55, Color3.fromRGB(50, 255, 100))

-- Spinning obstacles
local spinners = {
	createSpinner(Vector3.new(30, 55, -150), 15, Color3.fromRGB(255, 80, 80)),
	createSpinner(Vector3.new(130, 50, -50), 12, Color3.fromRGB(80, 80, 255)),
	createSpinner(Vector3.new(80, 65, -200), 18, Color3.fromRGB(255, 200, 50)),
	createSpinner(Vector3.new(50, 45, 20), 10, Color3.fromRGB(80, 255, 80)),
}

-- Animate spinners (rotate continuously)
task.spawn(function()
	local spinAngle = 0
	while true do
		spinAngle += 0.02
		for _, spinner in spinners do
			local hub = spinner:FindFirstChild("Hub")
			if not hub then continue end
			local pos = hub.Position

			local arm1 = spinner:FindFirstChild("Arm1")
			local arm2 = spinner:FindFirstChild("Arm2")
			if arm1 then
				arm1.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, spinAngle)
			end
			if arm2 then
				arm2.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, spinAngle + math.rad(90))
			end
		end
		task.wait(0.03)
	end
end)

-- Animate rings (gentle pulse glow)
task.spawn(function()
	local pulseTime = 0
	while true do
		pulseTime += 0.05
		local pulse = 0.1 + math.abs(math.sin(pulseTime)) * 0.2
		for _, ring in skyBarriersFolder:GetChildren() do
			if ring.Name == "SkyRing" then
				for _, segment in ring:GetChildren() do
					if segment.Name == "RingSegment" then
						segment.Transparency = pulse
					end
				end
			end
		end
		task.wait(0.05)
	end
end)

print("[RacingGame] Sky barriers loaded!")

-------------------------------------------------
-- Car Builder (supports different car types)
-------------------------------------------------
local carsFolder = Instance.new("Folder")
carsFolder.Name = "Cars"
carsFolder.Parent = workspace

local function createCar(player: Player, colorIndex: number, carTypeName: string): Model
	local carType = CarConfig.CarTypes[carTypeName] or CarConfig.CarTypes[CarConfig.DefaultCarType]
	local color = CarConfig.Colors[((colorIndex - 1) % #CarConfig.Colors) + 1]
	local bodySize = carType.BodySize

	local car = Instance.new("Model")
	car.Name = player.Name .. "_Car"

	-- Store car type name for reference
	local typeValue = Instance.new("StringValue")
	typeValue.Name = "CarType"
	typeValue.Value = carType.Name
	typeValue.Parent = car

	-- Main body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = bodySize
	body.BrickColor = color
	body.Material = Enum.Material.SmoothPlastic
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = car

	-- Build roof based on style
	if carType.RoofStyle == "sport" then
		-- Low sleek roof
		local roof = Instance.new("Part")
		roof.Name = "Roof"
		roof.Size = Vector3.new(bodySize.X - 1.5, 1.0, bodySize.Z * 0.35)
		roof.BrickColor = BrickColor.new("Institutional white")
		roof.Material = Enum.Material.SmoothPlastic
		roof.Transparency = 0.4
		roof.TopSurface = Enum.SurfaceType.Smooth
		roof.BottomSurface = Enum.SurfaceType.Smooth
		roof.Parent = car
		local roofWeld = Instance.new("WeldConstraint")
		roofWeld.Part0 = body
		roofWeld.Part1 = roof
		roofWeld.Parent = roof
		roof.CFrame = body.CFrame * CFrame.new(0, bodySize.Y / 2 + 0.5, 0)

		-- Rear spoiler for sport cars
		local spoiler = Instance.new("Part")
		spoiler.Name = "Spoiler"
		spoiler.Size = Vector3.new(bodySize.X - 0.5, 0.2, 1.5)
		spoiler.BrickColor = color
		spoiler.Material = Enum.Material.SmoothPlastic
		spoiler.Parent = car
		local spoilerWeld = Instance.new("WeldConstraint")
		spoilerWeld.Part0 = body
		spoilerWeld.Part1 = spoiler
		spoilerWeld.Parent = spoiler
		spoiler.CFrame = body.CFrame * CFrame.new(0, bodySize.Y / 2 + 0.8, bodySize.Z / 2 - 1)

		-- Spoiler stands
		for _, side in { -1, 1 } do
			local stand = Instance.new("Part")
			stand.Name = "SpoilerStand"
			stand.Size = Vector3.new(0.3, 0.8, 0.3)
			stand.BrickColor = color
			stand.Material = Enum.Material.SmoothPlastic
			stand.Parent = car
			local standWeld = Instance.new("WeldConstraint")
			standWeld.Part0 = body
			standWeld.Part1 = stand
			standWeld.Parent = stand
			stand.CFrame = body.CFrame * CFrame.new(side * (bodySize.X / 2 - 0.8), bodySize.Y / 2 + 0.4, bodySize.Z / 2 - 1)
		end

	elseif carType.RoofStyle == "truck" then
		-- Tall cab roof
		local roof = Instance.new("Part")
		roof.Name = "Roof"
		roof.Size = Vector3.new(bodySize.X - 0.5, 2.0, bodySize.Z * 0.35)
		roof.BrickColor = color
		roof.Material = Enum.Material.SmoothPlastic
		roof.Transparency = 0.2
		roof.TopSurface = Enum.SurfaceType.Smooth
		roof.BottomSurface = Enum.SurfaceType.Smooth
		roof.Parent = car
		local roofWeld = Instance.new("WeldConstraint")
		roofWeld.Part0 = body
		roofWeld.Part1 = roof
		roofWeld.Parent = roof
		roof.CFrame = body.CFrame * CFrame.new(0, bodySize.Y / 2 + 1.0, -bodySize.Z * 0.15)

		-- Truck bed
		local bed = Instance.new("Part")
		bed.Name = "TruckBed"
		bed.Size = Vector3.new(bodySize.X - 0.2, 1.0, bodySize.Z * 0.4)
		bed.BrickColor = color
		bed.Material = Enum.Material.SmoothPlastic
		bed.Parent = car
		local bedWeld = Instance.new("WeldConstraint")
		bedWeld.Part0 = body
		bedWeld.Part1 = bed
		bedWeld.Parent = bed
		bed.CFrame = body.CFrame * CFrame.new(0, bodySize.Y / 2 + 0.5, bodySize.Z * 0.3)

		-- Roof lights
		for _, xOff in { -1.5, 0, 1.5 } do
			local roofLight = Instance.new("Part")
			roofLight.Name = "RoofLight"
			roofLight.Size = Vector3.new(0.8, 0.4, 0.4)
			roofLight.BrickColor = BrickColor.new("Bright orange")
			roofLight.Material = Enum.Material.Neon
			roofLight.Parent = car
			local rlWeld = Instance.new("WeldConstraint")
			rlWeld.Part0 = body
			rlWeld.Part1 = roofLight
			rlWeld.Parent = roofLight
			roofLight.CFrame = body.CFrame * CFrame.new(xOff, bodySize.Y / 2 + 2.1, -bodySize.Z * 0.15)
		end

	else -- sedan
		local roof = Instance.new("Part")
		roof.Name = "Roof"
		roof.Size = Vector3.new(bodySize.X - 1, 1.5, bodySize.Z * 0.4)
		roof.BrickColor = BrickColor.new("Institutional white")
		roof.Material = Enum.Material.SmoothPlastic
		roof.Transparency = 0.3
		roof.TopSurface = Enum.SurfaceType.Smooth
		roof.BottomSurface = Enum.SurfaceType.Smooth
		roof.Parent = car
		local roofWeld = Instance.new("WeldConstraint")
		roofWeld.Part0 = body
		roofWeld.Part1 = roof
		roofWeld.Parent = roof
		roof.CFrame = body.CFrame * CFrame.new(0, bodySize.Y / 2 + 0.75, -bodySize.Z * 0.05)
	end

	-- Hood scoop for Muscle cars
	if carTypeName == "Muscle" then
		local scoop = Instance.new("Part")
		scoop.Name = "HoodScoop"
		scoop.Size = Vector3.new(1.5, 0.6, 2)
		scoop.BrickColor = BrickColor.new("Black")
		scoop.Material = Enum.Material.SmoothPlastic
		scoop.Parent = car
		local scoopWeld = Instance.new("WeldConstraint")
		scoopWeld.Part0 = body
		scoopWeld.Part1 = scoop
		scoopWeld.Parent = scoop
		scoop.CFrame = body.CFrame * CFrame.new(0, bodySize.Y / 2 + 0.3, -bodySize.Z * 0.25)
	end

	-- Headlights
	for _, side in { -1, 1 } do
		local light = Instance.new("Part")
		light.Name = "Headlight"
		light.Size = Vector3.new(1, 0.6, 0.2)
		light.BrickColor = BrickColor.new("New Yeller")
		light.Material = Enum.Material.Neon
		light.Parent = car
		local lightWeld = Instance.new("WeldConstraint")
		lightWeld.Part0 = body
		lightWeld.Part1 = light
		lightWeld.Parent = light
		light.CFrame = body.CFrame * CFrame.new(side * (bodySize.X / 2 - 0.8), 0, -bodySize.Z / 2)
	end

	-- Taillights
	for _, side in { -1, 1 } do
		local taillight = Instance.new("Part")
		taillight.Name = "Taillight"
		taillight.Size = Vector3.new(1, 0.6, 0.2)
		taillight.BrickColor = BrickColor.new("Really red")
		taillight.Material = Enum.Material.Neon
		taillight.Parent = car
		local tlWeld = Instance.new("WeldConstraint")
		tlWeld.Part0 = body
		tlWeld.Part1 = taillight
		tlWeld.Parent = taillight
		taillight.CFrame = body.CFrame * CFrame.new(side * (bodySize.X / 2 - 0.8), 0, bodySize.Z / 2)
	end

	-- Vehicle Seat (used for input only — we apply forces manually)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriveSeat"
	seat.Size = Vector3.new(2, 0.5, 2)
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.TurnSpeed = 0
	seat.Transparency = 0.5
	seat.BrickColor = BrickColor.new("Black")
	seat.Parent = car
	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = body
	seatWeld.Part1 = seat
	seatWeld.Parent = seat
	seat.CFrame = body.CFrame * CFrame.new(carType.SeatOffset)

	-- Prompt for player to enter car
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnterCarPrompt"
	prompt.ActionText = "Drive"
	prompt.ObjectText = carType.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat

	-- Wheels
	local wheelPositions = {
		CFrame.new(-bodySize.X / 2, -bodySize.Y / 2, -bodySize.Z / 2 + 1.5),
		CFrame.new(bodySize.X / 2, -bodySize.Y / 2, -bodySize.Z / 2 + 1.5),
		CFrame.new(-bodySize.X / 2, -bodySize.Y / 2, bodySize.Z / 2 - 1.5),
		CFrame.new(bodySize.X / 2, -bodySize.Y / 2, bodySize.Z / 2 - 1.5),
	}

	for _, offset in wheelPositions do
		local wheel = Instance.new("Part")
		wheel.Name = "Wheel"
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Size = Vector3.new(carType.WheelWidth, carType.WheelRadius * 2, carType.WheelRadius * 2)
		wheel.BrickColor = BrickColor.new("Black")
		wheel.Material = Enum.Material.SmoothPlastic
		wheel.TopSurface = Enum.SurfaceType.Smooth
		wheel.BottomSurface = Enum.SurfaceType.Smooth
		wheel.Parent = car
		local wheelWeld = Instance.new("WeldConstraint")
		wheelWeld.Part0 = body
		wheelWeld.Part1 = wheel
		wheelWeld.Parent = wheel
		wheel.CFrame = body.CFrame * offset * CFrame.Angles(0, 0, math.rad(90))
	end

	-- Engine sound
	local engineSound = Instance.new("Sound")
	engineSound.Name = "EngineSound"
	engineSound.SoundId = CarConfig.Sounds.Engine
	engineSound.Looped = true
	engineSound.Volume = 0.4
	engineSound.PlaybackSpeed = 0.8
	engineSound.Parent = body
	engineSound:Play()

	-- Boost sound (plays on demand)
	local boostSound = Instance.new("Sound")
	boostSound.Name = "BoostSound"
	boostSound.SoundId = CarConfig.Sounds.Boost
	boostSound.Looped = false
	boostSound.Volume = 0.7
	boostSound.Parent = body

	-- BodyGyro keeps the car level (prevents flipping) while allowing VehicleSeat to steer/drive
	local gyro = Instance.new("BodyGyro")
	gyro.Name = "StabilityGyro"
	gyro.CFrame = CFrame.new()
	gyro.MaxTorque = Vector3.new(400000, 0, 400000) -- strong but finite torque on pitch/roll
	gyro.P = 3000
	gyro.D = 500
	gyro.Parent = body

	-- Trail effect showing car movement in the sky
	-- Two attachments at rear left and rear right for the trail width
	local trailAttach0 = Instance.new("Attachment")
	trailAttach0.Name = "TrailAttach0"
	trailAttach0.Position = Vector3.new(-bodySize.X / 2 + 0.5, 0, bodySize.Z / 2)
	trailAttach0.Parent = body

	local trailAttach1 = Instance.new("Attachment")
	trailAttach1.Name = "TrailAttach1"
	trailAttach1.Position = Vector3.new(bodySize.X / 2 - 0.5, 0, bodySize.Z / 2)
	trailAttach1.Parent = body

	local trail = Instance.new("Trail")
	trail.Name = "CarTrail"
	trail.Attachment0 = trailAttach0
	trail.Attachment1 = trailAttach1
	trail.Lifetime = 1.5
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.LightEmission = 0.3
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	-- Trail color matches the car color
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color.Color),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	trail.Parent = body

	-- Exhaust smoke particles from the rear
	local exhaustAttach = Instance.new("Attachment")
	exhaustAttach.Name = "ExhaustAttach"
	exhaustAttach.Position = Vector3.new(0, -bodySize.Y / 2 + 0.3, bodySize.Z / 2)
	exhaustAttach.Parent = body

	local exhaust = Instance.new("ParticleEmitter")
	exhaust.Name = "Exhaust"
	exhaust.Rate = 30
	exhaust.Lifetime = NumberRange.new(0.5, 1.2)
	exhaust.Speed = NumberRange.new(3, 6)
	exhaust.SpreadAngle = Vector2.new(15, 15)
	exhaust.RotSpeed = NumberRange.new(-30, 30)
	exhaust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 1.5),
	})
	exhaust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	exhaust.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 60)),
	})
	exhaust.LightEmission = 0
	exhaust.Parent = exhaustAttach

	-- Tire marks (ground trail from each rear wheel)
	local tireMarkPositions = {
		Vector3.new(-bodySize.X / 2, -bodySize.Y / 2 - carType.WheelRadius + 0.1, bodySize.Z / 2 - 1.5),
		Vector3.new(bodySize.X / 2, -bodySize.Y / 2 - carType.WheelRadius + 0.1, bodySize.Z / 2 - 1.5),
	}

	for i, tirePos in tireMarkPositions do
		local tireAttach0 = Instance.new("Attachment")
		tireAttach0.Name = "TireMark" .. i .. "_A0"
		tireAttach0.Position = tirePos + Vector3.new(-0.3, 0, 0)
		tireAttach0.Parent = body

		local tireAttach1 = Instance.new("Attachment")
		tireAttach1.Name = "TireMark" .. i .. "_A1"
		tireAttach1.Position = tirePos + Vector3.new(0.3, 0, 0)
		tireAttach1.Parent = body

		local tireMark = Instance.new("Trail")
		tireMark.Name = "TireMark" .. i
		tireMark.Attachment0 = tireAttach0
		tireMark.Attachment1 = tireAttach1
		tireMark.Lifetime = 3
		tireMark.MinLength = 0.2
		tireMark.FaceCamera = false
		tireMark.LightEmission = 0
		tireMark.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.8, 0.7),
			NumberSequenceKeypoint.new(1, 1),
		})
		tireMark.WidthScale = NumberSequence.new(1)
		tireMark.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20))
		tireMark.Parent = body
	end

	car.PrimaryPart = body
	car.Parent = carsFolder

	-- Server owns car physics so server-side forces work
	body:SetNetworkOwner(nil)

	-- Set all car parts to "Cars" collision group so cars pass through each other
	for _, part in car:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Cars"
		end
	end

	return car
end

-------------------------------------------------
-- Race State
-------------------------------------------------
local playerData: {[Player]: {
	car: Model?,
	currentCheckpoint: number,
	lap: number,
	finished: boolean,
	finishTime: number?,
	startTime: number?,
	carType: string,
	boosted: boolean,
	boostEndTime: number,
	crashed: boolean,
	lastCrashTime: number,
}} = {}

local raceActive = false
local raceStartTime = 0
local playerCount = 0
local playerSpawnIndex: {[Player]: number} = {} -- track each player's unique grid slot

-- Spawn positions spread far apart so cars don't overlap
-- Road surface is at Y=0, car body center should be about Y=2
local spawnPositions = {
	CFrame.new(-6, 2, 15) * CFrame.Angles(0, math.rad(180), 0),
	CFrame.new(6, 2, 15) * CFrame.Angles(0, math.rad(180), 0),
	CFrame.new(-6, 2, 33) * CFrame.Angles(0, math.rad(180), 0),
	CFrame.new(6, 2, 33) * CFrame.Angles(0, math.rad(180), 0),
	CFrame.new(-6, 2, 51) * CFrame.Angles(0, math.rad(180), 0),
	CFrame.new(6, 2, 51) * CFrame.Angles(0, math.rad(180), 0),
	CFrame.new(-6, 2, 69) * CFrame.Angles(0, math.rad(180), 0),
	CFrame.new(6, 2, 69) * CFrame.Angles(0, math.rad(180), 0),
}

local function getSpawnCFrame(index: number): CFrame
	return spawnPositions[((index - 1) % #spawnPositions) + 1]
end

local function spawnPlayerCar(player: Player, carTypeName: string?)
	local chosenType = carTypeName or CarConfig.DefaultCarType

	-- Destroy existing car if any
	local existingData = playerData[player]
	if existingData and existingData.car then
		existingData.car:Destroy()
	end

	-- Assign a stable spawn slot per player (only increment for new players)
	if not playerSpawnIndex[player] then
		playerCount += 1
		playerSpawnIndex[player] = playerCount
	end

	local myIndex = playerSpawnIndex[player]
	local car = createCar(player, myIndex, chosenType)
	local spawnCF = getSpawnCFrame(myIndex)
	car:PivotTo(spawnCF)

	print("[RacingGame] Spawned car for", player.Name, "at", spawnCF.Position, "type:", chosenType)

	-- Setup ProximityPrompt to let player enter the car
	local seat = car:FindFirstChild("DriveSeat") :: VehicleSeat
	if seat then
		local prompt = seat:FindFirstChild("EnterCarPrompt") :: ProximityPrompt
		if prompt then
			prompt.Triggered:Connect(function(triggerPlayer)
				if triggerPlayer ~= player then return end

				local character = triggerPlayer.Character
				if not character then return end
				local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
				if not humanoid then return end

				-- Sit the player (character stays visible on the car)
				seat:Sit(humanoid)

				-- Keep physics on the server so ApplyImpulse works
				local carBody = car:FindFirstChild("Body")
				if carBody then
					carBody:SetNetworkOwner(nil)
				end

				-- Hide prompt while seated
				prompt.Enabled = false
			end)
		end

		-- When player gets out of the car
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant == nil then
				-- Stop the car when player exits
				local carBody = car:FindFirstChild("Body")
				if carBody then
					carBody.AssemblyLinearVelocity = Vector3.zero
					carBody.AssemblyAngularVelocity = Vector3.zero
				end

				-- Re-enable prompt
				local enterPrompt = seat:FindFirstChild("EnterCarPrompt") :: ProximityPrompt
				if enterPrompt then
					enterPrompt.Enabled = true
				end
			end
		end)
	end

	playerData[player] = {
		car = car,
		currentCheckpoint = 0,
		lap = 0,
		finished = false,
		finishTime = nil,
		startTime = nil,
		carType = chosenType,
		boosted = false,
		boostEndTime = 0,
		crashed = false,
		lastCrashTime = 0,
	}

	-- Crash detection is set up later via the override at the bottom
	-- (setupCrashDetection is defined after this function)

	return car
end

-- Forward reference for crash detection (filled in later)
local _setupCrashForNewCar: ((Player, any) -> ())?

local function respawnCar(player: Player)
	local data = playerData[player]
	if not data or not data.car then return end

	local spawnCF: CFrame
	if data.currentCheckpoint > 0 then
		local cp = checkpointsFolder:FindFirstChild("Checkpoint_" .. data.currentCheckpoint)
		if cp then
			spawnCF = cp.CFrame + Vector3.new(0, 5, 0)
		end
	end

	if not spawnCF then
		spawnCF = getSpawnCFrame(1) + Vector3.new(0, 5, 0)
	end

	-- Reset velocity and reposition
	local body = data.car:FindFirstChild("Body")
	if body then
		body.AssemblyLinearVelocity = Vector3.zero
		body.AssemblyAngularVelocity = Vector3.zero
	end

	data.car:PivotTo(spawnCF)

	-- Teleport player near the car so they can re-enter
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp and data.car.PrimaryPart then
			hrp.CFrame = CFrame.new(data.car.PrimaryPart.Position + Vector3.new(5, 3, 0))
		end
	end

	-- Re-enable enter prompt
	local seat = data.car:FindFirstChild("DriveSeat") :: VehicleSeat
	if seat then
		local prompt = seat:FindFirstChild("EnterCarPrompt") :: ProximityPrompt
		if prompt then
			prompt.Enabled = true
		end
	end
end

-------------------------------------------------
-- Boost Pad System
-------------------------------------------------
local function applyBoost(player: Player, data: any)
	if data.boosted then return end -- already boosted

	data.boosted = true
	data.boostEndTime = tick() + CarConfig.BoostDuration

	-- Play boost sound
	local body = data.car:FindFirstChild("Body")
	if body then
		local boostSound = body:FindFirstChild("BoostSound") :: Sound
		if boostSound then
			boostSound:Play()
		end
	end

	-- Notify client for visual effect
	BoostEvent:FireClient(player, true)

	-- Remove boost after duration
	task.delay(CarConfig.BoostDuration, function()
		if data.car and data.car.Parent then
			data.boosted = false
			BoostEvent:FireClient(player, false)
		end
	end)
end

local function setupBoostPads()
	for _, boostPad in boostPadsFolder:GetChildren() do
		if boostPad.Name:match("^BoostPad_") then
			boostPad.Touched:Connect(function(hit)
				local car = hit.Parent
				if not car then return end

				for player, data in playerData do
					if data.car == car and not data.finished then
						applyBoost(player, data)
						break
					end
				end
			end)
		end
	end
end

setupBoostPads()

-------------------------------------------------
-- Checkpoint System
-------------------------------------------------
local function setupCheckpoints()
	for _, checkpoint in checkpointsFolder:GetChildren() do
		checkpoint.Touched:Connect(function(hit)
			local car = hit.Parent
			if not car then return end

			for player, data in playerData do
				if data.car == car and not data.finished then
					local cpIndex = checkpoint:FindFirstChild("Index")
					if not cpIndex then return end

					local idx = cpIndex.Value
					local expectedNext = (data.currentCheckpoint % #trackPoints) + 1

					if idx == expectedNext then
						data.currentCheckpoint = idx

						if idx == 1 and data.lap >= 0 then
							data.lap += 1

							if data.lap >= RaceConfig.Laps then
								data.finished = true
								data.finishTime = tick() - raceStartTime
								RaceUpdateEvent:FireClient(player, "Finished", {
									time = data.finishTime,
									lap = data.lap,
								})
								SoundEvent:FireClient(player, "Finish")
							else
								RaceUpdateEvent:FireClient(player, "LapComplete", {
									lap = data.lap,
									totalLaps = RaceConfig.Laps,
								})
								SoundEvent:FireClient(player, "LapComplete")
							end
						end

						RaceUpdateEvent:FireClient(player, "Checkpoint", {
							checkpoint = data.currentCheckpoint,
							lap = data.lap,
							totalLaps = RaceConfig.Laps,
						})
					end
					break
				end
			end
		end)
	end
end

setupCheckpoints()

-------------------------------------------------
-- Car Drive Loop (manual force application)
-------------------------------------------------
local RunService = game:GetService("RunService")

RunService.Heartbeat:Connect(function(dt)
	for player, data in playerData do
		if not data.car then continue end
		local seat = data.car:FindFirstChild("DriveSeat") :: VehicleSeat
		local body = data.car:FindFirstChild("Body") :: BasePart
		if not seat or not body or seat.Occupant == nil then continue end
		if data.crashed then continue end

		local carType = CarConfig.CarTypes[data.carType] or CarConfig.CarTypes[CarConfig.DefaultCarType]
		local throttle = seat.Throttle -- -1, 0, or 1 (W/S keys)
		local steer = seat.Steer -- -1, 0, or 1 (A/D keys)

		local lookVector = body.CFrame.LookVector
		local currentVel = body.AssemblyLinearVelocity
		local forwardSpeed = currentVel:Dot(lookVector)

		-- Apply boost multiplier if active
		local maxSpeed = carType.MaxSpeed
		local torque = carType.Torque
		if data.boosted then
			maxSpeed = maxSpeed * CarConfig.BoostMultiplier
			torque = torque * CarConfig.BoostMultiplier
		end

		-- Forward/backward drive
		if throttle ~= 0 then
			-- Only apply force if below max speed in that direction
			if (throttle > 0 and forwardSpeed < maxSpeed) or (throttle < 0 and forwardSpeed > -maxSpeed * 0.5) then
				local force = lookVector * torque * throttle * body.AssemblyMass * dt
				body:ApplyImpulse(force)
			end
		else
			-- Natural deceleration when not pressing throttle
			local lateralVel = currentVel - lookVector * forwardSpeed
			body.AssemblyLinearVelocity = lookVector * forwardSpeed * 0.98 + lateralVel * 0.95
		end

		-- Steering (only when moving) — also lifts the car into the air
		if steer ~= 0 and math.abs(forwardSpeed) > 2 then
			local turnDir = -steer * carType.TurnSpeed
			if forwardSpeed < 0 then
				turnDir = -turnDir
			end
			body.AssemblyAngularVelocity = Vector3.new(0, turnDir, 0)

			-- Fly up while steering — harder steering = more lift
			local liftForce = math.abs(steer) * 18 * body.AssemblyMass * dt
			body:ApplyImpulse(Vector3.new(0, liftForce, 0))
		elseif math.abs(forwardSpeed) > 0.5 then
			-- Dampen angular velocity when not steering
			body.AssemblyAngularVelocity = body.AssemblyAngularVelocity * 0.9
		end
	end
end)

-------------------------------------------------
-- Speed & Engine Sound Update Loop
-------------------------------------------------
task.spawn(function()
	while true do
		for player, data in playerData do
			if data.car and data.car.PrimaryPart then
				local velocity = data.car.PrimaryPart.AssemblyLinearVelocity.Magnitude
				local speed = math.floor(velocity)
				SpeedUpdateEvent:FireClient(player, speed)

				-- Update engine sound pitch based on speed
				local body = data.car:FindFirstChild("Body")
				if body then
					-- Update BodyGyro to track current yaw so it only corrects pitch/roll
					local gyro = body:FindFirstChild("StabilityGyro") :: BodyGyro
					if gyro then
						local _, yaw, _ = body.CFrame:ToEulerAnglesYXZ()
						gyro.CFrame = CFrame.Angles(0, yaw, 0)
					end
					local carType = CarConfig.CarTypes[data.carType] or CarConfig.CarTypes[CarConfig.DefaultCarType]
					local speedRatio = math.clamp(velocity / carType.MaxSpeed, 0, 1)

					local engineSound = body:FindFirstChild("EngineSound") :: Sound
					if engineSound then
						engineSound.PlaybackSpeed = 0.6 + speedRatio * 1.2
						engineSound.Volume = 0.3 + speedRatio * 0.5
					end

					-- Exhaust gets thicker at higher speed
					local exhaustAttach = body:FindFirstChild("ExhaustAttach")
					if exhaustAttach then
						local exhaust = exhaustAttach:FindFirstChild("Exhaust") :: ParticleEmitter
						if exhaust then
							exhaust.Rate = 10 + speedRatio * 60
							exhaust.Speed = NumberRange.new(2 + speedRatio * 5, 4 + speedRatio * 8)
						end
					end

					-- Trail visibility based on speed (only visible when moving)
					local trail = body:FindFirstChild("CarTrail") :: Trail
					if trail then
						trail.Enabled = velocity > 3
					end

					-- Tire marks only when going fast or turning
					for i = 1, 2 do
						local tireMark = body:FindFirstChild("TireMark" .. i) :: Trail
						if tireMark then
							tireMark.Enabled = velocity > 15
						end
					end
				end

				-- Respawn if fallen off
				if data.car.PrimaryPart.Position.Y < RaceConfig.RespawnHeight then
					respawnCar(player)
				end
			end
		end
		task.wait(0.1)
	end
end)

-------------------------------------------------
-- Race Flow
-------------------------------------------------
local function startCountdown()
	for i = RaceConfig.CountdownSeconds, 1, -1 do
		CountdownEvent:FireAllClients(i)
		SoundEvent:FireAllClients("Countdown")
		task.wait(1)
	end
	CountdownEvent:FireAllClients(0) -- GO!
	SoundEvent:FireAllClients("Go")
	raceActive = true
	raceStartTime = tick()

	for _, data in playerData do
		data.startTime = raceStartTime
	end
end

local function startRace()
	task.wait(3)
	startCountdown()
end

-------------------------------------------------
-- Car Selection
-------------------------------------------------
CarSelectEvent.OnServerEvent:Connect(function(player, carTypeName: string)
	if not CarConfig.CarTypes[carTypeName] then return end

	local data = playerData[player]
	if data then
		-- Respawn with new car type
		local oldCheckpoint = data.currentCheckpoint
		local oldLap = data.lap
		spawnPlayerCar(player, carTypeName)
		-- Restore race progress
		local newData = playerData[player]
		if newData then
			newData.currentCheckpoint = oldCheckpoint
			newData.lap = oldLap
		end
	end
end)

-------------------------------------------------
-- Player Handling
-------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		task.wait(1)

		-- Set player to Players collision group so they don't push cars
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				part.CollisionGroup = "Players"
			end
		end

		-- Spawn the car near the start line (player walks to it)
		spawnPlayerCar(player, CarConfig.DefaultCarType)

		-- Teleport player near their car
		local data = playerData[player]
		if data and data.car and data.car.PrimaryPart then
			local carPos = data.car.PrimaryPart.Position
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(carPos + Vector3.new(5, 3, 0))
			end
		end

		if playerCount == 1 then
			task.spawn(startRace)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local data = playerData[player]
	if data and data.car then
		data.car:Destroy()
	end
	playerData[player] = nil
	playerSpawnIndex[player] = nil
end)

RespawnEvent.OnServerEvent:Connect(function(player)
	respawnCar(player)
end)

-------------------------------------------------
-- Crash Detection System
-------------------------------------------------
local function setupCrashDetection(player: Player, data: any)
	local car = data.car
	if not car then return end

	local body = car:FindFirstChild("Body")
	if not body then return end

	-- Enable TouchedEvent on body
	body.Touched:Connect(function(hit)
		if data.crashed or data.finished then return end
		if not hit or not hit.Parent then return end

		-- Ignore other car parts, checkpoints, boost pads, sky barriers
		if hit.CollisionGroup == "Cars" or hit.CollisionGroup == "Players" then return end
		if not hit.CanCollide and not hit.Anchored then return end

		-- Must be a track part (wall, road edge, etc.)
		local isTrackPart = hit.Anchored and hit.CanCollide
		if not isTrackPart then return end

		-- Ignore road surface (we drive on it)
		if hit.Name:match("^Road") then return end
		if hit.Name == "StartLine" or hit.Name == "SpawnPlatform" then return end

		-- Check crash cooldown
		if tick() - data.lastCrashTime < CarConfig.CrashCooldown then return end

		-- Check if going fast enough to crash
		local speed = body.AssemblyLinearVelocity.Magnitude
		if speed < CarConfig.CrashSpeedThreshold then return end

		print("[RacingGame] CRASH!", player.Name, "hit", hit.Name, "at speed", math.floor(speed))

		-- Crash detected!
		data.crashed = true
		data.lastCrashTime = tick()

		-- Stop the car (drive loop checks data.crashed to prevent further input)
		body.AssemblyLinearVelocity = Vector3.zero
		body.AssemblyAngularVelocity = Vector3.zero

		-- Play crash sound
		SoundEvent:FireClient(player, "Crash")

		-- Show crash menu to client
		CrashEvent:FireClient(player, {
			lap = data.lap,
			checkpoint = data.currentCheckpoint,
		})
	end)
end

-- Handle retry/continue response from client
CrashResponseEvent.OnServerEvent:Connect(function(player, choice: string)
	local data = playerData[player]
	if not data or not data.crashed then return end

	data.crashed = false

	if choice == "Retry" then
		-- Reset race progress and respawn at start
		data.currentCheckpoint = 0
		data.lap = 0
		data.finished = false
		data.finishTime = nil

		-- Destroy old car and spawn new one at start
		local carType = data.carType
		if data.car then
			data.car:Destroy()
		end

		local myIndex = playerSpawnIndex[player] or 1
		local car = createCar(player, myIndex, carType)
		car:PivotTo(getSpawnCFrame(myIndex))

		local seat = car:FindFirstChild("DriveSeat") :: VehicleSeat
		local character = player.Character
		if character and seat then
			local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
			if humanoid then
				seat:Sit(humanoid)
			end
		end

		data.car = car
		data.boosted = false
		data.boostEndTime = 0

		-- Setup crash detection for new car
		setupCrashDetection(player, data)

		RaceUpdateEvent:FireClient(player, "Checkpoint", {
			checkpoint = 0,
			lap = 0,
			totalLaps = RaceConfig.Laps,
		})

	elseif choice == "Continue" then
		-- Respawn at last checkpoint and keep race progress
		respawnCar(player)
	end
end)

-- Now that setupCrashDetection is defined, set up crash detection for ALL existing and future cars
-- Hook into every car spawn by watching the Cars folder
carsFolder.ChildAdded:Connect(function(car)
	task.wait(0.1) -- let playerData be set first
	for plr, data in playerData do
		if data.car == car and not data.crashed then
			setupCrashDetection(plr, data)
			print("[RacingGame] Crash detection enabled for", plr.Name)
			break
		end
	end
end)

-- Also set up crash detection for any cars that already exist
for plr, data in playerData do
	if data.car then
		setupCrashDetection(plr, data)
	end
end

-------------------------------------------------
-- Fly Controls (Space = up, Shift = down)
-------------------------------------------------
local FLY_FORCE = 20 -- gentle upward force
local MAX_FLY_HEIGHT = 120 -- max height the car can fly
local MIN_FLY_HEIGHT = 0 -- ground level

FlyEvent.OnServerEvent:Connect(function(player, direction: string)
	local data = playerData[player]
	if not data or not data.car then return end

	local body = data.car:FindFirstChild("Body")
	if not body then return end

	local currentHeight = body.Position.Y

	if direction == "Up" then
		-- Don't fly higher than max
		if currentHeight < MAX_FLY_HEIGHT then
			body:ApplyImpulse(Vector3.new(0, FLY_FORCE * body.AssemblyMass, 0))
		end
	elseif direction == "Down" then
		-- Don't go below ground
		if currentHeight > MIN_FLY_HEIGHT + 3 then
			body:ApplyImpulse(Vector3.new(0, -FLY_FORCE * body.AssemblyMass * 0.8, 0))
		end
	end
end)

print("[RacingGame] Server loaded!")
