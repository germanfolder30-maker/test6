--// Mine a Mountain - Color Ore ESP (Based on Wiki)
local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local enabled = false
local markers = {}
local scanThread = nil
local stopRequested = false

-- Очистка старого
if shared.__mamESP then
    for _, v in ipairs(shared.__mamESP) do
        pcall(function() v:Disconnect() end)
    end
end
if shared.__mamMarkers then
    for _, v in pairs(shared.__mamMarkers) do
        pcall(function() v:Destroy() end)
    end
end
if game.CoreGui:FindFirstChild("MAM_ESP") then
    game.CoreGui.MAM_ESP:Destroy()
end

-- Цвета руд (RGB) и допустимое отклонение
local ores = {
    {name = "Gunpowered Stone", r = 40, g = 40, b = 40, range = 25},   -- очень тёмный
    {name = "Dreadstone",       r = 35, g = 35, b = 35, range = 25},   -- почти чёрный
    {name = "Skyglass",         r = 100, g = 200, b = 255, range = 45},-- ярко-голубой
    {name = "Cryostone",        r = 150, g = 220, b = 255, range = 40},-- ледяной голубой
    {name = "Chronoshard",      r = 200, g = 120, b = 220, range = 45},-- фиолетово-розовый
    {name = "Venomite",         r = 80, g = 255, b = 80, range = 45},  -- кислотно-зелёный
    {name = "Cinderforge Plate",r = 255, g = 120, b = 40, range = 45}, -- оранжево-красный
    {name = "Stormsteel",       r = 140, g = 140, b = 150, range = 35},-- серый металлик
}

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MAM_ESP"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton")
btn.Parent = gui
btn.Size = UDim2.new(0, 200, 0, 45)
btn.Position = UDim2.new(0, 20, 0, 20)
btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
btn.Text = "ORE ESP: OFF"
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
status.Position = UDim2.new(0, 20, 0, 70)
status.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Font = Enum.Font.SourceSans
status.TextSize = 11
status.Text = "Ready"
status.BorderSizePixel = 0
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 5)

-- Поиск руды в террейне по цвету
local function scanTerrain()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return 0 end
    
    local char = player.Character
    if not char then return 0 end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return 0 end
    
    local center = root.Position
    local radius = 80
    local step = 3  -- шаг сканирования (меньше = точнее, но медленнее)
    local found = 0
    local maxMarkers = 300
    
    -- Удаляем старые маркеры
    for _, m in ipairs(markers) do
        pcall(function() m:Destroy() end)
    end
    markers = {}
    
    stopRequested = false
    
    for x = center.X - radius, center.X + radius, step do
        if stopRequested then break end
        for y = math.max(0, center.Y - radius), center.Y + radius, step do
            if stopRequested then break end
            for z = center.Z - radius, center.Z + radius, step do
                if stopRequested then break end
                if found >= maxMarkers then break end
                
                local pos = Vector3.new(x, y, z)
                local mat, occ = terrain:GetMaterialAtPosition(pos)
                
                if occ > 0.5 and mat ~= Enum.Material.Air then
                    local col = terrain:GetTerrainColorAtPosition(pos)
                    if col then
                        local r = math.floor(col.R * 255)
                        local g = math.floor(col.G * 255)
                        local b = math.floor(col.B * 255)
                        
                        for _, ore in ipairs(ores) do
                            local dr = math.abs(r - ore.r)
                            local dg = math.abs(g - ore.g)
                            local db = math.abs(b - ore.b)
                            
                            if dr <= ore.range and dg <= ore.range and db <= ore.range then
                                -- Проверяем, нет ли рядом маркера (минимальная дистанция 4)
                                local tooClose = false
                                for _, m in ipairs(markers) do
                                    if (m.Position - pos).Magnitude < 4 then
                                        tooClose = true
                                        break
                                    end
                                end
                                
                                if not tooClose then
                                    local marker = Instance.new("Part")
                                    marker.Name = "OreMarker"
                                    marker.Size = Vector3.new(2, 2, 2)
                                    marker.Position = pos
                                    marker.Anchored = true
                                    marker.CanCollide = false
                                    marker.Transparency = 0.5
                                    marker.Color = Color3.fromRGB(r, g, b)
                                    marker.Material = Enum.Material.Neon
                                    marker.Parent = workspace
                                    
                                    -- Highlight для видимости через стены
                                    local hl = Instance.new("Highlight")
                                    hl.FillColor = marker.Color
                                    hl.FillTransparency = 0.7
                                    hl.OutlineColor = marker.Color
                                    hl.OutlineTransparency = 0
                                    hl.Adornee = marker
                                    hl.Parent = marker
                                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    
                                    table.insert(markers, marker)
                                    found = found + 1
                                end
                                break  -- одна руда на точку
                            end
                        end
                    end
                end
            end
        end
        
        -- Обновляем статус каждые 10 строк X
        if math.fmod(x - center.X, step * 10) == 0 then
            status.Text = string.format("Scanning... %d found", found)
            runService.RenderStepped:Wait()
        end
    end
    
    return found
end

-- Переключение
local function toggle()
    enabled = not enabled
    if enabled then
        btn.Text = "ORE ESP: SCANNING..."
        btn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        status.Text = "Starting scan..."
        
        task.spawn(function()
            local count = scanTerrain()
            btn.Text = string.format("ORE ESP: ON (%d)", count)
            btn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
            status.Text = string.format("Found %d ore blocks", count)
        end)
    else
        stopRequested = true
        btn.Text = "ORE ESP: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        status.Text = "Ready"
        for _, m in ipairs(markers) do
            pcall(function() m:Destroy() end)
        end
        markers = {}
    end
end

btn.MouseButton1Click:Connect(toggle)

-- Бинд F6
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        toggle()
    end
end)

-- При возрождении перезапустить если активно
player.CharacterAdded:Connect(function()
    if enabled then
        stopRequested = true
        task.wait(0.5)
        stopRequested = false
        task.spawn(function()
            local count = scanTerrain()
            btn.Text = string.format("ORE ESP: ON (%d)", count)
            status.Text = string.format("Found %d ore blocks", count)
        end)
    end
end)

shared.__mamESP = {}
shared.__mamMarkers = markers
