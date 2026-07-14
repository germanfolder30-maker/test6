--// Infinite Bombs Script (Classic Bomb)
local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local enabled = false
local targetAmount = 999 -- сколько бомб держать в инвентаре
local bombItem = nil
local connection = nil

-- Очистка старого
if shared.__infBombs then
    for _, v in ipairs(shared.__infBombs) do
        pcall(function() v:Disconnect() end)
    end
end
if game.CoreGui:FindFirstChild("InfBombsGUI") then
    game.CoreGui.InfBombsGUI:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "InfBombsGUI"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton")
btn.Parent = gui
btn.Size = UDim2.new(0, 200, 0, 45)
btn.Position = UDim2.new(0, 20, 0, 20)
btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
btn.Text = "INF BOMBS: OFF"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 14
btn.BorderSizePixel = 0
btn.AutoButtonColor = false
btn.ZIndex = 99999
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Parent = gui
status.Size = UDim2.new(0, 200, 0, 25)
status.Position = UDim2.new(0, 20, 0, 70)
status.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Font = Enum.Font.SourceSans
status.TextSize = 11
status.Text = "Ready"
status.BorderSizePixel = 0
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 5)

-- Поле ввода количества
local amountBox = Instance.new("TextBox")
amountBox.Parent = gui
amountBox.Size = UDim2.new(0, 200, 0, 30)
amountBox.Position = UDim2.new(0, 20, 0, 100)
amountBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
amountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
amountBox.Font = Enum.Font.SourceSans
amountBox.TextSize = 13
amountBox.Text = "999"
amountBox.PlaceholderText = "Количество бомб"
amountBox.BorderSizePixel = 0
Instance.new("UICorner", amountBox).CornerRadius = UDim.new(0, 5)

-- Поиск бомбы в инвентаре
local function findBomb()
    -- Ищем в разных возможных местах
    local searchPaths = {
        player:FindFirstChild("Backpack"),
        player:FindFirstChild("Inventory"),
        player.Character
    }
    
    for _, parent in ipairs(searchPaths) do
        if parent then
            for _, item in ipairs(parent:GetChildren()) do
                local name = string.lower(item.Name)
                if string.find(name, "classic bomb") or string.find(name, "bomb") then
                    return item
                end
                -- Проверяем внутри инструментов
                if item:IsA("Tool") then
                    for _, child in ipairs(item:GetChildren()) do
                        if child:IsA("IntValue") or child:IsA("NumberValue") then
                            if string.find(string.lower(child.Name), "count") or 
                               string.find(string.lower(child.Name), "amount") or
                               string.find(string.lower(child.Name), "quantity") then
                                return child
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Ищем через PlayerGui (может быть UI инвентарь)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, item in ipairs(playerGui:GetDescendants()) do
            if item:IsA("IntValue") or item:IsA("NumberValue") then
                if string.find(string.lower(item.Name), "bomb") then
                    return item
                end
            end
        end
    end
    
    return nil
end

-- Функция поддержания количества
local function maintainBombs()
    bombItem = findBomb()
    if bombItem then
        local currentAmount = nil
        
        if bombItem:IsA("Tool") then
            -- Если это инструмент, ищем дочерний IntValue
            local countObj = bombItem:FindFirstChildWhichIsA("IntValue") or 
                             bombItem:FindFirstChildWhichIsA("NumberValue")
            if countObj then
                currentAmount = countObj.Value
                if currentAmount < targetAmount then
                    countObj.Value = targetAmount
                    status.Text = string.format("Bombs: %d (refilled)", targetAmount)
                end
            end
        elseif bombItem:IsA("IntValue") or bombItem:IsA("NumberValue") then
            currentAmount = bombItem.Value
            if currentAmount < targetAmount then
                bombItem.Value = targetAmount
                status.Text = string.format("Bombs: %d (refilled)", targetAmount)
            end
        end
    else
        status.Text = "Bomb not found in inventory"
    end
end

-- Переключение
local function toggle()
    enabled = not enabled
    
    if enabled then
        targetAmount = tonumber(amountBox.Text) or 999
        btn.Text = "INF BOMBS: ON"
        btn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        status.Text = "Monitoring bombs..."
        connection = runService.Heartbeat:Connect(maintainBombs)
    else
        btn.Text = "INF BOMBS: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        status.Text = "Ready"
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
end

btn.MouseButton1Click:Connect(toggle)

-- Горячая клавиша F7
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F7 then
        toggle()
    end
end)

-- При возрождении
player.CharacterAdded:Connect(function()
    if enabled then
        if connection then connection:Disconnect() end
        connection = runService.Heartbeat:Connect(maintainBombs)
    end
end)

shared.__infBombs = {connection}
