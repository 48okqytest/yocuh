-- STROLLER VOIDER
-- Complete fixed version with working GUI and all features

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Configuration
local BEHIND_OFFSET = Vector3.new(0, 0, -5)
local STROLLER_TOOL_NAME = "Stroller"
local PICKUP_WAIT_TIME = 0.5
local TELEPORT_DISTANCE = 20000
local DROP_HEIGHT = 500
local CHASE_INTERVAL = 0.2

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StrollerVoider"
ScreenGui.Parent = player.PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 400)
Frame.Position = UDim2.new(0.5, -150, 0.5, -200)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
Frame.BackgroundTransparency = 0.1
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

-- Make frame draggable
local dragInput, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragStart = nil
            end
        end)
    end
end)

Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Cosmic Glow Effect
local Glow = Instance.new("ImageLabel")
Glow.Name = "Glow"
Glow.Image = "rbxassetid://5028857084"
Glow.ImageColor3 = Color3.fromRGB(100, 0, 150)
Glow.ScaleType = Enum.ScaleType.Slice
Glow.SliceCenter = Rect.new(24, 24, 276, 276)
Glow.BackgroundTransparency = 1
Glow.Size = UDim2.new(1, 40, 1, 40)
Glow.Position = UDim2.new(0, -20, 0, -20)
Glow.ZIndex = -1
Glow.Parent = Frame

-- Title
local Title = Instance.new("TextLabel")
Title.Text = "STROLLER VOIDER"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(200, 150, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18
Title.TextStrokeTransparency = 0.7
Title.Parent = Frame

-- Player List Container
local PlayerListContainer = Instance.new("Frame")
PlayerListContainer.Size = UDim2.new(1, -20, 0, 250)
PlayerListContainer.Position = UDim2.new(0, 10, 0, 60)
PlayerListContainer.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
PlayerListContainer.BackgroundTransparency = 0.3
PlayerListContainer.BorderSizePixel = 0
PlayerListContainer.Parent = Frame

-- Player List Scrolling Frame
local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(1, -5, 1, -5)
PlayerList.Position = UDim2.new(0, 5, 0, 5)
PlayerList.BackgroundTransparency = 1
PlayerList.ScrollBarThickness = 4
PlayerList.ScrollBarImageColor3 = Color3.fromRGB(150, 50, 200)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.Parent = PlayerListContainer

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = PlayerList

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PlayerList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end)

-- Target Display
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Text = "TARGET: NONE"
TargetLabel.Size = UDim2.new(1, -20, 0, 30)
TargetLabel.Position = UDim2.new(0, 10, 0, 320)
TargetLabel.BackgroundTransparency = 1
TargetLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = Frame

-- Execute Button
local ExecuteButton = Instance.new("TextButton")
ExecuteButton.Text = "LAUNCH TO VOID"
ExecuteButton.Size = UDim2.new(1, -20, 0, 40)
ExecuteButton.Position = UDim2.new(0, 10, 0, 360)
ExecuteButton.BackgroundColor3 = Color3.fromRGB(80, 0, 120)
ExecuteButton.BackgroundTransparency = 0.2
ExecuteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteButton.Font = Enum.Font.GothamBold
ExecuteButton.TextSize = 14
ExecuteButton.Parent = Frame

-- Button Glow Effect
local ButtonGlow = Instance.new("ImageLabel")
ButtonGlow.Image = "rbxassetid://5028857084"
ButtonGlow.ImageColor3 = Color3.fromRGB(150, 50, 200)
ButtonGlow.ScaleType = Enum.ScaleType.Slice
ButtonGlow.SliceCenter = Rect.new(24, 24, 276, 276)
ButtonGlow.BackgroundTransparency = 1
ButtonGlow.Size = UDim2.new(1, 20, 1, 20)
ButtonGlow.Position = UDim2.new(0, -10, 0, -10)
ButtonGlow.ZIndex = -1
ButtonGlow.Parent = ExecuteButton

-- Variables
local selectedTarget = nil
local isChasing = false
local chaseConnection = nil
local originalPosition = nil

-- Find stroller in backpack
local function getStroller()
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool.Name == STROLLER_TOOL_NAME then
            return tool
        end
    end
    return nil
end

-- Create player button
local function createPlayerButton(playerName)
    local button = Instance.new("TextButton")
    button.Text = playerName
    button.Size = UDim2.new(1, -10, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
    button.BackgroundTransparency = 0.5
    button.TextColor3 = Color3.fromRGB(220, 180, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 12
    button.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Button hover effects
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(60, 30, 80)
    end)
    
    button.MouseLeave:Connect(function()
        if selectedTarget and selectedTarget.Name == playerName then
            button.BackgroundColor3 = Color3.fromRGB(100, 50, 130)
        else
            button.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
        end
    end)
    
    return button
end

-- Update player list
local function updatePlayerList()
    -- Clear existing buttons
    for _, child in ipairs(PlayerList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Add all players except yourself
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local playerButton = createPlayerButton(otherPlayer.Name)
            playerButton.Name = otherPlayer.Name
            playerButton.Parent = PlayerList
            
            playerButton.MouseButton1Click:Connect(function()
                selectedTarget = otherPlayer
                TargetLabel.Text = "TARGET: " .. otherPlayer.Name:upper()
                
                -- Update all button highlights
                for _, btn in ipairs(PlayerList:GetChildren()) do
                    if btn:IsA("TextButton") then
                        if btn.Text == otherPlayer.Name then
                            btn.BackgroundColor3 = Color3.fromRGB(100, 50, 130)
                            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        else
                            btn.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
                            btn.TextColor3 = Color3.fromRGB(220, 180, 255)
                        end
                    end
                end
            end)
        end
    end
end

-- Main execution function
local function executeScript()
    if not selectedTarget or not selectedTarget.Character then
        TargetLabel.Text = "ERROR: NO TARGET SELECTED!"
        task.wait(1)
        TargetLabel.Text = "TARGET: " .. (selectedTarget and selectedTarget.Name:upper() or "NONE")
        return
    end
    
    -- Store original position
    originalPosition = character.HumanoidRootPart.CFrame
    
    -- Check for stroller
    local stroller = getStroller()
    if not stroller then
        TargetLabel.Text = "ERROR: STROLLER NOT FOUND!"
        task.wait(1)
        TargetLabel.Text = "TARGET: " .. selectedTarget.Name:upper()
        return
    end
    
    local targetChar = selectedTarget.Character
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        TargetLabel.Text = "ERROR: TARGET ROOT PART MISSING!"
        return
    end
    
    -- Start chasing
    isChasing = true
    TargetLabel.Text = "CHASING "..selectedTarget.Name:upper().."..."
    chaseConnection = RunService.Heartbeat:Connect(function()
        if targetRoot and targetRoot.Parent then
            character.HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(BEHIND_OFFSET)
            character.HumanoidRootPart.CFrame = CFrame.new(
                character.HumanoidRootPart.Position,
                targetRoot.Position
            )
        end
    end)
    
    -- Equip stroller
    stroller.Parent = character
    
    -- Wait for pickup
    task.wait(PICKUP_WAIT_TIME)
    
    -- Stop chasing
    if chaseConnection then
        chaseConnection:Disconnect()
    end
    isChasing = false
    
    -- Teleport 20,000 studs away
    local randomDirection = Vector3.new(
        math.random(-100, 100),
        0,
        math.random(-100, 100)
    ).Unit
    
    local voidPosition = character.HumanoidRootPart.Position + (randomDirection * TELEPORT_DISTANCE)
    voidPosition = Vector3.new(voidPosition.X, DROP_HEIGHT, voidPosition.Z)
    
    -- Teleport to void position
    character.HumanoidRootPart.CFrame = CFrame.new(voidPosition)
    TargetLabel.Text = "LAUNCHING "..selectedTarget.Name:upper().." TO VOID..."
    
    -- Wait a moment for drop to register
    task.wait(0.5)
    
    -- Return to original position
    if originalPosition then
        character.HumanoidRootPart.CFrame = originalPosition
        TargetLabel.Text = "MISSION COMPLETE: "..selectedTarget.Name:upper()
    end
    
    -- Unequip stroller
    stroller.Parent = player.Backpack
end

-- Connect execute button
ExecuteButton.MouseButton1Click:Connect(executeScript)

-- Player tracking
Players.PlayerAdded:Connect(function(newPlayer)
    updatePlayerList()
    newPlayer.CharacterAdded:Connect(function()
        updatePlayerList()
    end)
end)

Players.PlayerRemoving:Connect(function()
    updatePlayerList()
end)

-- Initial setup
updatePlayerList()

-- Toggle GUI visibility
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.BackSlash then
        Frame.Visible = not Frame.Visible
    end
end)

-- Cleanup on character reset
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    if chaseConnection then
        chaseConnection:Disconnect()
        isChasing = false
    end
end)
