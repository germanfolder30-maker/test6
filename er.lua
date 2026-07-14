--// Auto Steal Ores from Any Plot (Mine a Mountain)
local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local enabled = false
local stealConnection = nil
local markers = {}  -- если захочешь визуализировать

-- Целевые руды (можно дополнить)
local oreNames = {
    "gunpowered stone", "skyglass", "cryostone", "cinderforge plate",
    "stormsteel", "venomite", "chronoshard", "dreadstone"
}

-- Очистка предыдущего запуска
if shared.__stealOres then
    for _, conn in ipairs(shared.__stealOres) do
        pcall(function() conn:Disconnect() end)
    end
end
if game.CoreGui:FindFirstChild("StealGUI") then
    game.CoreGui.StealGUI:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "StealGUI"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton")
btn.Parent = gui
btn.Size = UDim2.new(0, 200, 0, 45)
btn.Position = UDim2.new(0, 20, 0, 100)
btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
btn.Text = "STEAL ORES: OFF"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 15
btn.BorderSizePixel = 0
btn.AutoButtonColor = false
btn.ZIndex = 99999
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Parent = gui
status.Size = UDim2.new(0, 200, 0, 25)
status.Position = UDim2.new(0, 20, 0, 150)
status.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Font = Enum.Font.SourceSans
status.TextSize = 11
status.Text = "Ready"
status.BorderSizePixel = 0
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 5)

-- Функция проверки имени руды
local function isOrePart(part)
    if not part:IsA("BasePart") then return false end
    local name = string.lower(part.Name)
    local parentName = part.Parent and string.lower(part.Parent.Name) or ""
    for _, ore in ipairs(oreNames) do
        if name == ore or parentName == ore or string.find(name, ore) or string.find(parentName, ore) then
            return true
        end
    end
    return false
end

-- Попытка украсть руду
local function trySteal(part)
    -- Способ 1: ProximityPrompt
    local model = part.Parent
    if model and model:IsA("Model") then
        local prompt = model:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            -- Активируем подбор
            pcall(function()
                prompt:InputHoldBegin()
                wait(0.05)
                prompt:InputHoldEnd()
            end)
            return true
        end
    end

    -- Способ 2: ищем все RemoteEvent и пробуем отправить
    local remotes = replicatedStorage:GetDescendants()
    for _, remote in ipairs(remotes) do
        if remote:IsA("RemoteEvent") then
            pcall(function()
                remote:FireServer(part)         -- некоторые игры передают сам объект
                remote:FireServer(part, 1)      -- другие – объект и количество
                remote:FireServer(part.Name)    -- иногда только имя
            end)
        end
    end

    -- Способ 3: попытка телепортировать руду к игроку (если разрешено)
    if part.Anchored then
        part.Anchored = false
    end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        part.CFrame = root.CFrame * CFrame.new(0, 5, 0)  -- перед игроком
    end

    return false
end

-- Главный цикл автокражи
local function stealLoop()
    local stolen = 0
    local parts = workspace:GetDescendants()
    for _, part in ipairs(parts) do
        if isOrePart(part) then
            local dist = (part.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if dist < 50 then  -- радиус действия
                if trySteal(part) then
                    stolen = stolen + 1
                end
            end
        end
    end
    status.Text = string.format("Stolen: %d ores", stolen)
end

-- Включение/выключение
local function toggle()
    enabled = not enabled
    if enabled then
        btn.Text = "STEAL ORES: ON"
        btn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        status.Text = "Auto steal active"
        stealConnection = runService.Heartbeat:Connect(function()
            pcall(stealLoop)
        end)
    else
        btn.Text = "STEAL ORES: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        status.Text = "Ready"
        if stealConnection then
            stealConnection:Disconnect()
            stealConnection = nil
        end
    end
end

btn.MouseButton1Click:Connect(toggle)

uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F7 then
        toggle()
    end
end)

player.CharacterAdded:Connect(function()
    if enabled then
        -- перезапуск после смерти
        if stealConnection then stealConnection:Disconnect() end
        stealConnection = runService.Heartbeat:Connect(stealLoop)
    end
end)

shared.__stealOres = {stealConnection}
