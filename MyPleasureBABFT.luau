-- =======================================================
-- БЕЗОПАСНОЕ ПОДКЛЮЧЕНИЕ ИНТЕРФЕЙСА (FlexUI UI)
-- =======================================================
local FlexUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/UndefinedClear/FlexUI/refs/heads/main/Loader.lua"))().LoadFlex()()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- ✅ Ждем LocalPlayer перед использованием
local player = Players.LocalPlayer
if not player then
    player = Players.LocalPlayer or Players.PlayerAdded:Wait()
end

local camera = workspace.CurrentCamera

-- НАСТРОЙКИ
local walksspeedVar = 16
local isWalkSpeed = false
local speed = 50
local flying = false
local isNoclip = false
local isRunning = false
local isInvisible = false
local isSpectating = false

-- Anti-Fling
-- =======================================================
-- ANTI-FLING PROTECTION (by joshclark756)
-- Делает других игроков "призраками" и обнуляет их физику
-- =======================================================
local Client = Players.LocalPlayer
local AntiFlingConnection = nil
local IsAntiFlingActive = false

local function ApplyAntiFlingToPart(v)
    pcall(function()
        -- Обнуляем физику и делаем неколлизируемым
        v.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        v.Velocity = Vector3.new(0, 0, 0)
        v.RotVelocity = Vector3.new(0, 0, 0)
        v.CanCollide = false
        
        -- Также можно добавить в группу призраков для надежности
        if PhysicsService and PhysicsService:IsCollisionGroupRegistered("GhostPlayers") then
            v.CollisionGroup = "GhostPlayers"
        end
    end)
end

local function StartAntiFling()
    if IsAntiFlingActive then return end
    IsAntiFlingActive = true
    
    print("[AntiFling] Защита активирована!")
    
    -- Применяем ко всем существующим HRP других игроков
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and 
           v.Name == "HumanoidRootPart" and 
           v.Parent ~= Client.Character and 
           not v.Anchored then
            ApplyAntiFlingToPart(v)
        end
    end
    
    -- Подключаемся к Heartbeat для постоянной защиты
    AntiFlingConnection = RunService.Heartbeat:Connect(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and 
               v.Name == "HumanoidRootPart" and 
               v.Parent ~= Client.Character and 
               not v.Anchored then
                ApplyAntiFlingToPart(v)
            end
        end
    end)
    
    -- Отслеживаем появление новых частей
    workspace.DescendantAdded:Connect(function(part)
        if IsAntiFlingActive and 
           part:IsA("BasePart") and 
           part.Name == "HumanoidRootPart" and 
           part.Parent ~= Client.Character and 
           not part.Anchored then
            task.delay(1, function()
                if part and part.Parent then
                    ApplyAntiFlingToPart(part)
                end
            end)
        end
    end)
    
    -- Автоматически отключаем при смерти (чтобы не мешать респавну)
    local hum = Client.Character and Client.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function()
            StopAntiFling()
        end)
    end
end

local function StopAntiFling()
    if not IsAntiFlingActive then return end
    IsAntiFlingActive = false
    
    if AntiFlingConnection then
        AntiFlingConnection:Disconnect()
        AntiFlingConnection = nil
    end
    
    print("[AntiFling] Защита деактивирована.")
end

-- Уведомление при запуске (как в оригинале)
-- task.delay(2, function()
--     pcall(function()
--         StarterGui:SetCore("SendNotification", {
--             Title = "Anti Fling Activated",
--             Text = "Protection by joshclark756 | Integrated by UndefinecClear",
--             Duration = 5
--         })
--     end)
-- end)

-- Ссылки на UI элементы
local flyToggleUi, noclipToggleUi, afkToggleUi, coordsLabelUi, invisToggleUi, walkspeedToggleUi
local usernameInput, flingStatusText

-- AFK LINKS
local gold_per_cycle = 132
local time_per_cycle = 25
local gps = gold_per_cycle / time_per_cycle

-- ТАБЛИЦА КООРДИНАТ АВТО-ФАРМА
local points = {
    Vector3.new(145.55, -2.49, 1049.40),
    Vector3.new(101.13, 49.31, 1391.92),
    Vector3.new(88.01, 66.84, 2189.84),
    Vector3.new(106.06, 88.49, 2936.96),
    Vector3.new(103.36, 64.09, 3700.57),
    Vector3.new(101.43, 61.81, 4505.56),
    Vector3.new(84.62, 40.19, 5280.32),
    Vector3.new(101.02, 35.91, 6397.15),
    Vector3.new(105.98, 113.97, 7323.42),
    Vector3.new(80.70, 45.54, 8066.15),
    Vector3.new(-50.83, -357.62, 9501.02)
}

local teams_spawn_points = {
    white = Vector3.new(-49.85, -9.70, -503.81),
    blue = Vector3.new(393.68, -9.70, 299.99),
    green = Vector3.new(-488.69, -9.70, 291.89),
    red = Vector3.new(395.30, -9.70, -65.12),
    black = Vector3.new(-492.44, -9.66, -69.22),
    yellow = Vector3.new(-494.97, -9.70, 640.62),
    magenta = Vector3.new(381.62, -9.70, 647.55),
}

-- ОЧИСТКА СТАРЫХ ПОДКЛЮЧЕНИЙ
if _G.DebugInputConnection then _G.DebugInputConnection:Disconnect() end
if _G.FlyConnection then _G.FlyConnection:Disconnect() end
if _G.EffectsConnection then _G.EffectsConnection:Disconnect() end

-- =======================================================
-- ФУНКЦИИ ЭФФЕКТОВ
-- =======================================================
local PhysicsService = game:GetService("PhysicsService")
local GHOST_GROUP = "GhostPlayers"

-- Регистрация группы (выполняется один раз при запуске скрипта)
pcall(function()
    if not PhysicsService:IsCollisionGroupRegistered(GHOST_GROUP) then
        PhysicsService:RegisterCollisionGroup(GHOST_GROUP)
    end
    PhysicsService:CollisionGroupSetCollidable("Default", GHOST_GROUP, false)
    PhysicsService:CollisionGroupSetCollidable(GHOST_GROUP, GHOST_GROUP, false)
end)

local function setGhostMode(state)
    local char = player.Character
    if not char then return end
    
    for _, myPart in ipairs(char:GetDescendants()) do
        if myPart:IsA("BasePart") then
            pcall(function()
                if state then
                    -- ✅ ПРАВИЛЬНЫЙ СИНТАКСИС: через точку, а не двоеточие
                    myPart.CollisionGroup = GHOST_GROUP
                    if isNoclip then myPart.CanCollide = false end
                else
                    myPart.CollisionGroup = "Default"
                    if not isNoclip then myPart.CanCollide = true end
                end
            end)
        end
    end
end

local function CopyPlayersToClipboard()
    -- Собираем данные в строку
    local output = ""
    for _, player in ipairs(Players:GetPlayers()) do
        -- Формат: Никнейм - Username - ID
        local line = string.format("%s - %s - %d", 
            player.DisplayName, 
            player.Name, 
            player.UserId
        )
        output = output .. line .. "\n"
    end

    -- Выводим в консоль
    print(output)

    -- Копируем в буфер обмена
    if setclipboard then
        setclipboard(output)
        print("[Система] Список скопирован в буфер обмена!")
    else
        warn("[Система] Функция setclipboard недоступна в этом эксплойте.")
    end
end

local function applyInvisibility(state)
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if state then
                part.Transparency = 0.99
                part.LocalTransparencyModifier = -0.50
            else
                part.Transparency = 0
                part.LocalTransparencyModifier = 0
            end
        end
    end
end

local function applyNoclip(state)
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end
-- =======================================================
-- FIXED KILL FUNCTIONS + CLONE
-- =======================================================

local CloneController = {
    Active = false,
    CloneChar = nil,
    CloneHRP = nil,
    CloneHumanoid = nil,
    ControlConnection = nil
}

local function CreateClone()
    if CloneController.Active then DestroyClone() end -- Prevent duplicates
    
    local char = player.Character
    if not char then return warn("[Clone] No character") end
    
    print("[Clone] Creating...")
    
    local clone = char:Clone()
    clone.Name = "Clone_" .. player.Name
    clone.Parent = workspace
    
    local hrp = clone:FindFirstChild("HumanoidRootPart")
    local hum = clone:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not hum then 
        clone:Destroy()
        return warn("[Clone] Missing HRP or Humanoid") 
    end
    
    -- Visual + Physics setup
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0.45
            part.CanCollide = false
            part.Anchored = false
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0.3
        end
    end
    
    if clone:FindFirstChild("Animate") then clone.Animate:Destroy() end
    if clone:FindFirstChild("HumanoidRootPart") then
        clone.HumanoidRootPart.Transparency = 0.6
    end
    
    -- Position
    hrp.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -6)
    
    hum.WalkSpeed = 50
    hum.JumpPower = 50
    hum.PlatformStand = false
    
    CloneController.CloneChar = clone
    CloneController.CloneHRP = hrp
    CloneController.CloneHumanoid = hum
    CloneController.Active = true
    
    print("[Clone] ✅ Ready")
    
    -- Control Loop
    if CloneController.ControlConnection then CloneController.ControlConnection:Disconnect() end
    
    CloneController.ControlConnection = RunService.Heartbeat:Connect(function()
        if not CloneController.Active or not CloneController.CloneHRP then return end
        
        local cHRP = CloneController.CloneHRP
        local moveDir = Vector3.new(0,0,0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0,1,0) end
        
        local bv = cHRP:FindFirstChildOfClass("BodyVelocity") or Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * 55) or Vector3.new()
        bv.Parent = cHRP
        
        cHRP.CFrame = CFrame.new(cHRP.Position, cHRP.Position + camera.CFrame.LookVector)
    end)
end

local function DestroyClone()
    if CloneController.ControlConnection then
        CloneController.ControlConnection:Disconnect()
        CloneController.ControlConnection = nil
    end
    if CloneController.CloneChar and CloneController.CloneChar.Parent then
        CloneController.CloneChar:Destroy()
    end
    CloneController.Active = false
    print("[Clone] Destroyed")
end

-- Авто-очистка при респавне (чтобы клон не остался висеть)
-- player.CharacterAdded:Connect(function()
--     if CloneController.Active then
--         task.wait(1)
--         -- Обновляем ссылку на оригинал
--         CloneController.OriginalChar = player.Character
--     end
-- end)

-- Переменная для хранения найденного объекта игрока
local foundTargetPlayer = nil

local function findAndSelectPlayer(username)
    foundTargetPlayer = nil
    
    task.spawn(function()
        local success, userId = pcall(function()
            return Players:GetUserIdFromNameAsync(username)
        end)
        
        if not success then
            warn(`[Поиск] Ошибка при поиске "{username}": {userId}`)
            return
        end
        
        local p = Players:GetPlayerByUserId(userId)
        
        if p then
            foundTargetPlayer = p
            print(`[Поиск] ✅ Игрок найден: {p.Name} (ID: {userId})`)
            if flingStatusText then
                flingStatusText:SetText(`Цель: {p.Name} [ГОТОВ К FLING]`)
                flingStatusText:SetColor(Color3.fromRGB(0, 255, 150))
            end
        else
            warn(`[Поиск] ❌ Игрок "{username}" существует, но НЕ на этом сервере!`)
            if flingStatusText then
                flingStatusText:SetText(`Цель: {username} [НЕ НА СЕРВЕРЕ]`)
                flingStatusText:SetColor(Color3.fromRGB(255, 80, 80))
            end
        end
    end)
end

local function teleportToPlayer(targetPlayer)
    -- 1. Проверяем цель
    local targetChar = targetPlayer.Character
    if not targetChar then 
        warn(`[TP]  У игрока {targetPlayer.Name} НЕТ персонажа!`) 
        return 
    end
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        warn(`[TP] ❌ У цели есть персонаж, но НЕТ HumanoidRootPart! (Модель сломана/не загружена)`)
        -- Пытаемся найти любую часть тела как запасной вариант
        targetRoot = targetChar:FindFirstChildWhichIsA("BasePart")
        if not targetRoot then return end
        warn("[TP] ⚠️ Используем запасную часть: " .. targetRoot.Name)
    end

    -- 2. Проверяем себя
    local myChar = player.Character
    if not myChar then 
        warn("[TP] ❌ У ТЕБЯ нет персонажа! Жди респавна.") 
        return 
    end
    
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        warn("[TP] ❌ У ТЕБЯ нет HRP! Модель не загрузилась.")
        return 
    end
    
    -- 3. Телепорт
    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 0)
    print(`[TP] ✅ Перемещение к {targetPlayer.Name}`)
end

-- =======================================================
-- KILASIK MULTI-FLING INTEGRATION (БЕЗ SELECT)
-- =======================================================
local flingActive = false
local flingThread = nil
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

local function Message(Title, Text, Time)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = Title,
            Text = Text,
            Duration = Time or 3
        })
    end)
end

local function SkidFling(TargetPlayer)
    local Character = player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    
    if not TCharacter or not Character or not Humanoid or not RootPart then return end
    
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    
    if THumanoid and THumanoid.Sit then
        return Message("Error", TargetPlayer.Name .. " сидит", 2)
    end
    
    -- Камера на жертву для эффекта
    if THead then workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid then workspace.CurrentCamera.CameraSubject = THumanoid end
    
    if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
    
    local FPos = function(BasePart, Pos, Ang)
        if RootPart and RootPart.Parent then
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
    end
    
    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0
        
        repeat
            if RootPart and RootPart.Parent and THumanoid and THumanoid.Parent then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                end
            end
        until Time + TimeToWait < tick() or not flingActive or not RootPart.Parent
    end
    
    workspace.FallenPartsDestroyHeight = 0/0
    
    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(0, 0, 0)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    
    if TRootPart then
        SFBasePart(TRootPart)
    elseif THead then
        SFBasePart(THead)
    elseif Handle then
        SFBasePart(Handle)
    else
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
        return Message("Error", TargetPlayer.Name .. " нет валидных частей", 2)
    end
    
    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = Humanoid
    
    -- Reset character position
    if getgenv().OldPos and RootPart.Parent then
        repeat
            RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
            Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
            Humanoid:ChangeState("GettingUp")
            for _, part in pairs(Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                end
            end
            task.wait()
        until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25 or not RootPart.Parent
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
    end
end

local function StartFling()
    if flingActive then return end
    
    -- Берем имя из TextBox
    local targetName = usernameInput and usernameInput:GetValue() or ""
    if #targetName == 0 then
        Message("Error", "Введите ник цели в поле выше!", 2)
        return
    end
    
    local target = Players:FindFirstChild(targetName)
    if not target then 
        Message("Error", "Игрок " .. targetName .. " не найден", 2)
        return 
    end
    
    -- ✅ СОХРАНЯЕМ ПОЗИЦИЮ ПЕРЕД ЗАПУСКОМ
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then 
        getgenv().OldPos = root.CFrame 
    end
    
    flingActive = true
    Message("Started", "Флинг " .. targetName, 2)
    
    flingThread = task.spawn(function()
        while flingActive do
            if target and target.Character then
                SkidFling(target)
                task.wait(0.1)
            else
                Message("Stopped", "Цель потеряна", 2)
                break
            end
        end
    end)
end

local function StopFling()
    if not flingActive then return end
    flingActive = false
    if flingThread then task.cancel(flingThread); flingThread = nil end
    Message("Stopped", "Флинг остановлен. Возврат...", 2)
    
    -- ✅ ВОЗВРАТ НА ИСХОДНУЮ ПОЗИЦИЮ (Оригинальная логика Kilasik)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and getgenv().OldPos then
        repeat
            -- Плавно телепортируем обратно
            root.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
            char:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
            
            -- Сбрасываем скорости и поднимаем персонажа
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.new()
                    part.RotVelocity = Vector3.new()
                end
            end
            task.wait()
        until (root.Position - getgenv().OldPos.p).Magnitude < 25 or not root.Parent
        
        -- Очищаем сохраненную позицию
        getgenv().OldPos = nil
    end
    
    -- Возврат камеры
    workspace.CurrentCamera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

-- =======================================================
-- ОСНОВНОЙ ЦИКЛ (ВСЁ В ОДНОМ МЕСТЕ — ПОЛЁТ + ЭФФЕКТЫ)
-- =======================================================
_G.FlyConnection = RunService.Stepped:Connect(function()
    local character = player.Character
    if not character or not character.Parent then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root.Parent then return end
    
    local hum = character:FindFirstChildOfClass("Humanoid")
    
    -- === ПОЛЁТ ===
    local bv = root:FindFirstChildOfClass("BodyVelocity")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(0, 0, 0)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = root
    end
    
    if not flying then
        bv.MaxForce = Vector3.new(0, 0, 0)
        bv.Velocity = Vector3.new(0, 0, 0)
    else
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        
        local moveDirection = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

        if moveDirection.Magnitude > 0 then
            bv.Velocity = moveDirection.Unit * speed
        else
            bv.Velocity = Vector3.new(0, 0, 0)
        end
    end
    
    -- === WALKSPEED ===
    if isWalkSpeed and hum then
        hum.WalkSpeed = walksspeedVar
    end

    -- -- === КАМЕРА СЛЕЖЕНИЯ ===
    -- if isSpectating and foundTargetPlayer then
    --     local targetChar = foundTargetPlayer.Character
    --     if targetChar then
    --         local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    --         if targetRoot then
    --             -- Плавно направляем камеру на голову/HRP цели
    --             workspace.CurrentCamera.CFrame = CFrame.new(
    --                 workspace.CurrentCamera.CFrame.Position, 
    --                 targetRoot.Position + Vector3.new(0, 2, 0)
    --             )
    --         end
    --     end
    -- end

    -- -- === КАМЕРА СЛЕЖЕНИЯ (ТЕЛЕПОРТ К ЦЕЛИ) ===
    -- if isSpectating and foundTargetPlayer then
    --     local targetChar = foundTargetPlayer.Character
    --     if targetChar then
    --         local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    --         if targetRoot then
    --             -- Телепортируем камеру прямо к голове цели + небольшое смещение, чтобы не застрять внутри
    --             workspace.CurrentCamera.CFrame = targetRoot.CFrame * CFrame.new(0, 3, -8)
    --         end
    --     end
    -- end

    -- === КАМЕРА СЛЕЖЕНИЯ (ФИЗИЧЕСКИЙ ТЕЛЕПОРТ) ===
    -- if isSpectating and foundTargetPlayer then
    --     local targetChar = foundTargetPlayer.Character
    --     if targetChar then
    --         local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    --         if targetRoot then
    --             -- Позиция камеры: над головой цели + отступ назад
    --             local camPos = targetRoot.Position + Vector3.new(0, 4, -10)
                
    --             -- Камера ВСЕГДА смотрит точно в HRP цели
    --             workspace.CurrentCamera.CFrame = CFrame.new(camPos, targetRoot.Position)
    --         end
    --     end
    -- end
end)

-- Цикл эффектов (ноуклип + невидимость)
_G.EffectsConnection = RunService.Heartbeat:Connect(function()
    if isNoclip then applyNoclip(true) end
    if isInvisible then applyInvisibility(true) end
end)

local function teleport(_player, vector3)
    local char = _player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if root and root.Parent then
        root.CFrame = CFrame.new(vector3)
        print(string.format("[TP] Телепорт на точку: %s", tostring(vector3)))
    end
end


-- ==================== ADVANCED SPECTATE WITH MOUSE CONTROL ====================
local spectateConnection = nil
local spectateTarget = nil

local camOffset = Vector3.new(0, 6, -12)   -- расстояние от цели
local camRotation = 0
local camPitch = 0

local function StartSpectate(targetPlayer)
    if spectateConnection then spectateConnection:Disconnect() end
    spectateTarget = targetPlayer
    
    camRotation = 0
    camPitch = 10  -- небольшой наклон сверху
    
    spectateConnection = RunService.RenderStepped:Connect(function()
        if not isSpectating or not spectateTarget then return end
        
        local targetChar = spectateTarget.Character
        if not targetChar then 
            workspace.CurrentCamera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            return 
        end
        
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
        
        -- Управление мышью
        local mouseDelta = UserInputService:GetMouseDelta()
        camRotation = camRotation - mouseDelta.X * 0.4
        camPitch = math.clamp(camPitch + mouseDelta.Y * 0.3, -60, 60)
        
        -- Позиция камеры
        local distance = 12
        local radY = math.rad(camRotation)
        local radX = math.rad(camPitch)
        
        local offset = Vector3.new(
            math.sin(radY) * math.cos(radX) * distance,
            5 + math.sin(radX) * distance * 0.6,
            math.cos(radY) * math.cos(radX) * distance
        )
        
        local camPos = targetRoot.Position + offset
        local lookAt = targetRoot.Position + Vector3.new(0, 2, 0)
        
        workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, lookAt)
    end)
    
    print("[Spectate] Включено с управлением мышью")
end

local function StopSpectate()
    if spectateConnection then
        spectateConnection:Disconnect()
        spectateConnection = nil
    end
    spectateTarget = nil
    
    workspace.CurrentCamera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    print("[Spectate] Выключено")
end

-- =======================================================
-- AFK И КООРДИНАТЫ
-- =======================================================
local AFKCYCLEDELAY = 5
local COOLDOWN_EACH_TP = 2

local function startAfkCycle()
    while isRunning do
        for i, targetPos in ipairs(points) do
            if not isRunning then break end
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and root.Parent then
                root.CFrame = CFrame.new(targetPos)
                print(string.format("[AFK] Телепорт на точку %d: %s", i, tostring(targetPos)))
            end
            task.wait(COOLDOWN_EACH_TP)
        end
        
        if isRunning then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                print("[AFK] Круг пройден. Перезагрузка персонажа...")
                player.CharacterAdded:Wait()
                task.wait(AFKCYCLEDELAY)
            end
        end
    end
end

local function recordCoordinates()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local pos = root.Position
        print(string.format("Vector3.new(%.2f, %.2f, %.2f),", pos.X, pos.Y, pos.Z))
        if coordsLabelUi then
            coordsLabelUi:SetText(string.format("Последняя точка:\nX: %.2f\nY: %.2f | Z: %.2f", pos.X, pos.Y, pos.Z))
        end
    end
end

-- =======================================================
-- УПРАВЛЕНИЕ С КЛАВИАТУРЫ
-- =======================================================
_G.DebugInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    
    if input.KeyCode == Enum.KeyCode.E then
        recordCoordinates()

    elseif input.KeyCode == Enum.KeyCode.L then
        isNoclip = not isNoclip
        applyNoclip(isNoclip)
        if noclipToggleUi then noclipToggleUi:SetValue(isNoclip) end
        print("[Дебаг] Ноуклип:", isNoclip and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН")

    elseif input.KeyCode == Enum.KeyCode.P then
        flying = not flying
        if flyToggleUi then flyToggleUi:SetValue(flying) end
        print("[Дебаг] Полет:", flying and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН")

    elseif input.KeyCode == Enum.KeyCode.M then
        isInvisible = not isInvisible
        applyInvisibility(isInvisible)
        if invisToggleUi then invisToggleUi:SetValue(isInvisible) end
        print("[Дебаг] Невидимость:", isInvisible and "ВКЛЮЧЕНА" or "ВЫКЛЮЧЕНА")

    elseif input.KeyCode == Enum.KeyCode.J then
        isRunning = not isRunning
        if isRunning then flying = false end
        if afkToggleUi then afkToggleUi:SetValue(isRunning) end
        if flyToggleUi and not flying then flyToggleUi:SetValue(false) end
        if isRunning then
            print("[AFK] Авто-цикл ЗАПУЩЕН.")
            task.spawn(startAfkCycle)
        else
            print("[AFK] Авто-цикл ОСТАНОВЛЕН.")
        end
    end
end)

-- =======================================================
-- ИНТЕРФЕЙС (FlexUI UI)
-- =======================================================
local neonTheme = {
    CornerRadius = 10,
    WindowBackground = Color3.fromRGB(15, 15, 20),
    TitleText = Color3.fromRGB(0, 255, 150),
    ButtonBackground = Color3.fromRGB(30, 30, 35),
    ButtonHover = Color3.fromRGB(0, 255, 150),
    ButtonText = Color3.fromRGB(255, 255, 255),
    TriggerBackground = Color3.fromRGB(0, 255, 150),
    TitleTextSize = 10
}

local config = {
    titleText = "My Pleasure | By UndefinecClear",
	customTheme = neonTheme,
    menuOpenByKey = true,
	menuOpenButtonText = "MP"
}


local menu = FlexUI.new(config)

-- Start UI
menu:AddLabel("Управление читом", {
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor = Color3.fromRGB(0, 255, 150)
})

coordsLabelUi = menu:AddLabel("Координаты: не зафиксированы", {
    TextXAlignment = Enum.TextXAlignment.Left,
    Height = 40,
    Font = Enum.Font.Code
})

menu:AddButton("Зафиксировать точку [E]", recordCoordinates)
menu:AddButton("Копировать игроков в буфер обмена", CopyPlayersToClipboard)

menu:AddButton("🌀 START ANTI-FLING", function()
    StartAntiFling()
end)

menu:AddButton("⏹ STOP ANTI-FLING", function()
    StopAntiFling()
end)

menu:AddToggle("👻 Режим Призрака", false, function(state)
    setGhostMode(state)
    print(state and "[Призрак] Ты теперь невесом для других!" or "[Призрак] Обычная физика восстановлена.")
end)

menu:AddToggle("👤 Создать клона", false, function(state)
    if state then
        CreateClone()
    else
        DestroyClone()
    end
end)

noclipToggleUi = menu:AddToggle("Ноуклип (Сквозь стены) [L]", isNoclip, function(state)
    isNoclip = state
    applyNoclip(isNoclip)
    print("[UI] Ноуклип:", isNoclip)
end)

flyToggleUi = menu:AddToggle("Режим полета [P]", flying, function(state)
    flying = state
    print("[UI] Полет:", flying)
end)

menu:AddTextBox("Скорость полета (дефолт: 50)...", function(text)
    local n = tonumber(text)
    if n then speed = n print("[Система] Скорость полета:", speed)
    else print("[Ошибка] Введите число!") end
end)

walkspeedToggleUi = menu:AddToggle("Цикл WalkSpeed", isWalkSpeed, function(state)
    isWalkSpeed = state
    if state == false then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)

menu:AddTextBox("WalkSpeed (дефолт: 16)...", function(text)
    local n = tonumber(text)
    if n then walksspeedVar = n print("[Система] WalkSpeed:", walksspeedVar)
    else print("[Ошибка] Введите число!") end
end)

invisToggleUi = menu:AddToggle("Невидимость для других [M]", isInvisible, function(state)
    isInvisible = state
    applyInvisibility(isInvisible)
    print("[UI] Невидимость:", isInvisible)
end)

-- AFK UI
menu:AddLabel("Управление AFK-ботом", {
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor = Color3.fromRGB(0, 255, 150)
})

menu:AddLabel("AFK Profit:", {
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Code,
    TextColor = Color3.fromRGB(255, 215, 0)    
})

menu:AddLabel("Per minute: " .. math.floor(gps * 60) .. " Gold", {
    TextXAlignment = Enum.TextXAlignment.Left,
    Height = 40,
    Font = Enum.Font.Code,
    TextColor = Color3.fromRGB(214, 219, 182)
})

menu:AddLabel("Per 1 hour: " .. math.floor(gps * 3600) .. " Gold", {
    TextXAlignment = Enum.TextXAlignment.Left,
    Height = 40,
    Font = Enum.Font.Code,
    TextColor = Color3.fromRGB(214, 219, 182)
})

menu:AddLabel("Per 12 hours: " .. math.floor(gps * 43200) .. " Gold", {
    TextXAlignment = Enum.TextXAlignment.Left,
    Height = 40,
    Font = Enum.Font.Code,
    TextColor = Color3.fromRGB(214, 219, 182)
})

menu:AddLabel("Per 24 hours: " .. math.floor(gps * 86400) .. " Gold", {
    TextXAlignment = Enum.TextXAlignment.Left,
    Height = 40,
    Font = Enum.Font.Code,
    TextColor = Color3.fromRGB(214, 219, 182)
})

afkToggleUi = menu:AddToggle("Авто AFK-цикл [J]", isRunning, function(state)
    isRunning = state
    if isRunning then
        print("[UI] AFK запущен.")
        task.spawn(startAfkCycle)
    else
        print("[UI] AFK остановлен.")
    end
end)

-- Other
menu:AddLabel("Управление Всяким", {
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor = Color3.fromRGB(0, 255, 150)
})

-- Поиск игрока (Используется и для киллов, и для флинга)
usernameInput = menu:AddTextBox("Введите Username цели...", function(text, enterPressed)
    if enterPressed and #text > 0 then
        findAndSelectPlayer(text)
    end
end)

flingStatusText = menu:AddLabel("Цель: не выбрана", {
    TextXAlignment = Enum.TextXAlignment.Left,
    Height = 30,
    Font = Enum.Font.Code,
    TextColor = Color3.fromRGB(150, 150, 150)
})

local function refresh_player_searched()
    local text = usernameInput:GetValue()
    if #text > 0 then
        findAndSelectPlayer(text)
    else
        warn("[Поиск] Введите Username!")
    end
end

menu:AddButton("🔍 Найти / Обновить цель", function()
    refresh_player_searched()
end)

-- Киллы
menu:AddButton(" Kill (CFrame)", function()
    if foundTargetPlayer and foundTargetPlayer.Character then killPlayer(foundTargetPlayer) end
    refresh_player_searched()
end)

menu:AddButton(" Kill (Network)", function()
    if foundTargetPlayer and foundTargetPlayer.Character then networkKill(foundTargetPlayer) end
    refresh_player_searched()
end)

menu:AddButton("💀 Kill (Void)", function()
    if foundTargetPlayer and foundTargetPlayer.Character then voidKill(foundTargetPlayer) end
    refresh_player_searched()
end)

menu:AddButton("📍 Телепорт к цели", function()
    if foundTargetPlayer then
        teleportToPlayer(foundTargetPlayer)
    else
        warn("[TP] Сначала найди игрока через поле ввода!")
    end
    refresh_player_searched()
end)

menu:AddToggle("👁️ Следить за целью (мышью)", false, function(state)
    isSpectating = state
    if state and foundTargetPlayer then
        StartSpectate(foundTargetPlayer)
    else
        StopSpectate()
    end
end)

local function forceReloadCharacter(targetPlayer)
    print(`[Reload] Принудительная перезагрузка модели {targetPlayer.Name}...`)
    
    -- 1. Временно удаляем битую модель из workspace (только у тебя)
    local oldChar = targetPlayer.Character
    if oldChar and oldChar.Parent then
        oldChar:Destroy()
    end
    
    -- 2. Ждем, пока сервер создаст НОВУЮ модель
    -- CharacterAdded сработает только когда появится свежий объект
    local newChar = targetPlayer.CharacterAdded:Wait()
    
    -- 3. Даем время на прогрузку скелета и HRP
    task.wait(2) 
    
    -- 4. Проверяем, появилась ли HRP
    local root = newChar:FindFirstChild("HumanoidRootPart")
    if root then
        print(`[Reload] ✅ Модель восстановлена! HRP найден.`)
        
        -- Обновляем глобальную цель, чтобы кнопки TP/Kill работали
        foundTargetPlayer = targetPlayer 
        
        if flingStatusText then
            flingStatusText:SetText(`Цель: {targetPlayer.Name} [ГОТОВ]`)
            flingStatusText:SetColor(Color3.fromRGB(0, 255, 150))
        end
    else
        warn(`[Reload] ❌ Ошибка! Даже новая модель без HRP. Попробуй перезайти.`)
    end
end

-- Кнопка для меню
menu:AddButton("🛠️ FIX: Перезагрузить модель", function()
    if foundTargetPlayer then
        forceReloadCharacter(foundTargetPlayer)
    else
        -- Если цель не найдена, берем ник из поля ввода
        local name = usernameInput:GetValue()
        local p = Players:FindFirstChild(name)
        if p then 
            forceReloadCharacter(p) 
        else 
            warn("[Fix] Введите ник игрока!") 
        end
    end
end)

local function refreshPlayerModel(targetPlayer)
    local char = targetPlayer.Character
    if not char then return end
    
    -- Временно прячем старую модель
    char.Archivable = true
    local clone = char:Clone()
    char:Destroy()
    
    -- Ждем появления новой модели от сервера
    local newChar = targetPlayer.CharacterAdded:Wait()
    
    -- Если новая модель не появилась за 5 сек, возвращаем клон (на всякий случай)
    task.delay(5, function()
        if not targetPlayer.Character or not targetPlayer.Character.Parent then
            clone.Parent = workspace
            warn("[Refresh] Новая модель не загрузилась, восстановлен клон.")
        end
    end)
    
    print(`[Refresh] Модель {targetPlayer.Name} перезагружена.`)
end

menu:AddButton("🔄 Перезагрузить модель цели", function()
    if foundTargetPlayer then
        refreshPlayerModel(foundTargetPlayer)
    else
        warn("[Refresh] Сначала найди игрока!")
    end
end)

local function resyncTarget(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent then 
        warn("[Resync] Игрок покинул сервер") 
        return 
    end
    
    -- Сбрасываем глобальную переменную найденной цели
    foundTargetPlayer = nil 
    
    print(`[Resync] Пересинхронизация {targetPlayer.Name}...`)
    
    -- Ждем появления НОВОГО персонажа от сервера
    local newChar = targetPlayer.CharacterAdded:Wait()
    
    -- Даем 1 секунду на полную загрузку анимаций и хитбоксов
    task.wait(1)
    
    if newChar and newChar:FindFirstChild("HumanoidRootPart") then
        -- Обновляем цель на новую модель
        foundTargetPlayer = targetPlayer
        
        -- Визуальное подтверждение
        if flingStatusText then
            flingStatusText:SetText(`Цель: {targetPlayer.Name} [СИНХРОНИЗИРОВАНО]`)
            flingStatusText:SetColor(Color3.fromRGB(0, 255, 150))
        end
        
        print(`[Resync] ✅ Успешно! Теперь можно TP/Kill/Fling.`)
    else
        warn("[Resync]  Ошибка загрузки новой модели!")
    end
end

-- Кнопка для FlexUI
menu:AddButton("🔄 РЕСИНХРОНИЗАЦИЯ ЦЕЛИ", function()
    if usernameInput and #usernameInput:GetValue() > 0 then
        local name = usernameInput:GetValue()
        local p = Players:FindFirstChild(name)
        if p then
            resyncTarget(p)
        else
            warn("[Resync] Игрок не найден по нику из поля ввода!")
        end
    else
        warn("[Resync] Введите ник цели в поле выше!")
    end
end)

local function headRemoveKill(targetPlayer)
    local char = targetPlayer.Character
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    if head then
        head:Destroy()
        print(`[HeadKill] {targetPlayer.Name} обезглавлен.`)
    end
end

local function cleanKill(targetPlayer)
    local char = targetPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Parent then
        -- Принудительно ставим 0 здоровья
        hum.Health = 0
        
        -- Опционально: можно добавить эффект крови или звука, если игра позволяет
        print(`[CleanKill] {targetPlayer.Name} умер естественно.`)
    end
end

local function legitFling(targetPlayer)
    local char = targetPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Создаем BodyVelocity
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 500, 0) + Vector3.new(math.random(-100,100), 0, math.random(-100,100))
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = root
    
    -- Удаляем через 1 секунду, чтобы физика сама завершила полет
    task.delay(1, function() 
        if bv and bv.Parent then bv:Destroy() end 
    end)
    
    print(`[LegitFling] {targetPlayer.Name} отправлен в полет.`)
end

-- Кнопка 1: Чистое убийство
menu:AddButton("💀 Clean Kill", function()
    if foundTargetPlayer then cleanKill(foundTargetPlayer) end
    refresh_player_searched()
end)

-- Кнопка 2: Обезглавливание
menu:AddButton("🗡️ Head Remove", function()
    if foundTargetPlayer then headRemoveKill(foundTargetPlayer) end
    refresh_player_searched()
end)

-- Кнопка 3: Легитный флинг
menu:AddButton("🌀 Legit Fling", function()
    if foundTargetPlayer then legitFling(foundTargetPlayer) end
    refresh_player_searched()
end)

-- FLING SECTION (БЕЗ SELECT)
menu:AddLabel("=== KILASIK MULTI-FLING ===", {
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor = Color3.fromRGB(255, 80, 80)
})

menu:AddButton("🌀 START FLING", function()
    StartFling()
end)

menu:AddButton("⏹ STOP FLING", function()
    StopFling()
end)

-- Прочее
menu:AddButton("❤️ Восстановить здоровье", function()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = humanoid.MaxHealth
    end
end)

menu:AddButton("🛡️ Бессмертие (God Mode)", function()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
    end
end)

-- TEAM SWITCHER
local teams = game:GetService("Teams")
if #teams:GetChildren() > 0 then
    menu:AddLabel("=== СМЕНА КОМАНДЫ ===", {
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor = Color3.fromRGB(255, 200, 0)
    })
    
    for _, team in ipairs(teams:GetChildren()) do
        menu:AddButton("В команду: " .. team.Name, function()
            player.Team = team
            print("[Team Switcher] Перешёл в:", team.Name)
        end)
    end
end

menu:AddLabel("Телепорт по командам", {
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor = Color3.fromRGB(0, 255, 150)
})

for k, v in pairs(teams_spawn_points) do
    menu:AddButton("Команда: " .. k, function()
        teleport(player, v)
        print("[Team TP] Перешёл в:", k)
    end)
end

menu:AddLabel("Утилитки", {
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor = Color3.fromRGB(0, 255, 150)
})

menu:AddButton("Dexplorer", function()
    FlexUI.Dexplorer()
end)

menu:AddButton("Телепорт к сундуку", function()
    teleport(player, Vector3.new(145.55, -2.49, 1049.40))
    task.wait(1)
    teleport(player, Vector3.new(-50.83, -357.62, 9501.02))
end)

menu:AddDestroyButton("Закрыть и очистить память", Color3.fromRGB(200, 50, 50), function() 
    StopFling() -- Останавливаем флинг при закрытии
    if _G.DebugInputConnection then
        _G.DebugInputConnection:Disconnect()
        _G.DebugInputConnection = nil
    end
end)

-- Авто-обновление слежки при респавне цели
player.CharacterAdded:Connect(function()
    task.wait(1)
    if isSpectating and foundTargetPlayer then
        StopSpectate()
        task.wait(0.5)
        StartSpectate(foundTargetPlayer)
    end
end)

print("=======================================================")
print(" ИНТЕРФЕЙС ИНИЦИАЛИЗИРОВАН")
print(" [H] Меню | [P] Полёт | [M] Невидимость")
print(" [L] Ноуклип | [J] AFK | [E] Координаты")
print("=======================================================")