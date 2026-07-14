--// ESP Script for Mine a Mountain (8 Specific Ores Only)
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")

local enabled = false
local highlightCache = {}
local scanConnection = nil
local connections = {}

-- Очистка старого
if shared.__espMountain then
    for _, v in ipairs(shared.__espMountain) do
        pcall(function() v:Disconnect() end)
    end
end
if shared.__espHighlightCache then
    for _, v in pairs(shared.__espHighlightCache) do
        pcall(function() v:Destroy() end)
    end
end

-- Удаляем старый GUI
if game.CoreGui:FindFirstChild("ESPMountainGUI") then
    game.CoreGui.ESPMountainGUI:Destroy()
end

-- Список ТОЛЬКО нужных руд
local targetOres = {
    "gunpowered stone",
    "skyglass",
    "cryostone",
    "cinderforge plate",
    "stormsteel",
    "venomite",
    "chronoshard",
    "dreadstone"
}

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ESPMountainGUI"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local button = Instance.new("TextButton")
button.Name = "ESPButton"
button.Parent = gui
button.Size = UDim2.new(0, 200, 0, 45)
button.Position = UDim2.new(0, 15, 0, 15)
button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
button.Text = "ORE ESP: OFF"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 15
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Active = true
button.Selectable = true
button.Visible = true
button.ZIndex = 99999

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

-- Проверка: является ли объект нужной рудой
local function isTargetOre(obj)
    if not obj:IsA("BasePart") then return false end
    if obj.Transparency >= 1 then return false end
    if obj.Size.Magnitude > 300 then return false end
    if obj.Size.Magnitude < 0.1 then return false end
    
    local objName = string.lower(obj.Name)
    local parent = obj.Parent
    local parentName = parent and string.lower(parent.Name) or ""
    
    -- Проверяем имя объекта и родителя
    for _, oreName in ipairs(targetOres) do
        if objName == oreName or parentName == oreName then
            return true
        end
        if string.find(objName, oreName) or string.find(parentName, oreName) then
            return true
        end
    end
    
    return false
end

-- Создание подсветки
local function createHighlight(obj)
    if highlightCache[obj] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 255, 0)
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = Color3.fromRGB(255, 170, 0)
    highlight.OutlineTransparency = 0
    highlight.Adornee = obj
    highlight.Parent = obj
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    
    highlightCache[obj] = highlight
    
    -- Автоудаление при уничтожении объекта
    obj.Destroying:Connect(function()
        highlightCache[obj] = nil
    end)
end

-- Удаление подсветки
local function removeHighlight(obj)
    local highlight = highlightCache[obj]
    if highlight then
        pcall(function() highlight:Destroy() end)
        highlightCache[obj] = nil
    end
end

-- Сканирование с ограничением глубины
local function scanForOres(parent, depth)
    if depth > 25 then return end
    
    for _, child in ipairs(parent:GetChildren()) do
        if isTargetOre(child) then
            createHighlight(child)
        end
        
        -- Рекурсивно сканируем только папки и модели
        if child:IsA("Folder") or child:IsA("Model") then
            scanForOres(child, depth + 1)
        end
    end
end

-- Основной цикл
local function scanLoop()
    scanForOres(workspace, 0)
end

-- Переключение
local function toggle()
    enabled = not enabled
    
    if enabled then
        scanConnection = runService.Heartbeat:Connect(scanLoop)
        button.Text = "ORE ESP: ON"
        button.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
    else
        if scanConnection then
            scanConnection:Disconnect()
            scanConnection = nil
        end
        -- Удаляем всю подсветку
        for obj, hl in pairs(highlightCache) do
            pcall(function() hl:Destroy() end)
        end
        highlightCache = {}
        
        button.Text = "ORE ESP: OFF"
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end
end

-- Привязка кнопки
button.MouseButton1Click:Connect(toggle)

-- Горячая клавиша F6
connections[1] = uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        toggle()
    end
end)

-- При возрождении перезапускаем если было включено
connections[2] = player.CharacterAdded:Connect(function()
    if enabled then
        if scanConnection then
            scanConnection:Disconnect()
        end
        scanConnection = runService.Heartbeat:Connect(scanLoop)
    end
end)

shared.__espMountain = connections
shared.__espHighlightCache = highlightCache
