--// Anti Fall Damage Script (Final Fixed Version)
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local starterGui = game:GetService("StarterGui")

local enabled = false
local fallConnection = nil
local connections = {}

-- Очистка всего старого
if shared.__finalAntiFall then
    for _, v in ipairs(shared.__finalAntiFall) do
        pcall(function() v:Disconnect() end)
    end
end

-- Удаляем старые GUI
for _, obj in ipairs(player:WaitForChild("PlayerGui"):GetChildren()) do
    if obj.Name == "AntiFallGUI" then
        obj:Destroy()
    end
end

-- Создаём GUI в PlayerGui (более надёжное место)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiFallGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true

-- Кнопка с уникальным дизайном
local button = Instance.new("TextButton")
button.Name = "AntiFallButton"
button.Parent = screenGui
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0, 10, 0, 10)
button.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
button.Text = "ANTI FALL: OFF"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.BackgroundTransparency = 0
button.Active = true
button.Selectable = true
button.Visible = true
button.ZIndex = 99999
button.Modal = false

-- Тень для объёма
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Parent = button
shadow.Size = UDim2.new(1, 6, 1, 6)
shadow.Position = UDim2.new(0, -3, 0, -3)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.5
shadow.BorderSizePixel = 0
shadow.ZIndex = 99998

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = button

local cornerShadow = Instance.new("UICorner")
cornerShadow.CornerRadius = UDim.new(0, 12)
cornerShadow.Parent = shadow

-- Отправляем уведомление что скрипт загружен
starterGui:SetCore("SendNotification", {
    Title = "Anti Fall Damage",
    Text = "Скрипт загружен! Нажми F7 или кнопку",
    Duration = 5
})

-- Защита от падения
local function protectionLoop()
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if hum then
        -- Убираем урон от падения
        if hum.FallDamage ~= 0 then
            hum.FallDamage = 0
        end
        
        -- Предотвращаем спотыкание
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        
        -- Если здоровье уменьшилось — восстанавливаем
        if hum.Health < hum.MaxHealth and state ~= Enum.HumanoidStateType.Dead then
            local diff = hum.MaxHealth - hum.Health
            if diff > 0 and diff < 50 then -- только урон от падения
                hum.Health = hum.Health + diff
            end
        end
    end
    
    if root then
        -- Ограничиваем скорость падения
        local velY = root.Velocity.Y
        if velY < -50 then
            root.Velocity = Vector3.new(root.Velocity.X, -35, root.Velocity.Z)
        end
    end
end

-- Функция переключения
local function toggle()
    enabled = not enabled
    
    if enabled then
        if fallConnection then
            fallConnection:Disconnect()
        end
        fallConnection = runService.Stepped:Connect(protectionLoop)
        
        button.Text = "ANTI FALL: ON"
        button.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        
        starterGui:SetCore("SendNotification", {
            Title = "Anti Fall Damage",
            Text = "Защита от падения ВКЛЮЧЕНА",
            Duration = 3
        })
    else
        if fallConnection then
            fallConnection:Disconnect()
            fallConnection = nil
        end
        
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.FallDamage = 100
        end
        
        button.Text = "ANTI FALL: OFF"
        button.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        
        starterGui:SetCore("SendNotification", {
            Title = "Anti Fall Damage",
            Text = "Защита от падения ВЫКЛЮЧЕНА",
            Duration = 3
        })
    end
end

-- Привязка клика
button.MouseButton1Click:Connect(toggle)

-- Горячие клавиши (несколько для надёжности)
connections[1] = uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F7 or input.KeyCode == Enum.KeyCode.F8 then
        toggle()
    end
end)

-- При возрождении персонажа
connections[2] = player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    
    if enabled then
        if fallConnection then
            fallConnection:Disconnect()
        end
        fallConnection = runService.Stepped:Connect(protectionLoop)
    end
end)

-- Сохраняем ссылки
shared.__finalAntiFall = {fallConnection, connections[1], connections[2]}
