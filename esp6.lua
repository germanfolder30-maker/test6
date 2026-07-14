--// Color-Based Terrain Ore ESP
local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local enabled = false
local foundMarkers = {}
local connections = {}
local scanThread = nil
local stopScan = false

-- Очистка старого
if shared.__colorESP then
    for _, v in ipairs(shared.__colorESP) do
        pcall(function() v:Disconnect() end)
    end
end
if shared.__colorMarkers then
    for _, v in pairs(shared.__colorMarkers) do
        pcall(function() v:Destroy() end)
    end
end
for _, obj in ipairs(game.CoreGui:GetChildren()) do
    if obj.Name == "ColorESPGUI" then obj:Destroy() end
end

-- Цвета руды которые ты назвал
local targetColors = {
    {r = 40, g = 40, b = 40, name = "Dark/Black", range = 25},        -- тёмная руда
    {r = 255, g = 140, b = 180, name = "Light Pink", range = 60},     -- светло-розовый
    {r = 100, g = 200, b = 255, name = "Bright Blue", range = 55},    -- голубой яркий
    {r = 50, g = 255, b = 50, name = "Acid Green", range = 55},       -- зеленая как кислота
    {r = 20, g = 20, b = 20, name = "Very Dark", range = 15},         -- очень тёмная
    {r = 255, g = 100, b: 150, name: "Pink/Red", range: 60},          -- розово-красный
    {r: 255, g: 200, b: 100, name: "Gold/Yellow", range: 50},         -- золотой
    {r: 255, g: 50, b: 50, name: "Red", range: 55},                   -- красный
    {r: 180, g: 100, b: 255, name: "Purple", range: 55},              -- фиолетовый
}

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ColorESPGUI"
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
button.Active = true
button.Selectable = true
button.Visible = true
button.ZIndex = 99999
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = gui
statusLabel.Size = UDim2.new(0, 200, 0, 25)
statusLabel.Position = UDim2.new(0, 15, 0, 65)
statusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 11
statusLabel.Text = "Ready"
statusLabel.BorderSizePixel = 0
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 5)

-- Функция проверки цвета
local function isOreColor(r, g, b)
    for _, target in ipairs(targetColors) do
        local dr = math.abs(r - target.r)
        local dg = math.abs(g - target.g)
        local db = math.abs(b - target.b)
        if dr <= target.range and dg <= target.range and db <= target.range then
            return true, target.name
        end
    end
    return false, nil
end

-- Создание маркера
local function createMarker(pos, color, name)
    local marker = Instance.new("Part")
    marker.Name = "OreMarker_" .. name
    marker.Size = Vector3.new(2, 2, 2)
    marker.Position = pos
    marker.Anchored = true
    marker.CanCollide = false
    marker.Transparency = 0.4
    marker.Color = color
    marker.Material = Enum.Material.Neon
    marker.Parent = workspace
    
    -- Добавляем свечение
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0
    highlight.Adornee = marker
    highlight.Parent = marker
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    foundMarkers[#foundMarkers + 1] = marker
    return marker
end

-- Сканирование террейна по цвету
local function scanTerrainColors()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        statusLabel.Text = "No terrain found"
        return 0
    end
    
    if not player.Character then
        statusLabel.Text = "No character"
        return 0
    end
    
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        statusLabel.Text = "No HumanoidRootPart"
        return 0
    end
    
    local pos = root.Position
    local scanRadius = 100
    local stepSize = 2
    local totalFound = 0
    local scannedPoints = 0
    local totalPoints = ((scanRadius * 2) / stepSize) ^ 3
    
    stopScan = false
    
    for x = pos.X - scanRadius, pos.X + scanRadius, stepSize do
        if stopScan then break end
        
        for y = math.max(0, pos.Y - scanRadius), pos.Y + scanRadius, stepSize do
            if stopScan then break end
            
            for z = pos.Z - scanRadius, pos.Z + scanRadius, stepSize do
                if stopScan then break end
                
                scannedPoints = scannedPoints + 1
                
                -- Обновляем статус каждые 10000 точек
                if scannedPoints % 10000 == 0 then
                    local progress = math.floor(scannedPoints / totalPoints * 100)
                    statusLabel.Text = string.format("Scanning: %d%% (%d found)", progress, totalFound)
                    runService.RenderStepped:Wait()
                end
                
                local checkPos = Vector3.new(x, y, z)
                local material, occupancy = terrain:GetMaterialAtPosition(checkPos)
                
                if occupancy > 0.5 and material ~= Enum.Material.Air and material ~= Enum.Material.Water then
                    -- Получаем цвет террейна в этой точке
                    local color = terrain:GetTerrainColorAtPosition(checkPos)
                    
                    if color then
                        local r = math.floor(color.R * 255)
                        local g = math.floor(color.G * 255)
                        local b = math.floor(color.B * 255)
                        
                        local isOre, oreName = isOreColor(r, g, b)
                        if isOre then
                            -- Проверяем что рядом нет уже маркера
                            local tooClose = false
                            for _, marker in ipairs(foundMarkers) do
                                if (marker.Position - checkPos).Magnitude < 5 then
                                    tooClose = true
                                    break
                                end
                            end
                            
                            if not tooClose then
                                createMarker(checkPos, Color3.fromRGB(r, g, b), oreName)
                                totalFound = totalFound + 1
                                
                                -- Лимит маркеров для производительности
                                if totalFound >= 200 then
                                    statusLabel.Text = string.format("Found: %d (limit reached)", totalFound)
                                    return totalFound
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    statusLabel.Text = string.format("Complete: Found %d ore spots", totalFound)
    return totalFound
end

-- Очистка маркеров
local function clearMarkers()
    for _, marker in ipairs(foundMarkers) do
        pcall(function() marker:Destroy() end)
    end
    foundMarkers = {}
end

-- Переключение
local function toggle()
    enabled = not enabled
    
    if enabled then
        button.Text = "ORE ESP: SCANNING..."
        button.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        statusLabel.Text = "Starting scan..."
        
        -- Запускаем в отдельном потоке
        task.spawn(function()
            local count = scanTerrainColors()
            button.Text = string.format("ORE ESP: ON (%d)", count)
            button.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        end)
    else
        stopScan = true
        button.Text = "ORE ESP: OFF"
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        statusLabel.Text = "Ready"
        clearMarkers()
    end
end

-- Кнопка
button.MouseButton1Click:Connect(toggle)

-- Горячие клавиши
connections[1] = uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        toggle()
    end
end)

-- Очистка при возрождении
connections[2] = player.CharacterAdded:Connect(function()
    if enabled then
        clearMarkers()
        task.spawn(function()
            local count = scanTerrainColors()
            button.Text = string.format("ORE ESP: ON (%d)", count)
            button.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        end)
    end
end)

shared.__colorESP = connections
shared.__colorMarkers = foundMarkers
