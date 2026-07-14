--// Mine a Mountain – Terrain Color Ore ESP (Optimized + Pipette)
local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local enabled = false
local scanning = false
local markers = {}
local stopRequested = false
local connections = {}

-- Список цветов для поиска (можно пополнять пипеткой)
local targetColors = {
    -- формат: {r, g, b, range, name}
    -- примерные цвета руд (по описаниям)
    {r = 35, g = 35, b = 35, range = 25, name = "Gunpowered / Dreadstone"},
    {r = 90, g = 195, b = 250, range = 45, name = "Skyglass / Cryostone"},
    {r = 75, g = 250, b = 75, range = 45, name = "Venomite"},
    {r = 250, g = 115, b = 35, range = 45, name = "Cinderforge"},
    {r = 195, g = 115, b = 215, range = 45, name = "Chronoshard"},
    {r = 135, g = 135, b = 145, range = 35, name = "Stormsteel"},
    -- добавь сюда свои цвета после пипетки
}

-- GUI
if game.CoreGui:FindFirstChild("TerrainOreESP") then
    game.CoreGui.TerrainOreESP:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "TerrainOreESP"
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
status.Text = "Ready | F5 = pipette"
status.BorderSizePixel = 0
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 5)

-- Очистка маркеров
local function clearMarkers()
    for _, m in ipairs(markers) do
        pcall(function() m:Destroy() end)
    end
    markers = {}
end

-- Создание маркера
local function createMarker(pos, color)
    local marker = Instance.new("Part")
    marker.Name = "OreMarker"
    marker.Size = Vector3.new(2, 2, 2)
    marker.Position = pos
    marker.Anchored = true
    marker.CanCollide = false
    marker.Transparency = 0.5
    marker.Color = color
    marker.Material = Enum.Material.Neon
    marker.Parent = workspace

    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.FillTransparency = 0.6
    hl.OutlineColor = color
    hl.OutlineTransparency = 0
    hl.Adornee = marker
    hl.Parent = marker
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = true

    table.insert(markers, marker)
end

-- Сканирование террейна
local function scanTerrain()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return 0 end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return 0 end
    local root = char.HumanoidRootPart
    local center = root.Position
    local radius = 50   -- радиус сканирования
    local step = 4      -- шаг (компромисс скорость/точность)
    local found = 0
    local maxMarkers = 300
    stopRequested = false
    clearMarkers()

    for x = center.X - radius, center.X + radius, step do
        if stopRequested then break end
        for y = math.max(0, center.Y - radius), center.Y + radius, step do
            if stopRequested then break end
            for z = center.Z - radius, center.Z + radius, step do
                if stopRequested or found >= maxMarkers then break end
                local pos = Vector3.new(x, y, z)
                local mat, occ = terrain:GetMaterialAtPosition(pos)
                if occ > 0.5 and mat ~= Enum.Material.Air then
                    local col = terrain:GetTerrainColorAtPosition(pos)
                    if col then
                        local r = math.floor(col.R * 255)
                        local g = math.floor(col.G * 255)
                        local b = math.floor(col.B * 255)
                        for _, tc in ipairs(targetColors) do
                            if math.abs(r - tc.r) <= tc.range and
                               math.abs(g - tc.g) <= tc.range and
                               math.abs(b - tc.b) <= tc.range then
                                -- проверка минимальной дистанции
                                local tooClose = false
                                for _, m in ipairs(markers) do
                                    if (m.Position - pos).Magnitude < 4 then
                                        tooClose = true
                                        break
                                    end
                                end
                                if not tooClose then
                                    createMarker(pos, Color3.fromRGB(r, g, b))
                                    found = found + 1
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
        if math.fmod(x - center.X, step * 5) == 0 then
            status.Text = string.format("Scanning... %d ores", found)
            runService.RenderStepped:Wait() -- даём интерфейсу обновиться
        end
    end
    return found
end

-- Включение/выключение
local function toggle()
    if scanning then
        stopRequested = true
        status.Text = "Stopping..."
        return
    end
    if enabled then
        -- выключить
        enabled = false
        stopRequested = true
        btn.Text = "ORE ESP: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        status.Text = "Ready | F5 = pipette"
        task.wait(0.2)
        clearMarkers()
    else
        -- включить
        enabled = true
        scanning = true
        btn.Text = "ORE ESP: SCANNING..."
        btn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        status.Text = "Starting scan..."
        task.spawn(function()
            local count = scanTerrain()
            scanning = false
            if enabled then
                btn.Text = string.format("ORE ESP: ON (%d)", count)
                btn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
                status.Text = string.format("Found %d ore blocks", count)
            else
                btn.Text = "ORE ESP: OFF"
                btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                status.Text = "Ready | F5 = pipette"
                clearMarkers()
            end
        end)
    end
end

btn.MouseButton1Click:Connect(toggle)

-- Пипетка: запоминает цвет террейна под мышью
local function pipette()
    local mouse = player:GetMouse()
    local targetPos = mouse.Hit.p
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    local mat, occ = terrain:GetMaterialAtPosition(targetPos)
    if occ > 0 then
        local col = terrain:GetTerrainColorAtPosition(targetPos)
        if col then
            local r = math.floor(col.R * 255)
            local g = math.floor(col.G * 255)
            local b = math.floor(col.B * 255)
            -- добавляем новый цвет в список
            table.insert(targetColors, {r = r, g = g, b = b, range = 30, name = "Custom"})
            status.Text = string.format("Added RGB(%d,%d,%d)", r, g, b)
        else
            status.Text = "No color data"
        end
    else
        status.Text = "No terrain at cursor"
    end
end

-- Горячие клавиши
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        toggle()
    elseif input.KeyCode == Enum.KeyCode.F5 then
        pipette()
    end
end)

-- Перезапуск при возрождении
player.CharacterAdded:Connect(function()
    if enabled and not scanning then
        -- если был включен, перезапускаем сканирование
        scanning = true
        task.spawn(function()
            local count = scanTerrain()
            scanning = false
            if enabled then
                btn.Text = string.format("ORE ESP: ON (%d)", count)
                status.Text = string.format("Found %d ore blocks", count)
            end
        end)
    end
end)

shared.__terrainOreESP = connections
