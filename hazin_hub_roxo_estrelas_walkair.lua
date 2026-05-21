--// HAZIN HUB - UI roxa com estrelas + funções locais
--// 100% LocalScript
--// Coloque em StarterPlayer > StarterPlayerScripts > LocalScript
--// Se quiser usar GitHub: cole esse conteúdo em um arquivo .lua e carregue com loadstring(game:HttpGet(URL))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local HUB_NAME = "Hazin Hub"
local HUB_ICON = "H"

local states = {
	Speed = false,
	Jump = false,
	Fly = false,
	Noclip = false,
	InfJump = false,
	Fullbright = false,
	ESP = false,
	Fling = false,
	WalkAir = false,
}

local values = {
	Speed = 80,
	Jump = 150,
	FlySpeed = 60,
	FlingPower = 120,
	WalkAirSpeed = 1.2,
}

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

_G.HAZIN_BUBBLE_POS = _G.HAZIN_BUBBLE_POS or UDim2.new(0, 24, 0.55, 0)
_G.HAZIN_WALKAIR_UP_POS = _G.HAZIN_WALKAIR_UP_POS or UDim2.new(1, -150, 0.58, 0)
_G.HAZIN_WALKAIR_DOWN_POS = _G.HAZIN_WALKAIR_DOWN_POS or UDim2.new(1, -150, 0.72, 0)

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

local function tween(obj, time, props, style, dir)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
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
	s.Color = color or Color3.fromRGB(255, 255, 255)
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.4
	s.Parent = obj
	return s
end

local function gradient(obj, c1, c2, rot)
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
	local s = Instance.new("UIScale")
	s.Scale = value or 1
	s.Parent = obj
	return s
end

local function pressEffect(btn)
	local sc = scaleObj(btn, 1)

	btn.MouseButton1Down:Connect(function()
		tween(sc, 0.08, {Scale = 0.94})
	end)

	btn.MouseButton1Up:Connect(function()
		tween(sc, 0.12, {Scale = 1})
	end)

	btn.MouseLeave:Connect(function()
		tween(sc, 0.12, {Scale = 1})
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

local function setFullbright(on)
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
end

local function stopFling()
	if flingSpin then
		flingSpin:Destroy()
		flingSpin = nil
	end
end

local function notify(gui, text, good)
	local n = Instance.new("TextLabel")
	n.Size = UDim2.new(0, 300, 0, 42)
	n.Position = UDim2.new(0.5, -150, 0, -55)
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

	tween(n, 0.3, {Position = UDim2.new(0.5, -150, 0, 16)}, Enum.EasingStyle.Back)

	task.delay(2, function()
		if n and n.Parent then
			tween(n, 0.22, {Position = UDim2.new(0.5, -150, 0, -55)})
			task.wait(0.25)
			if n then n:Destroy() end
		end
	end)
end

local function createStars(parent)
	parent.ClipsDescendants = true

	if starConnection then
		starConnection:Disconnect()
		starConnection = nil
	end

	local colors = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 120, 255),
		Color3.fromRGB(190, 80, 255),
		Color3.fromRGB(120, 210, 255),
		Color3.fromRGB(255, 220, 90),
		Color3.fromRGB(120, 255, 190),
	}

	local stars = {}

	for i = 1, 42 do
		local star = Instance.new("ImageLabel")
		star.Name = "StarIcon"
		star.BackgroundTransparency = 1
		star.Image = "rbxassetid://78948693296136"
		star.ImageColor3 = colors[math.random(1, #colors)]
		star.ImageTransparency = math.random(10, 45) / 100

		local size = math.random(10, 22)
		star.Size = UDim2.new(0, size, 0, size)
		star.Position = UDim2.new(math.random(), 0, 0, math.random(-80, parent.AbsoluteSize.Y + 40))
		star.Rotation = math.random(0, 360)
		star.ZIndex = 1
		star.Parent = parent

		table.insert(stars, {
			obj = star,
			speed = math.random(18, 60),
			xDrift = math.random(-18, 18) / 1000,
			rotSpeed = math.random(-70, 70),
		})
	end

	starConnection = RunService.RenderStepped:Connect(function(dt)
		if not parent or not parent.Parent then
			if starConnection then
				starConnection:Disconnect()
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
					star.ImageTransparency = math.random(10, 45) / 100
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
		walkAirGui:Destroy()
		walkAirGui = nil
	end

	walkAirUp = false
	walkAirDown = false
end

local function stopWalkAir()
	removeWalkAirButtons()

	if walkAirPlatform then
		walkAirPlatform:Destroy()
		walkAirPlatform = nil
	end

	walkAirHeight = 0
end

local function makeHoldMoveButton(parent, name, text, position, saveCallback, holdCallback)
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
	grad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(1, 0.38)
	}

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

			holdCallback(true)
			tween(pressScale, 0.08, {Scale = 0.93})
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and startInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInput

			if math.abs(delta.X) > 8 or math.abs(delta.Y) > 8 then
				moved = true
				holdCallback(false)
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
			holdCallback(false)
			saveCallback(btn.Position)
			tween(pressScale, 0.1, {Scale = 1})
		end
	end)

	return btn
end

local function createWalkAirButtons()
	if walkAirGui then
		walkAirGui:Destroy()
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
	local old = gui:FindFirstChild("HazinBubble")
	if old then old:Destroy() end

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
				if bubble then bubble:Destroy() end

				mainFrame.Visible = true
				mainScale.Scale = 0.78
				tween(mainScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
			end

			started = nil
		end
	end)
end

local old = PlayerGui:FindFirstChild("HazinHubUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "HazinHubUI"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Name = "Fundo"
main.Size = UDim2.new(0.88, 0, 0.86, 0)
main.Position = UDim2.new(0.06, 0, 0.07, 0)
main.BackgroundColor3 = Color3.fromRGB(164, 6, 163)
main.BackgroundTransparency = 0.08
main.BorderSizePixel = 0
main.Parent = gui
main.ClipsDescendants = true

corner(main, 18)
stroke(main, Color3.fromRGB(255, 255, 255), 2, 0.6)
local mainGrad = gradient(main, Color3.fromRGB(110, 15, 135), Color3.fromRGB(45, 45, 60), -90)
mainGrad.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0.08),
	NumberSequenceKeypoint.new(1, 0.28)
}

local mainScale = scaleObj(main, 0.82)
tween(mainScale, 0.42, {Scale = 1}, Enum.EasingStyle.Back)

createStars(main)
makeDraggable(main, main)

--// Pesquisa
local searchFrame = Instance.new("Frame")
searchFrame.Name = "Pesquisa"
searchFrame.Size = UDim2.new(0, 170, 0, 38)
searchFrame.Position = UDim2.new(0, 18, 0, 18)
searchFrame.BackgroundColor3 = Color3.fromRGB(50, 5, 117)
searchFrame.BackgroundTransparency = 0.16
searchFrame.BorderSizePixel = 0
searchFrame.ZIndex = 3
searchFrame.Parent = main

corner(searchFrame, 999)
stroke(searchFrame, Color3.fromRGB(255, 255, 255), 1, 0.65)
local searchGrad = gradient(searchFrame, Color3.fromRGB(35, 35, 40), Color3.fromRGB(105, 105, 115), -90)
searchGrad.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0.25),
	NumberSequenceKeypoint.new(1, 0.45)
}

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -22, 1, 0)
searchBox.Position = UDim2.new(0, 11, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.Text = ""
searchBox.PlaceholderText = "search"
searchBox.PlaceholderColor3 = Color3.fromRGB(230, 230, 230)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.TextSize = 14
searchBox.Font = Enum.Font.GothamBold
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 4
searchBox.Parent = searchFrame

--// Botão X vira bolinha
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "BotaoMinimizar"
closeBtn.Size = UDim2.new(0, 46, 0, 46)
closeBtn.Position = UDim2.new(1, -60, 0, 14)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.BackgroundTransparency = 0.18
closeBtn.Text = "X"
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
tabs.Size = UDim2.new(0, 62, 1, -96)
tabs.Position = UDim2.new(0, 18, 0, 78)
tabs.BackgroundColor3 = Color3.fromRGB(145, 10, 180)
tabs.BorderSizePixel = 0
tabs.ScrollBarThickness = 0
tabs.CanvasSize = UDim2.new(0, 0, 0, 0)
tabs.ZIndex = 2
tabs.Parent = main

corner(tabs, 12)
stroke(tabs, Color3.fromRGB(255, 255, 255), 1, 0.7)
local tabsGrad = gradient(tabs, Color3.fromRGB(45, 45, 55), Color3.fromRGB(120, 120, 135), -90)
tabsGrad.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0.18),
	NumberSequenceKeypoint.new(1, 0.38)
}

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.Padding = UDim.new(0, 8)
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabsLayout.Parent = tabs

local tabsPadding = Instance.new("UIPadding")
tabsPadding.PaddingTop = UDim.new(0, 10)
tabsPadding.Parent = tabs

tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	tabs.CanvasSize = UDim2.new(0, 0, 0, tabsLayout.AbsoluteContentSize.Y + 20)
end)

local content = Instance.new("Frame")
content.Name = "Conteudo"
content.Size = UDim2.new(1, -112, 1, -96)
content.Position = UDim2.new(0, 92, 0, 78)
content.BackgroundColor3 = Color3.fromRGB(28, 4, 80)
content.BackgroundTransparency = 0.16
content.BorderSizePixel = 0
content.ZIndex = 2
content.Parent = main

corner(content, 14)
stroke(content, Color3.fromRGB(255, 255, 255), 1, 0.7)
local contentGrad = gradient(content, Color3.fromRGB(35, 35, 45), Color3.fromRGB(80, 40, 105), -90)
contentGrad.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0.16),
	NumberSequenceKeypoint.new(1, 0.34)
}

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
	b.BackgroundColor3 = Color3.fromRGB(50, 5, 117)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.ZIndex = 4

	corner(b, 12)
	stroke(b, Color3.fromRGB(255, 255, 255), 1, 0.75)
	local buttonGrad = gradient(b, Color3.fromRGB(35, 35, 40), Color3.fromRGB(105, 105, 115), -90)
	buttonGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0.45)
	}
	pressEffect(b)
end

local function tab(text, pageName)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 44, 0, 44)
	b.BackgroundColor3 = Color3.fromRGB(55, 5, 117)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextSize = 16
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
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -4, 0, 28)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.fromRGB(255, 220, 255)
	l.TextSize = 17
	l.Font = Enum.Font.GothamBlack
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 4
	l.Parent = parent
	return l
end

local function button(parent, text, callback)
	local b = Instance.new("TextButton")
	b.Name = text
	b.Size = UDim2.new(1, -4, 0, 42)
	b.Text = text
	b.TextSize = 15
	b.Parent = parent
	basicButtonStyle(b)

	table.insert(allSearchItems, {obj = b, text = string.lower(text)})

	b.MouseButton1Click:Connect(function()
		callback(b)
	end)

	return b
end

local function input(parent, placeholder, default, callback)
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
		callback(box.Text)
	end)

	return box
end

local function toggle(parent, text, stateName, callback)
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

local home = createPage("Home")
local move = createPage("Movimento")
local visual = createPage("Visual")
local playerPage = createPage("Player")
local extra = createPage("Extra")

tab("H", "Home")
tab("M", "Movimento")
tab("V", "Visual")
tab("P", "Player")
tab("E", "Extra")

--// HOME
label(home, "Home")

button(home, "Minimizar em bolinha", function()
	tween(mainScale, 0.18, {Scale = 0.75})
	task.wait(0.16)
	main.Visible = false
	createBubble(gui, main, mainScale)
end)

button(home, "Desativar Tudo", function()
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

	notify(gui, "Tudo desativado.", true)
end)

--// MOVIMENTO
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

label(move, "Fly")
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

label(move, "Walking Air")

toggle(move, "Walking Air", "WalkAir", function(on)
	if on then
		local _, _, root = getChar()
		walkAirHeight = root and (root.Position.Y - 3.2) or 0
		createWalkAirButtons()
	else
		stopWalkAir()
	end
end)

input(move, "Walking Air Speed", values.WalkAirSpeed, function(txt)
	values.WalkAirSpeed = tonumber(txt) or 1.2
end)

button(move, "Reset Walking Air Height", function()
	local _, _, root = getChar()
	if root then
		walkAirHeight = root.Position.Y - 3.2
	end
end)

label(move, "Fling Local")

toggle(move, "Fling Local", "Fling")

input(move, "Fling Power", values.FlingPower, function(txt)
	values.FlingPower = tonumber(txt) or 120
end)

button(move, "Fling Burst", function()
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
	end
end)

--// VISUAL
label(visual, "Visual")

toggle(visual, "Fullbright", "Fullbright", setFullbright)

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

--// PLAYER
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

--// EXTRA
label(extra, "Extra")

button(extra, "Remover ESP", clearESP)
button(extra, "Parar Fling", stopFling)

button(extra, "Print posição", function()
	local _, _, root = getChar()
	if root then
		print("Posição:", root.Position)
		notify(gui, "Posição enviada no console.", true)
	end
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
notify(gui, "Hazin Hub carregado.", true)

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

--// Fly + Fling + Walking Air
RunService.RenderStepped:Connect(function()
	local char, hum, root = getChar()
	if not char or not hum or not root then return end

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
			walkAirPlatform:Destroy()
			walkAirPlatform = nil
		end
	end

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
