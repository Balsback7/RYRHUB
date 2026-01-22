-- commands/farm.lua
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local farming = false
local botList = {}

local function refreshBots()
    botList = {}
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return end
    for _, name in ipairs({"random", "marras", "Karen"}) do
        local bot = chars:FindFirstChild(name)
        if bot then table.insert(botList, bot) end
    end
end

local function chooseRandomBot()
    refreshBots()
    if #botList == 0 then return nil end
    return botList[math.random(1,#botList)]
end

local function attackBot()
    pcall(function() ReplicatedStorage.Modules.Net["RE/chakramHit"]:FireServer(1) end)
    pcall(function() ReplicatedStorage.PUNCHEVENT:FireServer(1) end)
    pcall(function() ReplicatedStorage.Modules.Net["RE/CrowbarHit"]:FireServer(1) end)
end

local function Start(target)
    if farming then return end
    farming = true
    local currentBot = chooseRandomBot()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not farming then connection:Disconnect() return end
        if currentBot and currentBot:FindFirstChild("HumanoidRootPart") then
            local botHRP = currentBot.HumanoidRootPart
            hrp.CFrame = CFrame.new(botHRP.Position + Vector3.new(0,3,-3), botHRP.Position)
            attackBot()
        end
    end)
end

local function Stop()
    farming = false
end

return {Start = Start, Stop = Stop}
