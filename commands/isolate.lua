--// Isolate Player Command
local Isolate = {}

function Isolate.init(Shared)
    Isolate.Shared = Shared
end

-- Function to wield behind target
local function wieldBehindTarget(target)
    if not Isolate.Shared.hrp or not Isolate.Shared.hrp.Parent then return nil end
    
    local tChar = target.Character
    if not tChar then return nil end
    
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then return nil end
    
    local connection
    connection = Isolate.Shared.RunService.Heartbeat:Connect(function()
        if not Isolate.Shared.hrp or not Isolate.Shared.hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        if tHRP and tHRP.Parent then
            Isolate.Shared.hrp.CFrame = CFrame.new(
                tHRP.Position
                    + Vector3.new(0, Isolate.Shared.HEIGHT, 0)
                    + tHRP.CFrame.LookVector * Isolate.Shared.BACK_OFFSET,
                tHRP.Position
            )
            Isolate.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
            Isolate.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    -- store so it can be force-stopped
    Isolate.Shared._wieldConn = connection
    return connection
end

-- Function to attack until ragdoll
local function attackUntilRagdoll(target)
    if not target or not target.Character then return false end
    
    local tChar = target.Character
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then return false end
    
    local wieldConn = wieldBehindTarget(target)
    if not wieldConn then return false end
    
    local attempts = 0
    local maxAttempts = 40
    
    Isolate.Shared.updateStatus("Attacking "..target.Name.." until ragdoll...", Color3.fromRGB(246,189,59))
    
    while attempts < maxAttempts do
        if tChar:FindFirstChild("RagdollTrigger", true) then break end
        
        local humanoid = tChar:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health <= 0 then break end
        
        Isolate.Shared.useAllAttackRemotes()
        attempts += 1
        task.wait(0.2)
    end
    
    if wieldConn then wieldConn:Disconnect() end
    Isolate.Shared._wieldConn = nil
    
    return tChar:FindFirstChild("RagdollTrigger", true) ~= nil
end

-- Function to use charge command with isolation teleport
local function useChargeWithIsolationTeleport(target)
    Isolate.Shared.updateStatus("Using charge with isolation teleport...", Color3.fromRGB(246,189,59))
    
    local positionBeforeCharge = Isolate.Shared.savePosition()
    
    -- fire charge
    local success = pcall(function()
        Isolate.Shared.ReplicatedStorage:WaitForChild("JALADADEPELOEVENT"):FireServer()
    end)
    
    if not success then
        Isolate.Shared.updateStatus("Charge failed to fire", Color3.fromRGB(246,59,59))
        return false
    end
    
    -- STOP ALL POSITION LOCKS BEFORE TELEPORT
    if Isolate.Shared._wieldConn then
        Isolate.Shared._wieldConn:Disconnect()
        Isolate.Shared._wieldConn = nil
    end
    
    task.wait() -- allow heartbeat to fully stop
    
    -- prevent server snapback
    pcall(function()
        Isolate.Shared.hrp:SetNetworkOwner(nil)
    end)
    
    -- HARD TELEPORT
    Isolate.Shared.updateStatus("Teleporting to isolation...", Color3.fromRGB(246,189,59))
    Isolate.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
    Isolate.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
    Isolate.Shared.hrp:PivotTo(CFrame.new(-488, -251, 418))
    
    -- wait charge anim
    task.wait(3)
    
    -- isolation wait
    task.wait(5)
    
    -- return
    Isolate.Shared.updateStatus("Returning from isolation...", Color3.fromRGB(246,189,59))
    Isolate.Shared.smoothTP(positionBeforeCharge)
    task.wait(0.5)
    
    local tChar = target.Character
    return tChar and tChar:FindFirstChild("RagdollTrigger", true) ~= nil
end

-- Wait for ragdoll helper
local function waitForRagdoll(target, timeout)
    local start = tick()
    timeout = timeout or 3
    
    while tick() - start < timeout do
        local char = target.Character
        if char then
            if char:FindFirstChild("RagdollTrigger", true) then return true end
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health <= 0 then return true end
        end
        task.wait(0.5)
    end
    return false
end

function Isolate.execute(targetText)
    task.spawn(function()
        local originalPosition = Isolate.Shared.savePosition()
        local target = Isolate.Shared.findPlayerSmart(targetText)
        if not target then
            Isolate.Shared.updateStatus("Player not found", Color3.fromRGB(246,59,59))
            return
        end
        
        Isolate.Shared.updateStatus("Isolating "..target.Name.."...", Color3.fromRGB(168,85,247))
        
        local tChar = target.Character
        local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then
            Isolate.Shared.updateStatus("Target invalid", Color3.fromRGB(246,59,59))
            Isolate.Shared.smoothTP(originalPosition)
            return
        end
        
        -- teleport behind
        Isolate.Shared.hrp.CFrame = CFrame.new(
            tHRP.Position + tHRP.CFrame.LookVector * -2 + Vector3.new(0,2,0),
            tHRP.Position
        )
        
        task.wait(0.3)
        
        local wieldConn = wieldBehindTarget(target)
        task.wait(0.5)
        
        local success = useChargeWithIsolationTeleport(target)
        if wieldConn then wieldConn:Disconnect() end
        Isolate.Shared._wieldConn = nil
        
        if not success then
            success = waitForRagdoll(target, 2)
        end
        
        if not success then
            success = attackUntilRagdoll(target)
        end
        
        Isolate.Shared.updateStatus(
            success and "Isolation complete on "..target.Name or "Failed to isolate "..target.Name,
            success and Color3.fromRGB(59,246,105) or Color3.fromRGB(246,59,59)
        )
        
        Isolate.Shared.smoothTP(originalPosition)
        task.wait(1)
        Isolate.Shared.updateStatus("Idle", Color3.fromRGB(59,246,105))
    end)
end

return Isolate
