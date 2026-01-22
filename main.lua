-- main.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

-- Load GUI
local gui = require(script.Parent.gui)
gui:Init(player)

-- Load commands
local commands = {}
commands.Farm = require(script.Parent.commands.farm)
commands.Bring = require(script.Parent.commands.bring)
commands.Annoy = require(script.Parent.commands.annoy)
commands.Leash = require(script.Parent.commands.leash)
commands.Jail = require(script.Parent.commands.jail)

-- Example: connect GUI buttons
gui.OnFarmButtonClicked:Connect(function(target)
    commands.Farm.Start(target)
end)

gui.OnBringButtonClicked:Connect(function(target)
    commands.Bring.Execute(target)
end)

gui.OnAnnoyButtonClicked:Connect(function(target)
    commands.Annoy.Start(target)
end)

gui.OnLeashButtonClicked:Connect(function(target)
    commands.Leash.Execute(target)
end)

gui.OnJailButtonClicked:Connect(function(target)
    commands.Jail.Execute(target)
end)
