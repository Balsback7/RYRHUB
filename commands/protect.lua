--// Protect Player Command
local Protect = {}

-- Local variables
local protectTarget = nil
local protectConnection = nil
local damageConnection = nil
local originalPosition = nil
local lastDamageTime = 0
local currentAttacker = nil
local isAttacking = false

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
    
    currentAttacker = nil
    isAttacking = false
end

-- Function to wield behind target with distance (FIXED)
local function wieldBehindTarget(target, distanceOffset)
    if not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then return nil end
    
    local connection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not Protect.Shared.protecting or not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        -- Don't wield if we're currently attacking someone
        if isAttacking then return end
        
        local tChar = target.Character
        if not tChar then return end
        
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end
        
        -- Stay behind target with specified distance (FIXED CALCULATION)
        local targetPosition = tHRP.Position
        local targetLookVector = tHRP.CFrame.LookVector
        
        -- Calculate position behind target
        local offsetPosition = targetPosition + (targetLookVector * distanceOffset) + Vector3.new(0, Protect.Shared.HEIGHT, 0)
        
        -- Smooth teleport to position
        Protect.Shared.hrp.CFrame = CFrame.new(offsetPosition, targetPosition)
        Protect.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
        Protect.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    
    return connection
end

-- Function to wield behind attacker (close distance) - FIXED
local function wieldBehindAttacker(attacker)
    if not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then return nil end
    
    local connection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not isAttacking or not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        local aChar = attacker.Character
        if not aChar then 
            if connection then connection:Disconnect() end
            return
        end
        
        local aHRP = aChar:FindFirstChild("HumanoidRootPart")
        if not aHRP then return end
        
        -- Stay close behind attacker (regular bring distance) - FIXED CALCULATION
        local attackerPosition = aHRP.Position
        local attackerLookVector = aHRP.CFrame.LookVector
        
        -- Calculate position behind attacker
        local offsetPosition = attackerPosition + (attackerLookVector * Protect.Shared.BACK_OFFSET) + Vector3.new(0, Protect.Shared.HEIGHT, 0)
        
        -- Smooth teleport to position
        Protect.Shared.hrp.CFrame = CFrame.new(offsetPosition, attackerPosition)
        Protect.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
        Protect.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    
    return connection
end

-- Function to teleport to position (FIXED - no wielding, just teleport)
local function teleportToPosition(position, lookAt)
    if not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then return false end
    
    Protect.Shared.hrp.CFrame = CFrame.new(position, lookAt or position)
    Protect.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
    Protect.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
    
    return true
end

-- Function to attack attacker (3 ATTACKS) - FIXED
local function attackAttacker(attacker)
    if not attacker or not attacker.Character then return end
    
    Protect.Shared.updateStatus("Attacking "..attacker.Name.. "...", Color3.fromRGB(220, 38, 38))
    
    local aChar = attacker.Character
    local aHRP = aChar and aChar:FindFirstChild("HumanoidRootPart")
    
    if not aHRP then 
        Protect.Shared.updateStatus(attacker.Name.. " has no HRP", Color3.fromRGB(246, 59, 59))
        return 
    end
    
    -- Set attacking state
    isAttacking = true
    currentAttacker = attacker
    
    -- Stop protecting temporarily
    if protectConnection then
        protectConnection:Disconnect()
        protectConnection = nil
    end
    
    -- Get attacker's position for teleporting
    local attackerPosition = aHRP.Position
    local attackerLookVector = aHRP.CFrame.LookVector
    
    -- Calculate position behind attacker
    local behindAttackerPosition = attackerPosition + (attackerLookVector * Protect.Shared.BACK_OFFSET) + Vector3.new(0, Protect.Shared.HEIGHT, 0)
    
    -- Teleport behind attacker (FIXED - no wielding, direct teleport)
    if not teleportToPosition(behindAttackerPosition, attackerPosition) then
        Protect.Shared.updateStatus("Failed to teleport behind "..attacker.Name, Color3.fromRGB(246, 59, 59))
        isAttacking = false
        currentAttacker = nil
        return
    end
    
    task.wait(0.2) -- Small delay to ensure teleport
    
    -- ATTACK 3 TIMES while staying behind attacker
    Protect.Shared.updateStatus("Attacking "..attacker.Name.. " (3 hits)...", Color3.fromRGB(246, 189, 59))
    
    for attackCount = 1, 3 do
        -- Update position to stay behind attacker
        if aHRP and aHRP.Parent then
            attackerPosition = aHRP.Position
            attackerLookVector = aHRP.CFrame.LookVector
            behindAttackerPosition = attackerPosition + (attackerLookVector * Protect.Shared.BACK_OFFSET) + Vector3.new(0, Protect.Shared.HEIGHT, 0)
            teleportToPosition(behindAttackerPosition, attackerPosition)
        end
        
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
    
    -- Clear attacking state
    isAttacking = false
    currentAttacker = nil
    
    -- Return to protecting
    if Protect.Shared.protecting and protectTarget and protectTarget.Character then
        Protect.Shared.updateStatus("Returning to protect "..protectTarget.Name, Color3.fromRGB(59, 189, 246))
        
        -- Get protected target position
        local tChar = protectTarget.Character
        if tChar then
            local tHRP = tChar:FindFirstChild("HumanoidRootPart")
            if tHRP then
                local targetPosition = tHRP.Position
                local targetLookVector = tHRP.CFrame.LookVector
                
                -- Calculate position 50 studs behind target
                local behindTargetPosition = targetPosition + (targetLookVector * -50) + Vector3.new(0, Protect.Shared.HEIGHT, 0)
                
                -- Teleport to position (no wielding, direct teleport)
                teleportToPosition(behindTargetPosition, targetPosition)
            end
        end
        
        -- Resume wielding behind protected player (50 studs away)
        protectConnection = wieldBehindTarget(protectTarget, -50) -- 50 studs back
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
        if not Protect.Shared.protecting or not protectTarget then
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
    isAttacking = false
    lastDamageTime = 0
    originalPosition = Protect.Shared.savePosition()
    
    Protect.Shared.updateStatus("Protecting "..protectTarget.Name.. "...", Color3.fromRGB(59, 189, 246))
    
    -- Teleport to initial position 50 studs behind target
    local tChar = protectTarget.Character
    if tChar then
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if tHRP then
            local targetPosition = tHRP.Position
            local targetLookVector = tHRP.CFrame.LookVector
            
            -- Calculate position 50 studs behind target
            local behindTargetPosition = targetPosition + (targetLookVector * -50) + Vector3.new(0, Protect.Shared.HEIGHT, 0)
            
            -- Teleport to position
            teleportToPosition(behindTargetPosition, targetPosition)
        end
    end
    
    task.wait(0.3) -- Small delay
    
    -- Start wielding behind protected player (50 studs away)
    protectConnection = wieldBehindTarget(protectTarget, -50) -- Negative means behind, 50 studs
    
    -- Start tracking damage
    damageConnection = trackDamageDealers()
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
