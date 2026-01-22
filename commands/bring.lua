-- commands/bring.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local function getTargetPlayer(targetName)
    return Players:FindFirstChild(targetName)
end

local function Execute(targetName)
    local target = getTargetPlayer(targetName)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end

    local targetHRP = target.Character.HumanoidRootPart
    hrp.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0,3,-3))
end

return {Execute = Execute}
