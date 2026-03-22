local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CarConfig = require(ReplicatedStorage.Shared.CarConfig)

-------------------------------------------------
-- Wait for Remote Events
-------------------------------------------------
local RaceUpdateEvent = ReplicatedStorage:WaitForChild("RaceUpdateEvent")
local CountdownEvent = ReplicatedStorage:WaitForChild("CountdownEvent")
local SpeedUpdateEvent = ReplicatedStorage:WaitForChild("SpeedUpdateEvent")
local RespawnEvent = ReplicatedStorage:WaitForChild("RespawnRequestEvent")
local CarSelectEvent = ReplicatedStorage:WaitForChild("CarSelectEvent")
local BoostEvent = ReplicatedStorage:WaitForChild("BoostEvent")
local SoundEvent = ReplicatedStorage:WaitForChild("SoundEvent")
local CrashEvent = ReplicatedStorage:WaitForChild("CrashEvent")
local CrashResponseEvent = ReplicatedStorage:WaitForChild("CrashResponseEvent")
local FlyEvent = ReplicatedStorage:WaitForChild("FlyEvent")

-------------------------------------------------
-- Sound System
-------------------------------------------------
local soundFolder = Instance.new("Folder")
soundFolder.Name = "UISounds"
soundFolder.Parent = playerGui

local function createUISound(name: string, soundId: string, volume: number?): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = soundFolder
	return sound
end

local countdownSound = createUISound("Countdown", CarConfig.Sounds.Countdown, 0.6)
local goSound = createUISound("Go", CarConfig.Sounds.Go, 0.8)
local lapSound = createUISound("LapComplete", CarConfig.Sounds.LapComplete, 0.7)
local finishSound = createUISound("Finish", CarConfig.Sounds.Finish, 0.9)
local crashSound = createUISound("Crash", CarConfig.Sounds.Crash, 0.8)

SoundEvent.OnClientEvent:Connect(function(soundName: string)
	if soundName == "Countdown" then
		countdownSound:Play()
	elseif soundName == "Go" then
		goSound:Play()
	elseif soundName == "LapComplete" then
		lapSound:Play()
	elseif soundName == "Finish" then
		finishSound:Play()
	elseif soundName == "Crash" then
		crashSound:Play()
	end
end)

-------------------------------------------------
-- UI Creation
-------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RacingUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Speedometer
local speedFrame = Instance.new("Frame")
speedFrame.Name = "Speedometer"
speedFrame.Size = UDim2.new(0, 200, 0, 80)
speedFrame.Position = UDim2.new(1, -220, 1, -100)
speedFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
speedFrame.BackgroundTransparency = 0.3
speedFrame.Parent = screenGui

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 12)
speedCorner.Parent = speedFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedValue"
speedLabel.Size = UDim2.new(1, 0, 0.65, 0)
speedLabel.Position = UDim2.new(0, 0, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "0"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.GothamBold
speedLabel.Parent = speedFrame

local speedUnit = Instance.new("TextLabel")
speedUnit.Name = "SpeedUnit"
speedUnit.Size = UDim2.new(1, 0, 0.35, 0)
speedUnit.Position = UDim2.new(0, 0, 0.65, 0)
speedUnit.BackgroundTransparency = 1
speedUnit.Text = "STUDS/S"
speedUnit.TextColor3 = Color3.fromRGB(180, 180, 180)
speedUnit.TextScaled = true
speedUnit.Font = Enum.Font.Gotham
speedUnit.Parent = speedFrame

-- Boost indicator (inside speedometer)
local boostIndicator = Instance.new("TextLabel")
boostIndicator.Name = "BoostIndicator"
boostIndicator.Size = UDim2.new(1, 0, 0, 20)
boostIndicator.Position = UDim2.new(0, 0, 0, -22)
boostIndicator.BackgroundTransparency = 1
boostIndicator.Text = ""
boostIndicator.TextColor3 = Color3.fromRGB(0, 200, 255)
boostIndicator.TextStrokeTransparency = 0.5
boostIndicator.TextScaled = true
boostIndicator.Font = Enum.Font.GothamBold
boostIndicator.Parent = speedFrame

-- Lap Counter
local lapFrame = Instance.new("Frame")
lapFrame.Name = "LapCounter"
lapFrame.Size = UDim2.new(0, 160, 0, 50)
lapFrame.Position = UDim2.new(1, -220, 0, 20)
lapFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
lapFrame.BackgroundTransparency = 0.3
lapFrame.Parent = screenGui

local lapCorner = Instance.new("UICorner")
lapCorner.CornerRadius = UDim.new(0, 12)
lapCorner.Parent = lapFrame

local lapLabel = Instance.new("TextLabel")
lapLabel.Name = "LapText"
lapLabel.Size = UDim2.new(1, -10, 1, 0)
lapLabel.Position = UDim2.new(0, 5, 0, 0)
lapLabel.BackgroundTransparency = 1
lapLabel.Text = "LAP 0 / 3"
lapLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
lapLabel.TextScaled = true
lapLabel.Font = Enum.Font.GothamBold
lapLabel.Parent = lapFrame

-- Countdown Display
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "Countdown"
countdownLabel.Size = UDim2.new(0, 300, 0, 200)
countdownLabel.Position = UDim2.new(0.5, -150, 0.3, 0)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text = ""
countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
countdownLabel.TextStrokeTransparency = 0.5
countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
countdownLabel.TextScaled = true
countdownLabel.Font = Enum.Font.GothamBold
countdownLabel.Parent = screenGui

-- Race Message
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "RaceMessage"
messageLabel.Size = UDim2.new(0, 500, 0, 80)
messageLabel.Position = UDim2.new(0.5, -250, 0.15, 0)
messageLabel.BackgroundTransparency = 1
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.TextStrokeTransparency = 0.5
messageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
messageLabel.TextScaled = true
messageLabel.Font = Enum.Font.GothamBold
messageLabel.Parent = screenGui

-- Controls hint
local controlsFrame = Instance.new("Frame")
controlsFrame.Name = "Controls"
controlsFrame.Size = UDim2.new(0, 280, 0, 120)
controlsFrame.Position = UDim2.new(0, 20, 1, -140)
controlsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
controlsFrame.BackgroundTransparency = 0.3
controlsFrame.Parent = screenGui

local controlsCorner = Instance.new("UICorner")
controlsCorner.CornerRadius = UDim.new(0, 12)
controlsCorner.Parent = controlsFrame

local controlsLabel = Instance.new("TextLabel")
controlsLabel.Size = UDim2.new(1, -10, 1, 0)
controlsLabel.Position = UDim2.new(0, 5, 0, 0)
controlsLabel.BackgroundTransparency = 1
controlsLabel.Text = "W/S - Accelerate/Brake\nA/D - Steer\nSpace - Fly Up\nShift - Fly Down\nR - Respawn | C - Change Car"
controlsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
controlsLabel.TextScaled = true
controlsLabel.Font = Enum.Font.Gotham
controlsLabel.TextXAlignment = Enum.TextXAlignment.Left
controlsLabel.Parent = controlsFrame

-------------------------------------------------
-- Car Selection UI
-------------------------------------------------
local carSelectGui = Instance.new("ScreenGui")
carSelectGui.Name = "CarSelectUI"
carSelectGui.ResetOnSpawn = false
carSelectGui.Enabled = false
carSelectGui.Parent = playerGui

local selectBg = Instance.new("Frame")
selectBg.Name = "Background"
selectBg.Size = UDim2.new(1, 0, 1, 0)
selectBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
selectBg.BackgroundTransparency = 0.5
selectBg.Parent = carSelectGui

local selectFrame = Instance.new("Frame")
selectFrame.Name = "SelectFrame"
selectFrame.Size = UDim2.new(0, 700, 0, 400)
selectFrame.Position = UDim2.new(0.5, -350, 0.5, -200)
selectFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
selectFrame.BackgroundTransparency = 0.1
selectFrame.Parent = carSelectGui

local selectCorner = Instance.new("UICorner")
selectCorner.CornerRadius = UDim.new(0, 16)
selectCorner.Parent = selectFrame

local selectTitle = Instance.new("TextLabel")
selectTitle.Size = UDim2.new(1, 0, 0, 50)
selectTitle.BackgroundTransparency = 1
selectTitle.Text = "CHOOSE YOUR CAR"
selectTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
selectTitle.TextScaled = true
selectTitle.Font = Enum.Font.GothamBold
selectTitle.Parent = selectFrame

-- Car option buttons
local carOptions = Instance.new("Frame")
carOptions.Name = "CarOptions"
carOptions.Size = UDim2.new(1, -20, 1, -70)
carOptions.Position = UDim2.new(0, 10, 0, 60)
carOptions.BackgroundTransparency = 1
carOptions.Parent = selectFrame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = carOptions

local carTypeColors = {
	Sport = Color3.fromRGB(220, 50, 50),
	Muscle = Color3.fromRGB(50, 120, 220),
	Truck = Color3.fromRGB(80, 180, 50),
	Racer = Color3.fromRGB(220, 180, 30),
}

for typeName, carType in CarConfig.CarTypes do
	local btn = Instance.new("TextButton")
	btn.Name = typeName
	btn.Size = UDim2.new(0, 155, 1, -10)
	btn.BackgroundColor3 = carTypeColors[typeName] or Color3.fromRGB(100, 100, 100)
	btn.BackgroundTransparency = 0.2
	btn.Text = ""
	btn.Parent = carOptions

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = btn

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 40)
	nameLabel.Position = UDim2.new(0, 0, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = carType.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = btn

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -10, 0, 30)
	descLabel.Position = UDim2.new(0, 5, 0, 50)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = carType.Description
	descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.Parent = btn

	-- Stats display
	local statsText = string.format(
		"Speed: %d\nPower: %d\nHandling: %.1f",
		carType.MaxSpeed, carType.Torque, carType.TurnSpeed
	)
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, -10, 0, 80)
	statsLabel.Position = UDim2.new(0, 5, 0, 90)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = statsText
	statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsLabel.TextScaled = true
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Parent = btn

	-- Stat bars
	local function createBar(parent: Instance, yPos: number, value: number, maxVal: number, barColor: Color3)
		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(0.8, 0, 0, 8)
		barBg.Position = UDim2.new(0.1, 0, 0, yPos)
		barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		barBg.Parent = parent
		local barBgCorner = Instance.new("UICorner")
		barBgCorner.CornerRadius = UDim.new(0, 4)
		barBgCorner.Parent = barBg

		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.new(math.clamp(value / maxVal, 0, 1), 0, 1, 0)
		barFill.BackgroundColor3 = barColor
		barFill.Parent = barBg
		local barFillCorner = Instance.new("UICorner")
		barFillCorner.CornerRadius = UDim.new(0, 4)
		barFillCorner.Parent = barFill
	end

	createBar(btn, 185, carType.MaxSpeed, 160, Color3.fromRGB(50, 200, 50))
	createBar(btn, 200, carType.Torque, 700, Color3.fromRGB(255, 150, 50))
	createBar(btn, 215, carType.TurnSpeed, 5.5, Color3.fromRGB(50, 150, 255))

	-- Speed/Power/Handling labels for bars
	local barLabels = Instance.new("TextLabel")
	barLabels.Size = UDim2.new(1, -10, 0, 50)
	barLabels.Position = UDim2.new(0, 5, 0, 225)
	barLabels.BackgroundTransparency = 1
	barLabels.Text = "Speed\nPower\nHandling"
	barLabels.TextColor3 = Color3.fromRGB(180, 180, 180)
	barLabels.TextScaled = true
	barLabels.Font = Enum.Font.Gotham
	barLabels.TextXAlignment = Enum.TextXAlignment.Left
	barLabels.TextYAlignment = Enum.TextYAlignment.Top
	barLabels.Parent = btn

	btn.MouseButton1Click:Connect(function()
		CarSelectEvent:FireServer(typeName)
		carSelectGui.Enabled = false
	end)
end

-------------------------------------------------
-- Boost Visual Effect
-------------------------------------------------
local isBoosted = false

BoostEvent.OnClientEvent:Connect(function(active: boolean)
	isBoosted = active
	if active then
		boostIndicator.Text = "BOOST!"
		speedFrame.BackgroundColor3 = Color3.fromRGB(0, 80, 120)
	else
		boostIndicator.Text = ""
		speedFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	end
end)

-------------------------------------------------
-- Event Handlers
-------------------------------------------------
local currentLap = 0
local totalLaps = 3

SpeedUpdateEvent.OnClientEvent:Connect(function(speed: number)
	speedLabel.Text = tostring(speed)
	-- Color the speed text when going fast
	if isBoosted then
		speedLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	elseif speed > 100 then
		speedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	elseif speed > 60 then
		speedLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	else
		speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

-- Show "START" before the countdown begins
countdownLabel.Text = "START"
countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

CountdownEvent.OnClientEvent:Connect(function(count: number)
	if count > 0 then
		countdownLabel.Text = tostring(count)
		countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
	elseif count == 0 then
		countdownLabel.Text = "GO!"
		countdownLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
		task.delay(1.5, function()
			countdownLabel.Text = ""
		end)
	end
end)

local function showMessage(text: string, color: Color3, duration: number)
	messageLabel.Text = text
	messageLabel.TextColor3 = color
	task.delay(duration, function()
		if messageLabel.Text == text then
			messageLabel.Text = ""
		end
	end)
end

RaceUpdateEvent.OnClientEvent:Connect(function(eventType: string, data: {[string]: any})
	if eventType == "Checkpoint" then
		currentLap = data.lap
		totalLaps = data.totalLaps
		lapLabel.Text = `LAP {currentLap} / {totalLaps}`

	elseif eventType == "LapComplete" then
		currentLap = data.lap
		lapLabel.Text = `LAP {currentLap} / {totalLaps}`
		showMessage(`Lap {currentLap} Complete!`, Color3.fromRGB(50, 200, 255), 2)

	elseif eventType == "Finished" then
		local timeStr = string.format("%.2f", data.time)
		showMessage(`You Finished! Time: {timeStr}s`, Color3.fromRGB(255, 215, 0), 10)
	end
end)

-------------------------------------------------
-- Crash Menu UI
-------------------------------------------------
local crashGui = Instance.new("ScreenGui")
crashGui.Name = "CrashUI"
crashGui.ResetOnSpawn = false
crashGui.Enabled = false
crashGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
crashGui.Parent = playerGui

-- Red flash vignette (full screen, fades out)
local redFlash = Instance.new("Frame")
redFlash.Name = "RedFlash"
redFlash.Size = UDim2.new(1, 0, 1, 0)
redFlash.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
redFlash.BackgroundTransparency = 1
redFlash.ZIndex = 10
redFlash.Parent = screenGui -- on main GUI so it shows even before crash menu

-- Red vignette edges (stays during crash menu)
local vignetteTop = Instance.new("Frame")
vignetteTop.Name = "VignetteTop"
vignetteTop.Size = UDim2.new(1, 0, 0.15, 0)
vignetteTop.Position = UDim2.new(0, 0, 0, 0)
vignetteTop.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
vignetteTop.BackgroundTransparency = 1
vignetteTop.BorderSizePixel = 0
vignetteTop.Parent = crashGui

local vignetteTopGradient = Instance.new("UIGradient")
vignetteTopGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})
vignetteTopGradient.Rotation = 90
vignetteTopGradient.Parent = vignetteTop

local vignetteBottom = Instance.new("Frame")
vignetteBottom.Name = "VignetteBottom"
vignetteBottom.Size = UDim2.new(1, 0, 0.15, 0)
vignetteBottom.Position = UDim2.new(0, 0, 0.85, 0)
vignetteBottom.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
vignetteBottom.BackgroundTransparency = 1
vignetteBottom.BorderSizePixel = 0
vignetteBottom.Parent = crashGui

local vignetteBottomGradient = Instance.new("UIGradient")
vignetteBottomGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0.3),
})
vignetteBottomGradient.Rotation = 90
vignetteBottomGradient.Parent = vignetteBottom

-- Dark overlay
local crashOverlay = Instance.new("Frame")
crashOverlay.Name = "Overlay"
crashOverlay.Size = UDim2.new(1, 0, 1, 0)
crashOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
crashOverlay.BackgroundTransparency = 0.4
crashOverlay.Parent = crashGui

-- Crash menu panel (starts off-screen for slide animation)
local crashPanel = Instance.new("Frame")
crashPanel.Name = "CrashPanel"
crashPanel.Size = UDim2.new(0, 420, 0, 320)
crashPanel.Position = UDim2.new(0.5, -210, -0.5, 0) -- starts above screen
crashPanel.BackgroundColor3 = Color3.fromRGB(25, 8, 8)
crashPanel.BackgroundTransparency = 0.05
crashPanel.Parent = crashGui

local crashPanelCorner = Instance.new("UICorner")
crashPanelCorner.CornerRadius = UDim.new(0, 16)
crashPanelCorner.Parent = crashPanel

local crashPanelStroke = Instance.new("UIStroke")
crashPanelStroke.Color = Color3.fromRGB(255, 50, 50)
crashPanelStroke.Thickness = 2
crashPanelStroke.Transparency = 0.3
crashPanelStroke.Parent = crashPanel

-- Red accent bar at top
local crashAccent = Instance.new("Frame")
crashAccent.Name = "Accent"
crashAccent.Size = UDim2.new(1, 0, 0, 4)
crashAccent.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
crashAccent.BorderSizePixel = 0
crashAccent.Parent = crashPanel

local crashAccentCorner = Instance.new("UICorner")
crashAccentCorner.CornerRadius = UDim.new(0, 16)
crashAccentCorner.Parent = crashAccent

-- "CRASHED!" title
local crashTitle = Instance.new("TextLabel")
crashTitle.Name = "Title"
crashTitle.Size = UDim2.new(1, 0, 0, 55)
crashTitle.Position = UDim2.new(0, 0, 0, 12)
crashTitle.BackgroundTransparency = 1
crashTitle.Text = "CRASHED!"
crashTitle.TextColor3 = Color3.fromRGB(255, 60, 60)
crashTitle.TextStrokeTransparency = 0.3
crashTitle.TextStrokeColor3 = Color3.fromRGB(80, 0, 0)
crashTitle.TextScaled = true
crashTitle.Font = Enum.Font.GothamBold
crashTitle.Parent = crashPanel

-- Crash count label
local crashCount = 0
local crashCountLabel = Instance.new("TextLabel")
crashCountLabel.Name = "CrashCount"
crashCountLabel.Size = UDim2.new(1, 0, 0, 22)
crashCountLabel.Position = UDim2.new(0, 0, 0, 65)
crashCountLabel.BackgroundTransparency = 1
crashCountLabel.Text = "Crashes: 0"
crashCountLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
crashCountLabel.TextScaled = true
crashCountLabel.Font = Enum.Font.GothamBold
crashCountLabel.Parent = crashPanel

-- Info label (shows lap/checkpoint)
local crashInfo = Instance.new("TextLabel")
crashInfo.Name = "Info"
crashInfo.Size = UDim2.new(1, -20, 0, 30)
crashInfo.Position = UDim2.new(0, 10, 0, 90)
crashInfo.BackgroundTransparency = 1
crashInfo.Text = ""
crashInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
crashInfo.TextScaled = true
crashInfo.Font = Enum.Font.Gotham
crashInfo.Parent = crashPanel

-- Divider line
local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(0.8, 0, 0, 1)
divider.Position = UDim2.new(0.1, 0, 0, 125)
divider.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
divider.BorderSizePixel = 0
divider.Parent = crashPanel

-- Retry button (restart race from beginning)
local retryBtn = Instance.new("TextButton")
retryBtn.Name = "RetryButton"
retryBtn.Size = UDim2.new(0, 170, 0, 55)
retryBtn.Position = UDim2.new(0.5, -180, 0, 140)
retryBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
retryBtn.Text = ""
retryBtn.Parent = crashPanel

local retryCorner = Instance.new("UICorner")
retryCorner.CornerRadius = UDim.new(0, 10)
retryCorner.Parent = retryBtn

local retryStroke = Instance.new("UIStroke")
retryStroke.Color = Color3.fromRGB(255, 80, 80)
retryStroke.Thickness = 1.5
retryStroke.Transparency = 0.5
retryStroke.Parent = retryBtn

local retryLabel = Instance.new("TextLabel")
retryLabel.Size = UDim2.new(1, 0, 0.6, 0)
retryLabel.Position = UDim2.new(0, 0, 0, 2)
retryLabel.BackgroundTransparency = 1
retryLabel.Text = "RETRY RACE"
retryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
retryLabel.TextScaled = true
retryLabel.Font = Enum.Font.GothamBold
retryLabel.Parent = retryBtn

local retrySubLabel = Instance.new("TextLabel")
retrySubLabel.Size = UDim2.new(1, 0, 0.35, 0)
retrySubLabel.Position = UDim2.new(0, 0, 0.6, 0)
retrySubLabel.BackgroundTransparency = 1
retrySubLabel.Text = "Restart from Lap 1"
retrySubLabel.TextColor3 = Color3.fromRGB(200, 160, 160)
retrySubLabel.TextScaled = true
retrySubLabel.Font = Enum.Font.Gotham
retrySubLabel.Parent = retryBtn

-- Continue button (respawn at last checkpoint)
local continueBtn = Instance.new("TextButton")
continueBtn.Name = "ContinueButton"
continueBtn.Size = UDim2.new(0, 170, 0, 55)
continueBtn.Position = UDim2.new(0.5, 10, 0, 140)
continueBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
continueBtn.Text = ""
continueBtn.Parent = crashPanel

local continueCorner = Instance.new("UICorner")
continueCorner.CornerRadius = UDim.new(0, 10)
continueCorner.Parent = continueBtn

local continueStroke = Instance.new("UIStroke")
continueStroke.Color = Color3.fromRGB(80, 220, 80)
continueStroke.Thickness = 1.5
continueStroke.Transparency = 0.5
continueStroke.Parent = continueBtn

local continueLabel = Instance.new("TextLabel")
continueLabel.Size = UDim2.new(1, 0, 0.6, 0)
continueLabel.Position = UDim2.new(0, 0, 0, 2)
continueLabel.BackgroundTransparency = 1
continueLabel.Text = "CONTINUE"
continueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
continueLabel.TextScaled = true
continueLabel.Font = Enum.Font.GothamBold
continueLabel.Parent = continueBtn

local continueSubLabel = Instance.new("TextLabel")
continueSubLabel.Size = UDim2.new(1, 0, 0.35, 0)
continueSubLabel.Position = UDim2.new(0, 0, 0.6, 0)
continueSubLabel.BackgroundTransparency = 1
continueSubLabel.Text = "Resume at checkpoint"
continueSubLabel.TextColor3 = Color3.fromRGB(160, 220, 160)
continueSubLabel.TextScaled = true
continueSubLabel.Font = Enum.Font.Gotham
continueSubLabel.Parent = continueBtn

-- Auto-continue timer bar
local timerBarBg = Instance.new("Frame")
timerBarBg.Name = "TimerBarBg"
timerBarBg.Size = UDim2.new(0.85, 0, 0, 10)
timerBarBg.Position = UDim2.new(0.075, 0, 0, 215)
timerBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
timerBarBg.Parent = crashPanel

local timerBarBgCorner = Instance.new("UICorner")
timerBarBgCorner.CornerRadius = UDim.new(0, 5)
timerBarBgCorner.Parent = timerBarBg

local timerBarFill = Instance.new("Frame")
timerBarFill.Name = "TimerBarFill"
timerBarFill.Size = UDim2.new(1, 0, 1, 0)
timerBarFill.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
timerBarFill.Parent = timerBarBg

local timerBarFillCorner = Instance.new("UICorner")
timerBarFillCorner.CornerRadius = UDim.new(0, 5)
timerBarFillCorner.Parent = timerBarFill

local autoTimerLabel = Instance.new("TextLabel")
autoTimerLabel.Name = "AutoTimerLabel"
autoTimerLabel.Size = UDim2.new(1, 0, 0, 22)
autoTimerLabel.Position = UDim2.new(0, 0, 0, 228)
autoTimerLabel.BackgroundTransparency = 1
autoTimerLabel.Text = "Auto-continue in 10s..."
autoTimerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
autoTimerLabel.TextScaled = true
autoTimerLabel.Font = Enum.Font.Gotham
autoTimerLabel.Parent = crashPanel

-- Tip text at bottom
local tipLabel = Instance.new("TextLabel")
tipLabel.Name = "Tip"
tipLabel.Size = UDim2.new(1, -20, 0, 30)
tipLabel.Position = UDim2.new(0, 10, 1, -38)
tipLabel.BackgroundTransparency = 1
tipLabel.Text = "Tip: Slow down before turns to avoid crashing!"
tipLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
tipLabel.TextScaled = true
tipLabel.Font = Enum.Font.Gotham
tipLabel.Parent = crashPanel

local crashTips = {
	"Tip: Slow down before turns to avoid crashing!",
	"Tip: The Truck is heavier and harder to crash.",
	"Tip: Use boost pads on straights, not turns!",
	"Tip: Press C to switch to a sturdier car.",
	"Tip: Brake early, accelerate out of corners.",
	"Tip: The Racer is fast but fragile - be careful!",
}

-- Button hover effects
local function setupHover(btn: TextButton, normalColor: Color3, hoverColor: Color3)
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = hoverColor
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = normalColor
	end)
end

setupHover(retryBtn, Color3.fromRGB(180, 40, 40), Color3.fromRGB(220, 60, 60))
setupHover(continueBtn, Color3.fromRGB(40, 150, 40), Color3.fromRGB(60, 190, 60))

-- Screen shake state
local shakeIntensity = 0
local isCrashed = false
local AUTO_CONTINUE_TIME = 10 -- seconds before auto-continue
local crashTimestamp = 0
local crashMenuActive = false

-- Close crash menu helper
local function closeCrashMenu(choice: string)
	if not crashMenuActive then return end
	crashMenuActive = false
	isCrashed = false
	crashGui.Enabled = false

	-- Reset panel position for next time
	crashPanel.Position = UDim2.new(0.5, -210, -0.5, 0)

	CrashResponseEvent:FireServer(choice)
end

-- Button click handlers
retryBtn.MouseButton1Click:Connect(function()
	closeCrashMenu("Retry")
end)

continueBtn.MouseButton1Click:Connect(function()
	closeCrashMenu("Continue")
end)

-- Red flash effect
local function playRedFlash()
	redFlash.BackgroundTransparency = 0.3
	task.spawn(function()
		for i = 1, 10 do
			redFlash.BackgroundTransparency = 0.3 + (i / 10) * 0.7
			task.wait(0.05)
		end
		redFlash.BackgroundTransparency = 1
	end)
end

-- Screen shake effect (applied in RenderStepped)
local function triggerScreenShake()
	shakeIntensity = 15
	task.spawn(function()
		while shakeIntensity > 0.5 do
			shakeIntensity *= 0.85
			task.wait(0.03)
		end
		shakeIntensity = 0
	end)
end

-- Slide-in animation for crash panel
local function slidePanelIn()
	local targetPos = UDim2.new(0.5, -210, 0.5, -160)
	crashPanel.Position = UDim2.new(0.5, -210, -0.5, 0)
	task.spawn(function()
		local progress = 0
		while progress < 1 do
			progress = math.min(progress + 0.06, 1)
			-- Ease out bounce
			local t = progress
			local ease = 1 - (1 - t) * (1 - t)
			local startY = -0.5
			local endY = 0.5
			local currentY = startY + (endY - startY) * ease
			crashPanel.Position = UDim2.new(0.5, -210, currentY, -160)
			task.wait(0.016)
		end
		crashPanel.Position = targetPos
	end)
end

-- Auto-continue timer loop
local function startAutoTimer()
	local startTime = tick()
	crashTimestamp = startTime
	while crashMenuActive and (tick() - startTime) < AUTO_CONTINUE_TIME do
		local elapsed = tick() - startTime
		local remaining = AUTO_CONTINUE_TIME - elapsed
		local ratio = 1 - (elapsed / AUTO_CONTINUE_TIME)

		timerBarFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)

		-- Color transition: green -> yellow -> red
		if ratio > 0.5 then
			timerBarFill.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		elseif ratio > 0.25 then
			timerBarFill.BackgroundColor3 = Color3.fromRGB(220, 180, 30)
		else
			timerBarFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
		end

		autoTimerLabel.Text = `Auto-continue in {math.ceil(remaining)}s...`
		task.wait(0.1)
	end

	-- Auto-continue if menu is still open
	if crashMenuActive then
		closeCrashMenu("Continue")
	end
end

-- Listen for crash event from server
CrashEvent.OnClientEvent:Connect(function(data: {[string]: any})
	crashCount += 1
	isCrashed = true
	crashMenuActive = true

	-- Update UI text
	crashCountLabel.Text = `Crashes: {crashCount}`
	crashInfo.Text = `Lap {data.lap} / {totalLaps}  |  Checkpoint {data.checkpoint}`
	tipLabel.Text = crashTips[math.random(1, #crashTips)]

	-- Reset timer bar
	timerBarFill.Size = UDim2.new(1, 0, 1, 0)
	timerBarFill.BackgroundColor3 = Color3.fromRGB(50, 180, 50)

	-- Show crash UI
	crashGui.Enabled = true

	-- Play effects
	playRedFlash()
	triggerScreenShake()
	slidePanelIn()

	-- Start auto-continue timer
	task.spawn(startAutoTimer)
end)

-------------------------------------------------
-- Camera Follow (Third Person Behind Car)
-------------------------------------------------
local camera = workspace.CurrentCamera

local function getCar(): Model?
	local carsFolder = workspace:FindFirstChild("Cars")
	if not carsFolder then return nil end
	return carsFolder:FindFirstChild(player.Name .. "_Car")
end

local isInCar = false

RunService.RenderStepped:Connect(function()
	local car = getCar()
	if not car or not car.PrimaryPart then
		-- Not in car — use default camera
		if isInCar then
			isInCar = false
			camera.CameraType = Enum.CameraType.Custom
			camera.FieldOfView = 70
		end
		return
	end

	-- Check if player is actually sitting in the car
	local seat = car:FindFirstChild("DriveSeat") :: VehicleSeat
	if not seat or seat.Occupant == nil then
		if isInCar then
			isInCar = false
			camera.CameraType = Enum.CameraType.Custom
			camera.FieldOfView = 70
		end
		return
	end

	isInCar = true
	local carCF = car.PrimaryPart.CFrame
	local speed = car.PrimaryPart.AssemblyLinearVelocity.Magnitude

	-- Dynamic camera: pulls back at higher speeds
	local baseDist = 20
	local extraDist = math.clamp(speed / 20, 0, 10)
	local cameraHeight = 8 + extraDist * 0.3
	local cameraDist = baseDist + extraDist

	-- Slight FOV increase during boost
	if isBoosted then
		camera.FieldOfView = camera.FieldOfView + (85 - camera.FieldOfView) * 0.1
	else
		camera.FieldOfView = camera.FieldOfView + (70 - camera.FieldOfView) * 0.1
	end

	local cameraPos = carCF * CFrame.new(0, cameraHeight, cameraDist)
	local lookAt = carCF.Position + carCF.LookVector * 10

	camera.CameraType = Enum.CameraType.Scriptable
	local targetCF = CFrame.lookAt(cameraPos.Position, lookAt)

	-- Apply screen shake offset
	if shakeIntensity > 0 then
		local shakeX = (math.random() - 0.5) * shakeIntensity * 0.1
		local shakeY = (math.random() - 0.5) * shakeIntensity * 0.1
		targetCF = targetCF * CFrame.new(shakeX, shakeY, 0)
	end

	camera.CFrame = camera.CFrame:Lerp(targetCF, 0.1)
end)

-------------------------------------------------
-- Input Handling
-------------------------------------------------
local flyingUp = false
local flyingDown = false

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.R then
		RespawnEvent:FireServer()
	elseif input.KeyCode == Enum.KeyCode.C then
		carSelectGui.Enabled = not carSelectGui.Enabled
	elseif input.KeyCode == Enum.KeyCode.Space then
		flyingUp = true
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		flyingDown = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		flyingUp = false
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		flyingDown = false
	end
end)

-- Send fly input to server continuously while held
task.spawn(function()
	while true do
		if flyingUp then
			FlyEvent:FireServer("Up")
		elseif flyingDown then
			FlyEvent:FireServer("Down")
		end
		task.wait(0.1)
	end
end)

-- Hide controls hint after 20 seconds
task.delay(20, function()
	controlsFrame.Visible = false
end)

print("[RacingGame] Client loaded!")
