-- commands/leash.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function getTargetPlayer(targetName)
    return Players:FindFirstChild(targetName)
end

local function Execute(targetName)
    local target = getTargetPlayer(targetName)
    if not target then return end
    -- Fire leash remote
    local args = {target.Name}
    pcall(function()
        ReplicatedStorage.Modules.Net["RE/dogLeashEvent"]:FireServer(unpack(args))
    end)
end

return {Execute = Execute}
