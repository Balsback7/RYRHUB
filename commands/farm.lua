-- commands/farm.lua
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local module = {}

local farming = false
local currentNPC
local botList = {}
local followConnection
local attackConnection

local function getCharge()
    local v = LocalPlayer:FindFirstChild("jaladaDePeloCharge")
    return v and v.Value or 0
end

local function useAllAttackRemotes()
    pcall(function() ReplicatedStorage.Modules.Net["RE/chakramHit"]:FireServer(1) end)
    pcall(function() ReplicatedStorage.PUNCHEVENT:FireServer(1) end)
    pcall(function()
        ReplicatedStorage.Modules.Net["RE/CrowbarHit"]:FireServer(1)
    end)
end

local function refreshBots()
    botList = {}
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return end
    for _, name in ipairs({"random", "marras", "Karen"}) do
        local bot = chars:FindFirstChild(name)
        if bot then table.insert(botList, bot) end
    end
end

local function chooseRandomNPC()
    refreshBots()
    if #botList == 0 then return nil end
    currentNPC = botList[math.random(1,#botList)]
    return currentNPC
end

function module.start(updateStatus)
    if farming then return end
    farming = true

    local originalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    chooseRandomNPC()
    local lastBotName = ""

    followConnection = RunService.Heartbeat:Connect(function()
        if not farming then return end
        if currentNPC and currentNPC:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = 
                CFrame.new(currentNPC.HumanoidRootPart.Position + Vector3.new(0,3,-3), currentNPC.HumanoidRootPart.Position)
        else
            chooseRandomNPC()
        end
        if currentNPC and currentNPC.Name ~= lastBotName then
            lastBotName = currentNPC.Name
            updateStatus("Farming: "..lastBotName)
        end
    end)

    attackConnection = RunService.Heartbeat:Connect(function()
        if not farming then return end
        local charge = getCharge()
        useAllAttackRemotes()
        updateStatus("Charge: "..charge.."%")
        if charge >= 100 then
            module.stop(updateStatus)
        end
    end)
end

function module.stop(updateStatus)
    farming = false
    if followConnection then followConnection:Disconnect() followConnection = nil end
    if attackConnection then attackConnection:Disconnect() attackConnection = nil end
    updateStatus("Farming stopped")
end

return module
