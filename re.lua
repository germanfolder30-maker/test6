--// Free Shop Prices Script
local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local enabled = false
local connection = nil
local originalPrices = {} -- для восстановления

-- Очистка старого
if shared.__freeShop then
    for _, v in ipairs(shared.__freeShop) do
        pcall(function() v:Disconnect() end)
    end
end
if game.CoreGui:FindFirstChild("FreeShopGUI") then
    game.CoreGui.FreeShopGUI:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "FreeShopGUI"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton")
btn.Parent = gui
btn.Size = UDim2.new(0, 200, 0, 45)
btn.Position = UDim2.new(0, 20, 0, 20)
btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
btn.Text = "FREE SHOP: OFF"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 14
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
status.Text = "Ready | F8 = toggle"
status.BorderSizePixel = 0
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 5)

-- Функция поиска и замены цен
local function setPricesToZero()
    local changed = 0
    
    -- Поиск по PlayerGui (UI магазина)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, obj in ipairs(playerGui:GetDescendants()) do
            -- Ищем текстовые метки с ценами
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local text = obj.Text
                -- Сохраняем оригинал если ещё не сохранили
                if not originalPrices[obj] then
                    originalPrices[obj] = text
                end
                -- Проверяем, содержит ли текст цену (цифры и возможно знак валюты)
                if text and string.find(text, "%d") then
                    -- Заменяем только если текст короткий (типичная цена)
                    if #text <= 20 then
                        -- Меняем любые цифры на 0
                        local newText = string.gsub(text, "%d+,?%d*", "0")
                        obj.Text = newText
                        changed = changed + 1
                    end
                end
            end
            
            -- Ищем IntValue/NumberValue с ценами
            if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                local name = string.lower(obj.Name)
                if string.find(name, "price") or string.find(name, "cost") or 
                   string.find(name, "value") or string.find(name, "amount") then
                    if not originalPrices[obj] then
                        originalPrices[obj] = obj.Value
                    end
                    obj.Value = 0
                    changed = changed + 1
                end
            end
        end
    end
    
    -- Поиск в CoreGui (если магазин там)
    for _, obj in ipairs(game.CoreGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local text = obj.Text
            if not originalPrices[obj] then
                originalPrices[obj] = text
            end
            if text and string.find(text, "%d") then
                if #text <= 20 then
                    local newText = string.gsub(text, "%d+,?%d*", "0")
                    obj.Text = newText
                    changed = changed + 1
                end
            end
        end
    end
    
    -- Ищем RemoteEvent для покупки и пытаемся перехватить цену
    local replicatedStorage = game:GetService("ReplicatedStorage")
    for _, obj in ipairs(replicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (string.find(string.lower(obj.Name), "buy") or 
                                        string.find(string.lower(obj.Name), "purchase") or
                                        string.find(string.lower(obj.Name), "shop")) then
            -- Перехватываем вызов, чтобы отправить цену 0
            if not originalPrices[obj] then
                originalPrices[obj] = true -- отметка что мы его трогали
                -- Пробуем заменить функцию
                local oldFireServer = obj.FireServer
                obj.FireServer = function(self, ...)
                    local args = {...}
                    -- Если второй аргумент похож на цену, заменяем на 0
                    if #args >= 2 and type(args[2]) == "number" then
                        args[2] = 0
                    end
                    return oldFireServer(self, unpack(args))
                end
                changed = changed + 1
            end
        end
    end
    
    return changed
end

-- Восстановление оригинальных цен
local function restorePrices()
    for obj, original in pairs(originalPrices) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            pcall(function() obj.Text = original end)
        elseif obj:IsA("IntValue") or obj:IsA("NumberValue") then
            pcall(function() obj.Value = original end)
        end
    end
    originalPrices = {}
end

-- Основной цикл
local function freeShopLoop()
    local changed = setPricesToZero()
    if changed > 0 then
        status.Text = string.format("Free shop active (%d changes)", changed)
    end
end

-- Переключение
local function toggle()
    enabled = not enabled
    
    if enabled then
        btn.Text = "FREE SHOP: ON"
        btn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        status.Text = "Making prices free..."
        -- Запускаем с небольшой задержкой чтобы магазин загрузился
        freeShopLoop()
        connection = runService.Heartbeat:Connect(function()
            -- Обновляем каждые 0.5 секунды
            if math.fmod(time(), 0.5) == 0 then
                freeShopLoop()
            end
        end)
    else
        btn.Text = "FREE SHOP: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        status.Text = "Ready | F8 = toggle"
        if connection then
            connection:Disconnect()
            connection = nil
        end
        restorePrices()
    end
end

btn.MouseButton1Click:Connect(toggle)

-- Горячая клавиша F8
uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F8 then
        toggle()
    end
end)

shared.__freeShop = {connection}
