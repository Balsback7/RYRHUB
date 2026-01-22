-- commands/annoy.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local annoying = false

local function getTargetPlayer(targetName)
    return Players:FindFirstChild(targetName)
end

local function attackTarget(target)
    pcall(function() ReplicatedStorage.Modules.Net["RE/chakramHit"]:FireServer(1) end)
    pcall(function() ReplicatedStorage.PUNCHEVENT:FireServer(1) end)
    pcall(function() ReplicatedStorage.Modules.Net["RE/CrowbarHit"]:FireServer(1) end)
end

local function Start(targetName)
    if annoying then return end
    annoying = true
    local target = getTargetPlayer(targetName)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    local targetHRP = target.Character.HumanoidRootPart

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not annoying then connection:Disconnect() return end
        if targetHRP then
            hrp.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0,3,-3), targetHRP.Position)
            attackTarget(target)
        end
    end)
end

local function Stop()
    annoying = false
end

return {Start = Start, Stop = Stop}
