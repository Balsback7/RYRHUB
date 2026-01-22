-- gui.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GuiModule = {}
GuiModule.OnFarmButtonClicked = Instance.new("BindableEvent")
GuiModule.OnBringButtonClicked = Instance.new("BindableEvent")
GuiModule.OnAnnoyButtonClicked = Instance.new("BindableEvent")
GuiModule.OnLeashButtonClicked = Instance.new("BindableEvent")
GuiModule.OnJailButtonClicked = Instance.new("BindableEvent")

function GuiModule:Init(player)
    -- Create a ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RYRHubGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 500)
    frame.Position = UDim2.new(0.5, -200, 0.5, -250)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.Parent = screenGui

    -- Input box for player name
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0, 300, 0, 40)
    inputBox.Position = UDim2.new(0, 50, 0, 20)
    inputBox.PlaceholderText = "Enter player name"
    inputBox.Parent = frame

    -- Farm Button
    local farmBtn = Instance.new("TextButton")
    farmBtn.Size = UDim2.new(0, 150, 0, 40)
    farmBtn.Position = UDim2.new(0, 25, 0, 80)
    farmBtn.Text = "START FARM"
    farmBtn.Parent = frame
    farmBtn.MouseButton1Click:Connect(function()
        GuiModule.OnFarmButtonClicked:Fire(inputBox.Text)
    end)

    -- Bring Button
    local bringBtn = Instance.new("TextButton")
    bringBtn.Size = UDim2.new(0, 150, 0, 40)
    bringBtn.Position = UDim2.new(0, 225, 0, 80)
    bringBtn.Text = "BRING"
    bringBtn.Parent = frame
    bringBtn.MouseButton1Click:Connect(function()
        GuiModule.OnBringButtonClicked:Fire(inputBox.Text)
    end)

    -- Annoy Button
    local annoyBtn = Instance.new("TextButton")
    annoyBtn.Size = UDim2.new(0, 150, 0, 40)
    annoyBtn.Position = UDim2.new(0, 25, 0, 140)
    annoyBtn.Text = "ANNOY"
    annoyBtn.Parent = frame
    annoyBtn.MouseButton1Click:Connect(function()
        GuiModule.OnAnnoyButtonClicked:Fire(inputBox.Text)
    end)

    -- Leash Button
    local leashBtn = Instance.new("TextButton")
    leashBtn.Size = UDim2.new(0, 150, 0, 40)
    leashBtn.Position = UDim2.new(0, 225, 0, 140)
    leashBtn.Text = "LEASH"
    leashBtn.Parent = frame
    leashBtn.MouseButton1Click:Connect(function()
        GuiModule.OnLeashButtonClicked:Fire(inputBox.Text)
    end)

    -- Jail Button
    local jailBtn = Instance.new("TextButton")
    jailBtn.Size = UDim2.new(0, 150, 0, 40)
    jailBtn.Position = UDim2.new(0, 125, 0, 200)
    jailBtn.Text = "JAIL"
    jailBtn.Parent = frame
    jailBtn.MouseButton1Click:Connect(function()
        GuiModule.OnJailButtonClicked:Fire(inputBox.Text)
    end)
end

return GuiModule
