--// Protect Player Command
local Protect = {}

-- Local variables
local protectTargets = {}  -- Changed from single target to table
local protectConnections = {}  -- Multiple connections for multiple targets
local damageConnections = {}  -- Multiple damage trackers
local originalPosition = nil
local lastDamageTime = 0
local currentAttacker = nil
local isAttacking = false
local cleanupConnections = {}  -- Multiple cleanup connections

-- Function to parse multiple player names
local function parsePlayerNames(inputText)
    local players = {}
    local names = string.split(inputText, ",")
    
    for _, name in ipairs(names) do
        name = string.trim(name)
        if name ~= "" then
            local player = Protect.Shared.findPlayerSmart(name)
            if player then
                table.insert(players, player)
            end
        end
    end
    
    return players
end

-- Function to wield behind multiple targets (rotates between them)
local function wieldBehindTargets(targets, distanceOffset)
    if not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then return nil end
    if #targets == 0 then return nil end
    
    local currentTargetIndex = 1
    local lastSwitchTime = tick()
    local switchInterval = 3 -- Switch target every 3 seconds
    
    local connection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not Protect.Shared.protecting or not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        -- Don't wield if we're currently attacking someone
        if isAttacking then return end
        
        -- Switch target every few seconds if protecting multiple players
        if #targets > 1 and tick() - lastSwitchTime > switchInterval then
            currentTargetIndex = (currentTargetIndex % #targets) + 1
            lastSwitchTime = tick()
        end
        
        local target = targets[currentTargetIndex]
        if not target then return end
        
        local tChar = target.Character
        if not tChar then return end
        
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end
        
        if tHRP and tHRP.Parent then
            -- Stay behind target with specified distance (50 studs)
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

-- Function to wield behind attacker (close distance) - FIXED
local function wieldBehindAttacker(attacker)
    if not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then return nil end
    
    local aChar = attacker.Character
    if not aChar then return nil end
    
    local aHRP = aChar:FindFirstChild("HumanoidRootPart")
    if not aHRP then return nil end
    
    local lastValidPosition = aHRP.Position
    local stuckCheckTime = tick()
    
    local connection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not isAttacking or not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        -- Check if we're still attacking the same person
        if currentAttacker ~= attacker then
            if connection then connection:Disconnect() end
            return
        end
        
        local currentChar = attacker.Character
        if not currentChar or currentChar ~= aChar then
            if connection then connection:Disconnect() end
            return
        end
        
        local currentHRP = currentChar:FindFirstChild("HumanoidRootPart")
        if not currentHRP then 
            if connection then connection:Disconnect() end
            return
        end
        
        -- Update last valid position
        lastValidPosition = currentHRP.Position
        
        -- Stay close behind attacker (regular bring distance)
        Protect.Shared.hrp.CFrame = CFrame.new(
            currentHRP.Position + Vector3.new(0, Protect.Shared.HEIGHT, 0) + currentHRP.CFrame.LookVector * Protect.Shared.BACK_OFFSET, 
            currentHRP.Position
        )
        Protect.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
        Protect.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    
    return connection
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
    
    -- Set current attacker and attacking state
    currentAttacker = attacker
    isAttacking = true
    
    -- Stop protecting temporarily
    for _, conn in pairs(protectConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    protectConnections = {}
    
    -- Wield behind attacker (close distance) - FIXED
    local wieldConn = wieldBehindAttacker(attacker)
    
    if not wieldConn then
        Protect.Shared.updateStatus("Failed to wield behind "..attacker.Name, Color3.fromRGB(246, 59, 59))
        currentAttacker = nil
        isAttacking = false
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
    isAttacking = false
    
    -- Return to protecting
    if Protect.Shared.protecting and #protectTargets > 0 then
        Protect.Shared.updateStatus("Returning to protect players...", Color3.fromRGB(59, 189, 246))
        
        -- Resume wielding behind protected players (50 studs away)
        protectConnections[1] = wieldBehindTargets(protectTargets, -50) -- 50 studs back
    else
        Protect.Shared.updateStatus("Protection ended", Color3.fromRGB(246, 59, 59))
    end
end

-- Track damage to all protected players
local function trackDamageDealersForTarget(target)
    if not target then return nil end
    
    local lastHealth = 100
    local healthCheckConnection = nil
    
    healthCheckConnection = Protect.Shared.RunService.Heartbeat:Connect(function()
        -- Check if we're still protecting this target
        if not Protect.Shared.protecting or not table.find(protectTargets, target) then
            if healthCheckConnection then
                healthCheckConnection:Disconnect()
            end
            return
        end
        
        local tChar = target.Character
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
                Protect.Shared.updateStatus(target.Name.. " took "..math.floor(damageTaken).. " damage!", Color3.fromRGB(246, 189, 59))
                
                -- Find who caused the damage (closest player within damage range)
                local potentialAttacker = nil
                local closestDistance = 9999
                
                for _, player in pairs(Protect.Shared.Players:GetPlayers()) do
                    if player ~= Protect.Shared.player and not table.find(protectTargets, player) then
                        local pChar = player.Character
                        if pChar then
                            local pHRP = pChar:FindFirstChild("HumanoidRootPart")
                            local tHRP = tChar:FindFirstChild("HumanoidRootPart")
                            
                            if pHRP and tHRP then
                                local distance = (pHRP.Position - tHRP.Position).Magnitude
                                -- Attack range is typically 10-15 studs in most games
                                if distance < 20 and distance < closestDistance then
                                    potentialAttacker = player
                                    closestDistance = distance
                                end
                            end
                        end
                    end
                end
                
                if potentialAttacker and not isAttacking then
                    Protect.Shared.updateStatus(potentialAttacker.Name.. " attacked "..target.Name, Color3.fromRGB(220, 38, 38))
                    attackAttacker(potentialAttacker)
                end
            end
        end
        
        lastHealth = humanoid.Health
    end)
    
    return healthCheckConnection
end

-- Clean up all connections
local function cleanupProtectConnections()
    isAttacking = false
    currentAttacker = nil
    
    -- Clean up protect connections
    for _, conn in pairs(protectConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    protectConnections = {}
    
    -- Clean up damage connections
    for _, conn in pairs(damageConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    damageConnections = {}
    
    -- Clean up cleanup connections
    for _, conn in pairs(cleanupConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    cleanupConnections = {}
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
    
    -- Parse multiple player names
    local newTargets = parsePlayerNames(targetText)
    if #newTargets == 0 then
        Protect.Shared.updateStatus("No valid players found", Color3.fromRGB(246, 59, 59))
        return
    end
    
    -- Limit to 5 players
    if #newTargets > 5 then
        Protect.Shared.updateStatus("Maximum 5 players, using first 5", Color3.fromRGB(246, 189, 59))
        while #newTargets > 5 do
            table.remove(newTargets)
        end
    end
    
    Protect.Shared.protecting = true
    protectTargets = newTargets
    currentAttacker = nil
    isAttacking = false
    lastDamageTime = 0
    originalPosition = Protect.Shared.savePosition()
    
    -- Create status message with all protected players
    local targetNames = ""
    for i, target in ipairs(protectTargets) do
        targetNames = targetNames .. target.Name
        if i < #protectTargets then
            targetNames = targetNames .. ", "
        end
    end
    
    Protect.Shared.updateStatus("Protecting "..targetNames.. "...", Color3.fromRGB(59, 189, 246))
    
    -- Start wielding behind protected players (50 studs away)
    protectConnections[1] = wieldBehindTargets(protectTargets, -50) -- 50 studs back
    
    -- Start tracking damage for each protected player
    for i, target in ipairs(protectTargets) do
        damageConnections[i] = trackDamageDealersForTarget(target)
    end
    
    -- Simple cleanup connection
    cleanupConnections[1] = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not Protect.Shared.protecting then
            cleanupProtectConnections()
            return
        end
    end)
end

function Protect.stop()
    Protect.Shared.protecting = false
    
    -- Clean up all connections
    cleanupProtectConnections()
    
    -- Clear targets
    protectTargets = {}
    
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
    protectTargets = {}
    originalPosition = nil
    lastDamageTime = 0
end

return Protect
