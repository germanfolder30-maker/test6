--// Light ESP Script for Mine a Mountain (No Lag)
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")

local enabled = false
local connections = {}
local foundOres = {}

-- Очистка старого
if shared.__lightESP then
    for _, v in ipairs(shared.__lightESP) do
        pcall(function() v:Disconnect() end)
    end
end
if shared.__lightESPOres then
    for _, v in pairs(shared.__lightESPOres) do
        pcall(function() v:Destroy() end)
    end
end

-- Удаляем старый GUI
if game.CoreGui:FindFirstChild("LightESPGUI") then
    game.CoreGui.LightESPGUI:Destroy()
end

-- Список нужных руд
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
gui.Name = "LightESPGUI"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

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
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

-- Проверка на нужную руду
local function isTargetOre(obj)
    if not obj:IsA("BasePart") then return false end
    if obj.Transparency >= 1 then return false end
    
    local objName = string.lower(obj.Name)
    local parent = obj.Parent
    local parentName = parent and string.lower(parent.Name) or ""
    
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

-- Создание BoxHandleAdornment (легче чем Highlight)
local function createBox(obj)
    if foundOres[obj] then return end
    
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESPBox"
    box.Adornee = obj
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = obj.Size + Vector3.new(0.5, 0.5, 0.5)
    box.Color3 = Color3.fromRGB(255, 255, 0)
    box.Transparency = 0.4
    box.Parent = obj
    
    foundOres[obj] = box
    
    -- Удаление при уничтожении объекта
    obj.Destroying:Connect(function()
        foundOres[obj] = nil
    end)
end

-- Удаление бокса
local function removeBox(obj)
    local box = foundOres[obj]
    if box then
        pcall(function() box:Destroy() end)
        foundOres[obj] = nil
    end
end

-- ОДНОРАЗОВОЕ сканирование
local function scanOnce()
    local count = 0
    
    local function scan(parent, depth)
        if depth > 30 then return end
        
        for _, child in ipairs(parent:GetChildren()) do
            if isTargetOre(child) then
                createBox(child)
                count = count + 1
            end
            
            if child:IsA("Folder") or child:IsA("Model") then
                scan(child, depth + 1)
            end
        end
    end
    
    scan(workspace, 0)
    return count
end

-- Удаление всех боксов
local function clearAll()
    for obj, box in pairs(foundOres) do
        pcall(function() box:Destroy() end)
    end
    foundOres = {}
end

-- Переключение
local function toggle()
    enabled = not enabled
    
    if enabled then
        button.Text = "ORE ESP: ON"
        button.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        local count = scanOnce()
        print("Найдено руды: " .. count)
    else
        button.Text = "ORE ESP: OFF"
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        clearAll()
    end
end

-- Кнопка
button.MouseButton1Click:Connect(toggle)

-- Горячая клавиша F6
connections[1] = uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        toggle()
    end
end)

-- При возрождении
connections[2] = player.CharacterAdded:Connect(function()
    if enabled then
        clearAll()
        scanOnce()
    end
end)

shared.__lightESP = connections
shared.__lightESPOres = foundOres
