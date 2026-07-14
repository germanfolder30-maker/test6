local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")

uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F5 then
        local mouse = player:GetMouse()
        local target = mouse.Target
        if target then
            local info = string.format(
                "Name: %s\nClass: %s\nParent: %s\nFull Path: %s",
                target.Name,
                target.ClassName,
                target.Parent and target.Parent.Name or "nil",
                target:GetFullName()
            )
            -- Показываем в консоли (F9) и на экране
            print(info)
            -- Можно также вывести в GUI
            local gui = Instance.new("ScreenGui", game.CoreGui)
            local label = Instance.new("TextLabel", gui)
            label.Size = UDim2.new(0, 300, 0, 80)
            label.Position = UDim2.new(0, 20, 0, 100)
            label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            label.BackgroundTransparency = 0.3
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.Font = Enum.Font.SourceSans
            label.TextSize = 14
            label.Text = info
            label.TextWrapped = true
            task.delay(5, function() gui:Destroy() end)
        else
            print("Ничего не найдено под курсором")
        end
    end
end)
