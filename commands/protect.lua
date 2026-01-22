--// Protect Player Command
local Protect = {}

-- Local variables
local protectTarget = nil
local protectConnection = nil
local damageConnection = nil
local originalPosition = nil
local lastDamageTime = 0
local currentAttacker = nil
local recentlyAttackedPlayers = {} -- Track players we've recently attacked
local ATTACK_COOLDOWN = 10 -- Seconds before attacking same player again

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

-- Check if we should attack this player (cooldown check)
local function shouldAttackPlayer(player)
    if not player then return false end
    
    -- Check if we've recently attacked this player
    if recentlyAttackedPlayers[player] then
        local timeSinceLastAttack = tick() - recentlyAttackedPlayers[player]
        if timeSinceLastAttack < ATTACK_COOLDOWN then
            return false -- Still in cooldown
        end
    end
    
    return true
end

-- Mark player as recently attacked
local function markPlayerAttacked(player)
    recentlyAttackedPlayers[player] = tick()
end

-- Clean up old cooldowns
local function cleanupCooldowns()
    local currentTime = tick()
    local playersToRemove = {}
    
    for player, attackTime in pairs(recentlyAttackedPlayers) do
        if currentTime - attackTime > ATTACK_COOLDOWN then
            table.insert(playersToRemove, player)
        end
    end
    
    for _, player in ipairs(playersToRemove) do
        recentlyAttackedPlayers[player] = nil
    end
end

-- Function to attack attacker (ONE HIT ONLY)
local function attackAttacker(attacker)
    if not attacker or not attacker.Character then return end
    
    -- Check cooldown
    if not shouldAttackPlayer(attacker) then
        Protect.Shared.updateStatus("Recently attacked "..attacker.Name.. ", skipping", Color3.fromRGB(246, 189, 59))
        return
    end
    
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
    
    -- ONE HIT ONLY - Use all attack remotes once
    Protect.Shared.updateStatus("Hitting "..attacker.Name.. " once...", Color3.fromRGB(246, 189, 59))
    Protect.Shared.useAllAttackRemotes()
    
    -- Mark as recently attacked
    markPlayerAttacked(attacker)
    
    -- Wait a moment for the hit
    task.wait(0.5)
    
    -- Stop wielding behind attacker
    if wieldConn then
        wieldConn:Disconnect()
        wieldConn = nil
    end
    
    -- Clear current attacker
    currentAttacker = nil
    
    -- Clean up old cooldowns
    cleanupCooldowns()
    
    -- Return to protecting
    if Protect.Shared.protecting and protectTarget and protectTarget.Character then
        Protect.Shared.updateStatus("Returning to protect "..protectTarget.Name, Color3.fromRGB(59, 189, 246))
        
        -- Resume wielding behind protected player (10 studs away)
        protectConnection = wieldBehindTarget(protectTarget, -10) -- 10 studs back
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
            
            if damageTaken > 0 and tick() - lastDamageTime > 1 then -- 1 second cooldown
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
    if Protect.Shared.protecting then return end
    
    protectTarget = Protect.Shared.findPlayerSmart(targetText)
    if not protectTarget then
        Protect.Shared.updateStatus("Player not found", Color3.fromRGB(246, 59, 59))
        return
    end
    
    Protect.Shared.protecting = true
    currentAttacker = nil
    originalPosition = Protect.Shared.savePosition()
    
    Protect.Shared.updateStatus("Protecting "..protectTarget.Name.. "...", Color3.fromRGB(59, 189, 246))
    
    -- Start wielding behind protected player (10 studs away)
    protectConnection = wieldBehindTarget(protectTarget, -10) -- Negative means behind, 10 studs
    
    -- Start tracking damage
    damageConnection = trackDamageDealers()
    
    -- Periodically clean up cooldowns
    local cleanupConnection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not Protect.Shared.protecting then
            cleanupConnection:Disconnect()
            return
        end
        
        cleanupCooldowns()
    end)
    
    Protect.Shared.protectConnection = cleanupConnection
end

function Protect.stop()
    Protect.Shared.protecting = false
    currentAttacker = nil
    protectTarget = nil
    
    -- Disconnect all connections
    if protectConnection then
        protectConnection:Disconnect()
        protectConnection = nil
    end
    
    if damageConnection then
        damageConnection:Disconnect()
        damageConnection = nil
    end
    
    if Protect.Shared.protectConnection then
        Protect.Shared.protectConnection:Disconnect()
        Protect.Shared.protectConnection = nil
    end
    
    -- Clear cooldowns
    recentlyAttackedPlayers = {}
    
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
    currentAttacker = nil
    protectTarget = nil
    originalPosition = nil
    lastDamageTime = 0
    recentlyAttackedPlayers = {}
end

return Protect
