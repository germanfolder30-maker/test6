--// Free Shop Prices v2 (Shop Only, No Balance Touch)
local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local enabled = false
local connection = nil
local changedObjects = {}

-- Очистка старого
if shared.__freeShop2 then
    for _, v in ipairs(shared.__freeShop2) do
        pcall(function() v:Disconnect() end)
    end
end
if game.CoreGui:FindFirstChild("FreeShopGUI2") then
    game.CoreGui.FreeShopGUI2:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "FreeShopGUI2"
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
status.Text = "Ready | Open shop then F8"
status.BorderSizePixel = 0
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 5)

-- Ключевые слова, которые указывают что это цена в магазине
local shopKeywords = {"price", "cost", "buy", "purchase", "shop", "store", "$", "💰", "💎", "🪙", "coin", "gem", "gold"}

-- Проверка: является ли объект ценой в магазине (НЕ балансом)
local function isShopPrice(obj)
    if not obj:IsA("TextLabel") and not obj:IsA("TextButton") then return false end
    
    local text = obj.Text or ""
    local name = string.lower(obj.Name)
    local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""
    
    -- Проверяем что текст содержит цифры (цену) и он короткий
    if not string.find(text, "%d") then return false end
    if #text > 30 then return false end -- слишком длинный текст (не цена)
    
    -- Проверяем ключевые слова в имени объекта или родителя
    for _, keyword in ipairs(shopKeywords) do
        if string.find(name, keyword) or string.find(parentName, keyword) or string.find(string.lower(text), keyword) then
            return true
        end
    end
    
    -- Доп. проверка: родитель содержит "shop", "store", "market"
    local parent = obj.Parent
    for _ = 1, 5 do
        if parent then
            local pName = string.lower(parent.Name)
            if string.find(pName, "shop") or string.find(pName, "store") or string.find(pName, "market") or string.find(pName, "menu") then
                return true
            end
            parent = parent.Parent
        end
    end
    
    return false
end

-- Замена цен
local function setShopPricesToZero()
    local changed = 0
    local playerGui = player:FindFirstChild("PlayerGui")
    
    local function scan(parent)
        for _, obj in ipairs(parent:GetChildren()) do
            if isShopPrice(obj) then
                if not changedObjects[obj] then
                    changedObjects[obj] = obj.Text -- сохраняем оригинал
                end
                -- Заменяем числа на 0
                local newText = string.gsub(obj.Text, "%d+", "0")
                obj.Text = newText
                changed = changed + 1
            end
            
            if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                local name = string.lower(obj.Name)
                -- Только если это именно цена товара, а не баланс
                if (string.find(name, "price") or string.find(name, "cost")) and 
                   not string.find(name, "balance") and not string.find(name, "money") and not string.find(name, "cash") then
                    if not changedObjects[obj] then
                        changedObjects[obj] = obj.Value
                    end
                    obj.Value = 0
                    changed = changed + 1
                end
            end
            
            if #obj:GetChildren() > 0 then
                scan(obj)
            end
        end
    end
    
    if playerGui then scan(playerGui) end
    scan(game.CoreGui)
    
    return changed
end

-- Восстановление
local function restorePrices()
    for obj, original in pairs(changedObjects) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            pcall(function() obj.Text = original end)
        elseif obj:IsA("IntValue") or obj:IsA("NumberValue") then
            pcall(function() obj.Value = original end)
        end
    end
    changedObjects = {}
end

-- Основной цикл
local function updatePrices()
    local changed = setShopPricesToZero()
    if changed > 0 then
        status.Text = string.format("Shop prices: FREE (%d changed)", changed)
    end
end

-- Переключение
local function toggle()
    enabled = not enabled
    
    if enabled then
        btn.Text = "FREE SHOP: ON"
        btn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        status.Text = "Open shop to apply..."
        updatePrices()
        connection = runService.Heartbeat:Connect(function()
            if math.fmod(time(), 0.3) == 0 then
                updatePrices()
            end
        end)
    else
        btn.Text = "FREE SHOP: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        status.Text = "Ready | Open shop then F8"
        if connection then connection:Disconnect(); connection = nil end
        restorePrices()
    end
end

btn.MouseButton1Click:Connect(toggle)

uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F8 then
        toggle()
    end
end)

shared.__freeShop2 = {connection}
