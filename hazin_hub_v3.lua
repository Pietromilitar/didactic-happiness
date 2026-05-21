--// HAZIN HUB V3 - 100% LOCALSCRIPT
--// Key system + painel animado + fly por WASD/direcional mobile
--// Studio Lite / Roblox LocalScript
--// Coloque em: StarterPlayer > StarterPlayerScripts > LocalScript

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local HUB_NAME = "Hazin Hub"

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

_G.HAZIN_KEY_EXPIRES_AT = _G.HAZIN_KEY_EXPIRES_AT or 0
_G.HAZIN_KEY_NAME = _G.HAZIN_KEY_NAME or ""

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

local animatedGradients = {}
local createKeyUI
local openPanel
local Controls = nil

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

local function tween(obj, time, props, style, direction)
	local info = TweenInfo.new(
		time or 0.25,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)

	local tw = TweenService:Create(obj, info, props)
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
	s.Color = color or Color3.fromRGB(130, 203, 255)
	s.Thickness = thickness or 2
	s.Transparency = transparency or 0
	s.Parent = obj
	return s
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

local function addScale(obj, scaleValue)
	local sc = Instance.new("UIScale")
	sc.Scale = scaleValue or 1
	sc.Parent = obj
	return sc
end

local function pressEffect(button)
	local sc = addScale(button, 1)

	button.MouseButton1Down:Connect(function()
		tween(sc, 0.08, {Scale = 0.96})
	end)

	button.MouseButton1Up:Connect(function()
		tween(sc, 0.12, {Scale = 1})
	end)

	button.MouseLeave:Connect(function()
		tween(sc, 0.12, {Scale = 1})
	end)
end

local function makeDraggable(handle, frame)
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
	local char, hum = getChar()
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

local function notification(parent, text, good)
	local n = Instance.new("TextLabel")
	n.Size = UDim2.new(0, 300, 0, 44)
	n.Position = UDim2.new(0.5, -150, 0, -55)
	n.BackgroundColor3 = good and Color3.fromRGB(0, 120, 90) or Color3.fromRGB(180, 50, 70)
	n.TextColor3 = Color3.fromRGB(255, 255, 255)
	n.Text = text
	n.TextSize = 16
	n.Font = Enum.Font.GothamBold
	n.BorderSizePixel = 0
	n.Parent = parent

	corner(n, 12)
	stroke(n, Color3.fromRGB(255, 255, 255), 1, 0.7)

	tween(n, 0.35, {Position = UDim2.new(0.5, -150, 0, 15)}, Enum.EasingStyle.Back)

	task.delay(2, function()
		if n then
			tween(n, 0.25, {Position = UDim2.new(0.5, -150, 0, -55)})
			task.wait(0.3)
			if n then
				n:Destroy()
			end
		end
	end)
end

local function shake(frame)
	local original = frame.Position

	for i = 1, 3 do
		tween(frame, 0.05, {Position = original + UDim2.new(0, 8, 0, 0)})
		task.wait(0.05)
		tween(frame, 0.05, {Position = original + UDim2.new(0, -8, 0, 0)})
		task.wait(0.05)
	end

	tween(frame, 0.08, {Position = original})
end

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

	tween(dark, 0.35, {BackgroundTransparency = 0.35})

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(0, 400, 0, 230)
	main.Position = UDim2.new(0.5, -200, 0.5, -115)
	main.BackgroundColor3 = Color3.fromRGB(0, 7, 130)
	main.BorderSizePixel = 0
	main.Parent = gui

	corner(main, 20)
	stroke(main, Color3.fromRGB(130, 203, 255), 2, 0)
	gradient(main, Color3.fromRGB(0, 7, 130), Color3.fromRGB(255, 255, 255), 45, 18)

	local scale = addScale(main, 0.75)
	tween(scale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 56)
	top.BackgroundTransparency = 1
	top.Parent = main

	makeDraggable(top, main)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 0, 32)
	title.Position = UDim2.new(0, 18, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = HUB_NAME
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 26
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = main

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -40, 0, 24)
	subtitle.Position = UDim2.new(0, 20, 0, 45)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Key system local • acesso temporário"
	subtitle.TextColor3 = Color3.fromRGB(220, 235, 255)
	subtitle.TextSize = 14
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = main

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 36, 0, 36)
	close.Position = UDim2.new(1, -48, 0, 12)
	close.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextSize = 18
	close.Font = Enum.Font.GothamBold
	close.BorderSizePixel = 0
	close.Parent = main

	corner(close, 10)
	pressEffect(close)

	local keyFrame = Instance.new("Frame")
	keyFrame.Size = UDim2.new(1, -46, 0, 52)
	keyFrame.Position = UDim2.new(0, 23, 0, 88)
	keyFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 150)
	keyFrame.BorderSizePixel = 0
	keyFrame.Parent = main

	corner(keyFrame, 14)
	stroke(keyFrame, Color3.fromRGB(130, 203, 255), 2, 0.1)
	gradient(keyFrame, Color3.fromRGB(17, 26, 144), Color3.fromRGB(255, 255, 255), 0, 10)

	local keyBox = Instance.new("TextBox")
	keyBox.Name = "Senha Aqui"
	keyBox.Size = UDim2.new(1, -22, 1, 0)
	keyBox.Position = UDim2.new(0, 11, 0, 0)
	keyBox.BackgroundTransparency = 1
	keyBox.Text = ""
	keyBox.PlaceholderText = "Digite a key aqui..."
	keyBox.PlaceholderColor3 = Color3.fromRGB(230, 230, 230)
	keyBox.TextColor3 = Color3.fromRGB(0, 0, 0)
	keyBox.TextSize = 22
	keyBox.ClearTextOnFocus = false
	keyBox.Font = Enum.Font.GothamBold
	keyBox.Parent = keyFrame

	local enter = Instance.new("TextButton")
	enter.Size = UDim2.new(0.52, 0, 0, 44)
	enter.Position = UDim2.new(0.24, 0, 0, 154)
	enter.BackgroundColor3 = Color3.fromRGB(0, 20, 160)
	enter.Text = "ENTRAR"
	enter.TextColor3 = Color3.fromRGB(255, 255, 255)
	enter.TextSize = 19
	enter.Font = Enum.Font.GothamBold
	enter.BorderSizePixel = 0
	enter.Parent = main

	corner(enter, 14)
	stroke(enter, Color3.fromRGB(255, 255, 255), 1, 0.65)
	gradient(enter, Color3.fromRGB(0, 7, 130), Color3.fromRGB(112, 173, 219), 45, 25)
	pressEffect(enter)

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -20, 0, 24)
	status.Position = UDim2.new(0, 10, 1, -30)
	status.BackgroundTransparency = 1
	status.Text = "Keys: 1234 ou SEMANA123"
	status.TextColor3 = Color3.fromRGB(245, 245, 245)
	status.TextSize = 14
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

			status.Text = info.name .. " ativada!"
			status.TextColor3 = Color3.fromRGB(0, 255, 120)
			notification(gui, "Key correta. Carregando painel...", true)

			task.wait(0.45)

			tween(dark, 0.25, {BackgroundTransparency = 1})
			tween(scale, 0.25, {Scale = 1.15})
			task.wait(0.1)
			tween(scale, 0.2, {Scale = 0.65})

			task.wait(0.22)
			gui:Destroy()
			openPanel()
		else
			status.Text = "Key errada, criatura."
			status.TextColor3 = Color3.fromRGB(255, 70, 90)
			tween(keyFrame, 0.15, {BackgroundColor3 = Color3.fromRGB(160, 20, 50)})
			shake(main)
			task.wait(0.35)
			tween(keyFrame, 0.2, {BackgroundColor3 = Color3.fromRGB(20, 30, 150)})
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

openPanel = function()
	local old = PlayerGui:FindFirstChild("HazinMainPanel")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "HazinMainPanel"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui

	local main = Instance.new("Frame")
	main.Size = UDim2.new(0, 450, 0, 500)
	main.Position = UDim2.new(0.5, -225, 0.5, -250)
	main.BackgroundColor3 = Color3.fromRGB(9, 12, 40)
	main.BorderSizePixel = 0
	main.Parent = gui

	corner(main, 20)
	stroke(main, Color3.fromRGB(130, 203, 255), 2, 0)
	gradient(main, Color3.fromRGB(0, 7, 130), Color3.fromRGB(30, 40, 95), 45, 8)

	local scale = addScale(main, 0.8)
	tween(scale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 58)
	top.BackgroundColor3 = Color3.fromRGB(10, 15, 60)
	top.BorderSizePixel = 0
	top.Parent = main
	corner(top, 20)

	makeDraggable(top, main)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -110, 0, 34)
	title.Position = UDim2.new(0, 18, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = HUB_NAME .. " V3"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = top

	local keyTimer = Instance.new("TextLabel")
	keyTimer.Size = UDim2.new(1, -120, 0, 20)
	keyTimer.Position = UDim2.new(0, 20, 0, 35)
	keyTimer.BackgroundTransparency = 1
	keyTimer.Text = "Key ativa"
	keyTimer.TextColor3 = Color3.fromRGB(190, 220, 255)
	keyTimer.TextSize = 13
	keyTimer.Font = Enum.Font.Gotham
	keyTimer.TextXAlignment = Enum.TextXAlignment.Left
	keyTimer.Parent = top

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 38, 0, 38)
	close.Position = UDim2.new(1, -50, 0, 10)
	close.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextSize = 19
	close.Font = Enum.Font.GothamBold
	close.BorderSizePixel = 0
	close.Parent = top
	corner(close, 12)
	pressEffect(close)

	local sidebar = Instance.new("Frame")
	sidebar.Size = UDim2.new(0, 120, 1, -72)
	sidebar.Position = UDim2.new(0, 12, 0, 64)
	sidebar.BackgroundColor3 = Color3.fromRGB(8, 10, 35)
	sidebar.BorderSizePixel = 0
	sidebar.Parent = main
	corner(sidebar, 16)
	stroke(sidebar, Color3.fromRGB(130, 203, 255), 1, 0.7)

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0, 8)
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Parent = sidebar

	local sidePadding = Instance.new("UIPadding")
	sidePadding.PaddingTop = UDim.new(0, 10)
	sidePadding.PaddingLeft = UDim.new(0, 8)
	sidePadding.PaddingRight = UDim.new(0, 8)
	sidePadding.Parent = sidebar

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -150, 1, -72)
	content.Position = UDim2.new(0, 140, 0, 64)
	content.BackgroundColor3 = Color3.fromRGB(12, 15, 45)
	content.BorderSizePixel = 0
	content.Parent = main
	corner(content, 16)
	stroke(content, Color3.fromRGB(130, 203, 255), 1, 0.75)

	local pages = {}

	local function createPage(name)
		local page = Instance.new("ScrollingFrame")
		page.Name = name
		page.Size = UDim2.new(1, -16, 1, -16)
		page.Position = UDim2.new(0, 8, 0, 8)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 4
		page.Visible = false
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.Parent = content

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = page

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
		end)

		pages[name] = page
		return page
	end

	local function showPage(name)
		for pageName, page in pairs(pages) do
			page.Visible = pageName == name
		end

		local page = pages[name]
		if page then
			page.Position = UDim2.new(0, 18, 0, 8)
			tween(page, 0.25, {Position = UDim2.new(0, 8, 0, 8)})
		end
	end

	local function tabButton(text, pageName)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 40)
		b.BackgroundColor3 = Color3.fromRGB(17, 26, 144)
		b.Text = text
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.TextSize = 15
		b.Font = Enum.Font.GothamBold
		b.BorderSizePixel = 0
		b.Parent = sidebar

		corner(b, 12)
		gradient(b, Color3.fromRGB(17, 26, 144), Color3.fromRGB(70, 110, 200), 45, 12)
		pressEffect(b)

		b.MouseButton1Click:Connect(function()
			showPage(pageName)
		end)
	end

	local function label(parent, text)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -4, 0, 28)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = Color3.fromRGB(130, 203, 255)
		l.TextSize = 18
		l.Font = Enum.Font.GothamBold
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = parent
		return l
	end

	local function button(parent, text, callback)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -4, 0, 42)
		b.BackgroundColor3 = Color3.fromRGB(18, 26, 100)
		b.Text = text
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.TextSize = 16
		b.Font = Enum.Font.GothamBold
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Parent = parent

		corner(b, 12)
		stroke(b, Color3.fromRGB(130, 203, 255), 1, 0.75)
		gradient(b, Color3.fromRGB(17, 26, 144), Color3.fromRGB(80, 130, 220), 35, 12)
		pressEffect(b)

		b.MouseButton1Click:Connect(function()
			callback(b)
		end)

		return b
	end

	local function toggle(parent, text, stateName, callback)
		local holder = Instance.new("TextButton")
		holder.Size = UDim2.new(1, -4, 0, 46)
		holder.BackgroundColor3 = Color3.fromRGB(18, 26, 100)
		holder.Text = ""
		holder.BorderSizePixel = 0
		holder.AutoButtonColor = false
		holder.Parent = parent

		corner(holder, 12)
		stroke(holder, Color3.fromRGB(130, 203, 255), 1, 0.75)

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, -78, 1, 0)
		txt.Position = UDim2.new(0, 14, 0, 0)
		txt.BackgroundTransparency = 1
		txt.Text = text
		txt.TextColor3 = Color3.fromRGB(255, 255, 255)
		txt.TextSize = 16
		txt.Font = Enum.Font.GothamBold
		txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.Parent = holder

		local switch = Instance.new("Frame")
		switch.Size = UDim2.new(0, 50, 0, 24)
		switch.Position = UDim2.new(1, -62, 0.5, -12)
		switch.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
		switch.BorderSizePixel = 0
		switch.Parent = holder
		corner(switch, 99)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 20, 0, 20)
		knob.Position = UDim2.new(0, 2, 0.5, -10)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		knob.Parent = switch
		corner(knob, 99)

		pressEffect(holder)

		local function update()
			local on = states[stateName]

			if on then
				tween(switch, 0.18, {BackgroundColor3 = Color3.fromRGB(0, 170, 120)})
				tween(knob, 0.18, {Position = UDim2.new(1, -22, 0.5, -10)})
			else
				tween(switch, 0.18, {BackgroundColor3 = Color3.fromRGB(90, 90, 110)})
				tween(knob, 0.18, {Position = UDim2.new(0, 2, 0.5, -10)})
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

	local function input(parent, text, default, callback)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -4, 0, 42)
		box.BackgroundColor3 = Color3.fromRGB(22, 30, 90)
		box.BorderSizePixel = 0
		box.Text = tostring(default)
		box.PlaceholderText = text
		box.PlaceholderColor3 = Color3.fromRGB(170, 190, 230)
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.TextSize = 16
		box.Font = Enum.Font.GothamBold
		box.ClearTextOnFocus = false
		box.Parent = parent

		corner(box, 12)
		stroke(box, Color3.fromRGB(130, 203, 255), 1, 0.75)

		box.Focused:Connect(function()
			tween(box, 0.15, {BackgroundColor3 = Color3.fromRGB(35, 45, 130)})
		end)

		box.FocusLost:Connect(function()
			tween(box, 0.15, {BackgroundColor3 = Color3.fromRGB(22, 30, 90)})
			callback(box.Text)
		end)

		return box
	end

	local home = createPage("Home")
	local move = createPage("Movimento")
	local visual = createPage("Visual")
	local playerPage = createPage("Player")

	tabButton("Home", "Home")
	tabButton("Movimento", "Movimento")
	tabButton("Visual", "Visual")
	tabButton("Player", "Player")

	label(home, "Informações")

	local keyInfo = Instance.new("TextLabel")
	keyInfo.Size = UDim2.new(1, -4, 0, 58)
	keyInfo.BackgroundColor3 = Color3.fromRGB(18, 26, 100)
	keyInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyInfo.TextSize = 15
	keyInfo.Font = Enum.Font.GothamBold
	keyInfo.TextWrapped = true
	keyInfo.Text = "Key ativa"
	keyInfo.Parent = home
	corner(keyInfo, 12)
	stroke(keyInfo, Color3.fromRGB(130, 203, 255), 1, 0.7)

	button(home, "Esquecer Key", function()
		_G.HAZIN_KEY_EXPIRES_AT = 0
		_G.HAZIN_KEY_NAME = ""
		gui:Destroy()
		createKeyUI()
	end)

	button(home, "Fechar Painel", function()
		tween(scale, 0.2, {Scale = 0.75})
		task.wait(0.22)
		gui:Destroy()
	end)

	label(move, "Movimento")

	toggle(move, "Speed", "Speed", function()
		applyMovement()
	end)

	input(move, "Valor do Speed", values.Speed, function(txt)
		values.Speed = tonumber(txt) or 80
		applyMovement()
	end)

	toggle(move, "Jump Power", "Jump", function()
		applyMovement()
	end)

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

	label(playerPage, "Player")

	button(playerPage, "Heal Local", function()
		local char, hum = getChar()
		if hum then
			hum.Health = hum.MaxHealth
		end
	end)

	button(playerPage, "Reset", function()
		local char, hum = getChar()
		if hum then
			hum.Health = 0
		end
	end)

	button(playerPage, "TP Spawn Local", function()
		local char, hum, root = getChar()
		if root then
			local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation")
			if spawn then
				root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
			end
		end
	end)

	button(playerPage, "Sentar", function()
		local char, hum = getChar()
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

		local char, hum = getChar()
		if hum then
			hum.PlatformStand = false
		end

		Lighting.Brightness = 1
		Lighting.ClockTime = 12
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = true

		notification(gui, "Tudo desativado.", true)
	end)

	close.MouseButton1Click:Connect(function()
		tween(scale, 0.2, {Scale = 0.75})
		task.wait(0.22)
		gui:Destroy()
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
			keyInfo.Text = text

			task.wait(1)
		end
	end)

	showPage("Home")
	notification(gui, "Painel carregado.", true)
end

UserInputService.JumpRequest:Connect(function()
	if states.InfJump then
		local char, hum = getChar()
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

			local direction =
				(right * moveVector.X) +
				(look * -moveVector.Z)

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

task.wait(1)

if hasAccess() then
	openPanel()
else
	createKeyUI()
end
