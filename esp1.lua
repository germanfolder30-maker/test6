--// Fixed ESP Script for Mine a Mountain (Case Insensitive)
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")

local enabled = false
local connections = {}
local foundOres = {}

-- Очистка старого
if shared.__fixedESP then
    for _, v in ipairs(shared.__fixedESP) do
        pcall(function() v:Disconnect() end)
    end
end
if shared.__fixedESPOres then
    for _, v in pairs(shared.__fixedESPOres) do
        pcall(function() v:Destroy() end)
    end
end

-- Удаляем старый GUI
if game.CoreGui:FindFirstChild("FixedESPGUI") then
    game.CoreGui.FixedESPGUI:Destroy()
end

-- Список нужных руд (нижний регистр)
local targetOres = {
    "gunpowered stone",
    "gunpowered_stone",
    "gunpoweredstone",
    "skyglass",
    "sky_glass",
    "cryostone",
    "cryo_stone",
    "cinderforge plate",
    "cinderforge_plate",
    "cinderforgeplate",
    "stormsteel",
    "storm_steel",
    "venomite",
    "chronoshard",
    "chrono_shard",
    "dreadstone",
    "dread_stone"
}

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "FixedESPGUI"
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

-- Проверка на нужную руду (регистронезависимая)
local function isTargetOre(obj)
    if not obj:IsA("BasePart") then return false end
    if obj.Transparency >= 1 then return false end
    if obj.Size.Magnitude < 0.05 then return false end
    
    local objName = string.lower(obj.Name)
    local parent = obj.Parent
    local parentName = parent and string.lower(parent.Name) or ""
    local grandParent = parent and parent.Parent
    local grandParentName = grandParent and string.lower(grandParent.Name) or ""
    
    -- Убираем пробелы и подчёркивания для сравнения
    local cleanObjName = string.gsub(objName, "[_ ]", "")
    local cleanParentName = string.gsub(parentName, "[_ ]", "")
    local cleanGrandParentName = string.gsub(grandParentName, "[_ ]", "")
    
    for _, oreName in ipairs(targetOres) do
        local cleanOreName = string.gsub(oreName, "[_ ]", "")
        
        -- Проверяем сам объект
        if cleanObjName == cleanOreName then
            return true
        end
        -- Проверяем родителя
        if cleanParentName == cleanOreName then
            return true
        end
        -- Проверяем родителя родителя
        if cleanGrandParentName == cleanOreName then
            return true
        end
        -- Частичное совпадение
        if string.find(cleanObjName, cleanOreName) or string.find(cleanOreName, cleanObjName) then
            if #cleanObjName >= #cleanOreName * 0.7 then -- минимум 70% совпадение
                return true
            end
        end
    end
    
    return false
end

-- Создание подсветки
local function createBox(obj)
    if foundOres[obj] then return end
    
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESPBox"
    box.Adornee = obj
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = obj.Size + Vector3.new(1, 1, 1)
    box.Color3 = Color3.fromRGB(255, 255, 0)
    box.Transparency = 0.3
    box.Parent = obj
    
    foundOres[obj] = box
    
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

-- Глубокое сканирование ВСЕХ возможных мест
local function deepScan()
    local count = 0
    local scanned = {}
    
    local function scan(parent, depth, path)
        if depth > 50 then return end
        if scanned[parent] then return end
        scanned[parent] = true
        
        for _, child in ipairs(parent:GetChildren()) do
            -- Проверяем ВСЕ объекты, не только BasePart
            if isTargetOre(child) then
                createBox(child)
                count = count + 1
            end
            
            -- Сканируем всё что может содержать объекты
            if child:IsA("Folder") or child:IsA("Model") or child:IsA("Part") 
               or child:IsA("BasePart") or child:IsA("UnionOperation") 
               or child:IsA("MeshPart") or child:IsA("Union") then
                scan(child, depth + 1, path .. "/" .. child.Name)
            end
        end
    end
    
    -- Сканируем workspace и все основные контейнеры
    scan(workspace, 0, "workspace")
    
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
        button.Text = "SCANNING..."
        button.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        
        -- Даём интерфейсу обновиться
        task.wait(0.1)
        
        local count = deepScan()
        
        button.Text = "ORE ESP: ON (" .. count .. ")"
        button.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
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
        task.wait(0.5)
        deepScan()
    end
end)

shared.__fixedESP = connections
shared.__fixedESPOres = foundOres
