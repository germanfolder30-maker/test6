--// Mine a Mountain – Working Ore ESP + Color List
local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local enabled = false
local scanning = false
local markers = {}
local stopRequested = false
local targetColors = {}  -- список {r, g, b, range, name}

-- Добавляем несколько типичных цветов руд (можно расширить пипеткой)
targetColors = {
    {r = 35, g = 35, b = 35, range = 25, name = "Dark Stone"},
    {r = 90, g = 195, b = 250, range = 45, name = "Sky Blue"},
    {r = 75, g = 250, b = 75, range = 45, name = "Venomite"},
    {r = 250, g = 115, b = 35, range = 45, name = "Cinderforge"},
    {r = 195, g = 115, b = 215, range = 45, name = "Chronoshard"},
    {r = 135, g = 135, b = 145, range = 35, name = "Stormsteel"},
}

-- Удаляем старый GUI
if game.CoreGui:FindFirstChild("OreESP_GUI") then
    game.CoreGui.OreESP_GUI:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "OreESP_GUI"
gui.Parent = game.CoreGui

-- Кнопка ESP
local btnESP = Instance.new("TextButton")
btnESP.Parent = gui
btnESP.Size = UDim2.new(0, 180, 0, 40)
btnESP.Position = UDim2.new(0, 20, 0, 20)
btnESP.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
btnESP.Text = "ESP: OFF"
btnESP.TextColor3 = Color3.fromRGB(255, 255, 255)
btnESP.Font = Enum.Font.SourceSansBold
btnESP.TextSize = 14
btnESP.BorderSizePixel = 0
btnESP.AutoButtonColor = false
Instance.new("UICorner", btnESP).CornerRadius = UDim.new(0, 8)

-- Кнопка Scan All Colors
local btnScanColors = Instance.new("TextButton")
btnScanColors.Parent = gui
btnScanColors.Size = UDim2.new(0, 180, 0, 40)
btnScanColors.Position = UDim2.new(0, 20, 0, 70)
btnScanColors.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
btnScanColors.Text = "Scan All Colors"
btnScanColors.TextColor3 = Color3.fromRGB(255, 255, 255)
btnScanColors.Font = Enum.Font.SourceSansBold
btnScanColors.TextSize = 14
btnScanColors.BorderSizePixel = 0
btnScanColors.AutoButtonColor = false
Instance.new("UICorner", btnScanColors).CornerRadius = UDim.new(0, 8)

-- Окно вывода (для пипетки и списка цветов)
local output = Instance.new("TextBox")
output.Parent = gui
output.Size = UDim2.new(0, 350, 0, 200)
output.Position = UDim2.new(0, 20, 0, 120)
output.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
output.TextColor3 = Color3.fromRGB(255, 255, 255)
output.Font = Enum.Font.SourceSans
output.TextSize = 12
output.Text = "F5 - pipette (color under crosshair)\nF6 - toggle ESP\nScan All Colors - list unique colors"
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextXAlignment = Enum.TextXAlignment.Left
output.MultiLine = true
output.ClearTextOnFocus = false
output.BorderSizePixel = 0
Instance.new("UICorner", output).CornerRadius = UDim.new(0, 8)

-- Очистка маркеров
local function clearMarkers()
    for _, m in ipairs(markers) do
        pcall(function() m:Destroy() end)
    end
    markers = {}
end

-- Создание маркера
local function createMarker(pos, color, name)
    local marker = Instance.new("Part")
    marker.Name = "OreMarker_" .. (name or "?")
    marker.Size = Vector3.new(1.5, 1.5, 1.5)
    marker.Position = pos
    marker.Anchored = true
    marker.CanCollide = false
    marker.Transparency = 0.4
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

-- Пипетка (считывает цвет террейна под прицелом)
local function pipette()
    local cam = workspace.CurrentCamera
    -- луч из центра экрана
    local ray = cam:ScreenPointToRay(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    -- ищем точку на террейне на расстоянии до 200
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace:FindFirstChildOfClass("Terrain")}
    local result = workspace:Raycast(ray.Origin, ray.Direction * 200, params)
    if result and result.Instance:IsA("Terrain") then
        local pos = result.Position
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        local mat, occ = terrain:GetMaterialAtPosition(pos)
        if occ > 0 then
            local col = terrain:GetTerrainColorAtPosition(pos)
            if col then
                local r = math.floor(col.R * 255)
                local g = math.floor(col.G * 255)
                local b = math.floor(col.B * 255)
                -- добавляем в список, если такого ещё нет
                local already = false
                for _, tc in ipairs(targetColors) do
                    if tc.r == r and tc.g == g and tc.b == b then already = true; break end
                end
                if not already then
                    table.insert(targetColors, {r = r, g = g, b = b, range = 30, name = "Custom"})
                    output.Text = string.format("Added RGB(%d,%d,%d)\n%s", r, g, b, output.Text)
                else
                    output.Text = string.format("Color RGB(%d,%d,%d) already in list.\n%s", r, g, b, output.Text)
                end
                return
            end
        end
    end
    output.Text = "No terrain hit (look at mountain)\n" .. output.Text
end

-- Сканирование с поиском определённых цветов
local function scanForOres()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return 0 end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return 0 end
    local root = char.HumanoidRootPart
    local center = root.Position
    local radius = 40
    local step = 5
    local found = 0
    local maxMarkers = 200

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
                                local tooClose = false
                                for _, m in ipairs(markers) do
                                    if (m.Position - pos).Magnitude < 4 then
                                        tooClose = true; break
                                    end
                                end
                                if not tooClose then
                                    createMarker(pos, Color3.fromRGB(r,g,b), tc.name)
                                    found = found + 1
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
        -- отдача управления, чтобы не вешать поток
        runService.Heartbeat:Wait()
    end
    return found
end

-- Сканирование всех уникальных цветов (без маркеров)
local function scanAllColors()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local center = root.Position
    local radius = 30
    local step = 6
    local colors = {}  -- ключ "r,g,b", значение count

    for x = center.X - radius, center.X + radius, step do
        for y = math.max(0, center.Y - radius), center.Y + radius, step do
            for z = center.Z - radius, center.Z + radius, step do
                local pos = Vector3.new(x, y, z)
                local mat, occ = terrain:GetMaterialAtPosition(pos)
                if occ > 0.5 and mat ~= Enum.Material.Air then
                    local col = terrain:GetTerrainColorAtPosition(pos)
                    if col then
                        local r = math.floor(col.R * 255)
                        local g = math.floor(col.G * 255)
                        local b = math.floor(col.B * 255)
                        local key = string.format("%d,%d,%d", r, g, b)
                        colors[key] = (colors[key] or 0) + 1
                    end
                end
            end
        end
        runService.Heartbeat:Wait()
    end

    -- вывод в output
    local lines = {"=== Unique Terrain Colors ==="}
    for key, count in pairs(colors) do
        table.insert(lines, string.format("RGB(%s) x%d", key, count))
    end
    table.sort(lines, function(a,b) return a < b end)
    output.Text = table.concat(lines, "\n")
end

-- Логика включения/выключения ESP
local function stopESP()
    stopRequested = true
    if scanning then
        -- подождём завершения потока
        repeat task.wait(0.1) until not scanning
    end
    enabled = false
    btnESP.Text = "ESP: OFF"
    btnESP.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    clearMarkers()
    output.Text = "ESP stopped.\n" .. output.Text
end

local function startESP()
    if scanning then return end
    enabled = true
    scanning = true
    btnESP.Text = "ESP: SCAN..."
    btnESP.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
    output.Text = "Scanning...\n" .. output.Text

    task.spawn(function()
        local count = scanForOres()
        scanning = false
        if enabled and not stopRequested then
            btnESP.Text = string.format("ESP: ON (%d)", count)
            btnESP.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
            output.Text = string.format("Found %d ore blocks.\n%s", count, output.Text)
        else
            stopESP()
        end
    end)
end

local function toggleESP()
    if scanning then
        stopESP()
    elseif enabled then
        stopESP()
    else
        startESP()
    end
end

btnESP.MouseButton1Click:Connect(toggleESP)
btnScanColors.MouseButton1Click:Connect(function()
    output.Text = "Scanning colors...\n"
    task.spawn(scanAllColors)
end)

-- Горячие клавиши
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F5 then
        pipette()
    elseif input.KeyCode == Enum.KeyCode.F6 then
        toggleESP()
    end
end)

-- Сброс при возрождении
player.CharacterAdded:Connect(function()
    if enabled and not scanning then
        startESP()
    end
end)
