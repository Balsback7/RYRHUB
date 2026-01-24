--// RYR Hub Main Script
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load modules
local GUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Balsback7/RYRHUB/refs/heads/main/gui.lua"))()
local Commands = {}

-- Load command modules
local commandFiles = {
    "farm",
    "bring", 
    "annoy",
    "leash",
    "isolate",  -- Changed from jail to isolate
    "protect"
}

for _, cmdName in ipairs(commandFiles) do
    local success, cmd = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Balsback7/RYRHub/main/commands/" .. cmdName .. ".lua"))()
    end)
    
    if success and cmd then
        Commands[cmdName] = cmd
    else
        warn("Failed to load command: " .. cmdName)
    end
end

-- Initialize player
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

-- Shared state
local Shared = {
    player = player,
    char = char,
    humanoid = humanoid,
    hrp = hrp,
    Players = Players,
    RunService = RunService,
    ReplicatedStorage = ReplicatedStorage,
    
    -- State
    farming = false,
    annoying = false,
    protecting = false,
    followConnection = nil,
    attackConnection = nil,
    annoyConnection = nil,
    protectConnection = nil,
    
    -- Settings
    HEIGHT = 3,
    BACK_OFFSET = -3,
    BOT_REFRESH_INTERVAL = 1,
    UNDERGROUND_OFFSET = -7,
    
    -- Utility functions (will be injected by main)
    updateStatus = nil,
    cleanupAllConnections = nil,
    savePosition = nil,
    smoothTP = nil,
    getCharge = nil,
    useAllAttackRemotes = nil,
    findPlayerSmart = nil,
    chooseRandomNPC = nil,
    stopFarm = nil,
    stopAnnoy = nil,
    stopProtect = nil,
    
    -- Commands
    Commands = Commands
}

-- Utility functions (same as before, no changes needed)
Shared.getCharge = function()
    local v = Shared.player:FindFirstChild("jaladaDePeloCharge")
    return v and v.Value or 0
end

Shared.smoothTP = function(cf)
    if not cf then return end
    local TweenService = game:GetService("TweenService")
    Shared.hrp.AssemblyLinearVelocity = Vector3.zero
    Shared.hrp.AssemblyAngularVelocity = Vector3.zero
    TweenService:Create(Shared.hrp, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = cf}):Play()
end

Shared.savePosition = function()
    return Shared.hrp.CFrame
end

Shared.cleanupAllConnections = function()
    if Shared.followConnection then 
        Shared.followConnection:Disconnect() 
        Shared.followConnection = nil 
    end
    if Shared.attackConnection then 
        Shared.attackConnection:Disconnect() 
        Shared.attackConnection = nil 
    end
    if Shared.annoyConnection then 
        Shared.annoyConnection:Disconnect() 
        Shared.annoyConnection = nil 
    end
    if Shared.protectConnection then
        Shared.protectConnection:Disconnect()
        Shared.protectConnection = nil
    end
    Shared.farming = false
    Shared.annoying = false
    Shared.protecting = false
end

Shared.useAllAttackRemotes = function()
    -- Remote 1: RE/chakramHit
    pcall(function() 
        ReplicatedStorage.Modules.Net["RE/chakramHit"]:FireServer(1) 
    end)
    
    -- Remote 2: PUNCHEVENT
    pcall(function() 
        ReplicatedStorage.PUNCHEVENT:FireServer(1) 
    end)
    
    -- Remote 3: RE/CrowbarHit
    pcall(function()
        local args = {1}
        ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/CrowbarHit"):FireServer(unpack(args))
    end)
end

Shared.findPlayerSmart = function(input)
    if not input or input == "" then return nil end
    input = input:lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Shared.player and (plr.Name:lower():find(input) or (plr.DisplayName and plr.DisplayName:lower():find(input))) then
            return plr
        end
    end
    return nil
end

Shared.chooseRandomNPC = function()
    local botList = {}
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return nil end
    
    -- Add all available bots
    local botNames = {"random", "marras", "Karen"}
    for _, name in ipairs(botNames) do
        local bot = chars:FindFirstChild(name)
        if bot then table.insert(botList, bot) end
    end
    
    if #botList == 0 then return nil end
    
    -- Create a list of non-ragdolled bots
    local availableBots = {}
    for _, bot in ipairs(botList) do
        if not bot:FindFirstChild("RagdollTrigger", true) then
            table.insert(availableBots, bot)
        end
    end
    
    -- If no non-ragdolled bots, use any bot
    if #availableBots == 0 then
        availableBots = botList
    end
    
    -- Select random bot
    if #availableBots > 0 then
        local randomIndex = math.random(1, #availableBots)
        return availableBots[randomIndex]
    end
    
    return nil
end

-- Inject Shared into all commands
for cmdName, cmdModule in pairs(Commands) do
    if cmdModule and type(cmdModule) == "table" and cmdModule.init then
        cmdModule.init(Shared)
    end
end

-- Initialize GUI
GUI.init(Shared)

-- Character respawn handler
player.CharacterAdded:Connect(function(newChar)
    Shared.char = newChar
    Shared.humanoid = newChar:WaitForChild("Humanoid")
    Shared.hrp = newChar:WaitForChild("HumanoidRootPart")
    
    -- Re-initialize commands with new character
    for cmdName, cmdModule in pairs(Commands) do
        if cmdModule and type(cmdModule) == "table" and cmdModule.onCharacterAdded then
            cmdModule.onCharacterAdded()
        end
    end
end)

return Shared
