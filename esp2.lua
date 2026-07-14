--// Object Scanner with List + Highlight + Teleport
local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local foundObjects = {}
local selectedIndex = 1
local currentHighlight = nil
local connections = {}

-- Очистка старого
if shared.__advScanner then
    for _, v in ipairs(shared.__advScanner) do
        pcall(function() v:Disconnect() end)
    end
end
if game.CoreGui:FindFirstChild("AdvScannerGUI") then
    game.CoreGui.AdvScannerGUI:Destroy()
end
if currentHighlight then
    pcall(function() currentHighlight:Destroy() end)
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AdvScannerGUI"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

-- Фрейм для списка
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Parent = gui
frame.Size = UDim2.new(0, 380, 0, 350)
frame.Position = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Visible = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Заголовок
local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = "OBJECT SCANNER"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.BorderSizePixel = 0
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

-- Кнопка сканирования
local scanBtn = Instance.new("TextButton")
scanBtn.Parent = frame
scanBtn.Size = UDim2.new(0, 170, 0, 30)
scanBtn.Position = UDim2.new(0, 10, 0, 35)
scanBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
scanBtn.Text = "SCAN (F8)"
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Font = Enum.Font.SourceSansBold
scanBtn.TextSize = 12
scanBtn.BorderSizePixel = 0
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка очистки
local clearBtn = Instance.new("TextButton")
clearBtn.Parent = frame
clearBtn.Size = UDim2.new(0, 100, 0, 30)
clearBtn.Position = UDim2.new(0, 190, 0, 35)
clearBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
clearBtn.Text = "CLEAR"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Font = Enum.Font.SourceSansBold
clearBtn.TextSize = 12
clearBtn.BorderSizePixel = 0
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 6)

-- Поле с информацией о выбранном объекте
local infoLabel = Instance.new("TextLabel")
infoLabel.Parent = frame
infoLabel.Size = UDim2.new(1, -20, 0, 40)
infoLabel.Position = UDim2.new(0, 10, 0, 70)
infoLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.Font = Enum.Font.SourceSans
infoLabel.TextSize = 11
infoLabel.Text = "Selected: none"
infoLabel.TextWrapped = true
infoLabel.BorderSizePixel = 0
Instance.new("UICorner", infoLabel).CornerRadius = UDim.new(0, 5)

-- Список объектов (прокручиваемый)
local listFrame = Instance.new("ScrollingFrame")
listFrame.Parent = frame
listFrame.Size = UDim2.new(1, -20, 0, 160)
listFrame.Position = UDim2.new(0, 10, 0, 115)
listFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 8
listFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 5)

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = listFrame
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 2)

-- Кнопка подсветки
local highlightBtn = Instance.new("TextButton")
highlightBtn.Parent = frame
highlightBtn.Size = UDim2.new(0, 170, 0, 30)
highlightBtn.Position = UDim2.new(0, 10, 0, 280)
highlightBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
highlightBtn.Text = "HIGHLIGHT (F9)"
highlightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
highlightBtn.Font = Enum.Font.SourceSansBold
highlightBtn.TextSize = 12
highlightBtn.BorderSizePixel = 0
Instance.new("UICorner", highlightBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка телепорта
local teleportBtn = Instance.new("TextButton")
teleportBtn.Parent = frame
teleportBtn.Size = UDim2.new(0, 170, 0, 30)
teleportBtn.Position = UDim2.new(0, 190, 0, 280)
teleportBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
teleportBtn.Text = "TELEPORT (F10)"
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportBtn.Font = Enum.Font.SourceSansBold
teleportBtn.TextSize = 12
teleportBtn.BorderSizePixel = 0
Instance.new("UICorner", teleportBtn).CornerRadius = UDim.new(0, 6)

-- Статус
local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = frame
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 320)
statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 10
statusLabel.Text = "Scroll: list | Click: select | F9: highlight | F10: teleport"
statusLabel.BorderSizePixel = 0
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 5)

-- Функция создания кнопки для объекта в списке
local function createObjectButton(obj, index)
    local btn = Instance.new("TextButton")
    btn.Name = "ObjBtn_" .. index
    btn.Parent = listFrame
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = string.format("[%d] %s (%dm)", index, obj.Name, obj.Distance)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    
    -- Клик по объекту в списке
    btn.MouseButton1Click:Connect(function()
        selectedIndex = index
        updateSelection()
    end)
    
    return btn
end

-- Обновление выделения
function updateSelection()
    -- Убираем старую подсветку
    if currentHighlight then
        pcall(function() currentHighlight:Destroy() end)
        currentHighlight = nil
    end
    
    if #foundObjects == 0 then return end
    
    local obj = foundObjects[selectedIndex]
    if not obj then return end
    
    -- Обновляем инфо
    infoLabel.Text = string.format("Selected: [%d/%d] %s | Class: %s | Dist: %dm | Parent: %s",
        selectedIndex, #foundObjects, obj.Name, obj.ClassName, obj.Distance, obj.ParentName)
    
    -- Обновляем цвета кнопок
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            if child.Name == "ObjBtn_" .. selectedIndex then
                child.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
            else
                child.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            end
        end
    end
    
    -- Подсвечиваем выбранный объект
    highlightObject(obj)
    
    -- Обновляем размер канваса
    listFrame.CanvasSize = UDim2.new(0, 0, 0, #foundObjects * 27)
end

-- Подсветка объекта
function highlightObject(obj)
    if currentHighlight then
        pcall(function() currentHighlight:Destroy() end)
        currentHighlight = nil
    end
    
    if not obj or not obj.RealObject then return end
    
    local realObj = obj.RealObject
    if not realObj or not realObj:IsA("BasePart") then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 255, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 170, 0)
    highlight.OutlineTransparency = 0
    highlight.Adornee = realObj
    highlight.Parent = realObj
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    
    currentHighlight = highlight
end

-- Сканирование
local function scanNearby()
    -- Очищаем старый список
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    foundObjects = {}
    selectedIndex = 1
    
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local playerPos = root.Position
    local radius = 150
    
    statusLabel.Text = "Scanning..."
    
    local function search(parent, depth)
        if depth > 30 then return end
        
        for _, child in ipairs(parent:GetChildren()) do
            local pos = nil
            
            if child:IsA("BasePart") then
                pos = child.Position
            elseif child:IsA("Model") then
                local primary = child:FindFirstChildWhichIsA("BasePart")
                if primary then pos = primary.Position end
            end
            
            if pos and child.Name ~= "Terrain" and child.Name ~= "Base" then
                local dist = (pos - playerPos).Magnitude
                if dist <= radius and dist > 0 then
                    local info = {
                        Name = child.Name,
                        ClassName = child.ClassName,
                        Distance = math.floor(dist),
                        ParentName = parent.Name,
                        RealObject = child
                    }
                    table.insert(foundObjects, info)
                end
            end
            
            if #child:GetChildren() > 0 and not child:IsA("Player") then
                search(child, depth + 1)
            end
        end
    end
    
    search(workspace, 0)
    
    -- Сортируем по расстоянию
    table.sort(foundObjects, function(a, b) return a.Distance < b.Distance end)
    
    -- Создаём кнопки списка (максимум 50 для производительности)
    local maxShow = math.min(#foundObjects, 50)
    for i = 1, maxShow do
        createObjectButton(foundObjects[i], i)
    end
    
    if #foundObjects > 50 then
        statusLabel.Text = string.format("Found: %d objects (showing first 50). Use scroll.", #foundObjects)
    else
        statusLabel.Text = string.format("Found: %d objects. Click to select.", #foundObjects)
    end
    
    updateSelection()
end

-- Прокрутка колёсиком мыши
listFrame.MouseWheelForward:Connect(function()
    if #foundObjects == 0 then return end
    selectedIndex = math.max(1, selectedIndex - 1)
    updateSelection()
end)

listFrame.MouseWheelBackward:Connect(function()
    if #foundObjects == 0 then return end
    selectedIndex = math.min(#foundObjects, selectedIndex + 1)
    updateSelection()
end)

-- Кнопки
scanBtn.MouseButton1Click:Connect(scanNearby)
clearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    foundObjects = {}
    selectedIndex = 1
    if currentHighlight then
        pcall(function() currentHighlight:Destroy() end)
        currentHighlight = nil
    end
    infoLabel.Text = "Selected: none"
    statusLabel.Text = "Cleared."
end)

highlightBtn.MouseButton1Click:Connect(function()
    if #foundObjects == 0 then return end
    highlightObject(foundObjects[selectedIndex])
    statusLabel.Text = "Highlighted: " .. foundObjects[selectedIndex].Name
end)

teleportBtn.MouseButton1Click:Connect(function()
    if #foundObjects == 0 then return end
    local obj = foundObjects[selectedIndex]
    if obj and obj.RealObject and obj.RealObject:IsA("BasePart") then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = obj.RealObject.CFrame + Vector3.new(0, 5, 0)
            statusLabel.Text = "Teleported to: " .. obj.Name
        end
    end
end)

-- Горячие клавиши
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F8 then
        scanNearby()
    elseif input.KeyCode == Enum.KeyCode.F9 then
        if #foundObjects > 0 then
            highlightObject(foundObjects[selectedIndex])
        end
    elseif input.KeyCode == Enum.KeyCode.F10 then
        if #foundObjects > 0 then
            local obj = foundObjects[selectedIndex]
            if obj and obj.RealObject and obj.RealObject:IsA("BasePart") then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = obj.RealObject.CFrame + Vector3.new(0, 5, 0)
                end
            end
        end
    end
end)
