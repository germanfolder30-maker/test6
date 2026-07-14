--// Object Scanner - Узнай названия всех объектов вокруг
local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")

local enabled = false
local connections = {}

-- Очистка старого
if shared.__objScanner then
    for _, v in ipairs(shared.__objScanner) do
        pcall(function() v:Disconnect() end)
    end
end
if game.CoreGui:FindFirstChild("ObjScannerGUI") then
    game.CoreGui.ObjScannerGUI:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ObjScannerGUI"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

-- Кнопка сканирования
local scanBtn = Instance.new("TextButton")
scanBtn.Parent = gui
scanBtn.Size = UDim2.new(0, 200, 0, 45)
scanBtn.Position = UDim2.new(0, 15, 0, 70)
scanBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
scanBtn.Text = "SCAN OBJECTS"
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Font = Enum.Font.SourceSansBold
scanBtn.TextSize = 15
scanBtn.BorderSizePixel = 0
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 8)

-- Окно вывода
local output = Instance.new("TextBox")
output.Parent = gui
output.Size = UDim2.new(0, 350, 0, 300)
output.Position = UDim2.new(0, 15, 0, 125)
output.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
output.TextColor3 = Color3.fromRGB(255, 255, 255)
output.Font = Enum.Font.SourceSans
output.TextSize = 11
output.Text = "Нажми SCAN для поиска объектов рядом..."
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextXAlignment = Enum.TextXAlignment.Left
output.MultiLine = true
output.ClearTextOnFocus = false
output.BorderSizePixel = 0
Instance.new("UICorner", output).CornerRadius = UDim.new(0, 8)

-- Кнопка очистки
local clearBtn = Instance.new("TextButton")
clearBtn.Parent = gui
clearBtn.Size = UDim2.new(0, 100, 0, 30)
clearBtn.Position = UDim2.new(0, 230, 0, 70)
clearBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
clearBtn.Text = "CLEAR"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Font = Enum.Font.SourceSansBold
clearBtn.TextSize = 12
clearBtn.BorderSizePixel = 0
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 6)

-- Функция форматированного вывода
local function printInfo(text)
    local current = output.Text
    output.Text = current .. "\n" .. text
    output.CursorPosition = #output.Text
end

-- Сканирование объектов рядом с игроком
local function scanNearby()
    output.Text = "СКАНИРОВАНИЕ...\n"
    
    local char = player.Character
    if not char then
        printInfo("Ошибка: персонаж не найден!")
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then
        printInfo("Ошибка: HumanoidRootPart не найден!")
        return
    end
    
    local playerPos = root.Position
    local radius = 100 -- радиус сканирования
    local found = {}
    
    -- Функция поиска
    local function search(parent, depth, path)
        if depth > 30 then return end
        
        for _, child in ipairs(parent:GetChildren()) do
            local pos = nil
            
            -- Пробуем получить позицию
            if child:IsA("BasePart") then
                pos = child.Position
            elseif child:FindFirstChild("Position") then
                pos = child.Position
            elseif child:IsA("Model") and child:FindFirstChild("HumanoidRootPart") then
                pos = child.HumanoidRootPart.Position
            else
                -- Для моделей без явной позиции
                local primary = child:FindFirstChildWhichIsA("BasePart")
                if primary then
                    pos = primary.Position
                end
            end
            
            -- Проверяем расстояние
            if pos then
                local dist = (pos - playerPos).Magnitude
                if dist <= radius then
                    -- Собираем инфу
                    local info = {
                        Name = child.Name,
                        Class = child.ClassName,
                        Distance = math.floor(dist),
                        Parent = parent.Name,
                        Material = child:IsA("BasePart") and tostring(child.Material) or "N/A",
                        Color = child:IsA("BasePart") and tostring(child.BrickColor) or "N/A",
                        Size = child:IsA("BasePart") and ("%.1f x %.1f x %.1f"):format(child.Size.X, child.Size.Y, child.Size.Z) or "N/A"
                    }
                    table.insert(found, info)
                end
            end
            
            -- Рекурсивный поиск
            if #child:GetChildren() > 0 then
                search(child, depth + 1, path .. "/" .. child.Name)
            end
        end
    end
    
    -- Запускаем поиск
    search(workspace, 0, "")
    
    -- Сортируем по расстоянию
    table.sort(found, function(a, b) return a.Distance < b.Distance end)
    
    -- Выводим результат
    printInfo("НАЙДЕНО ОБЪЕКТОВ: " .. #found)
    printInfo("================================")
    
    -- Группируем по имени
    local nameCount = {}
    for _, obj in ipairs(found) do
        local name = obj.Name
        if not nameCount[name] then
            nameCount[name] = {count = 0, examples = {}}
        end
        nameCount[name].count = nameCount[name].count + 1
        if #nameCount[name].examples < 3 then
            table.insert(nameCount[name].examples, obj)
        end
    end
    
    -- Выводим сгруппированную статистику
    for name, data in pairs(nameCount) do
        printInfo(string.format("[%s] x%d", name, data.count))
        for _, obj in ipairs(data.examples) do
            printInfo(string.format("  Class: %s | Dist: %dm | Parent: %s", 
                obj.Class, obj.Distance, obj.Parent))
            if obj.Material ~= "N/A" then
                printInfo(string.format("  Material: %s | Size: %s", obj.Material, obj.Size))
            end
        end
        printInfo("")
    end
end

-- Кнопки
scanBtn.MouseButton1Click:Connect(scanNearby)
clearBtn.MouseButton1Click:Connect(function()
    output.Text = ""
end)

-- Горячая клавиша F8
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F8 then
        scanNearby()
    end
end)
