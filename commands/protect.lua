--// Protect Player Command
local Protect = {}

-- Local variables
local protectTarget = nil
local protectConnection = nil
local damageConnection = nil
local originalPosition = nil

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

-- Function to attack attacker until ragdoll
local function attackUntilRagdoll(attacker)
    if not attacker or not attacker.Character then return end
    
    Protect.Shared.updateStatus("Attacking "..attacker.Name.."...", Color3.fromRGB(220, 38, 38))
    
    local aChar = attacker.Character
    local aHRP = aChar and aChar:FindFirstChild("HumanoidRootPart")
    
    if not aHRP then return end
    
    -- Wield behind attacker
    local wieldConn = nil
    wieldConn = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not Protect.Shared.protecting or not Protect.Shared.hrp or not Protect.Shared.hrp.Parent then
            if wieldConn then wieldConn:Disconnect() end
            return
        end
        
        if aHRP and aHRP.Parent then
            Protect.Shared.hrp.CFrame = CFrame.new(
                aHRP.Position + Vector3.new(0, Protect.Shared.HEIGHT, 0) + aHRP.CFrame.LookVector * Protect.Shared.BACK_OFFSET, 
                aHRP.Position
            )
        end
    end)
    
    -- Attack until ragdoll
    local attempts = 0
    local maxAttempts = 30
    
    while Protect.Shared.protecting and attempts < maxAttempts do
        -- Check if attacker is ragdolled
        if aChar:FindFirstChild("RagdollTrigger", true) then
            Protect.Shared.updateStatus(attacker.Name.. " ragdolled!", Color3.fromRGB(59, 246, 105))
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
    end
    
    -- Return to wielding behind protected player
    if Protect.Shared.protecting and protectTarget then
        Protect.Shared.updateStatus("Returning to protect "..protectTarget.Name, Color3.fromRGB(59, 189, 246))
    end
end

-- Monitor damage to protected player
local function monitorDamage()
    if damageConnection then
        damageConnection:Disconnect()
        damageConnection = nil
    end
    
    if not protectTarget or not Protect.Shared.protecting then return end
    
    local tChar = protectTarget.Character
    if not tChar then return end
    
    local humanoid = tChar:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    damageConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if not Protect.Shared.protecting or not protectTarget then return end
        
        -- Check who caused damage (simplified - in real game you'd need more complex detection)
        -- For now, we'll check all players and attack anyone nearby
        for _, player in pairs(Protect.Shared.Players:GetPlayers()) do
            if player ~= Protect.Shared.player and player ~= protectTarget then
                local pChar = player.Character
                if pChar then
                    local pHRP = pChar:FindFirstChild("HumanoidRootPart")
                    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
                    
                    if pHRP and tHRP then
                        local distance = (pHRP.Position - tHRP.Position).Magnitude
                        if distance < 20 then -- Attack anyone within 20 studs
                            Protect.Shared.updateStatus(player.Name.. " is near "..protectTarget.Name, Color3.fromRGB(246, 189, 59))
                            attackUntilRagdoll(player)
                            break
                        end
                    end
                end
            end
        end
    end)
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
    originalPosition = Protect.Shared.savePosition()
    
    Protect.Shared.updateStatus("Protecting "..protectTarget.Name.. "...", Color3.fromRGB(59, 189, 246))
    
    -- Start wielding behind protected player
    protectConnection = wieldBehindTarget(protectTarget)
    
    -- Start monitoring for damage
    monitorDamage()
    
    -- Also periodically check for nearby threats
    Protect.Shared.protectConnection = Protect.Shared.RunService.Heartbeat:Connect(function()
        if not Protect.Shared.protecting or not protectTarget then
            if Protect.Shared.protectConnection then
                Protect.Shared.protectConnection:Disconnect()
            end
            return
        end
        
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
        
        -- Check for nearby players who might attack
        for _, player in pairs(Protect.Shared.Players:GetPlayers()) do
            if player ~= Protect.Shared.player and player ~= protectTarget then
                local pChar = player.Character
                if pChar then
                    local pHRP = pChar:FindFirstChild("HumanoidRootPart")
                    if pHRP then
                        local distance = (pHRP.Position - tHRP.Position).Magnitude
                        if distance < 15 then -- Attack anyone getting too close
                            Protect.Shared.updateStatus(player.Name.. " is getting close!", Color3.fromRGB(246, 189, 59))
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
    protectTarget = nil
    originalPosition = nil
end

return Protect
