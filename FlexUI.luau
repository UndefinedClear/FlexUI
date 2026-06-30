local FlexUI = {}
FlexUI.__index = FlexUI

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

function FlexUI.Dexplorer()
	loadstring(game:HttpGet('https://raw.githubusercontent.com/MassiveHubs/loadstring/refs/heads/main/DexXenoAndRezware'))()
end

function FlexUI.InfiniteYield()
	loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end

function FlexUI.SendNotification(title, text, dur, icon)
	if dur == nil then
		dur = 16
	end

	if icon == nil or icon == "" then
		icon = "rbxthumb://type=Asset&id=5107182114&w=150&h=150"
	end

	game:GetService("StarterGui"):SetCore("SendNotification", { 
		Title = title,
		Text = text,
		Icon = icon,
		Duration = dur
	})
end



-- ДЕФОЛТНАЯ ТЕМА
local DefaultTheme = {
	CornerRadius                      = 8,
	ButtonCornerRadius                = 5,
	WindowBackground                  = Color3.fromRGB(30, 30, 30),

	TitleText                         = Color3.fromRGB(255, 255, 255),
	TitleTextSize                     = 14,

	CloseButtonBackground             = Color3.fromRGB(45, 45, 45),
	CloseButtonText                   = Color3.fromRGB(200, 200, 200),

	ButtonBackground                  = Color3.fromRGB(45, 45, 45),
	ButtonHover                       = Color3.fromRGB(60, 60, 60),
	ButtonClick                       = Color3.fromRGB(0, 120, 215),
	ButtonText                        = Color3.fromRGB(230, 230, 230),

	-- UI BUTTON
	TriggerBackground                 = Color3.fromRGB(0, 120, 215),
	TriggerText                       = Color3.fromRGB(255, 255, 255),

	--  Select
	SelectTriggerButtonColor          = Color3.fromRGB(40, 40, 40),
	SelectTriggerButtonTextColor      = Color3.fromRGB(200, 200, 200),
	SelectTriggerButtonArrowTextColor = Color3.fromRGB(150, 150, 150),

	SelectOptionActiveBGColor         = Color3.fromRGB(60, 60, 90),
	SelectOptionActiveTextColor       = Color3.fromRGB(255, 255, 255),

	SelectOptionBGColor               = Color3.fromRGB(45, 45, 45),
	SelectOptionTextColor             = Color3.fromRGB(180, 180, 180)
}

-- local NeonTheme = {
--     CornerRadius = 10,
--     WindowBackground = Color3.fromRGB(15, 15, 20),
--     TitleText = Color3.fromRGB(0, 255, 150),
--     ButtonBackground = Color3.fromRGB(30, 30, 35),
--     ButtonHover = Color3.fromRGB(0, 255, 150),
--     ButtonText = Color3.fromRGB(255, 255, 255),
--     TriggerBackground = Color3.fromRGB(0, 255, 150),
-- 	titleTextSize = 7
-- }

-- 1. Таблица с дефолтными значениями
local settings = {
	titleText = "Example Title",
	menuOpenByKey = true,
	menuOpenBindEnum = nil,
	menuOpenButtonText = "UI"
}

-- local example_config = {
--     titleText = "Новый заголовок",
-- 	customTheme = DefaultTheme,
--     menuOpenByKey = true,
-- 	menuOpenButtonText = "BABFT"
-- }

-- titleText, menuOpenByKey, customTheme, menuOpenBindEnum
-- Utils
local function removeByValue(arr, value)
    for i = #arr, 1, -1 do
		if arr[i] == value then
			table.remove(arr, i)
			return true
		end
	end
    return false -- элемент не найден
end


function FlexUI.new(_settings)
	local self = setmetatable({}, FlexUI)

	-- 3. Заменяем дефолты на то, что есть в parsedConfig
	for key, value in pairs(_settings) do
		settings[key] = value
	end
	
	self.Theme = DefaultTheme
	if settings.customTheme and type(settings.customTheme) == "table" then
		for key, value in pairs(settings.customTheme) do self.Theme[key] = value end
	end
	
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FlexUI_Debugger"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	self.ScreenGui = screenGui
	
	self.IsVisible = true
	self.Keybinds = {} 
	
	-- ИЗМЕНЕНИЕ 1: Сохраняем целевой размер окна для анимации
	self.TargetSize = UDim2.new(0, 260, 0, 420)
	
	-- ИЗМЕНЕНИЕ 2: Заменяем Frame на CanvasGroup, чтобы дети не вылезали при сжатии
	local mainFrame = Instance.new("CanvasGroup")
	mainFrame.Size = self.TargetSize
	
	-- ИЗМЕНЕНИЕ 3: Выставляем AnchorPoint и Position по центру экрана
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	
	mainFrame.BackgroundColor3 = self.Theme.WindowBackground
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	self.MainFrame = mainFrame
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, self.Theme.CornerRadius)
	uiCorner.Parent = mainFrame
	
	-- Заголовок
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 40)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = settings.titleText or "DEBUG MENU"
	title.TextColor3 = self.Theme.TitleText
	title.Font = Enum.Font.GothamBold
	title.TextSize = self.Theme.TitleTextSize
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = mainFrame
	
	-- Крестик закрытия
	local closeMenuBtn = Instance.new("TextButton")
	closeMenuBtn.Size = UDim2.new(0, 30, 0, 30)
	closeMenuBtn.Position = UDim2.new(1, -35, 0, 5)
	closeMenuBtn.BackgroundColor3 = self.Theme.CloseButtonBackground
	closeMenuBtn.Text = "X"
	closeMenuBtn.TextColor3 = self.Theme.CloseButtonText
	closeMenuBtn.Font = Enum.Font.Gotham
	closeMenuBtn.TextSize = 12
	closeMenuBtn.BorderSizePixel = 0
	closeMenuBtn.Parent = mainFrame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, self.Theme.ButtonCornerRadius)
	closeCorner.Parent = closeMenuBtn
	
	-- Контейнер для элементов
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Size = UDim2.new(1, 0, 1, -45)
	contentFrame.Position = UDim2.new(0, 0, 0, 45)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 3
	contentFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	contentFrame.Parent = mainFrame
	self.ContentFrame = contentFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = contentFrame
	
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
	
	-- КНОПКА UI (добавляем ей AnchorPoint по центру, чтобы она тоже красиво вылетала)
	local openButton = Instance.new("TextButton")
	openButton.AnchorPoint = Vector2.new(0.5, 0.5)
	openButton.Size = UDim2.new(0, 50, 0, 50)
	openButton.Position = UDim2.new(0, 50, 0, 50)
	openButton.BackgroundColor3 = self.Theme.TriggerBackground
	openButton.Text = settings.menuOpenButtonText
	openButton.TextColor3 = self.Theme.TriggerText
	openButton.Font = Enum.Font.GothamBold
	openButton.TextSize = 14
	openButton.BorderSizePixel = 0
	openButton.Visible = false
	openButton.ZIndex = 10
	openButton.Parent = screenGui
	self.OpenButton = openButton
	
	local openCorner = Instance.new("UICorner")
	openCorner.CornerRadius = UDim.new(1, 0)
	openCorner.Parent = openButton
	
	self:_makeDraggable(self.MainFrame)
	self:_makeDraggable(self.OpenButton)
	
	closeMenuBtn.MouseButton1Click:Connect(function() self:ToggleVisibility(false) end)
	openButton.MouseButton1Click:Connect(function() self:ToggleVisibility(true) end)

	if settings.menuOpenByKey == true then
		self.InputConnection = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			
			-- if settings.menuOpenByKey == false then return end

			if settings.menuOpenBindEnum then
				if input.KeyCode == settings.menuOpenBindEnum then 
					self:ToggleVisibility(not self.IsVisible) 
				end
			else
				if input.KeyCode == Enum.KeyCode.H then 
					self:ToggleVisibility(not self.IsVisible) 
				end
			end
			
			if self.Keybinds[input.KeyCode] then
				task.spawn(self.Keybinds[input.KeyCode])
			end
		end)
	end
	
	return self
end

function FlexUI:_makeDraggable(uiElement)
	local dragging, dragStart, startPos
	uiElement.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = uiElement.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			uiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ВСТРОЕННЫЙ ОБНОВЛЕННЫЙ МЕТОД TOGGLEVISIBILITY
function FlexUI:ToggleVisibility(state)
	self.IsVisible = state
	
	-- Анимация открытия: Back создаст крутой эффект "выскакивания" с пружиной
	local infoOpen = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	-- Анимация закрытия: Quad плавно и быстро сожмет в центр
	local infoClose = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	
	if state then
		self.MainFrame.Visible = true
		self.OpenButton.Visible = false
		
		-- СТАРТОВЫЙ ХАРАКТЕР: Окно сжато в 0 и полностью прозрачно в самом центре
		self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
		self.MainFrame.GroupTransparency = 1
		
		-- Твин до дефолтных размеров
		TweenService:Create(self.MainFrame, infoOpen, {
			Size = self.TargetSize,
			GroupTransparency = 0
		}):Play()
		
	else
		-- Анимация схлопывания в центр
		local closeTween = TweenService:Create(self.MainFrame, infoClose, {
			Size = UDim2.new(0, 0, 0, 0), -- Сжимаем и ширину, и высоту в ноль
			GroupTransparency = 1
		})
		
		closeTween:Play()
		
		closeTween.Completed:Connect(function()
			if not self.IsVisible then
				self.MainFrame.Visible = false
				self.OpenButton.Visible = true
				
				-- Появление кнопки открытия из центра её позиции
				self.OpenButton.Size = UDim2.new(0, 0, 0, 0)
				TweenService:Create(self.OpenButton, infoOpen, {Size = UDim2.new(0, 50, 0, 50)}):Play()
			end
		end)
	end
end

function FlexUI:AddBind(keyCode, callback)
	if typeof(keyCode) == "EnumItem" then
		self.Keybinds[keyCode] = callback
		print("[FlexUI] Setted up bind for: " .. keyCode.Name)
	end
end

function FlexUI:RemoveBind(keyCode)
	if typeof(keyCode) == "EnumItem" then
		self.Keybinds[keyCode] = nil
		print("[FlexUI] Remove bind for: " .. keyCode.Name)
	end
end

function FlexUI:AddButton(text, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 235, 0, 35)
	button.BackgroundColor3 = self.Theme.ButtonBackground
	button.Text = text
	button.TextColor3 = self.Theme.ButtonText
	button.Font = Enum.Font.Gotham
	button.TextSize = 12
	button.BorderSizePixel = 0
	button.Parent = self.ContentFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.ButtonCornerRadius)
	corner.Parent = button
	
	button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.ButtonHover}):Play() end)
	button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.ButtonBackground}):Play() end)
	button.MouseButton1Click:Connect(function()
		button.BackgroundColor3 = self.Theme.ButtonClick
		task.wait(0.1)
		button.BackgroundColor3 = self.Theme.ButtonHover
		if callback then 
			task.spawn(callback)
		end
	end)

	local ButtonObject = {}
	function ButtonObject:Destroy() button:Destroy() end
	return ButtonObject
end

-- self.Theme.SelectTriggerButtonColor = Color3.fromRGB(40, 40, 40)
-- self.Theme.SelectTriggerButtonTextColor = Color3.fromRGB(200, 200, 200)
-- self.Theme.SelectTriggerButtonArrowTextColor = Color3.fromRGB(150, 150, 150)


	-- self.Theme.SelectOptionActiveBGColor = Color3.fromRGB(60, 60, 90)
	-- self.Theme.SelectOptionActiveTextColor = Color3.fromRGB(255, 255, 255)

	-- self.Theme.SelectOptionBGColor = Color3.fromRGB(45, 45, 45)
	-- self.Theme.SelectOptionTextColor = Color3.fromRGB(180, 180, 180)

--  in dev
-- ====================== FINAL WORKING SELECT ======================
function FlexUI:AddSelect(elements, defaultValue, callback)
	local currentValue = defaultValue or (elements and elements[1]) or ""
	local isOpen = false
	local SelectObject = {}

	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 235, 0, 35)
	container.BackgroundTransparency = 1
	container.ZIndex = 100
	container.Parent = self.ContentFrame

	-- Trigger
	local trigger = Instance.new("TextButton")
	trigger.Size = UDim2.new(1, 0, 1, 0)
	trigger.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	trigger.Text = tostring(currentValue)
	trigger.TextColor3 = Color3.fromRGB(220, 220, 220)
	trigger.Font = Enum.Font.Gotham
	trigger.TextSize = 13
	trigger.ZIndex = 101
	trigger.Parent = container

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 6)
	tCorner.Parent = trigger

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(0, 25, 1, 0)
	arrow.Position = UDim2.new(1, -25, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "▼"
	arrow.TextColor3 = Color3.fromRGB(180, 180, 180)
	arrow.Font = Enum.Font.Gotham
	arrow.TextSize = 14
	arrow.ZIndex = 102
	arrow.Parent = trigger

	-- Dropdown
	local dropdown = Instance.new("ScrollingFrame")
	dropdown.Size = UDim2.new(0, 235, 0, 0)
	dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	dropdown.BorderSizePixel = 0
	dropdown.ScrollBarThickness = 4
	dropdown.Visible = false
	dropdown.ZIndex = 9999
	dropdown.ClipsDescendants = true
	dropdown.Parent = self.ScreenGui

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 2)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = dropdown

	local function refreshDropdown()
		for _, child in ipairs(dropdown:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		if elements then
			for i, val in ipairs(elements) do
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -4, 0, 30)
				btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
				btn.Text = tostring(val)
				btn.TextColor3 = Color3.fromRGB(200, 200, 200)
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 13
				btn.ZIndex = 10000
				btn.Parent = dropdown

				btn.MouseButton1Click:Connect(function()
					local old = currentValue
					currentValue = val
					trigger.Text = tostring(val)
					if callback then callback(currentValue, old) end
					SelectObject:Close()
				end)
			end
		end
	end

	refreshDropdown()

	trigger.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			local absPos = trigger.AbsolutePosition
			dropdown.Position = UDim2.new(0, absPos.X, 0, absPos.Y + trigger.AbsoluteSize.Y + 5)
			local height = math.min(#(elements or {}) * 32, 220)
			dropdown.Size = UDim2.new(0, 235, 0, height)
			dropdown.Visible = true
			arrow.Text = "▲"
		else
			dropdown.Visible = false
			arrow.Text = "▼"
		end
	end)

	-- Методы
	function SelectObject:Close()
		isOpen = false
		dropdown.Visible = false
		arrow.Text = "▼"
	end

	function SelectObject:SetValue(val)
		currentValue = val
		trigger.Text = tostring(val)
		if callback then callback(val) end
	end

	function SelectObject:GetValue()
		return currentValue
	end

	function SelectObject:SetElementsArray(newList)
		elements = newList or {}
		refreshDropdown()
		currentValue = elements[1] or ""
		trigger.Text = tostring(currentValue)
	end

	function SelectObject:AddElement(val)
		table.insert(elements, val)
		refreshDropdown()
	end

	function SelectObject:Destroy()
		container:Destroy()
		dropdown:Destroy()
	end

	return SelectObject
end
-- ====================== NEW SLIDER ======================
function FlexUI:AddSlider(text, min, max, default, callback)
	local value = default or min
	local dragging = false

	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 235, 0, 50)
	container.BackgroundTransparency = 1
	container.Parent = self.ContentFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = text .. ": " .. tostring(value)
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.new(0, 0, 1, -12)
	bar.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	bar.Parent = container

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(0, 0, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.ZIndex = 2
	knob.Parent = bar

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local function updateSlider()
		local percent = (value - min) / (max - min)
		fill.Size = UDim2.new(percent, 0, 1, 0)
		knob.Position = UDim2.new(percent, -7, 0.5, -7)
		label.Text = text .. ": " .. string.format("%.1f", value)
		if callback then callback(value) end
	end

	local function slide(input)
		local relative = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		value = min + (max - min) * relative
		updateSlider()
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			slide(input)
		end
	end)

	bar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			slide(input)
		end
	end)

	updateSlider()

	local SliderObj = {}
	function SliderObj:SetValue(newVal)
		value = math.clamp(newVal, min, max)
		updateSlider()
	end
	function SliderObj:GetValue() return value end
	function SliderObj:Destroy() container:Destroy() end

	return SliderObj
end

function FlexUI:AddLabel(defaultText, options)
	local cfg = { Font = Enum.Font.Gotham, TextSize = 12, TextColor = Color3.fromRGB(200, 200, 200), Height = 25, TextXAlignment = Enum.TextXAlignment.Center }
	if options and type(options) == "table" then for k, v in pairs(options) do cfg[k] = v end end
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 235, 0, cfg.Height)
	label.BackgroundTransparency = 1
	label.Text = defaultText or ""
	label.TextColor3 = cfg.TextColor
	label.Font = cfg.Font
	label.TextSize = cfg.TextSize
	label.TextXAlignment = cfg.TextXAlignment
	label.TextWrapped = true
	label.Parent = self.ContentFrame

	local LabelObject = {}
	function LabelObject:SetText(newText) label.Text = tostring(newText) end
	function LabelObject:SetColor(newColor) label.TextColor3 = newColor end
	function LabelObject:SetSize(newSize) label.TextSize = newSize end
	function LabelObject:SetFont(newFont) label.Font = newFont end
	function LabelObject:Destroy() label:Destroy() end
	return LabelObject
end

function FlexUI:AddToggle(text, defaultState, callback)
	local toggled = defaultState or false
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 235, 0, 35)
	container.BackgroundTransparency = 1
	container.Parent = self.ContentFrame
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -55, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local bg = Instance.new("TextButton")
	bg.Size = UDim2.new(0, 42, 0, 22)
	bg.Position = UDim2.new(1, -45, 0.5, -11)
	bg.BackgroundColor3 = toggled and Color3.fromRGB(48, 209, 88) or Color3.fromRGB(60, 60, 65)
	bg.Text = ""
	bg.BorderSizePixel = 0
	bg.Parent = container
	
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = bg
	
	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 18, 0, 18)
	circle.Position = toggled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	circle.BorderSizePixel = 0
	circle.Parent = bg
	
	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = circle
	
	local function updateToggle()
		local targetPos = toggled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
		local targetColor = toggled and Color3.fromRGB(48, 209, 88) or Color3.fromRGB(60, 60, 65)
		TweenService:Create(circle, TweenInfo.new(0.2), {Position = targetPos}):Play()
		TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
		if callback then task.spawn(callback, toggled) end
	end
	
	bg.MouseButton1Click:Connect(function()
		toggled = not toggled
		updateToggle()
	end)

	local ToggleObject = {}
	function ToggleObject:SetValue(state) toggled = state updateToggle() end
	function ToggleObject:GetValue() return toggled end

	function ToggleObject:Destroy() container:Destroy() end
	return ToggleObject
end

function FlexUI:AddCheckbox(text, defaultState, callback)
	local checked = defaultState or false
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 235, 0, 35)
	container.BackgroundTransparency = 1
	container.Parent = self.ContentFrame
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -35, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	local box = Instance.new("TextButton")
	box.Size = UDim2.new(0, 20, 0, 20)
	box.Position = UDim2.new(1, -25, 0.5, -10)
	box.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	box.Text = checked and "✓" or ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 14
	box.BorderSizePixel = 0
	box.Parent = container
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, self.Theme.ButtonCornerRadius)
	boxCorner.Parent = box
	box.MouseButton1Click:Connect(function()
		checked = not checked
		box.Text = checked and "✓" or ""
		TweenService:Create(box, TweenInfo.new(0.1), {BackgroundColor3 = checked and self.Theme.ButtonClick or Color3.fromRGB(45, 45, 50)}):Play()
		if callback then task.spawn(callback, checked) end
	end)

	local CheckboxObject = {}
	function CheckboxObject:SetValue(state) checked = state box.Text = state and "✓" or "" box.BackgroundColor3 = state and self.Theme.ButtonClick or Color3.fromRGB(45, 45, 50) end
	function CheckboxObject:GetValue() return checked end

	function CheckboxObject:Destroy() container:Destroy() end
	return CheckboxObject
end

function FlexUI:AddTextBox(placeholderText, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 235, 0, 35)
	container.BackgroundTransparency = 1
	container.Parent = self.ContentFrame
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 1, 0)
	box.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	box.PlaceholderText = placeholderText or "Введите text..."
	box.PlaceholderColor3 = Color3.fromRGB(120, 120, 125)
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Parent = container
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, self.Theme.ButtonCornerRadius)
	boxCorner.Parent = box

	box.FocusLost:Connect(function(enterPressed)
		if callback then task.spawn(callback, box.Text, enterPressed) end
	end)

	local TextBoxObject = {}
	function TextBoxObject:SetPlaceholder(text) box.PlaceholderText = tostring(text) end
	function TextBoxObject:SetValue(text) box.Text = tostring(text) end
	function TextBoxObject:GetValue() return box.Text end

	function TextBoxObject:GetInstance()
		return box
	end
	function TextBoxObject:Destroy() container:Destroy() end
	return TextBoxObject
end

function FlexUI:AddKeybind(text, defaultKey, callback)
	local currentKey = defaultKey 
	local isBinding = false
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 235, 0, 35)
	container.BackgroundTransparency = 1
	container.Parent = self.ContentFrame
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -75, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	local bindBtn = Instance.new("TextButton")
	bindBtn.Size = UDim2.new(0, 65, 0, 24)
	bindBtn.Position = UDim2.new(1, -70, 0.5, -12)
	bindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	bindBtn.Text = currentKey and currentKey.Name or "NONE"
	bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	bindBtn.Font = Enum.Font.GothamBold
	bindBtn.TextSize = 11
	bindBtn.BorderSizePixel = 0
	bindBtn.Parent = container
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = bindBtn
	
	bindBtn.MouseButton1Click:Connect(function()
		if isBinding then return end
		isBinding = true
		bindBtn.Text = "..."
		bindBtn.BackgroundColor3 = self.Theme.ButtonClick
		local listenConnection
		listenConnection = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if currentKey then self.Keybinds[currentKey] = nil end
				currentKey = input.KeyCode
				bindBtn.Text = currentKey.Name
				bindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
				if callback then self.Keybinds[currentKey] = callback end
				isBinding = false
				listenConnection:Disconnect()
			end
		end)
		
		-- СОХРАНЯЕМ CONNECTION ДЛЯ ПОСЛЕДУЮЩЕЙ ОЧИСТКИ
		if not self.ActiveConnections then self.ActiveConnections = {} end
		table.insert(self.ActiveConnections, listenConnection)
	end)

	if currentKey and callback then
		self.Keybinds[currentKey] = callback
	end

	local KeybindButtonObject = {}
	function KeybindButtonObject:Destroy() container:Destroy() end
	return KeybindButtonObject
end

function FlexUI:AddDestroyButton(customText, customColor, beforeDestroy)
	local destroyColor = customColor or Color3.fromRGB(180, 40, 40)
	local hoverColor = Color3.new(destroyColor.R * 0.7, destroyColor.G * 0.7, destroyColor.B * 0.7)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 235, 0, 35)
	button.BackgroundColor3 = destroyColor
	button.Text = customText or "Destroy menu"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.BorderSizePixel = 0
	button.Parent = self.ContentFrame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.ButtonCornerRadius)
	corner.Parent = button

	button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play() end)
	button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = destroyColor}):Play() end)
	button.MouseButton1Click:Connect(function()
		-- БЕЗОПАСНЫЙ ВЫЗОВ: проверяем что beforeDestroy это функция
		if type(beforeDestroy) == "function" then
			local success, err = pcall(beforeDestroy)
			if not success then
				warn("[FlexUI] Error in beforeDestroy:", err)
			end
		end
		self:Destroy()
	end)
end

function FlexUI:Destroy()
	-- Отключаем основной InputConnection
	if self.InputConnection then 
		self.InputConnection:Disconnect() 
		self.InputConnection = nil
	end
	
	-- Отключаем ВСЕ активные listenConnection от AddKeybind
	if self.ActiveConnections then
		for _, conn in ipairs(self.ActiveConnections) do
			if conn and conn.Connected then
				conn:Disconnect()
			end
		end
		self.ActiveConnections = nil
	end
	
	-- Уничтожаем GUI
	if self.ScreenGui then 
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
	
	-- Очищаем Keybinds
	if self.Keybinds then
		for key, _ in pairs(self.Keybinds) do
			self.Keybinds[key] = nil
		end
		self.Keybinds = nil
	end
	
	-- Очищаем ссылки на UI элементы
	self.MainFrame = nil
	self.ContentFrame = nil
	self.OpenButton = nil
	self.Theme = nil
	self.TargetSize = nil
	self.IsVisible = nil
	
	print("[FlexUI] Menu have been disposed!")
end

return FlexUI