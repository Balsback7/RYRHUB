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
    
    local connection = Isolate.Shared.RunService.Heartbeat:Connect(function()
        if not Isolate.Shared.hrp or not Isolate.Shared.hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        if tHRP and tHRP.Parent then
            -- Stay behind target (height 3, back offset -3)
            Isolate.Shared.hrp.CFrame = CFrame.new(
                tHRP.Position + Vector3.new(0, Isolate.Shared.HEIGHT, 0) + tHRP.CFrame.LookVector * Isolate.Shared.BACK_OFFSET, 
                tHRP.Position
            )
            Isolate.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
            Isolate.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    
    return connection
end

-- Function to attack until ragdoll
local function attackUntilRagdoll(target)
    if not target or not target.Character then return false end
    
    local tChar = target.Character
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    
    if not tHRP then return false end
    
    -- Wield behind target while attacking
    local wieldConn = wieldBehindTarget(target)
    
    if not wieldConn then return false end
    
    -- Attack until ragdoll
    local attempts = 0
    local maxAttempts = 40
    
    Isolate.Shared.updateStatus("Attacking "..target.Name.. " until ragdoll...", Color3.fromRGB(246, 189, 59))
    
    while attempts < maxAttempts do
        -- Check if target is ragdolled
        if tChar:FindFirstChild("RagdollTrigger", true) then
            Isolate.Shared.updateStatus(target.Name.. " ragdolled!", Color3.fromRGB(59, 246, 105))
            break
        end
        
        -- Check if target is dead
        local humanoid = tChar:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            Isolate.Shared.updateStatus(target.Name.. " is down!", Color3.fromRGB(59, 246, 105))
            break
        end
        
        -- Attack with all remotes
        Isolate.Shared.useAllAttackRemotes()
        
        attempts += 1
        
        if attempts % 5 == 0 then
            Isolate.Shared.updateStatus("Attacking... ("..attempts.."/"..maxAttempts..")", Color3.fromRGB(246, 189, 59))
        end
        
        task.wait(0.2)
    end
    
    -- Stop wielding
    if wieldConn then
        wieldConn:Disconnect()
    end
    
    -- Check if ragdolled or dead
    return tChar:FindFirstChild("RagdollTrigger", true) ~= nil
end

-- Function to use charge command
local function useChargeCommand()
    Isolate.Shared.updateStatus("Using jaladaDePeloCharge...", Color3.fromRGB(246, 189, 59))
    
    local chargeUsed = false
    
    pcall(function()
        Isolate.Shared.ReplicatedStorage:WaitForChild("JALADADEPELOEVENT"):FireServer()
        chargeUsed = true
        Isolate.Shared.updateStatus("Charge fired!", Color3.fromRGB(59, 189, 246))
    end)
    
    return chargeUsed
end

-- Function to wait for target to ragdoll
local function waitForRagdoll(target, timeout)
    local startTime = tick()
    local maxWaitTime = timeout or 5
    
    Isolate.Shared.updateStatus("Waiting for "..target.Name.. " to ragdoll...", Color3.fromRGB(246, 189, 59))
    
    while tick() - startTime < maxWaitTime do
        local tChar = target.Character
        if tChar then
            -- Check if ragdolled
            if tChar:FindFirstChild("RagdollTrigger", true) then
                Isolate.Shared.updateStatus(target.Name.. " ragdolled!", Color3.fromRGB(59, 246, 105))
                return true
            end
            
            -- Check if dead
            local humanoid = tChar:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health <= 0 then
                Isolate.Shared.updateStatus(target.Name.. " is down!", Color3.fromRGB(59, 246, 105))
                return true
            end
        end
        
        task.wait(0.5)
    end
    
    Isolate.Shared.updateStatus("Timeout - target did not ragdoll", Color3.fromRGB(246, 59, 59))
    return false
end

function Isolate.execute(targetText)
    task.spawn(function()
        local originalPosition = Isolate.Shared.savePosition()
        
        local target = Isolate.Shared.findPlayerSmart(targetText)
        if not target then
            Isolate.Shared.updateStatus("Player not found", Color3.fromRGB(246, 59, 59))
            return
        end
        
        Isolate.Shared.updateStatus("Isolating "..target.Name.. "...", Color3.fromRGB(168, 85, 247))
        
        -- PHASE 1: Teleport to target
        Isolate.Shared.updateStatus("Phase 1: Teleporting to target...", Color3.fromRGB(246, 189, 59))
        
        local tChar = target.Character
        if not tChar then
            Isolate.Shared.updateStatus("Target has no character", Color3.fromRGB(246, 59, 59))
            Isolate.Shared.smoothTP(originalPosition)
            return
        end
        
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then
            Isolate.Shared.updateStatus("Target has no HRP", Color3.fromRGB(246, 59, 59))
            Isolate.Shared.smoothTP(originalPosition)
            return
        end
        
        -- Teleport behind target
        local behindPosition = tHRP.Position + tHRP.CFrame.LookVector * -2 + Vector3.new(0, 2, 0)
        Isolate.Shared.hrp.CFrame = CFrame.new(behindPosition, tHRP.Position)
        
        task.wait(0.3)
        
        -- PHASE 2: Attempt charge command
        Isolate.Shared.updateStatus("Phase 2: Attempting charge...", Color3.fromRGB(246, 189, 59))
        
        local chargeSuccess = false
        local chargeUsed = false
        
        -- Wield behind target for charge
        local wieldConn = wieldBehindTarget(target)
        
        if wieldConn then
            -- Use charge command
            chargeUsed = useChargeCommand()
            
            -- Wait for charge to hit
            task.wait(0.5)
            
            -- Stop wielding
            wieldConn:Disconnect()
            
            -- Wait for ragdoll (if charge was used)
            if chargeUsed then
                chargeSuccess = waitForRagdoll(target, 3) -- Wait 3 seconds for ragdoll
            end
        end
        
        -- PHASE 3: If charge failed, use attack remotes
        if chargeUsed and not chargeSuccess then
            Isolate.Shared.updateStatus("Charge didn't ragdoll, using attack remotes...", Color3.fromRGB(246, 189, 59))
            chargeSuccess = attackUntilRagdoll(target)
        elseif not chargeUsed then
            Isolate.Shared.updateStatus("Charge failed, using attack remotes...", Color3.fromRGB(246, 189, 59))
            chargeSuccess = attackUntilRagdoll(target)
        end
        
        -- Check if target was ragdolled
        if not chargeSuccess then
            Isolate.Shared.updateStatus("Failed to ragdoll "..target.Name, Color3.fromRGB(246, 59, 59))
            Isolate.Shared.updateStatus("Returning to position...", Color3.fromRGB(246, 189, 59))
            Isolate.Shared.smoothTP(originalPosition)
            Isolate.Shared.updateStatus("Isolation failed", Color3.fromRGB(246, 59, 59))
            return
        end
        
        -- PHASE 4: Teleport to isolation location (-488, -251, 418) - ONLY AFTER RAGDOLL
        Isolate.Shared.updateStatus("Phase 4: Teleporting to isolation...", Color3.fromRGB(246, 189, 59))
        
        local ISOLATE_POSITION = CFrame.new(-488, -251, 418)
        Isolate.Shared.hrp.CFrame = ISOLATE_POSITION
        
        -- Wait at isolation location
        Isolate.Shared.updateStatus("At isolation location, waiting...", Color3.fromRGB(246, 189, 59))
        task.wait(2)
        
        -- PHASE 5: Teleport back to original position
        Isolate.Shared.updateStatus("Phase 5: Returning from isolation...", Color3.fromRGB(246, 189, 59))
        Isolate.Shared.smoothTP(originalPosition)
        
        Isolate.Shared.updateStatus("Isolation complete on "..target.Name, Color3.fromRGB(59, 246, 105))
        
        task.wait(1)
        Isolate.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
    end)
end

return Isolate
