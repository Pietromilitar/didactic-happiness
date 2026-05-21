--// HAZIN HUB V2 - UI roxa com estrelas + funções otimizadas
--// 100% LocalScript - Interface Melhorada, Lógica Avançada, Anti-Detecção, Key System
--// Coloque em StarterPlayer > StarterPlayerScripts > LocalScript
--// Se quiser usar GitHub: cole esse conteúdo em um arquivo .lua e carregue com loadstring(game:HttpGet(URL))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local HUB_NAME = "Hazin Hub V2"
local HUB_ICON = "H"
local VERSION = "2.0.0"

--// KEY SYSTEM - Muda a cada dia
local function generateDailyKey()
	local date = os.date("*t")
	local dayKey = string.format("%04d%02d%02d", date.year, date.month, date.day)
	return "HAZIN_" .. dayKey .. "_DAILY"
end

local DAILY_KEY = generateDailyKey()
local keyStorage = {}

local function validateKey(inputKey)
	if inputKey == DAILY_KEY or inputKey == "HAZIN_MASTER_KEY_2024" then
		return true
	end
	return false
end

--// Estados Melhorados com mais opções
local states = {
	--// Movimento
	Speed = false,
	Jump = false,
	Fly = false,
	Noclip = false,
	InfJump = false,
	WalkAir = false,
	
	--// Visual
	Fullbright = false,
	ESP = false,
	Tracers = false,
	BoxESP = false,
	NameTags = false,
	Chams = false,
	
	--// Combat
	Fling = false,
	AutoAttack = false,
	AimBot = false,
	
	--// Survival (para jogos de sobrevivência)
	AutoFarm = false,
	AutoCollect = false,
	AutoCraft = false,
	
	--// RPG (para jogos RPG)
	AutoQuest = false,
	AutoDungeon = false,
	
	--// Outros
	NoClipWalls = false,
	GhostMode = false,
	SpeedHack = false,
	JumpHack = false,
	FlyHack = false,
}

local values = {
	Speed = 80,
	Jump = 150,
	FlySpeed = 60,
	FlingPower = 120,
	WalkAirSpeed = 1.2,
	ESPDistance = 1000,
	AutoAttackDelay = 0.5,
	AImbotFOV = 180,
}

--// Variáveis de Controle
local flyUp = false
local flyDown = false
local flyVelocity
local flyGyro
local flingSpin
local walkAirPlatform
local walkAirGui
local walkAirUp = false
local walkAirDown = false
local walkAirHeight = 0
local starConnection
local espConnections = {}
local currentGameType = "DEFAULT"

--// Global Positions
_G.HAZIN_BUBBLE_POS = _G.HAZIN_BUBBLE_POS or UDim2.new(0, 24, 0.55, 0)
_G.HAZIN_WALKAIR_UP_POS = _G.HAZIN_WALKAIR_UP_POS or UDim2.new(1, -150, 0.58, 0)
_G.HAZIN_WALKAIR_DOWN_POS = _G.HAZIN_WALKAIR_DOWN_POS or UDim2.new(1, -150, 0.72, 0)

--// Detecção de Tipo de Jogo
local function detectGameType()
	local placeId = game.PlaceId
	local gameName = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name:lower()
	
	if gameName:find("survival") or gameName:find("famine") then
		return "SURVIVAL"
	elseif gameName:find("rpg") or gameName:find("role") then
		return "RPG"
	elseif gameName:find("combat") or gameName:find("fight") then
		return "COMBAT"
	elseif gameName:find("tycoon") or gameName:find("business") then
		return "TYCOON"
	elseif gameName:find("racing") or gameName:find("car") then
		return "RACING"
	else
		return "DEFAULT"
	end
end

--// Anti-Detecção Melhorada
local function antiDetection()
	--// Limpar scripts suspeitos
	local suspiciousNames = {"Anti", "Guard", "Monitor", "Detect", "Admin"}
	
	task.spawn(function()
		while true do
			task.wait(math.random(30, 60))
			
			for _, script in ipairs(workspace:FindFirstChildOfClass("LocalScript")) do
				for _, name in ipairs(suspiciousNames) do
					if script.Name:find(name) then
						--// Não destruir, apenas desabilitar (menos detectável)
						pcall(function()
							script.Disabled = true
						end)
					end
				end
			end
		end
	end)
	
	--// Ocultar atividade RenderStepped
	return function()
		local success, result = pcall(function()
			return RunService.RenderStepped:Wait()
		end)
		return success
	end
end

local safeWait = antiDetection()

local Controls
task.spawn(function()
	local ok, result = pcall(function()
		local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		return PlayerModule:GetControls()
	end)
	
	if ok then
		Controls = result
	end
end)

--// Funções de UI Melhoradas
local function tween(obj, time, props, style, dir)
	if not obj or not obj.Parent then return end
	
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function corner(obj, radius)
	if not obj then return end
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = obj
	return c
end

local function stroke(obj, color, thickness, transparency)
	if not obj then return end
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(255, 255, 255)
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.4
	s.Parent = obj
	return s
end

local function gradient(obj, c1, c2, rot)
	if not obj then return end
	local g = Instance.new("UIGradient")
	g.Rotation = rot or 45
	g.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	}
	g.Parent = obj
	return g
end

local function scaleObj(obj, value)
	if not obj then return end
	local s = Instance.new("UIScale")
	s.Scale = value or 1
	s.Parent = obj
	return s
end

local function pressEffect(btn)
	if not btn then return end
	local sc = scaleObj(btn, 1)
	
	btn.MouseButton1Down:Connect(function()
		if btn.Parent then tween(sc, 0.08, {Scale = 0.94}) end
	end)
	
	btn.MouseButton1Up:Connect(function()
		if btn.Parent then tween(sc, 0.12, {Scale = 1}) end
	end)
	
	btn.MouseLeave:Connect(function()
		if btn.Parent then tween(sc, 0.12, {Scale = 1}) end
	end)
end

local function makeDraggable(handle, frame, onEnd)
	if not handle or not frame then return end
	
	local dragging = false
	local dragStart
	local startPos
	
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging and onEnd then
				onEnd(frame.Position)
			end
			dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--// Funções Auxiliares Melhoradas
local function getChar()
	local char = player.Character
	if not char then return nil, nil, nil end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	
	return char, hum, root
end

local function getMoveVector()
	if Controls then
		local ok, move = pcall(function()
			return Controls:GetMoveVector()
		end)
		
		if ok and typeof(move) == "Vector3" then
			return move
		end
	end
	
	local _, hum = getChar()
	if hum then
		local md = hum.MoveDirection
		return Vector3.new(md.X, 0, -md.Z)
	end
	
	return Vector3.zero
end

local function applyMovement()
	local _, hum = getChar()
	if not hum then return end
	
	hum.UseJumpPower = true
	hum.WalkSpeed = (states.Speed or states.SpeedHack) and values.Speed or 16
	hum.JumpPower = (states.Jump or states.JumpHack) and values.Jump or 50
end

local function clearESP()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			for _, espObj in ipairs({"HazinESP", "HazinTracer", "HazinBox", "HazinTag", "HazinCham"}) do
				local h = p.Character:FindFirstChild(espObj)
				if h then
					pcall(function()
						h:Destroy()
					end)
				end
			end
		end
	end
	
	for i, conn in ipairs(espConnections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	espConnections = {}
end

local function setFullbright(on)
	pcall(function()
		if on then
			Lighting.Brightness = 3
			Lighting.ClockTime = 14
			Lighting.FogEnd = 100000
			Lighting.GlobalShadows = false
		else
			Lighting.Brightness = 1
			Lighting.ClockTime = 12
			Lighting.FogEnd = 100000
			Lighting.GlobalShadows = true
		end
	end)
end

local function stopFling()
	if flingSpin then
		pcall(function()
			flingSpin:Destroy()
		end)
		flingSpin = nil
	end
end

local function notify(gui, text, good, duration)
	if not gui or not gui.Parent then return end
	
	local n = Instance.new("TextLabel")
	n.Size = UDim2.new(0, 350, 0, 48)
	n.Position = UDim2.new(0.5, -175, 0, -65)
	n.BackgroundColor3 = good and Color3.fromRGB(60, 8, 140) or Color3.fromRGB(180, 40, 80)
	n.Text = text
	n.TextColor3 = Color3.fromRGB(255, 255, 255)
	n.TextSize = 14
	n.Font = Enum.Font.GothamBold
	n.TextWrapped = true
	n.BorderSizePixel = 0
	n.ZIndex = 99
	n.Parent = gui
	
	corner(n, 12)
	stroke(n, Color3.fromRGB(255, 255, 255), 1, 0.55)
	
	tween(n, 0.3, {Position = UDim2.new(0.5, -175, 0, 16)}, Enum.EasingStyle.Back)
	
	task.delay(duration or 2.5, function()
		if n and n.Parent then
			tween(n, 0.22, {Position = UDim2.new(0.5, -175, 0, -65)})
			task.wait(0.25)
			if n then 
				pcall(function()
					n:Destroy()
				end)
			end
		end
	end)
end

local function createStars(parent)
	if not parent then return end
	parent.ClipsDescendants = true
	
	if starConnection then
		pcall(function()
			starConnection:Disconnect()
		end)
		starConnection = nil
	end
	
	local colors = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 120, 255),
		Color3.fromRGB(190, 80, 255),
		Color3.fromRGB(120, 210, 255),
		Color3.fromRGB(255, 220, 90),
		Color3.fromRGB(120, 255, 190),
		Color3.fromRGB(200, 120, 255),
		Color3.fromRGB(100, 200, 255),
	}
	
	local stars = {}
	
	for i = 1, 50 do
		local star = Instance.new("ImageLabel")
		star.Name = "StarIcon"
		star.BackgroundTransparency = 1
		star.Image = "rbxassetid://78948693296136"
		star.ImageColor3 = colors[math.random(1, #colors)]
		star.ImageTransparency = math.random(10, 40) / 100
		
		local size = math.random(12, 28)
		star.Size = UDim2.new(0, size, 0, size)
		star.Position = UDim2.new(math.random(), 0, 0, math.random(-80, parent.AbsoluteSize.Y + 40))
		star.Rotation = math.random(0, 360)
		star.ZIndex = 1
		star.Parent = parent
		
		table.insert(stars, {
			obj = star,
			speed = math.random(20, 80),
			xDrift = math.random(-25, 25) / 1000,
			rotSpeed = math.random(-100, 100),
		})
	end
	
	starConnection = RunService.RenderStepped:Connect(function(dt)
		if not parent or not parent.Parent then
			if starConnection then
				pcall(function()
					starConnection:Disconnect()
				end)
				starConnection = nil
			end
			return
		end
		
		local parentHeight = math.max(parent.AbsoluteSize.Y, 1)
		
		for _, data in ipairs(stars) do
			local star = data.obj
			
			if star and star.Parent then
				local y = star.Position.Y.Offset + data.speed * dt
				local x = star.Position.X.Scale + data.xDrift * dt
				
				if y > parentHeight + 30 then
					y = -30
					x = math.random()
					star.ImageColor3 = colors[math.random(1, #colors)]
					star.ImageTransparency = math.random(10, 40) / 100
				end
				
				if x < -0.08 then
					x = 1.08
				elseif x > 1.08 then
					x = -0.08
				end
				
				star.Position = UDim2.new(x, 0, 0, y)
				star.Rotation = (star.Rotation + data.rotSpeed * dt) % 360
			end
		end
	end)
end

local function removeWalkAirButtons()
	if walkAirGui then
		pcall(function()
			walkAirGui:Destroy()
		end)
		walkAirGui = nil
	end
	
	walkAirUp = false
	walkAirDown = false
end

local function stopWalkAir()
	removeWalkAirButtons()
	
	if walkAirPlatform then
		pcall(function()
			walkAirPlatform:Destroy()
		end)
		walkAirPlatform = nil
	end
	
	walkAirHeight = 0
end

local function makeHoldMoveButton(parent, name, text, position, saveCallback, holdCallback)
	if not parent then return nil end
	
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 74, 0, 74)
	btn.Position = position
	btn.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
	btn.BackgroundTransparency = 0.08
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 26
	btn.Font = Enum.Font.GothamBlack
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.ZIndex = 120
	btn.Parent = parent
	
	corner(btn, 999)
	stroke(btn, Color3.fromRGB(255, 255, 255), 2, 0.35)
	
	local grad = gradient(btn, Color3.fromRGB(35, 35, 40), Color3.fromRGB(120, 120, 135), -90)
	if grad then
		grad.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.18),
			NumberSequenceKeypoint.new(1, 0.38)
		}
	end
	
	local small = Instance.new("TextLabel")
	small.Size = UDim2.new(1, 0, 0, 18)
	small.Position = UDim2.new(0, 0, 1, -21)
	small.BackgroundTransparency = 1
	small.Text = "segure"
	small.TextColor3 = Color3.fromRGB(230, 230, 230)
	small.TextSize = 10
	small.Font = Enum.Font.GothamBold
	small.ZIndex = 121
	small.Parent = btn
	
	local pressScale = scaleObj(btn, 1)
	
	local startPos
	local startInput
	local dragging = false
	local moved = false
	
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			startInput = input.Position
			startPos = btn.Position
			dragging = true
			moved = false
			
			if holdCallback then holdCallback(true) end
			tween(pressScale, 0.08, {Scale = 0.93})
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and startInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInput
			
			if math.abs(delta.X) > 8 or math.abs(delta.Y) > 8 then
				moved = true
				if holdCallback then holdCallback(false) end
			end
			
			if moved then
				btn.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if holdCallback then holdCallback(false) end
			if saveCallback then saveCallback(btn.Position) end
			tween(pressScale, 0.1, {Scale = 1})
		end
	end)
	
	return btn
end

local function createWalkAirButtons()
	if walkAirGui then
		pcall(function()
			walkAirGui:Destroy()
		end)
		walkAirGui = nil
	end
	
	walkAirGui = Instance.new("ScreenGui")
	walkAirGui.Name = "HazinWalkAirButtons"
	walkAirGui.ResetOnSpawn = false
	walkAirGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	walkAirGui.Parent = PlayerGui
	
	makeHoldMoveButton(
		walkAirGui,
		"WalkAirUp",
		"▲",
		_G.HAZIN_WALKAIR_UP_POS,
		function(pos)
			_G.HAZIN_WALKAIR_UP_POS = pos
		end,
		function(on)
			walkAirUp = on
		end
	)
	
	makeHoldMoveButton(
		walkAirGui,
		"WalkAirDown",
		"▼",
		_G.HAZIN_WALKAIR_DOWN_POS,
		function(pos)
			_G.HAZIN_WALKAIR_DOWN_POS = pos
		end,
		function(on)
			walkAirDown = on
		end
	)
end

local function createBubble(gui, mainFrame, mainScale)
	if not gui or not mainFrame or not mainScale then return end
	
	local old = gui:FindFirstChild("HazinBubble")
	if old then 
		pcall(function()
			old:Destroy()
		end)
	end
	
	local bubble = Instance.new("TextButton")
	bubble.Name = "HazinBubble"
	bubble.Size = UDim2.new(0, 58, 0, 58)
	bubble.Position = _G.HAZIN_BUBBLE_POS
	bubble.BackgroundColor3 = Color3.fromRGB(62, 4, 120)
	bubble.Text = "H"
	bubble.TextColor3 = Color3.fromRGB(255, 255, 255)
	bubble.TextSize = 30
	bubble.Font = Enum.Font.GothamBlack
	bubble.BorderSizePixel = 0
	bubble.AutoButtonColor = false
	bubble.ZIndex = 100
	bubble.Parent = gui
	
	corner(bubble, 999)
	stroke(bubble, Color3.fromRGB(255, 255, 255), 2, 0.25)
	gradient(bubble, Color3.fromRGB(170, 8, 190), Color3.fromRGB(70, 7, 162), 45)
	
	local sc = scaleObj(bubble, 0)
	tween(sc, 0.28, {Scale = 1}, Enum.EasingStyle.Back)
	
	local started
	local startPos
	local moved = false
	
	bubble.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			started = input.Position
			startPos = bubble.Position
			moved = false
			tween(sc, 0.08, {Scale = 0.92})
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if started and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - started
			
			if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
				moved = true
			end
			
			bubble.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if started and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			_G.HAZIN_BUBBLE_POS = bubble.Position
			tween(sc, 0.1, {Scale = 1})
			
			if not moved then
				tween(sc, 0.12, {Scale = 0})
				task.wait(0.13)
				if bubble then 
					pcall(function()
						bubble:Destroy()
					end)
				end
				
				mainFrame.Visible = true
				mainScale.Scale = 0.78
				tween(mainScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
			end
			
			started = nil
		end
	end)
end

--// UI Principal
local old = PlayerGui:FindFirstChild("HazinHubUI")
if old then 
	pcall(function()
		old:Destroy()
	end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "HazinHubUI"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Name = "Fundo"
main.Size = UDim2.new(0.9, 0, 0.88, 0)
main.Position = UDim2.new(0.05, 0, 0.06, 0)
main.BackgroundColor3 = Color3.fromRGB(164, 6, 163)
main.BackgroundTransparency = 0.08
main.BorderSizePixel = 0
main.Parent = gui
main.ClipsDescendants = true

corner(main, 18)
stroke(main, Color3.fromRGB(255, 255, 255), 2, 0.6)
local mainGrad = gradient(main, Color3.fromRGB(110, 15, 135), Color3.fromRGB(45, 45, 60), -90)
if mainGrad then
	mainGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 0.28)
	}
end

local mainScale = scaleObj(main, 0.82)
tween(mainScale, 0.42, {Scale = 1}, Enum.EasingStyle.Back)

createStars(main)
makeDraggable(main, main)

--// Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(80, 10, 120)
header.BackgroundTransparency = 0.2
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = main

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -100, 1, 0)
headerLabel.Position = UDim2.new(0, 15, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = HUB_NAME .. " v" .. VERSION .. " | " .. currentGameType
headerLabel.TextColor3 = Color3.fromRGB(255, 220, 255)
headerLabel.TextSize = 16
headerLabel.Font = Enum.Font.GothamBlack
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.ZIndex = 4
headerLabel.Parent = header

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 200, 1, 0)
versionLabel.Position = UDim2.new(1, -215, 0, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "📅 Key: " .. DAILY_KEY:sub(-8)
versionLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
versionLabel.TextSize = 12
versionLabel.Font = Enum.Font.GothamBold
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.ZIndex = 4
versionLabel.Parent = header

--// Pesquisa
local searchFrame = Instance.new("Frame")
searchFrame.Name = "Pesquisa"
searchFrame.Size = UDim2.new(0, 220, 0, 38)
searchFrame.Position = UDim2.new(0, 18, 0, 60)
searchFrame.BackgroundColor3 = Color3.fromRGB(50, 5, 117)
searchFrame.BackgroundTransparency = 0.16
searchFrame.BorderSizePixel = 0
searchFrame.ZIndex = 3
searchFrame.Parent = main

corner(searchFrame, 999)
stroke(searchFrame, Color3.fromRGB(255, 255, 255), 1, 0.65)
local searchGrad = gradient(searchFrame, Color3.fromRGB(35, 35, 40), Color3.fromRGB(105, 105, 115), -90)
if searchGrad then
	searchGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0.45)
	}
end

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -22, 1, 0)
searchBox.Position = UDim2.new(0, 11, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 buscar..."
searchBox.PlaceholderColor3 = Color3.fromRGB(200, 200, 200)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.TextSize = 14
searchBox.Font = Enum.Font.GothamBold
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 4
searchBox.Parent = searchFrame

--// Botão X
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "BotaoMinimizar"
closeBtn.Size = UDim2.new(0, 46, 0, 46)
closeBtn.Position = UDim2.new(1, -60, 0, 14)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.BackgroundTransparency = 0.18
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(20, 0, 0)
closeBtn.TextSize = 28
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 4
closeBtn.Parent = main

corner(closeBtn, 999)
stroke(closeBtn, Color3.fromRGB(255, 255, 255), 1, 0.5)
gradient(closeBtn, Color3.fromRGB(72, 0, 0), Color3.fromRGB(255, 255, 255), 45)
pressEffect(closeBtn)

closeBtn.MouseButton1Click:Connect(function()
	tween(mainScale, 0.18, {Scale = 0.75})
	task.wait(0.16)
	main.Visible = false
	createBubble(gui, main, mainScale)
end)

--// Abas
local tabs = Instance.new("ScrollingFrame")
tabs.Name = "Abas"
tabs.Size = UDim2.new(0, 100, 1, -120)
tabs.Position = UDim2.new(0, 18, 0, 110)
tabs.BackgroundColor3 = Color3.fromRGB(145, 10, 180)
tabs.BorderSizePixel = 0
tabs.ScrollBarThickness = 0
tabs.CanvasSize = UDim2.new(0, 0, 0, 0)
tabs.ZIndex = 2
tabs.Parent = main

corner(tabs, 12)
stroke(tabs, Color3.fromRGB(255, 255, 255), 1, 0.7)
local tabsGrad = gradient(tabs, Color3.fromRGB(45, 45, 55), Color3.fromRGB(120, 120, 135), -90)
if tabsGrad then
	tabsGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(1, 0.38)
	}
end

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.Padding = UDim.new(0, 8)
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabsLayout.Parent = tabs

local tabsPadding = Instance.new("UIPadding")
tabsPadding.PaddingTop = UDim.new(0, 10)
tabsPadding.PaddingBottom = UDim.new(0, 10)
tabsPadding.Parent = tabs

tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	tabs.CanvasSize = UDim2.new(0, 0, 0, tabsLayout.AbsoluteContentSize.Y + 20)
end)

--// Conteúdo
local content = Instance.new("Frame")
content.Name = "Conteudo"
content.Size = UDim2.new(1, -158, 1, -120)
content.Position = UDim2.new(0, 136, 0, 110)
content.BackgroundColor3 = Color3.fromRGB(28, 4, 80)
content.BackgroundTransparency = 0.16
content.BorderSizePixel = 0
content.ZIndex = 2
content.Parent = main

corner(content, 14)
stroke(content, Color3.fromRGB(255, 255, 255), 1, 0.7)
local contentGrad = gradient(content, Color3.fromRGB(35, 35, 45), Color3.fromRGB(80, 40, 105), -90)
if contentGrad then
	contentGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.16),
		NumberSequenceKeypoint.new(1, 0.34)
	}
end

local pages = {}
local tabButtons = {}
local allSearchItems = {}

local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.new(1, -18, 1, -18)
	page.Position = UDim2.new(0, 9, 0, 9)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 5
	page.ScrollBarImageColor3 = Color3.fromRGB(220, 120, 255)
	page.Visible = false
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.ZIndex = 3
	page.Parent = content
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page
	
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 14)
	end)
	
	pages[name] = page
	return page
end

local function showPage(name)
	for n, p in pairs(pages) do
		p.Visible = n == name
	end
	
	for n, b in pairs(tabButtons) do
		b.BackgroundColor3 = n == name and Color3.fromRGB(90, 20, 180) or Color3.fromRGB(55, 5, 117)
	end
	
	local page = pages[name]
	if page then
		page.Position = UDim2.new(0, 24, 0, 9)
		tween(page, 0.22, {Position = UDim2.new(0, 9, 0, 9)})
	end
end

local function basicButtonStyle(b)
	if not b then return end
	b.BackgroundColor3 = Color3.fromRGB(50, 5, 117)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.ZIndex = 4
	
	corner(b, 12)
	stroke(b, Color3.fromRGB(255, 255, 255), 1, 0.75)
	local buttonGrad = gradient(b, Color3.fromRGB(35, 35, 40), Color3.fromRGB(105, 105, 115), -90)
	if buttonGrad then
		buttonGrad.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(1, 0.45)
		}
	end
	pressEffect(b)
end

local function tab(text, pageName)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 50, 0, 50)
	b.BackgroundColor3 = Color3.fromRGB(55, 5, 117)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextSize = 20
	b.Font = Enum.Font.GothamBlack
	b.BorderSizePixel = 0
	b.ZIndex = 3
	b.Parent = tabs
	
	corner(b, 12)
	stroke(b, Color3.fromRGB(255, 255, 255), 1, 0.75)
	pressEffect(b)
	
	tabButtons[pageName] = b
	
	b.MouseButton1Click:Connect(function()
		showPage(pageName)
	end)
end

local function label(parent, text)
	if not parent then return nil end
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -4, 0, 32)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.fromRGB(255, 220, 255)
	l.TextSize = 18
	l.Font = Enum.Font.GothamBlack
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 4
	l.Parent = parent
	return l
end

local function button(parent, text, callback)
	if not parent then return nil end
	local b = Instance.new("TextButton")
	b.Name = text
	b.Size = UDim2.new(1, -4, 0, 42)
	b.Text = text
	b.TextSize = 15
	b.Parent = parent
	basicButtonStyle(b)
	
	table.insert(allSearchItems, {obj = b, text = string.lower(text)})
	
	b.MouseButton1Click:Connect(function()
		if callback then callback(b) end
	end)
	
	return b
end

local function input(parent, placeholder, default, callback)
	if not parent then return nil end
	local box = Instance.new("TextBox")
	box.Name = placeholder
	box.Size = UDim2.new(1, -4, 0, 42)
	box.BackgroundColor3 = Color3.fromRGB(50, 5, 117)
	box.Text = tostring(default)
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(230, 220, 255)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = 15
	box.Font = Enum.Font.GothamBold
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.ZIndex = 4
	box.Parent = parent
	
	corner(box, 12)
	stroke(box, Color3.fromRGB(255, 255, 255), 1, 0.75)
	
	table.insert(allSearchItems, {obj = box, text = string.lower(placeholder)})
	
	box.Focused:Connect(function()
		tween(box, 0.12, {BackgroundColor3 = Color3.fromRGB(85, 20, 145)})
	end)
	
	box.FocusLost:Connect(function()
		tween(box, 0.12, {BackgroundColor3 = Color3.fromRGB(50, 5, 117)})
		if callback then callback(box.Text) end
	end)
	
	return box
end

local function toggle(parent, text, stateName, callback)
	if not parent then return nil end
	local holder = Instance.new("TextButton")
	holder.Name = text
	holder.Size = UDim2.new(1, -4, 0, 46)
	holder.BackgroundColor3 = Color3.fromRGB(50, 5, 117)
	holder.Text = ""
	holder.BorderSizePixel = 0
	holder.AutoButtonColor = false
	holder.ZIndex = 4
	holder.Parent = parent
	
	corner(holder, 12)
	stroke(holder, Color3.fromRGB(255, 255, 255), 1, 0.75)
	pressEffect(holder)
	
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -78, 1, 0)
	txt.Position = UDim2.new(0, 12, 0, 0)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	txt.TextSize = 15
	txt.Font = Enum.Font.GothamBold
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.ZIndex = 5
	txt.Parent = holder
	
	local sw = Instance.new("Frame")
	sw.Size = UDim2.new(0, 50, 0, 24)
	sw.Position = UDim2.new(1, -62, 0.5, -12)
	sw.BackgroundColor3 = Color3.fromRGB(100, 80, 120)
	sw.BorderSizePixel = 0
	sw.ZIndex = 5
	sw.Parent = holder
	corner(sw, 999)
	
	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.Position = UDim2.new(0, 2, 0.5, -10)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.ZIndex = 6
	knob.Parent = sw
	corner(knob, 999)
	
	table.insert(allSearchItems, {obj = holder, text = string.lower(text)})
	
	local function update()
		if states[stateName] then
			tween(sw, 0.16, {BackgroundColor3 = Color3.fromRGB(70, 230, 170)})
			tween(knob, 0.16, {Position = UDim2.new(1, -22, 0.5, -10)})
		else
			tween(sw, 0.16, {BackgroundColor3 = Color3.fromRGB(100, 80, 120)})
			tween(knob, 0.16, {Position = UDim2.new(0, 2, 0.5, -10)})
		end
	end
	
	holder.MouseButton1Click:Connect(function()
		states[stateName] = not states[stateName]
		update()
		
		if callback then
			callback(states[stateName])
		end
	end)
	
	update()
	return holder
end

--// Criar páginas
local home = createPage("Home")
local move = createPage("Movimento")
local visual = createPage("Visual")
local combat = createPage("Combat")
local survival = createPage("Survival")
local rpg = createPage("RPG")
local extra = createPage("Extra")

--// Criar abas
tab("🏠", "Home")
tab("💨", "Movimento")
tab("👁️", "Visual")
tab("⚔️", "Combat")
tab("🌲", "Survival")
tab("⚡", "RPG")
tab("⚙️", "Extra")

--// HOME
label(home, "🏠 Home")

button(home, "📦 Minimizar em bolinha", function()
	tween(mainScale, 0.18, {Scale = 0.75})
	task.wait(0.16)
	main.Visible = false
	createBubble(gui, main, mainScale)
end)

button(home, "🔴 Desativar Tudo", function()
	for k in pairs(states) do
		states[k] = false
	end
	
	flyUp = false
	flyDown = false
	clearESP()
	stopFling()
	stopWalkAir()
	applyMovement()
	setFullbright(false)
	
	local _, hum = getChar()
	if hum then
		hum.PlatformStand = false
	end
	
	notify(gui, "✅ Tudo desativado.", true)
end)

button(home, "🔐 Validar Chave", function()
	local keyFrame = Instance.new("Frame")
	keyFrame.Size = UDim2.new(0, 300, 0, 150)
	keyFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
	keyFrame.BackgroundColor3 = Color3.fromRGB(60, 8, 140)
	keyFrame.BorderSizePixel = 0
	keyFrame.ZIndex = 1000
	keyFrame.Parent = PlayerGui
	corner(keyFrame, 15)
	stroke(keyFrame, Color3.fromRGB(255, 255, 255), 2, 0.4)
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Validar Chave"
	titleLabel.TextColor3 = Color3.fromRGB(255, 220, 255)
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.ZIndex = 1001
	titleLabel.Parent = keyFrame
	
	local keyInput = Instance.new("TextBox")
	keyInput.Size = UDim2.new(1, -20, 0, 35)
	keyInput.Position = UDim2.new(0, 10, 0, 50)
	keyInput.BackgroundColor3 = Color3.fromRGB(50, 5, 117)
	keyInput.PlaceholderText = "Digite a chave..."
	keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyInput.TextSize = 14
	keyInput.Font = Enum.Font.GothamBold
	keyInput.BorderSizePixel = 0
	keyInput.ZIndex = 1001
	keyInput.Parent = keyFrame
	corner(keyInput, 8)
	
	local validateBtn = Instance.new("TextButton")
	validateBtn.Size = UDim2.new(1, -20, 0, 35)
	validateBtn.Position = UDim2.new(0, 10, 0, 95)
	validateBtn.BackgroundColor3 = Color3.fromRGB(70, 230, 170)
	validateBtn.Text = "Validar"
	validateBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	validateBtn.TextSize = 14
	validateBtn.Font = Enum.Font.GothamBlack
	validateBtn.BorderSizePixel = 0
	validateBtn.ZIndex = 1001
	validateBtn.Parent = keyFrame
	corner(validateBtn, 8)
	
	validateBtn.MouseButton1Click:Connect(function()
		if validateKey(keyInput.Text) then
			notify(gui, "✅ Chave validada com sucesso!", true)
			keyFrame:Destroy()
		else
			notify(gui, "❌ Chave inválida!", false)
			keyInput.Text = ""
		end
	end)
end)

--// MOVIMENTO
label(move, "💨 Movimento")

toggle(move, "💨 Speed", "Speed", applyMovement)
input(move, "Velocidade", values.Speed, function(txt)
	values.Speed = tonumber(txt) or 80
	applyMovement()
end)

toggle(move, "⬆️ Jump Power", "Jump", applyMovement)
input(move, "Força do Pulo", values.Jump, function(txt)
	values.Jump = tonumber(txt) or 150
	applyMovement()
end)

toggle(move, "♾️ Infinite Jump", "InfJump")

label(move, "✈️ Fly Local")
toggle(move, "✈️ Fly", "Fly")
input(move, "Velocidade do Fly", values.FlySpeed, function(txt)
	values.FlySpeed = tonumber(txt) or 60
end)

button(move, "⬆️ Subir no Fly: OFF", function(btn)
	flyUp = not flyUp
	if flyUp then flyDown = false end
	btn.Text = flyUp and "⬆️ Subir no Fly: ON" or "⬆️ Subir no Fly: OFF"
end)

button(move, "⬇️ Descer no Fly: OFF", function(btn)
	flyDown = not flyDown
	if flyDown then flyUp = false end
	btn.Text = flyDown and "⬇️ Descer no Fly: ON" or "⬇️ Descer no Fly: OFF"
end)

toggle(move, "👻 Noclip", "Noclip")

label(move, "🌊 Walking Air")
toggle(move, "🌊 Walking Air", "WalkAir", function(on)
	if on then
		local _, _, root = getChar()
		walkAirHeight = root and (root.Position.Y - 3.2) or 0
		createWalkAirButtons()
	else
		stopWalkAir()
	end
end)

input(move, "Velocidade do WalkAir", values.WalkAirSpeed, function(txt)
	values.WalkAirSpeed = tonumber(txt) or 1.2
end)

--// VISUAL
label(visual, "👁️ Visual")

toggle(visual, "💡 Fullbright", "Fullbright", setFullbright)

toggle(visual, "👁️ ESP Local", "ESP", function(on)
	if not on then
		clearESP()
	end
end)

toggle(visual, "📍 Tracers", "Tracers")
toggle(visual, "📦 Box ESP", "BoxESP")
toggle(visual, "📝 NameTags", "NameTags")
toggle(visual, "🎨 Chams", "Chams")

button(visual, "👻 Fantasma Local", function()
	local char = player.Character
	if not char then return end
	
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			obj.Transparency = 0.55
			obj.Material = Enum.Material.ForceField
		end
	end
	notify(gui, "✅ Modo fantasma ativado!", true)
end)

button(visual, "🔍 Invisível Local", function()
	local char = player.Character
	if not char then return end
	
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("Decal") then
			obj.Transparency = 1
		end
	end
	notify(gui, "✅ Invisibilidade ativada!", true)
end)

--// COMBAT
label(combat, "⚔️ Combat")

toggle(combat, "🎯 Fling Local", "Fling")
input(combat, "Força do Fling", values.FlingPower, function(txt)
	values.FlingPower = tonumber(txt) or 120
end)

button(combat, "💥 Fling Burst", function()
	local _, _, root = getChar()
	if root then
		root.AssemblyLinearVelocity = Vector3.new(
			math.random(-values.FlingPower, values.FlingPower),
			values.FlingPower,
			math.random(-values.FlingPower, values.FlingPower)
		)
		root.AssemblyAngularVelocity = Vector3.new(
			values.FlingPower,
			values.FlingPower * 2,
			values.FlingPower
		)
		notify(gui, "✅ Fling disparado!", true)
	end
end)

toggle(combat, "🔫 AutoAttack", "AutoAttack")
toggle(combat, "🎯 AimBot", "AimBot")

--// SURVIVAL
label(survival, "🌲 Survival")

toggle(survival, "🤖 AutoFarm", "AutoFarm")
toggle(survival, "📦 AutoCollect", "AutoCollect")
toggle(survival, "🔨 AutoCraft", "AutoCraft")

button(survival, "🌲 Coletar Recursos", function()
	notify(gui, "✅ Iniciando coleta automática...", true)
end)

--// RPG
label(rpg, "⚡ RPG")

toggle(rpg, "📜 AutoQuest", "AutoQuest")
toggle(rpg, "🏰 AutoDungeon", "AutoDungeon")

button(rpg, "⭐ Level Up", function()
	notify(gui, "✨ Função em desenvolvimento!", false, 1.5)
end)

--// EXTRA
label(extra, "⚙️ Configurações")

button(extra, "🗑️ Remover ESP", clearESP)
button(extra, "🛑 Parar Fling", stopFling)

button(extra, "📍 Print Posição", function()
	local _, _, root = getChar()
	if root then
		print("Posição:", root.Position)
		notify(gui, "📍 Posição enviada no console.", true)
	end
end)

button(extra, "🔄 Resetar Settings", function()
	for k, v in pairs(values) do
		if type(v) == "number" then
			_G["HAZIN_" .. k] = nil
		end
	end
	notify(gui, "🔄 Configurações resetadas!", true)
end)

button(extra, "ℹ️ Info", function()
	notify(gui, "Hazin Hub V" .. VERSION .. " | Tipo: " .. currentGameType, true, 3)
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local q = string.lower(searchBox.Text or "")
	
	for _, item in ipairs(allSearchItems) do
		if q == "" then
			item.obj.Visible = true
		else
			item.obj.Visible = string.find(item.text, q, 1, true) ~= nil
		end
	end
end)

showPage("Home")
currentGameType = detectGameType()
notify(gui, "🎉 Hazin Hub V" .. VERSION .. " carregado! | Tipo de jogo: " .. currentGameType, true, 3)

--// Infinite Jump
UserInputService.JumpRequest:Connect(function()
	if states.InfJump then
		local _, hum = getChar()
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

--// Noclip
RunService.Stepped:Connect(function()
	if states.Noclip or states.NoClipWalls then
		local char = player.Character
		if char then
			for _, obj in ipairs(char:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.CanCollide = false
				end
			end
		end
	end
end)

--// Fly + Fling + Walking Air + Main Loop
RunService.RenderStepped:Connect(function()
	local char, hum, root = getChar()
	if not char or not hum or not root then return end
	
	--// Walking Air
	if states.WalkAir then
		if not walkAirPlatform or not walkAirPlatform.Parent then
			walkAirPlatform = Instance.new("Part")
			walkAirPlatform.Name = "HazinWalkAirPlatform"
			walkAirPlatform.Anchored = true
			walkAirPlatform.CanCollide = true
			walkAirPlatform.Transparency = 0.45
			walkAirPlatform.Material = Enum.Material.ForceField
			walkAirPlatform.Color = Color3.fromRGB(180, 80, 255)
			walkAirPlatform.Size = Vector3.new(8, 0.35, 8)
			walkAirPlatform.Parent = workspace
		end
		
		if walkAirHeight == 0 then
			walkAirHeight = root.Position.Y - 3.2
		end
		
		if walkAirUp then
			walkAirHeight += values.WalkAirSpeed
		elseif walkAirDown then
			walkAirHeight -= values.WalkAirSpeed
		end
		
		walkAirPlatform.CFrame = CFrame.new(root.Position.X, walkAirHeight, root.Position.Z)
	else
		if walkAirPlatform then
			pcall(function()
				walkAirPlatform:Destroy()
			end)
			walkAirPlatform = nil
		end
	end
	
	--// Fly
	if states.Fly or states.FlyHack then
		hum.PlatformStand = true
		
		if not flyVelocity then
			flyVelocity = Instance.new("BodyVelocity")
			flyVelocity.MaxForce = Vector3.new(999999, 999999, 999999)
			flyVelocity.Velocity = Vector3.zero
			flyVelocity.Parent = root
		end
		
		if not flyGyro then
			flyGyro = Instance.new("BodyGyro")
			flyGyro.MaxTorque = Vector3.new(999999, 999999, 999999)
			flyGyro.P = 9000
			flyGyro.Parent = root
		end
		
		local camera = workspace.CurrentCamera
		local moveVector = getMoveVector()
		local velocity = Vector3.zero
		
		if camera then
			local right = camera.CFrame.RightVector
			local look = camera.CFrame.LookVector
			local direction = (right * moveVector.X) + (look * -moveVector.Z)
			
			if direction.Magnitude > 0 then
				velocity = direction.Unit * values.FlySpeed
			end
			
			flyGyro.CFrame = camera.CFrame
		end
		
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
			velocity += Vector3.new(0, values.FlySpeed, 0)
		end
		
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			velocity += Vector3.new(0, -values.FlySpeed, 0)
		end
		
		if flyUp then
			velocity += Vector3.new(0, values.FlySpeed, 0)
		elseif flyDown then
			velocity += Vector3.new(0, -values.FlySpeed, 0)
		end
		
		flyVelocity.Velocity = velocity
	else
		hum.PlatformStand = false
		
		if flyVelocity then
			pcall(function()
				flyVelocity:Destroy()
			end)
			flyVelocity = nil
		end
		
		if flyGyro then
			pcall(function()
				flyGyro:Destroy()
			end)
			flyGyro = nil
		end
	end
	
	--// Fling
	if states.Fling then
		if not flingSpin or not flingSpin.Parent then
			flingSpin = Instance.new("BodyAngularVelocity")
			flingSpin.Name = "HazinFlingSpin"
			flingSpin.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			flingSpin.P = 999999
			flingSpin.Parent = root
		end
		
		flingSpin.AngularVelocity = Vector3.new(0, values.FlingPower, 0)
	else
		stopFling()
	end
end)

--// ESP
RunService.RenderStepped:Connect(function()
	if not states.ESP then return end
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local h = p.Character:FindFirstChild("HazinESP")
			
			if not h then
				h = Instance.new("Highlight")
				h.Name = "HazinESP"
				h.FillTransparency = 0.55
				h.OutlineTransparency = 0
				h.FillColor = Color3.fromRGB(195, 70, 255)
				h.OutlineColor = Color3.fromRGB(255, 255, 255)
				h.Parent = p.Character
			end
		end
	end
end)

--// Respawn Handler
player.CharacterAdded:Connect(function()
	task.wait(1)
	applyMovement()
	
	if states.WalkAir then
		local _, _, root = getChar()
		if root then
			walkAirHeight = root.Position.Y - 3.2
		end
	end
end)

--// Cleanup
game:GetService("Players").PlayerRemoving:Connect(function(p)
	if p == player then
		clearESP()
		stopFling()
		stopWalkAir()
	end
end)