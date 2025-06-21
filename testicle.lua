-- Get services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Local player reference
local localPlayer = Players.LocalPlayer
local punching = false
local originalPosition = nil
local PUNCH_DISTANCE = 3 -- Studs behind the target (adjust as needed)

-- Create ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "48 sigma"
gui.Parent = game:GetService("CoreGui") or localPlayer:WaitForChild("PlayerGui")

-- Create main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.3, 0, 0.5, 0)
frame.Position = UDim2.new(0.35, 0, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Parent = gui

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.1, 0)
title.Text = "48 Sigma Punch Selector"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

-- Scrolling frame for player list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 0.8, 0)
scrollFrame.Position = UDim2.new(0, 0, 0.1, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 5
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = frame

-- UIListLayout for player buttons
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(1, 0, 0.1, 0)
closeButton.Position = UDim2.new(0, 0, 0.9, 0)
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
closeButton.Font = Enum.Font.Gotham
closeButton.TextSize = 16
closeButton.Parent = frame

closeButton.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Function to teleport to player and punch
local function teleportAndPunch(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    -- Make sure we have a character
    if not localPlayer.Character then
        localPlayer.CharacterAdded:Wait()
    end
    
    local character = localPlayer.Character
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local targetRoot = target.Character.HumanoidRootPart
    
    -- Save original position
    originalPosition = humanoidRootPart.CFrame
    
    -- Equip punch tool (press 1)
    local tool = localPlayer.Backpack:FindFirstChildOfClass("Tool") or character:FindFirstChildOfClass("Tool")
    if tool then
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.1)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.One, false, game)
        task.wait(0.2)
    end
    
    punching = true
    
    -- Start punching
    local startTime = os.clock()
    
    -- Teleport behind player and maintain position while punching
    spawn(function()
        while punching and os.clock() - startTime < 5 and target and target.Character and targetRoot.Parent do
            -- Calculate position behind the target
            local targetCFrame = targetRoot.CFrame
            local behindPosition = targetCFrame * CFrame.new(0, 0, PUNCH_DISTANCE)
            
            -- Face the target while punching
            humanoidRootPart.CFrame = CFrame.new(behindPosition.Position, targetRoot.Position)
            
            -- Hold left click (punch)
            game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 1)
            RunService.Heartbeat:Wait()
        end
        
        -- Release mouse button when done
        game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 1)
        
        -- Return to original position
        if originalPosition and humanoidRootPart then
            humanoidRootPart.CFrame = originalPosition
        end
        
        punching = false
    end)
end

-- Function to create player buttons
local function createPlayerButtons()
    -- Clear existing buttons
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Create buttons for each player
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -10, 0, 40)
            button.Position = UDim2.new(0, 5, 0, 0)
            button.Text = player.DisplayName .. " (@" .. player.Name .. ")"
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            button.Font = Enum.Font.Gotham
            button.TextSize = 14
            button.Parent = scrollFrame
            
            -- Add glow effect on hover
            button.MouseEnter:Connect(function()
                TweenService:Create(
                    button,
                    TweenInfo.new(0.2),
                    {BackgroundColor3 = Color3.fromRGB(90, 90, 90)}
                ):Play()
            end)
            
            button.MouseLeave:Connect(function()
                TweenService:Create(
                    button,
                    TweenInfo.new(0.2),
                    {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}
                ):Play()
            end)
            
            -- Punch action on click
            button.MouseButton1Click:Connect(function()
                if not punching then
                    teleportAndPunch(player)
                end
            end)
        end
    end
end

-- Initial setup
createPlayerButtons()

-- Update player list when players join/leave
Players.PlayerAdded:Connect(createPlayerButtons)
Players.PlayerRemoving:Connect(createPlayerButtons)

-- Toggle GUI with key (optional)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.P and not gameProcessed then
        gui.Enabled = not gui.Enabled
    end
end)
