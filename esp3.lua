--// Terrain Ore Scanner + ESP (Читает воксели горы)
local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local enabled = false
local scanConnection = nil
local connections = {}
local foundBoxes = {}

-- Очистка старого
if shared.__terrainESP then
    for _, v in ipairs(shared.__terrainESP) do
        pcall(function() v:Disconnect() end)
    end
end
if shared.__terrainBoxes then
    for _, v in pairs(shared.__terrainBoxes) do
        pcall(function() v:Destroy() end)
    end
end
if game.CoreGui:FindFirstChild("TerrainESPGUI") then
    game.CoreGui.TerrainESPGUI:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "TerrainESPGUI"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

local button = Instance.new("TextButton")
button.Name = "ESPButton"
button.Parent = gui
button.Size = UDim2.new(0, 200, 0, 45)
button.Position = UDim2.new(0, 15, 0, 15)
button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
button.Text = "TERRAIN ESP: OFF"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 13
button.BorderSizePixel = 0
button.AutoButtonColor = false
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = gui
statusLabel.Size = UDim2.new(0, 200, 0, 25)
statusLabel.Position = UDim2.new(0, 15, 0, 65)
statusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 11
statusLabel.Text = "Status: Ready"
statusLabel.BorderSizePixel = 0
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 5)

-- Цвета для разных руд
local oreColors = {
    [Enum.Material.Slate] = {Color3.fromRGB(60, 60, 60), "Dark Stone"},
    [Enum.Material.Granite] = {Color3.fromRGB(140, 140, 140), "Granite"},
    [Enum.Material.Marble] = {Color3.fromRGB(200, 200, 200), "Marble"},
    [Enum.Material.Sandstone] = {Color3.fromRGB(180, 160, 100), "Sandstone"},
    [Enum.Material.Basalt] = {Color3.fromRGB(80, 80, 80), "Basalt"},
    [Enum.Material.Limestone] = {Color3.fromRGB(220, 220, 200), "Limestone"},
    [Enum.Material.Glacier] = {Color3.fromRGB(150, 220, 255), "Glacier"},
    [Enum.Material.Salt] = {Color3.fromRGB(255, 200, 200), "Salt"},
    [Enum.Material.Metal] = {Color3.fromRGB(150, 150, 150), "Metal"},
    [Enum.Material.DiamondPlate] = {Color3.fromRGB(100, 200, 255), "Diamond"},
    [Enum.Material.CorrodedMetal] = {Color3.fromRGB(180, 120, 80), "Corroded"},
    [Enum.Material.Gold] = {Color3.fromRGB(255, 215, 0), "Gold"},
    [Enum.Material.Neon] = {Color3.fromRGB(255, 100, 255), "Neon"},
    [Enum.Material.Glass] = {Color3.fromRGB(200, 230, 255), "Glass"},
    [Enum.Material.Cobblestone] = {Color3.fromRGB(120, 120, 120), "Cobblestone"},
    [Enum.Material.Concrete] = {Color3.fromRGB(160, 160, 160), "Concrete"},
    [Enum.Material.Brick] = {Color3.fromRGB(180, 100, 80), "Brick"},
    [Enum.Material.Pebble] = {Color3.fromRGB(140, 130, 120), "Pebble"},
    [Enum.Material.Rock] = {Color3.fromRGB(100, 100, 100), "Rock"},
    [Enum.Material.Asphalt] = {Color3.fromRGB(60, 60, 60), "Asphalt"},
}

-- Функция сканирования террейна
local function scanTerrain()
    if not player.Character then return end
    
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local pos = root.Position
    local scanRadius = 80 -- радиус сканирования
    local stepSize = 3 -- шаг сканирования (меньше = точнее, но медленнее)
    local count = 0
    
    -- Очищаем старые боксы
    for _, box in pairs(foundBoxes) do
        pcall(function() box:Destroy() end)
    end
    foundBoxes = {}
    
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        statusLabel.Text = "Status: No terrain found"
        return 0
    end
    
    -- Сканируем куб вокруг игрока
    local minX = pos.X - scanRadius
    local maxX = pos.X + scanRadius
    local minY = math.max(0, pos.Y - scanRadius)
    local maxY = pos.Y + scanRadius
    local minZ = pos.Z - scanRadius
    local maxZ = pos.Z + scanRadius
    
    local region = Region3.new(
        Vector3.new(minX, minY, minZ),
        Vector3.new(maxX, maxY, maxZ)
    )
    
    -- Получаем материалы в регионе
    local materialMap = {}
    
    for x = minX, maxX, stepSize do
        for y = minY, maxY, stepSize do
            for z = minZ, maxZ, stepSize do
                local checkPos = Vector3.new(x, y, z)
                local cellMaterial, cellOccupancy = terrain:GetMaterialAtPosition(checkPos)
                
                -- Проверяем, не является ли это обычным воздухом или землёй
                if cellOccupancy > 0 and cellMaterial ~= Enum.Material.Air and cellMaterial ~= Enum.Material.Water then
                    -- Проверяем, не является ли материал "обычной землёй"
                    -- Обычно руда отличается от окружающего материала
                    local cellId = tostring(cellMaterial) .. "|" .. math.floor(x/stepSize) .. "," .. math.floor(y/stepSize) .. "," .. math.floor(z/stepSize)
                    
                    if not materialMap[cellMaterial] then
                        materialMap[cellMaterial] = {count = 0, positions = {}}
                    end
                    materialMap[cellMaterial].count = materialMap[cellMaterial].count + 1
                    
                    -- Сохраняем несколько позиций для каждого материала
                    if #materialMap[cellMaterial].positions < 50 then
                        table.insert(materialMap[cellMaterial].positions, Vector3.new(x, y, z))
                    end
                end
            end
        end
        
        -- Обновляем статус
        if math.random(1, 100) == 1 then
            statusLabel.Text = string.format("Scanning: %.0f%%", (x - minX) / (maxX - minX) * 100)
            runService.RenderStepped:Wait()
        end
    end
    
    -- Создаём боксы для КАЖДОГО найденного материала
    local totalBoxes = 0
    for material, data in pairs(materialMap) do
        local color = oreColors[material]
        if color then
            for _, boxPos in ipairs(data.positions) do
                -- Создаём маленький бокс на месте руды
                local box = Instance.new("Part")
                box.Name = "OreMarker"
                box.Size = Vector3.new(stepSize, stepSize, stepSize)
                box.Position = boxPos
                box.Anchored = true
                box.CanCollide = false
                box.Transparency = 0.6
                box.Color = color[1]
                box.Material = Enum.Material.Neon
                box.Parent = workspace
                
                foundBoxes[box] = true
                totalBoxes = totalBoxes + 1
            end
        end
    end
    
    return totalBoxes
end

-- Очистка всех боксов
local function clearBoxes()
    for box, _ in pairs(foundBoxes) do
        pcall(function() box:Destroy() end)
    end
    foundBoxes = {}
end

-- Переключение
local function toggle()
    enabled = not enabled
    
    if enabled then
        button.Text = "TERRAIN ESP: SCANNING..."
        button.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        statusLabel.Text = "Status: Scanning terrain..."
        
        -- Запускаем сканирование в отдельном потоке
        task.spawn(function()
            local count = scanTerrain()
            statusLabel.Text = string.format("Status: Found %d ore blocks", count)
            button.Text = string.format("TERRAIN ESP: ON (%d)", count)
            button.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        end)
    else
        button.Text = "TERRAIN ESP: OFF"
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        statusLabel.Text = "Status: Ready"
        clearBoxes()
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

-- Очистка при выходе
connections[2] = player.CharacterAdded:Connect(function()
    if enabled then
        clearBoxes()
        task.spawn(function()
            local count = scanTerrain()
            statusLabel.Text = string.format("Status: Found %d ore blocks", count)
            button.Text = string.format("TERRAIN ESP: ON (%d)", count)
        end)
    end
end)

shared.__terrainESP = connections
shared.__terrainBoxes = foundBoxes
