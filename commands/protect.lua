--// Protect Player Command
local Protect = {}

-- Local variables
local protectTarget = nil
local protectConnection = nil
local damageConnection = nil
local originalPosition = nil
local lastDamageTime = 0
local currentAttacker = nil
local cleanupConnection = nil

-- Clean up all connections
local function cleanupProtectConnections()
    if protectConnection then
        protectConnection:Disconnect()
        protectConnection = nil
    end
    
    if damageConnection then
        damageConnection:Disconnect()
        damageConnection = nil
    end
    
    if cleanupConnection then
        cleanupConnection:Disconnect()
        cleanupConnection = nil
    end
    
    currentAttacker = nil
end

-- Function to wield behind target with distance
local function wieldBehindTarget(target, distanceOffset)
    if not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then return nil end
    
    local tChar = target.Character
    if not tChar then return nil end
    
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then return nil end
    
    local connection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not Protect.Shared.protecting or not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        -- Don't wield if we're currently attacking someone
        if currentAttacker then return end
        
        -- Check if target is still the same
        if protectTarget ~= target then
            if connection then connection:Disconnect() end
            return
        end
        
        if tHRP and tHRP.Parent then
            -- Stay behind target with specified distance
            Protect.Shared.hrp.CFrame = CFrame.new(
                tHRP.Position + Vector3.new(0, Protect.Shared.HEIGHT, 0) + tHRP.CFrame.LookVector * distanceOffset, 
                tHRP.Position
            )
            Protect.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
            Protect.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    
    return connection
end

-- Function to wield behind attacker (close distance)
local function wieldBehindAttacker(attacker)
    if not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then return nil end
    
    local aChar = attacker.Character
    if not aChar then return nil end
    
    local aHRP = aChar:FindFirstChild("HumanoidRootPart")
    if not aHRP then return nil end
    
    local connection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not currentAttacker or not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        -- Check if we're still attacking the same person
        if currentAttacker ~= attacker then
            if connection then connection:Disconnect() end
            return
        end
        
        if aHRP and aHRP.Parent then
            -- Stay close behind attacker (regular bring distance)
            Protect.Shared.hrp.CFrame = CFrame.new(
                aHRP.Position + Vector3.new(0, Protect.Shared.HEIGHT, 0) + aHRP.CFrame.LookVector * Protect.Shared.BACK_OFFSET, 
                aHRP.Position
            )
            Protect.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
            Protect.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    
    return connection
end

-- Function to attack attacker (3 ATTACKS)
local function attackAttacker(attacker)
    if not attacker or not attacker.Character then return end
    
    Protect.Shared.updateStatus("Attacking "..attacker.Name.. "...", Color3.fromRGB(220, 38, 38))
    
    local aChar = attacker.Character
    local aHRP = aChar and aChar:FindFirstChild("HumanoidRootPart")
    
    if not aHRP then 
        Protect.Shared.updateStatus(attacker.Name.. " has no HRP", Color3.fromRGB(246, 59, 59))
        return 
    end
    
    -- Set current attacker
    currentAttacker = attacker
    
    -- Stop protecting temporarily
    if protectConnection then
        protectConnection:Disconnect()
        protectConnection = nil
    end
    
    -- Wield behind attacker (close distance)
    local wieldConn = wieldBehindAttacker(attacker)
    
    if not wieldConn then
        Protect.Shared.updateStatus("Failed to wield behind "..attacker.Name, Color3.fromRGB(246, 59, 59))
        currentAttacker = nil
        return
    end
    
    -- ATTACK 3 TIMES
    Protect.Shared.updateStatus("Attacking "..attacker.Name.. " (3 hits)...", Color3.fromRGB(246, 189, 59))
    
    for attackCount = 1, 3 do
        -- Use all attack remotes
        Protect.Shared.useAllAttackRemotes()
        
        -- Update status
        Protect.Shared.updateStatus("Hit "..attackCount.."/3 on "..attacker.Name, Color3.fromRGB(246, 189, 59))
        
        -- Wait between attacks
        if attackCount < 3 then
            task.wait(0.3) -- 0.3 seconds between attacks
        end
    end
    
    -- Wait a moment after final attack
    task.wait(0.5)
    
    -- Stop wielding behind attacker
    if wieldConn then
        wieldConn:Disconnect()
        wieldConn = nil
    end
    
    -- Clear current attacker
    currentAttacker = nil
    
    -- Return to protecting (only if we're still protecting the same target)
    if Protect.Shared.protecting and protectTarget and protectTarget.Character then
        Protect.Shared.updateStatus("Returning to protect "..protectTarget.Name, Color3.fromRGB(59, 189, 246))
        
        -- Resume wielding behind protected player (20 studs away)
        protectConnection = wieldBehindTarget(protectTarget, -20) -- 20 studs back
    else
        Protect.Shared.updateStatus("Protection ended", Color3.fromRGB(246, 59, 59))
    end
end

-- Track damage to protected player
local function trackDamageDealers()
    if not protectTarget then return end
    
    local lastHealth = 100
    local healthCheckConnection = nil
    
    healthCheckConnection = Protect.Shared.RunService.Heartbeat:Connect(function()
        -- Check if we're still protecting the same target
        if not Protect.Shared.protecting or protectTarget ~= protectTarget then
            if healthCheckConnection then
                healthCheckConnection:Disconnect()
            end
            return
        end
        
        local tChar = protectTarget.Character
        if not tChar then 
            return 
        end
        
        local humanoid = tChar:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- Check if health decreased
        if humanoid.Health < lastHealth then
            local damageTaken = lastHealth - humanoid.Health
            
            if damageTaken > 0 and tick() - lastDamageTime > 1 then -- 1 second cooldown between attack triggers
                lastDamageTime = tick()
                Protect.Shared.updateStatus(protectTarget.Name.. " took "..math.floor(damageTaken).. " damage!", Color3.fromRGB(246, 189, 59))
                
                -- Find who caused the damage (closest player within damage range)
                local potentialAttacker = nil
                local closestDistance = 9999
                
                for _, player in pairs(Protect.Shared.Players:GetPlayers()) do
                    if player ~= Protect.Shared.player and player ~= protectTarget then
                        local pChar = player.Character
                        if pChar then
                            local pHRP = pChar:FindFirstChild("HumanoidRootPart")
                            local tHRP = tChar:FindFirstChild("HumanoidRootPart")
                            
                            if pHRP and tHRP then
                                local distance = (pHRP.Position - tHRP.Position).Magnitude
                                -- Attack range is typically 10-15 studs in most games
                                if distance < 15 and distance < closestDistance then
                                    potentialAttacker = player
                                    closestDistance = distance
                                end
                            end
                        end
                    end
                end
                
                if potentialAttacker then
                    Protect.Shared.updateStatus(potentialAttacker.Name.. " attacked "..protectTarget.Name, Color3.fromRGB(220, 38, 38))
                    attackAttacker(potentialAttacker)
                else
                    Protect.Shared.updateStatus("Unknown attacker", Color3.fromRGB(246, 189, 59))
                end
            end
        end
        
        lastHealth = humanoid.Health
    end)
    
    return healthCheckConnection
end

function Protect.init(Shared)
    Protect.Shared = Shared
end

function Protect.start(targetText)
    -- If already protecting, stop first
    if Protect.Shared.protecting then
        Protect.stop()
        task.wait(0.5) -- Small delay to ensure cleanup
    end
    
    local newTarget = Protect.Shared.findPlayerSmart(targetText)
    if not newTarget then
        Protect.Shared.updateStatus("Player not found", Color3.fromRGB(246, 59, 59))
        return
    end
    
    Protect.Shared.protecting = true
    protectTarget = newTarget
    currentAttacker = nil
    lastDamageTime = 0
    originalPosition = Protect.Shared.savePosition()
    
    Protect.Shared.updateStatus("Protecting "..protectTarget.Name.. "...", Color3.fromRGB(59, 189, 246))
    
    -- Start wielding behind protected player (20 studs away)
    protectConnection = wieldBehindTarget(protectTarget, -20) -- Negative means behind, 20 studs
    
    -- Start tracking damage
    damageConnection = trackDamageDealers()
    
    -- Simple cleanup connection
    cleanupConnection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not Protect.Shared.protecting then
            if cleanupConnection then
                cleanupConnection:Disconnect()
                cleanupConnection = nil
            end
            return
        end
    end)
end

function Protect.stop()
    Protect.Shared.protecting = false
    
    -- Clean up all connections
    cleanupProtectConnections()
    
    -- Clear target
    protectTarget = nil
    
    -- Return to original position
    if originalPosition then
        Protect.Shared.updateStatus("Returning to position...", Color3.fromRGB(246, 189, 59))
        Protect.Shared.smoothTP(originalPosition)
        originalPosition = nil
    end
    
    Protect.Shared.updateStatus("Protection stopped", Color3.fromRGB(59, 246, 105))
end

function Protect.onCharacterAdded()
    -- Reset protect state when character respawns
    Protect.Shared.protecting = false
    cleanupProtectConnections()
    protectTarget = nil
    originalPosition = nil
    lastDamageTime = 0
end

return Protect
