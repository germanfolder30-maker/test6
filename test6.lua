--// Force High Jump Script (Обход защиты)
local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local enabled = false
local JUMP_POWER = 300
local defaultJump = 50
local forceConnection = nil

-- Получаем стандартную высоту
local char = player.Character
if char and char:FindFirstChild("Humanoid") then
    defaultJump = char.Humanoid.JumpPower
end

-- Очистка старых связей
if shared.__forceHighJump then
    for _, conn in ipairs(shared.__forceHighJump) do
        pcall(function() conn:Disconnect() end)
    end
end
local connections = {}

-- GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ForceHighJump"
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton", gui)
btn.Size = UDim2.new(0, 160, 0, 40)
btn.Position = UDim2.new(0, 20, 0, 470)
btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
btn.Text = "JUMP: OFF"
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 14
btn.BorderSizePixel = 0
btn.AutoButtonColor = false
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

-- Принудительное обновление JumpPower каждый кадр
local function forceJumpPower()
    local currentChar = player.Character
    if currentChar then
        local hum = currentChar:FindFirstChild("Humanoid")
        if hum and hum.JumpPower ~= JUMP_POWER then
            hum.JumpPower = JUMP_POWER
        end
    end
end

-- Переключение
local function toggle()
    enabled = not enabled
    
    if enabled then
        -- Запускаем принудительное обновление
        forceConnection = runService.RenderStepped:Connect(forceJumpPower)
        btn.Text = "JUMP: ON"
        btn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
    else
        -- Останавливаем и возвращаем стандартный прыжок
        if forceConnection then
            forceConnection:Disconnect()
            forceConnection = nil
        end
        local currentChar = player.Character
        if currentChar then
            local hum = currentChar:FindFirstChild("Humanoid")
            if hum then
                hum.JumpPower = defaultJump
            end
        end
        btn.Text = "JUMP: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end
end

-- События
connections[1] = btn.MouseButton1Click:Connect(toggle)

connections[2] = uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F3 then
        toggle()
    end
end)

connections[3] = player.CharacterAdded:Connect(function(newChar)
    newChar:WaitForChild("Humanoid")
    if not enabled then return end
    -- Перезапускаем принудительное обновление на новом персонаже
    if forceConnection then
        forceConnection:Disconnect()
    end
    forceConnection = runService.RenderStepped:Connect(forceJumpPower)
end)

shared.__forceHighJump = connections
