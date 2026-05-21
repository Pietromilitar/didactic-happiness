--// HAZIN HUB V4 - 100% LOCALSCRIPT COM GITHUB
--// Key system + painel melhorado + minimizar em bolinha arrastável
--// Coloque em StarterPlayer > StarterPlayerScripts > LocalScript
--// Ou hospede no GitHub e carregue com loadstring(game:HttpGet(URL))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

--// CONFIG
local HUB_NAME = "Hazin Hub"
local HUB_VERSION = "V4"
local HUB_ICON_TEXT = "H"
local HUB_ICON_IMAGE = "" -- opcional: coloque um rbxassetid://ID se quiser imagem na bolinha

local VALID_KEYS = {
	["HAZIN_HUB"] = {
		duration = 60 * 60 * 24,
		name = "Key 1 Dia",
	},

	["HAZI-HUB"] = {
		duration = 60 * 60 * 24 * 7,
		name = "Key 1 Semana",
	},
}

--// Memória local de sessão
_G.HAZIN_KEY_EXPIRES_AT = _G.HAZIN_KEY_EXPIRES_AT or 0
_G.HAZIN_KEY_NAME = _G.HAZIN_KEY_NAME or ""
_G.HAZIN_BUBBLE_POS = _G.HAZIN_BUBBLE_POS or UDim2.new(0, 24, 0.55, 0)

--// Estados
local states = {
	Speed = false,
	Jump = false,
	Fly = false,
	Noclip = false,
	InfJump = false,
	Fullbright = false,
	ESP = false,
}

local values = {
	Speed = 80,
	Jump = 150,
	FlySpeed = 60,
}

local flyUp = false
local flyDown = false
local flyVelocity
local flyGyro
local Controls = nil
local animatedGradients = {}

local createKeyUI
local openPanel

--// PlayerModule Controls: pega WASD, joystick mobile e controle
task.spawn(function()
	local ok, result = pcall(function()
		local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		return PlayerModule:GetControls()
	end)

	if ok then
		Controls = result
	end
end)

local function getMoveVector()
	if Controls then
		local ok, move = pcall(function()
			return Controls:GetMoveVector()
		end)

		if ok and typeof(move) == "Vector3" then
			return move
		end
	end

	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			local md = hum.MoveDirection
			return Vector3.new(md.X, 0, -md.Z)
		end
	end

	return Vector3.zero
end

--// Utils
local function tween(obj, time, props, style, direction)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = obj
	return c
end

local function stroke(obj, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(80, 170, 255)
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = obj
	return s
end

local function padding(obj, all)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, all)
	p.PaddingBottom = UDim.new(0, all)
	p.PaddingLeft = UDim.new(0, all)
	p.PaddingRight = UDim.new(0, all)
	p.Parent = obj
	return p
end

local function gradient(obj, c1, c2, rot, speed)
	local g = Instance.new("UIGradient")
	g.Rotation = rot or 45
	g.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	}
	g.Parent = obj

	if speed then
		table.insert(animatedGradients, {
			gradient = g,
			speed = speed,
		})
	end

	return g
end

local function addScale(obj, value)
	local s = Instance.new("UIScale")
	s.Scale = value or 1
	s.Parent = obj
	return s
end

local function pressEffect(button)
	local scale = addScale(button, 1)

	button.MouseButton1Down:Connect(function()
		tween(scale, 0.08, {Scale = 0.95})
	end)

	button.MouseButton1Up:Connect(function()
		tween(scale, 0.12, {Scale = 1})
	end)

	button.MouseLeave:Connect(function()
		tween(scale, 0.12, {Scale = 1})
	end)
end

local function makeDraggable(handle, frame, onEnd)
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

local function formatTime(seconds)
	seconds = math.max(0, seconds)

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if days > 0 then
		return days .. "d " .. hours .. "h"
	elseif hours > 0 then
		return hours .. "h " .. minutes .. "m"
	else
		return minutes .. "m"
	end
end

local function hasAccess()
	return tonumber(_G.HAZIN_KEY_EXPIRES_AT or 0) > os.time()
end

local function getRemainingTime()
	return math.max(0, (_G.HAZIN_KEY_EXPIRES_AT or 0) - os.time())
end

local function getChar()
	local char = player.Character
	if not char then return nil, nil, nil end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")

	return char, hum, root
end

local function applyMovement()
	local _, hum = getChar()
	if not hum then return end

	hum.UseJumpPower = true
	hum.WalkSpeed = states.Speed and values.Speed or 16
	hum.JumpPower = states.Jump and values.Jump or 50
end

local function clearESP()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			local h = p.Character:FindFirstChild("HazinESP")
			if h then
				h:Destroy()
			end
		end
	end
end

local function notify(parent, text, good)
	local n = Instance.new("TextLabel")
	n.Name = "HazinNotify"
	n.Size = UDim2.new(0, 310, 0, 46)
	n.Position = UDim2.new(0.5, -155, 0, -60)
	n.BackgroundColor3 = good and Color3.fromRGB(0, 145, 110) or Color3.fromRGB(210, 55, 80)
	n.TextColor3 = Color3.fromRGB(255, 255, 255)
	n.Text = text
	n.TextSize = 15
	n.Font = Enum.Font.GothamBold
	n.TextWrapped = true
	n.BorderSizePixel = 0
	n.ZIndex = 50
	n.Parent = parent

	corner(n, 14)
	stroke(n, Color3.fromRGB(255, 255, 255), 1, 0.65)

	tween(n, 0.32, {Position = UDim2.new(0.5, -155, 0, 18)}, Enum.EasingStyle.Back)

	task.delay(2.15, function()
		if n and n.Parent then
			tween(n, 0.22, {Position = UDim2.new(0.5, -155, 0, -60)})
			task.wait(0.25)
			if n then
				n:Destroy()
			end
		end
	end)
end

local function shake(frame)
	local original = frame.Position
	for _ = 1, 3 do
		tween(frame, 0.045, {Position = original + UDim2.new(0, 8, 0, 0)})
		task.wait(0.045)
		tween(frame, 0.045, {Position = original + UDim2.new(0, -8, 0, 0)})
		task.wait(0.045)
	end
	tween(frame, 0.08, {Position = original})
end

local function setButtonTheme(button)
	button.BackgroundColor3 = Color3.fromRGB(16, 24, 80)
	button.TextColor3 = Color3.fromRGB(245, 250, 255)
	button.Font = Enum.Font.GothamBold
	button.BorderSizePixel = 0
	button.AutoButtonColor = false

	corner(button, 13)
	stroke(button, Color3.fromRGB(85, 180, 255), 1, 0.7)
	gradient(button, Color3.fromRGB(17, 26, 144), Color3.fromRGB(70, 130, 230), 30, 10)
	pressEffect(button)
end

--// Bolinha minimizada
local function createBubble(parentGui, mainFrame, mainScale)
	local old = parentGui:FindFirstChild("HazinBubble")
	if old then
		old:Destroy()
	end

	local bubble = Instance.new("TextButton")
	bubble.Name = "HazinBubble"
	bubble.Size = UDim2.new(0, 58, 0, 58)
	bubble.Position = _G.HAZIN_BUBBLE_POS
	bubble.BackgroundColor3 = Color3.fromRGB(0, 8, 55)
	bubble.BorderSizePixel = 0
	bubble.Text = ""
	bubble.AutoButtonColor = false
	bubble.ZIndex = 100
	bubble.Parent = parentGui

	corner(bubble, 999)
	stroke(bubble, Color3.fromRGB(120, 210, 255), 2, 0)
	gradient(bubble, Color3.fromRGB(0, 7, 130), Color3.fromRGB(50, 180, 255), 45, 35)

	local iconHolder

	if HUB_ICON_IMAGE ~= "" then
		iconHolder = Instance.new("ImageLabel")
		iconHolder.Image = HUB_ICON_IMAGE
		iconHolder.BackgroundTransparency = 1
		iconHolder.Size = UDim2.new(0.7, 0, 0.7, 0)
		iconHolder.Position = UDim2.new(0.15, 0, 0.15, 0)
		iconHolder.ZIndex = 101
		iconHolder.Parent = bubble
	else
		iconHolder = Instance.new("TextLabel")
		iconHolder.BackgroundTransparency = 1
		iconHolder.Size = UDim2.new(1, 0, 1, 0)
		iconHolder.Text = HUB_ICON_TEXT
		iconHolder.TextColor3 = Color3.fromRGB(255, 255, 255)
		iconHolder.TextSize = 30
		iconHolder.Font = Enum.Font.GothamBlack
		iconHolder.ZIndex = 101
		iconHolder.Parent = bubble
	end

	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(0.38, 0, 0.38, 0)
	shine.Position = UDim2.new(0.1, 0, 0.08, 0)
	shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shine.BackgroundTransparency = 0.82
	shine.BorderSizePixel = 0
	shine.ZIndex = 102
	shine.Parent = bubble
	corner(shine, 999)

	local scale = addScale(bubble, 0)
	tween(scale, 0.28, {Scale = 1}, Enum.EasingStyle.Back)

	local startedAt
	local startPos
	local moved = false

	bubble.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			startedAt = input.Position
			startPos = bubble.Position
			moved = false
			tween(scale, 0.08, {Scale = 0.92})
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if startedAt and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startedAt

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
		if startedAt and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			_G.HAZIN_BUBBLE_POS = bubble.Position
			tween(scale, 0.1, {Scale = 1})

			if not moved then
				tween(scale, 0.12, {Scale = 0})
				task.wait(0.12)
				if bubble then
					bubble:Destroy()
				end

				mainFrame.Visible = true
				mainScale.Scale = 0.78
				tween(mainScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
			end

			startedAt = nil
		end
	end)

	return bubble
end

--// Key System
createKeyUI = function()
	local old1 = PlayerGui:FindFirstChild("HazinKeySystem")
	if old1 then old1:Destroy() end

	local old2 = PlayerGui:FindFirstChild("HazinMainPanel")
	if old2 then old2:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "HazinKeySystem"
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ResetOnSpawn = false
	gui.Parent = PlayerGui

	local dark = Instance.new("Frame")
	dark.Size = UDim2.new(1, 0, 1, 0)
	dark.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dark.BackgroundTransparency = 1
	dark.Parent = gui
	tween(dark, 0.35, {BackgroundTransparency = 0.32})

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(0, 420, 0, 245)
	main.Position = UDim2.new(0.5, -210, 0.5, -122)
	main.BackgroundColor3 = Color3.fromRGB(3, 8, 42)
	main.BorderSizePixel = 0
	main.Parent = gui

	corner(main, 22)
	stroke(main, Color3.fromRGB(90, 190, 255), 2, 0.1)
	gradient(main, Color3.fromRGB(0, 7, 130), Color3.fromRGB(18, 25, 70), 35, 18)

	local scale = addScale(main, 0.75)
	tween(scale, 0.42, {Scale = 1}, Enum.EasingStyle.Back)

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 70)
	top.BackgroundTransparency = 1
	top.Parent = main
	makeDraggable(top, main)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 44, 0, 44)
	icon.Position = UDim2.new(0, 18, 0, 14)
	icon.BackgroundColor3 = Color3.fromRGB(0, 30, 130)
	icon.Text = HUB_ICON_TEXT
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.TextSize = 24
	icon.Font = Enum.Font.GothamBlack
	icon.BorderSizePixel = 0
	icon.Parent = main
	corner(icon, 14)
	stroke(icon, Color3.fromRGB(110, 210, 255), 1, 0.25)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -110, 0, 30)
	title.Position = UDim2.new(0, 72, 0, 14)
	title.BackgroundTransparency = 1
	title.Text = HUB_NAME
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 25
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = main

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -110, 0, 22)
	sub.Position = UDim2.new(0, 73, 0, 44)
	sub.BackgroundTransparency = 1
	sub.Text = "Key system local • interface melhorada"
	sub.TextColor3 = Color3.fromRGB(190, 225, 255)
	sub.TextSize = 13
	sub.Font = Enum.Font.Gotham
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Parent = main

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 36, 0, 36)
	close.Position = UDim2.new(1, -48, 0, 14)
	close.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
	close.Text = "×"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextSize = 22
	close.Font = Enum.Font.GothamBlack
	close.BorderSizePixel = 0
	close.Parent = main
	corner(close, 12)
	pressEffect(close)

	local keyFrame = Instance.new("Frame")
	keyFrame.Size = UDim2.new(1, -44, 0, 54)
	keyFrame.Position = UDim2.new(0, 22, 0, 92)
	keyFrame.BackgroundColor3 = Color3.fromRGB(18, 27, 95)
	keyFrame.BorderSizePixel = 0
	keyFrame.Parent = main
	corner(keyFrame, 15)
	stroke(keyFrame, Color3.fromRGB(100, 200, 255), 1, 0.35)
	gradient(keyFrame, Color3.fromRGB(15, 25, 105), Color3.fromRGB(80, 155, 255), 0, 8)

	local keyBox = Instance.new("TextBox")
	keyBox.Size = UDim2.new(1, -22, 1, 0)
	keyBox.Position = UDim2.new(0, 11, 0, 0)
	keyBox.BackgroundTransparency = 1
	keyBox.Text = ""
	keyBox.PlaceholderText = "Digite a key..."
	keyBox.PlaceholderColor3 = Color3.fromRGB(210, 230, 255)
	keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyBox.TextSize = 20
	keyBox.ClearTextOnFocus = false
	keyBox.Font = Enum.Font.GothamBold
	keyBox.Parent = keyFrame

	local enter = Instance.new("TextButton")
	enter.Size = UDim2.new(0.56, 0, 0, 46)
	enter.Position = UDim2.new(0.22, 0, 0, 160)
	enter.Text = "ENTRAR"
	enter.TextSize = 18
	enter.Parent = main
	setButtonTheme(enter)

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -20, 0, 24)
	status.Position = UDim2.new(0, 10, 1, -32)
	status.BackgroundTransparency = 1
	status.Text = "Keys: HAZIN_HUB ou HAZI-HUB"
	status.TextColor3 = Color3.fromRGB(220, 235, 255)
	status.TextSize = 13
	status.Font = Enum.Font.GothamBold
	status.Parent = main

	local function closeKey()
		tween(dark, 0.2, {BackgroundTransparency = 1})
		tween(scale, 0.2, {Scale = 0.7})
		task.wait(0.22)
		gui:Destroy()
	end

	local function verify()
		local typed = string.gsub(keyBox.Text or "", "%s+", "")
		local info = VALID_KEYS[typed]

		if info then
			_G.HAZIN_KEY_EXPIRES_AT = os.time() + info.duration
			_G.HAZIN_KEY_NAME = info.name

			status.Text = info.name .. " ativada"
			status.TextColor3 = Color3.fromRGB(0, 255, 160)
			notify(gui, "Key correta. Carregando painel...", true)

			task.wait(0.42)
			tween(dark, 0.23, {BackgroundTransparency = 1})
			tween(scale, 0.2, {Scale = 0.72})
			task.wait(0.22)

			gui:Destroy()
			openPanel()
		else
			status.Text = "Key errada, criatura."
			status.TextColor3 = Color3.fromRGB(255, 90, 110)
			tween(keyFrame, 0.15, {BackgroundColor3 = Color3.fromRGB(140, 25, 55)})
			shake(main)
			task.wait(0.32)
			tween(keyFrame, 0.18, {BackgroundColor3 = Color3.fromRGB(18, 27, 95)})
		end
	end

	enter.MouseButton1Click:Connect(verify)

	keyBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			verify()
		end
	end)

	close.MouseButton1Click:Connect(closeKey)
end

--// Main Panel
openPanel = function()
	local old = PlayerGui:FindFirstChild("HazinMainPanel")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "HazinMainPanel"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui

	local main = Instance.new("Frame")
	main.Name = "MainPanel"
	main.Size = UDim2.new(0, 470, 0, 520)
	main.Position = UDim2.new(0.5, -235, 0.5, -260)
	main.BackgroundColor3 = Color3.fromRGB(5, 8, 32)
	main.BorderSizePixel = 0
	main.Parent = gui

	corner(main, 22)
	stroke(main, Color3.fromRGB(85, 185, 255), 2, 0.08)
	gradient(main, Color3.fromRGB(0, 7, 130), Color3.fromRGB(9, 12, 42), 45, 8)

	local scale = addScale(main, 0.78)
	tween(scale, 0.42, {Scale = 1}, Enum.EasingStyle.Back)

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 66)
	top.BackgroundColor3 = Color3.fromRGB(7, 12, 48)
	top.BorderSizePixel = 0
	top.Parent = main
	corner(top, 22)

	makeDraggable(top, main)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 42, 0, 42)
	icon.Position = UDim2.new(0, 15, 0, 12)
	icon.BackgroundColor3 = Color3.fromRGB(0, 35, 135)
	icon.Text = HUB_ICON_TEXT
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.TextSize = 24
	icon.Font = Enum.Font.GothamBlack
	icon.BorderSizePixel = 0
	icon.Parent = top
	corner(icon, 14)
	stroke(icon, Color3.fromRGB(100, 205, 255), 1, 0.2)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -165, 0, 34)
	title.Position = UDim2.new(0, 66, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = HUB_NAME .. " " .. HUB_VERSION
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 23
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = top

	local keyTimer = Instance.new("TextLabel")
	keyTimer.Size = UDim2.new(1, -165, 0, 20)
	keyTimer.Position = UDim2.new(0, 67, 0, 39)
	keyTimer.BackgroundTransparency = 1
	keyTimer.Text = "Key ativa"
	keyTimer.TextColor3 = Color3.fromRGB(180, 220, 255)
	keyTimer.TextSize = 12
	keyTimer.Font = Enum.Font.GothamMedium
	keyTimer.TextXAlignment = Enum.TextXAlignment.Left
	keyTimer.Parent = top

	local minimize = Instance.new("TextButton")
	minimize.Size = UDim2.new(0, 38, 0, 38)
	minimize.Position = UDim2.new(1, -92, 0, 14)
	minimize.BackgroundColor3 = Color3.fromRGB(20, 110, 230)
	minimize.Text = "–"
	minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
	minimize.TextSize = 26
	minimize.Font = Enum.Font.GothamBlack
	minimize.BorderSizePixel = 0
	minimize.Parent = top
	corner(minimize, 12)
	pressEffect(minimize)

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 38, 0, 38)
	close.Position = UDim2.new(1, -48, 0, 14)
	close.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
	close.Text = "×"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextSize = 24
	close.Font = Enum.Font.GothamBlack
	close.BorderSizePixel = 0
	close.Parent = top
	corner(close, 12)
	pressEffect(close)

	minimize.MouseButton1Click:Connect(function()
		tween(scale, 0.18, {Scale = 0.72})
		task.wait(0.16)
		main.Visible = false
		createBubble(gui, main, scale)
	end)

	close.MouseButton1Click:Connect(function()
		tween(scale, 0.2, {Scale = 0.72})
		task.wait(0.22)
		gui:Destroy()
	end)

	local sidebar = Instance.new("Frame")
	sidebar.Size = UDim2.new(0, 126, 1, -82)
	sidebar.Position = UDim2.new(0, 12, 0, 74)
	sidebar.BackgroundColor3 = Color3.fromRGB(7, 11, 40)
	sidebar.BorderSizePixel = 0
	sidebar.Parent = main
	corner(sidebar, 18)
	stroke(sidebar, Color3.fromRGB(80, 170, 255), 1, 0.72)
	padding(sidebar, 8)

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0, 8)
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Parent = sidebar

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -158, 1, -82)
	content.Position = UDim2.new(0, 146, 0, 74)
	content.BackgroundColor3 = Color3.fromRGB(9, 13, 43)
	content.BorderSizePixel = 0
	content.Parent = main
	corner(content, 18)
	stroke(content, Color3.fromRGB(80, 170, 255), 1, 0.74)

	local pages = {}
	local tabButtons = {}

	local function createPage(name)
		local page = Instance.new("ScrollingFrame")
		page.Name = name
		page.Size = UDim2.new(1, -16, 1, -16)
		page.Position = UDim2.new(0, 8, 0, 8)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 4
		page.ScrollBarImageColor3 = Color3.fromRGB(90, 190, 255)
		page.Visible = false
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
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
		for pageName, page in pairs(pages) do
			page.Visible = pageName == name
		end

		for pageName, btn in pairs(tabButtons) do
			btn.BackgroundColor3 = pageName == name and Color3.fromRGB(25, 95, 180) or Color3.fromRGB(13, 22, 75)
		end

		local page = pages[name]
		if page then
			page.Position = UDim2.new(0, 18, 0, 8)
			tween(page, 0.22, {Position = UDim2.new(0, 8, 0, 8)})
		end
	end

	local function tab(text, pageName)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 42)
		b.Text = text
		b.TextSize = 14
		b.Parent = sidebar
		setButtonTheme(b)
		tabButtons[pageName] = b

		b.MouseButton1Click:Connect(function()
			showPage(pageName)
		end)
	end

	local function label(parent, text)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -4, 0, 28)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = Color3.fromRGB(115, 205, 255)
		l.TextSize = 17
		l.Font = Enum.Font.GothamBlack
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = parent
		return l
	end

	local function button(parent, text, callback)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -4, 0, 42)
		b.Text = text
		b.TextSize = 15
		b.Parent = parent
		setButtonTheme(b)

		b.MouseButton1Click:Connect(function()
			callback(b)
		end)

		return b
	end

	local function input(parent, placeholder, default, callback)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -4, 0, 42)
		box.BackgroundColor3 = Color3.fromRGB(14, 24, 80)
		box.BorderSizePixel = 0
		box.Text = tostring(default)
		box.PlaceholderText = placeholder
		box.PlaceholderColor3 = Color3.fromRGB(155, 195, 255)
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.TextSize = 15
		box.Font = Enum.Font.GothamBold
		box.ClearTextOnFocus = false
		box.Parent = parent
		corner(box, 13)
		stroke(box, Color3.fromRGB(85, 180, 255), 1, 0.72)

		box.Focused:Connect(function()
			tween(box, 0.14, {BackgroundColor3 = Color3.fromRGB(24, 42, 130)})
		end)

		box.FocusLost:Connect(function()
			tween(box, 0.14, {BackgroundColor3 = Color3.fromRGB(14, 24, 80)})
			callback(box.Text)
		end)
	end

	local function toggle(parent, text, stateName, callback)
		local holder = Instance.new("TextButton")
		holder.Size = UDim2.new(1, -4, 0, 46)
		holder.BackgroundColor3 = Color3.fromRGB(14, 24, 80)
		holder.Text = ""
		holder.BorderSizePixel = 0
		holder.AutoButtonColor = false
		holder.Parent = parent
		corner(holder, 14)
		stroke(holder, Color3.fromRGB(85, 180, 255), 1, 0.72)
		pressEffect(holder)

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, -80, 1, 0)
		txt.Position = UDim2.new(0, 13, 0, 0)
		txt.BackgroundTransparency = 1
		txt.Text = text
		txt.TextColor3 = Color3.fromRGB(255, 255, 255)
		txt.TextSize = 15
		txt.Font = Enum.Font.GothamBold
		txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.Parent = holder

		local switch = Instance.new("Frame")
		switch.Size = UDim2.new(0, 52, 0, 24)
		switch.Position = UDim2.new(1, -64, 0.5, -12)
		switch.BackgroundColor3 = Color3.fromRGB(90, 95, 115)
		switch.BorderSizePixel = 0
		switch.Parent = holder
		corner(switch, 999)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 20, 0, 20)
		knob.Position = UDim2.new(0, 2, 0.5, -10)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		knob.Parent = switch
		corner(knob, 999)

		local function update()
			if states[stateName] then
				tween(switch, 0.16, {BackgroundColor3 = Color3.fromRGB(0, 170, 125)})
				tween(knob, 0.16, {Position = UDim2.new(1, -22, 0.5, -10)})
			else
				tween(switch, 0.16, {BackgroundColor3 = Color3.fromRGB(90, 95, 115)})
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
	end

	local home = createPage("Home")
	local move = createPage("Movimento")
	local visual = createPage("Visual")
	local playerPage = createPage("Player")

	tab("Home", "Home")
	tab("Movimento", "Movimento")
	tab("Visual", "Visual")
	tab("Player", "Player")

	-- Home
	label(home, "Informações")

	local keyInfo = Instance.new("TextLabel")
	keyInfo.Size = UDim2.new(1, -4, 0, 68)
	keyInfo.BackgroundColor3 = Color3.fromRGB(14, 24, 80)
	keyInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyInfo.TextSize = 14
	keyInfo.Font = Enum.Font.GothamBold
	keyInfo.TextWrapped = true
	keyInfo.Text = "Key ativa"
	keyInfo.Parent = home
	corner(keyInfo, 14)
	stroke(keyInfo, Color3.fromRGB(85, 180, 255), 1, 0.72)

	button(home, "Minimizar em bolinha", function()
		tween(scale, 0.18, {Scale = 0.72})
		task.wait(0.16)
		main.Visible = false
		createBubble(gui, main, scale)
	end)

	button(home, "Esquecer Key", function()
		_G.HAZIN_KEY_EXPIRES_AT = 0
		_G.HAZIN_KEY_NAME = ""
		gui:Destroy()
		createKeyUI()
	end)

	-- Movimento
	label(move, "Movimento")
	toggle(move, "Speed", "Speed", applyMovement)
	input(move, "Valor do Speed", values.Speed, function(txt)
		values.Speed = tonumber(txt) or 80
		applyMovement()
	end)

	toggle(move, "Jump Power", "Jump", applyMovement)
	input(move, "Valor do Jump", values.Jump, function(txt)
		values.Jump = tonumber(txt) or 150
		applyMovement()
	end)

	toggle(move, "Infinite Jump", "InfJump")

	label(move, "Fly por direcional / WASD")
	toggle(move, "Fly Local", "Fly")
	input(move, "Fly Speed", values.FlySpeed, function(txt)
		values.FlySpeed = tonumber(txt) or 60
	end)

	button(move, "Subir no Fly: OFF", function(btn)
		flyUp = not flyUp
		if flyUp then flyDown = false end
		btn.Text = flyUp and "Subir no Fly: ON" or "Subir no Fly: OFF"
	end)

	button(move, "Descer no Fly: OFF", function(btn)
		flyDown = not flyDown
		if flyDown then flyUp = false end
		btn.Text = flyDown and "Descer no Fly: ON" or "Descer no Fly: OFF"
	end)

	toggle(move, "Noclip", "Noclip")

	-- Visual
	label(visual, "Visual")
	toggle(visual, "Fullbright", "Fullbright", function(on)
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

	toggle(visual, "ESP Local", "ESP", function(on)
		if not on then
			clearESP()
		end
	end)

	button(visual, "Fantasma Local", function()
		local char = player.Character
		if not char then return end

		for _, obj in ipairs(char:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
				obj.Transparency = 0.55
				obj.Material = Enum.Material.ForceField
			end
		end
	end)

	button(visual, "Invisível Local", function()
		local char = player.Character
		if not char then return end

		for _, obj in ipairs(char:GetDescendants()) do
			if obj:IsA("BasePart") or obj:IsA("Decal") then
				obj.Transparency = 1
			end
		end
	end)

	button(visual, "Visível Local", function()
		local char = player.Character
		if not char then return end

		for _, obj in ipairs(char:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
				obj.Transparency = 0
				obj.Material = Enum.Material.Plastic
			elseif obj:IsA("Decal") then
				obj.Transparency = 0
			end
		end
	end)

	-- Player
	label(playerPage, "Player")

	button(playerPage, "Heal Local", function()
		local _, hum = getChar()
		if hum then
			hum.Health = hum.MaxHealth
		end
	end)

	button(playerPage, "Reset", function()
		local _, hum = getChar()
		if hum then
			hum.Health = 0
		end
	end)

	button(playerPage, "TP Spawn Local", function()
		local _, _, root = getChar()
		if root then
			local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation")
			if spawn then
				root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
			end
		end
	end)

	button(playerPage, "Sentar", function()
		local _, hum = getChar()
		if hum then
			hum.Sit = true
		end
	end)

	button(playerPage, "Desativar Tudo", function()
		for k in pairs(states) do
			states[k] = false
		end

		flyUp = false
		flyDown = false
		clearESP()
		applyMovement()

		local _, hum = getChar()
		if hum then
			hum.PlatformStand = false
		end

		Lighting.Brightness = 1
		Lighting.ClockTime = 12
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = true

		notify(gui, "Tudo desativado.", true)
	end)

	task.spawn(function()
		while gui.Parent do
			if not hasAccess() then
				gui:Destroy()
				createKeyUI()
				break
			end

			local rest = getRemainingTime()
			local text = "Key: " .. tostring(_G.HAZIN_KEY_NAME) .. " | expira em " .. formatTime(rest)
			keyTimer.Text = text
			keyInfo.Text = text .. "\nMinimize no botão – e arraste a bolinha para qualquer canto."

			task.wait(1)
		end
	end)

	showPage("Home")
	notify(gui, "Painel carregado.", true)
end

--// Loops das funções
UserInputService.JumpRequest:Connect(function()
	if states.InfJump then
		local _, hum = getChar()
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

RunService.Stepped:Connect(function()
	if states.Noclip then
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

RunService.RenderStepped:Connect(function(dt)
	for i = #animatedGradients, 1, -1 do
		local data = animatedGradients[i]

		if data.gradient and data.gradient.Parent then
			data.gradient.Rotation = (data.gradient.Rotation + data.speed * dt) % 360
		else
			table.remove(animatedGradients, i)
		end
	end

	local char, hum, root = getChar()
	if not char or not hum or not root then return end

	if states.Fly then
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
			flyVelocity:Destroy()
			flyVelocity = nil
		end

		if flyGyro then
			flyGyro:Destroy()
			flyGyro = nil
		end
	end
end)

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
				h.FillColor = Color3.fromRGB(0, 170, 255)
				h.OutlineColor = Color3.fromRGB(255, 255, 255)
				h.Parent = p.Character
			end
		end
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(1)
	applyMovement()
end)

--// Start
task.wait(1)

if hasAccess() then
	openPanel()
else
	createKeyUI()
end
