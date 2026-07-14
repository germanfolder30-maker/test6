--// Mine a Mountain – Color Ore ESP (Fast & Stoppable)
local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local enabled = false
local markers = {}
local stopRequested = false
local scanning = false

-- Очистка старых данных
if shared.__mamESP2 then
    for _, v in ipairs(shared.__mamESP2) do
        pcall(function() v:Disconnect() end)
    end
end
if shared.__mamMarkers2 then
    for _, v in pairs(shared.__mamMarkers2) do
        pcall(function() v:Destroy() end)
    end
end
if game.CoreGui:FindFirstChild("MAM_ESP2") then
    game.CoreGui.MAM_ESP2:Destroy()
end

-- Цвета руд (твои описания + вики)
local ores = {
    {name = "Gunpowered Stone", r = 35, g = 35, b = 35, range = 25},
    {name = "Dreadstone",       r = 30, g = 30, b = 30, range = 20},
    {name = "Skyglass",         r = 90, g = 195, b = 250, range = 45},
    {name = "Cryostone",        r = 145, g = 215, b = 250, range = 40},
    {name = "Chronoshard",      r = 195, g = 115, b = 215, range = 45},
    {name = "Venomite",         r = 75, g = 250, b = 75, range = 45},
    {name = "Cinderforge Plate",r = 250, g = 115, b = 35, range = 45},
    {name = "Stormsteel",       r = 135, g = 135, b = 145, range = 35},
}

-- Интерфейс
local gui = Instance.new("ScreenGui")
gui.Name = "MAM_ESP2"
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

-- Очистка всех маркеров
local function clearMarkers()
    for _, m in ipairs(markers) do
        pcall(function() m:Destroy() end)
    end
    markers = {}
end

-- Быстрое сканирование (радиус 60, шаг 4)
local function scanTerrain()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return 0 end
    local char = player.Character
    if not char then return 0 end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return 0 end

    local center = root.Position
    local radius = 60
    local step = 4
    local found = 0
    local maxMarkers = 300
    stopRequested = false

    clearMarkers()

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
                                -- минимальное расстояние между маркерами
                                local tooClose = false
                                for _, m in ipairs(markers) do
                                    if (m.Position - pos).Magnitude < 5 then
                                        tooClose = true
                                        break
                                    end
                                end
                                if not tooClose then
                                    local marker = Instance.new("Part")
                                    marker.Name = "OreMarker"
                                    marker.Size = Vector3.new(step, step, step)
                                    marker.Position = pos
                                    marker.Anchored = true
                                    marker.CanCollide = false
                                    marker.Transparency = 0.5
                                    marker.Color = Color3.fromRGB(r, g, b)
                                    marker.Material = Enum.Material.Neon
                                    marker.Parent = workspace

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
                                break
                            end
                        end
                    end
                end
            end
        end
        -- обновление прогресса (без задержки, просто для информации)
        if math.fmod(x - center.X, step * 10) == 0 then
            status.Text = string.format("Scanning... %d found", found)
        end
    end

    return found
end

-- Переключение
local function toggle()
    if scanning then
        -- если уже идёт сканирование, останавливаем
        stopRequested = true
        status.Text = "Stopping..."
        return
    end

    if enabled then
        -- выключение ESP
        enabled = false
        stopRequested = true
        btn.Text = "ORE ESP: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        status.Text = "Ready"
        -- подождём завершения потока сканирования и очистим
        task.spawn(function()
            task.wait(0.2)
            clearMarkers()
        end)
    else
        -- включение ESP
        enabled = true
        scanning = true
        btn.Text = "ORE ESP: SCANNING..."
        btn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        status.Text = "Starting..."

        task.spawn(function()
            local count = scanTerrain()
            scanning = false
            if enabled then
                btn.Text = string.format("ORE ESP: ON (%d)", count)
                btn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
                status.Text = string.format("Found %d ore blocks", count)
            else
                -- если выключили во время сканирования
                btn.Text = "ORE ESP: OFF"
                btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                status.Text = "Ready"
                clearMarkers()
            end
        end)
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

-- При возрождении перезапустить, если было включено
player.CharacterAdded:Connect(function()
    if enabled then
        -- остановим текущее, запустим заново после спавна
        stopRequested = true
        scanning = false
        clearMarkers()
        task.wait(0.5)
        toggle()  -- включит заново
    end
end)

shared.__mamESP2 = {}
shared.__mamMarkers2 = markers
