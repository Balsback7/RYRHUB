--// Protect Player Command
local Protect = {}

-- Local variables
local protectTarget = nil
local protectConnection = nil
local damageConnection = nil
local originalPosition = nil
local lastDamageTime = 0
local lastAttacker = nil
local isAttackingAttacker = false

-- Function to wield behind target
local function wieldBehindTarget(target)
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
        
        if tHRP and tHRP.Parent then
            -- Stay behind target (height 3, back offset -3)
            Protect.Shared.hrp.CFrame = CFrame.new(
                tHRP.Position + Vector3.new(0, Protect.Shared.HEIGHT, 0) + tHRP.CFrame.LookVector * Protect.Shared.BACK_OFFSET, 
                tHRP.Position
            )
            Protect.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
            Protect.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    
    return connection
end

-- Function to wield behind attacker (EXACTLY like bring command)
local function wieldBehindAttacker(attacker)
    if not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then return nil end
    
    local aChar = attacker.Character
    if not aChar then return nil end
    
    local aHRP = aChar:FindFirstChild("HumanoidRootPart")
    if not aHRP then return nil end
    
    local connection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not isAttackingAttacker or not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        if aHRP and aHRP.Parent then
            -- Stay behind attacker (height 3, back offset -3) - EXACTLY like bring command
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

-- Function to attack attacker until ragdoll
local function attackUntilRagdoll(attacker)
    if not attacker or not attacker.Character then return end
    
    Protect.Shared.updateStatus("Attacking "..attacker.Name.. "...", Color3.fromRGB(220, 38, 38))
    
    local aChar = attacker.Character
    local aHRP = aChar and aChar:FindFirstChild("HumanoidRootPart")
    
    if not aHRP then 
        Protect.Shared.updateStatus(attacker.Name.. " has no HRP", Color3.fromRGB(246, 59, 59))
        return 
    end
    
    -- Stop protecting temporarily
    isAttackingAttacker = true
    if protectConnection then
        protectConnection:Disconnect()
        protectConnection = nil
    end
    
    -- Wield behind attacker (EXACTLY like bring command)
    local wieldConn = wieldBehindAttacker(attacker)
    
    if not wieldConn then
        Protect.Shared.updateStatus("Failed to wield behind "..attacker.Name, Color3.fromRGB(246, 59, 59))
        isAttackingAttacker = false
        return
    end
    
    -- Attack until ragdoll
    local attempts = 0
    local maxAttempts = 30
    
    Protect.Shared.updateStatus("Wielding behind "..attacker.Name.. " and attacking...", Color3.fromRGB(246, 189, 59))
    
    while isAttackingAttacker and attempts < maxAttempts do
        -- Check if attacker is ragdolled
        if aChar:FindFirstChild("RagdollTrigger", true) then
            Protect.Shared.updateStatus(attacker.Name.. " ragdolled!", Color3.fromRGB(59, 246, 105))
            break
        end
        
        -- Check if attacker is dead
        local humanoid = aChar:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            Protect.Shared.updateStatus(attacker.Name.. " is down!", Color3.fromRGB(59, 246, 105))
            break
        end
        
        -- Check if attacker still has character
        if not attacker.Character or attacker.Character ~= aChar then
            Protect.Shared.updateStatus(attacker.Name.. " character changed", Color3.fromRGB(246, 189, 59))
            break
        end
        
        -- Attack with all remotes
        Protect.Shared.useAllAttackRemotes()
        
        attempts += 1
        
        if attempts % 5 == 0 then
            Protect.Shared.updateStatus("Attacking... ("..attempts.."/"..maxAttempts..")", Color3.fromRGB(246, 189, 59))
        end
        
        task.wait(0.2)
    end
    
    -- Stop wielding behind attacker
    if wieldConn then
        wieldConn:Disconnect()
        wieldConn = nil
    end
    
    -- Resume protecting
    isAttackingAttacker = false
    
    -- Return to wielding behind protected player
    if Protect.Shared.protecting and protectTarget and protectTarget.Character then
        Protect.Shared.updateStatus("Returning to protect "..protectTarget.Name, Color3.fromRGB(59, 189, 246))
        
        -- Resume wielding behind protected player
        protectConnection = wieldBehindTarget(protectTarget)
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
            Protect.Shared.updateStatus(protectTarget.Name.. " has no character", Color3.fromRGB(246, 189, 59))
            return 
        end
        
        local humanoid = tChar:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- Check if health decreased
        if humanoid.Health < lastHealth then
            local damageTaken = lastHealth - humanoid.Health
            
            if damageTaken > 0 and tick() - lastDamageTime > 2 then -- Cooldown to prevent spam
                lastDamageTime = tick()
                Protect.Shared.updateStatus(protectTarget.Name.. " took "..damageTaken.. " damage!", Color3.fromRGB(246, 189, 59))
                
                -- Find the closest player who might have caused damage
                local closestAttacker = nil
                local closestDistance = 9999
                
                for _, player in pairs(Protect.Shared.Players:GetPlayers()) do
                    if player ~= Protect.Shared.player and player ~= protectTarget then
                        local pChar = player.Character
                        if pChar then
                            local pHRP = pChar:FindFirstChild("HumanoidRootPart")
                            local tHRP = tChar:FindFirstChild("HumanoidRootPart")
                            
                            if pHRP and tHRP then
                                local distance = (pHRP.Position - tHRP.Position).Magnitude
                                if distance < 30 and distance < closestDistance then -- Within 30 studs
                                    closestAttacker = player
                                    closestDistance = distance
                                end
                            end
                        end
                    end
                end
                
                if closestAttacker then
                    Protect.Shared.updateStatus(closestAttacker.Name.. " likely caused damage!", Color3.fromRGB(220, 38, 38))
                    lastAttacker = closestAttacker
                    attackUntilRagdoll(closestAttacker)
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
    isAttackingAttacker = false
    originalPosition = Protect.Shared.savePosition()
    
    Protect.Shared.updateStatus("Protecting "..protectTarget.Name.. "...", Color3.fromRGB(59, 189, 246))
    
    -- Start wielding behind protected player
    protectConnection = wieldBehindTarget(protectTarget)
    
    -- Start tracking damage
    damageConnection = trackDamageDealers()
    
    -- Also periodically check for threats
    Protect.Shared.protectConnection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not Protect.Shared.protecting or not protectTarget then
            if Protect.Shared.protectConnection then
                Protect.Shared.protectConnection:Disconnect()
            end
            return
        end
        
        -- Don't check for threats while actively attacking someone
        if isAttackingAttacker then return end
        
        local tChar = protectTarget.Character
        if not tChar then
            Protect.Shared.updateStatus(protectTarget.Name.. " has no character", Color3.fromRGB(246, 189, 59))
            Protect.stop()
            return
        end
        
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then
            Protect.Shared.updateStatus(protectTarget.Name.. " has no HRP", Color3.fromRGB(246, 189, 59))
            Protect.stop()
            return
        end
        
        -- Check for players holding weapons or attacking animations
        for _, player in pairs(Protect.Shared.Players:GetPlayers()) do
            if player ~= Protect.Shared.player and player ~= protectTarget and not isAttackingAttacker then
                local pChar = player.Character
                if pChar then
                    local pHRP = pChar:FindFirstChild("HumanoidRootPart")
                    if pHRP then
                        local distance = (pHRP.Position - tHRP.Position).Magnitude
                        
                        -- Check if player is holding a weapon or tool
                        local hasWeapon = false
                        for _, tool in pairs(pChar:GetChildren()) do
                            if tool:IsA("Tool") then
                                hasWeapon = true
                                break
                            end
                        end
                        
                        -- Attack if armed and close, or if they were the last attacker
                        if (hasWeapon and distance < 20) or (player == lastAttacker and distance < 30) then
                            Protect.Shared.updateStatus(player.Name.. " is a threat!", Color3.fromRGB(246, 189, 59))
                            attackUntilRagdoll(player)
                            break
                        end
                    end
                end
            end
        end
    end)
end

function Protect.stop()
    Protect.Shared.protecting = false
    isAttackingAttacker = false
    protectTarget = nil
    lastAttacker = nil
    
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
    isAttackingAttacker = false
    protectTarget = nil
    lastAttacker = nil
    originalPosition = nil
    lastDamageTime = 0
end

return Protect
