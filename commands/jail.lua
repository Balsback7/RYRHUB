--// Jail Command
local Jail = {}

function Jail.init(Shared)
    Jail.Shared = Shared
end

-- Improved prompt trigger function
local function triggerProximityPrompt(prompt)
    if not prompt then return false end
    
    if fireproximityprompt then
        -- If using executor, fire the prompt
        fireproximityprompt(prompt)
        return true
    else
        -- For non-executor
        prompt.HoldDuration = 0
        prompt:InputHoldBegin()
        task.wait(0.1)
        prompt:InputHoldEnd()
        return true
    end
end

-- Function to wait for target to ragdoll
local function waitForRagdoll(target)
    local startTime = tick()
    local maxWaitTime = 10 -- Maximum 10 seconds wait
    
    Jail.Shared.updateStatus("Waiting for target to ragdoll...", Color3.fromRGB(246, 189, 59))
    
    while tick() - startTime < maxWaitTime do
        local tChar = target.Character
        if tChar then
            -- Check if ragdolled
            if tChar:FindFirstChild("RagdollTrigger", true) then
                Jail.Shared.updateStatus("Target ragdolled!", Color3.fromRGB(59, 246, 105))
                return true
            end
            
            -- Also check if humanoid is dead or ragdolled through other methods
            local humanoid = tChar:FindFirstChild("Humanoid")
            if humanoid then
                if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Physics then
                    Jail.Shared.updateStatus("Target is down!", Color3.fromRGB(59, 246, 105))
                    return true
                end
            end
        end
        
        -- Small wait between checks
        task.wait(0.5)
    end
    
    Jail.Shared.updateStatus("Timeout - target did not ragdoll", Color3.fromRGB(246, 59, 59))
    return false
end

-- Function to find jail cage and prompt
local function findJailCage()
    local policeStation = workspace:FindFirstChild("PoliceStation")
    if not policeStation then
        Jail.Shared.updateStatus("PoliceStation not found", Color3.fromRGB(246, 59, 59))
        return nil, nil
    end
    
    -- Search for cage or jail-related parts
    local cage = nil
    local prompt = nil
    
    -- Common jail/cage names to search for
    local jailNames = {
        "Cage", "Jail", "Cell", "Prison", "CageDoor", "JailDoor",
        "Cage1", "Cage2", "Cage3", "Jail1", "Jail2", "Jail3"
    }
    
    for _, obj in pairs(policeStation:GetDescendants()) do
        -- First, look for proximity prompts
        if obj:IsA("ProximityPrompt") then
            prompt = obj
            
            -- Try to find the parent cage/part
            local parent = obj.Parent
            if parent and (parent:IsA("Part") or parent:IsA("MeshPart") or parent:IsA("Model")) then
                cage = parent
                Jail.Shared.updateStatus("Found jail prompt: "..obj.Name.. " on "..parent.Name, Color3.fromRGB(59, 246, 105))
                return cage, prompt
            end
        end
        
        -- Also search for parts with jail-related names
        for _, jailName in ipairs(jailNames) do
            if obj.Name:lower():find(jailName:lower()) then
                -- Check if this part has a proximity prompt
                local childPrompt = obj:FindFirstChildOfClass("ProximityPrompt")
                if childPrompt then
                    cage = obj
                    prompt = childPrompt
                    Jail.Shared.updateStatus("Found jail: "..obj.Name, Color3.fromRGB(59, 246, 105))
                    return cage, prompt
                end
            end
        end
    end
    
    -- If no prompt found, just find any cage-like structure
    for _, obj in pairs(policeStation:GetDescendants()) do
        for _, jailName in ipairs(jailNames) do
            if obj.Name:lower():find(jailName:lower()) and (obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model")) then
                cage = obj
                Jail.Shared.updateStatus("Found cage: "..obj.Name, Color3.fromRGB(246, 189, 59))
                return cage, prompt
            end
        end
    end
    
    return cage, prompt
end

-- Function to get position outside the cage
local function getPositionOutsideCage(cage)
    if not cage then
        -- Default position if no cage found
        return CFrame.new(185, 9, 453)
    end
    
    local cagePosition
    
    if cage:IsA("Model") then
        -- Get the primary part or average position
        if cage.PrimaryPart then
            cagePosition = cage.PrimaryPart.Position
        else
            -- Calculate center of model
            local parts = {}
            for _, child in pairs(cage:GetChildren()) do
                if child:IsA("BasePart") then
                    table.insert(parts, child)
                end
            end
            if #parts > 0 then
                local total = Vector3.new(0, 0, 0)
                for _, part in ipairs(parts) do
                    total = total + part.Position
                end
                cagePosition = total / #parts
            else
                cagePosition = cage:GetPivot().Position
            end
        end
    else
        -- It's a single part
        cagePosition = cage.Position
    end
    
    -- Position 5 studs in front of the cage
    local outsidePosition = cagePosition + Vector3.new(0, 0, 5)
    return CFrame.new(outsidePosition.X, outsidePosition.Y + 2, outsidePosition.Z)
end

-- Function to wield behind target (like bring command)
local function wieldBehindTarget(target, duration)
    local wieldConnection = nil
    local startTime = tick()
    
    Jail.Shared.updateStatus("Wielding behind target...", Color3.fromRGB(246, 189, 59))
    
    wieldConnection = Jail.Shared.RunService.Heartbeat:Connect(function()
        local tChar = target.Character
        if not tChar then
            if wieldConnection then wieldConnection:Disconnect() end
            return
        end
        
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP or not tHRP.Parent or not Jail.Shared.hrp or not Jail.Shared.hrp.Parent then
            if wieldConnection then wieldConnection:Disconnect() end
            return
        end
        
        -- Stay behind target (height 3, back offset -3) - EXACTLY like bring command
        Jail.Shared.hrp.CFrame = CFrame.new(
            tHRP.Position + Vector3.new(0, Jail.Shared.HEIGHT, 0) + tHRP.CFrame.LookVector * Jail.Shared.BACK_OFFSET, 
            tHRP.Position
        )
        Jail.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
        Jail.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
        
        -- Stop after duration
        if tick() - startTime >= duration then
            if wieldConnection then wieldConnection:Disconnect() end
        end
    end)
    
    return wieldConnection
end

function Jail.execute(targetText)
    task.spawn(function()
        local originalPosition = Jail.Shared.savePosition()
        
        local target = Jail.Shared.findPlayerSmart(targetText)
        if not target then
            Jail.Shared.updateStatus("Player not found", Color3.fromRGB(246, 59, 59))
            return
        end
        
        Jail.Shared.updateStatus("Jailing "..target.Name.. "...", Color3.fromRGB(220, 38, 38))
        
        -- PHASE 1: Find jail cage first
        Jail.Shared.updateStatus("Phase 1: Locating jail...", Color3.fromRGB(246, 189, 59))
        local cage, prompt = findJailCage()
        
        if not cage then
            Jail.Shared.updateStatus("Jail cage not found", Color3.fromRGB(246, 59, 59))
            Jail.Shared.smoothTP(originalPosition)
            return
        end
        
        -- PHASE 2: Wield behind target and attack until ragdoll
        Jail.Shared.updateStatus("Phase 2: Attacking target...", Color3.fromRGB(246, 189, 59))
        
        local tChar = target.Character
        if not tChar then
            Jail.Shared.updateStatus("Target has no character", Color3.fromRGB(246, 59, 59))
            Jail.Shared.smoothTP(originalPosition)
            return
        end
        
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then
            Jail.Shared.updateStatus("Target has no HRP", Color3.fromRGB(246, 59, 59))
            Jail.Shared.smoothTP(originalPosition)
            return
        end
        
        -- Start wielding behind target (like bring command)
        local wieldConn = wieldBehindTarget(target, 5) -- Wield for 5 seconds while attacking
        
        -- Attack with all remotes while wielding
        local ragdolled = false
        local attempts = 0
        local maxAttempts = 20
        
        Jail.Shared.updateStatus("Using attack remotes...", Color3.fromRGB(246, 189, 59))
        
        while not ragdolled and attempts < maxAttempts do
            -- Check if already ragdolled
            if tChar:FindFirstChild("RagdollTrigger", true) then
                ragdolled = true
                break
            end
            
            -- Use all attack remotes
            Jail.Shared.useAllAttackRemotes()
            
            attempts += 1
            
            -- Update status every few attempts
            if attempts % 5 == 0 then
                Jail.Shared.updateStatus("Attacking... ("..attempts.."/"..maxAttempts..")", Color3.fromRGB(246, 189, 59))
            end
            
            task.wait(0.2)
        end
        
        -- Stop wielding
        if wieldConn then
            wieldConn:Disconnect()
        end
        
        -- PHASE 3: Wait for ragdoll confirmation
        Jail.Shared.updateStatus("Phase 3: Waiting for ragdoll...", Color3.fromRGB(246, 189, 59))
        
        if not waitForRagdoll(target) then
            Jail.Shared.updateStatus("Proceeding anyway...", Color3.fromRGB(246, 189, 59))
        end
        
        -- PHASE 4: Use JALADADEPELOEVENT while wielding behind target
        Jail.Shared.updateStatus("Phase 4: Using jaladaDePeloCharge...", Color3.fromRGB(246, 189, 59))
        
        -- Wield behind target again for the charge
        local chargeWieldConn = wieldBehindTarget(target, 2)
        
        -- Use the charge
        pcall(function()
            Jail.Shared.ReplicatedStorage:WaitForChild("JALADADEPELOEVENT"):FireServer()
            Jail.Shared.updateStatus("Charge fired!", Color3.fromRGB(59, 189, 246))
        end)
        
        -- Wait for charge effect
        task.wait(1)
        
        -- Stop wielding
        if chargeWieldConn then
            chargeWieldConn:Disconnect()
        end
        
        -- Wait a bit more for charge animation
        Jail.Shared.updateStatus("Waiting for charge to complete...", Color3.fromRGB(246, 189, 59))
        task.wait(2)
        
        -- PHASE 5: Move to position outside cage
        Jail.Shared.updateStatus("Phase 5: Moving outside cage...", Color3.fromRGB(246, 189, 59))
        
        local outsidePosition = getPositionOutsideCage(cage)
        Jail.Shared.hrp.CFrame = outsidePosition
        task.wait(0.5)
        
        -- PHASE 6: Trigger jail prompt
        Jail.Shared.updateStatus("Phase 6: Triggering jail...", Color3.fromRGB(246, 189, 59))
        
        local success = false
        
        if prompt then
            Jail.Shared.updateStatus("Found jail prompt, activating...", Color3.fromRGB(59, 246, 105))
            
            -- Move right next to the prompt
            if cage:IsA("BasePart") then
                Jail.Shared.hrp.CFrame = CFrame.new(cage.Position + Vector3.new(0, 2, 0))
            elseif cage:IsA("Model") and cage.PrimaryPart then
                Jail.Shared.hrp.CFrame = CFrame.new(cage.PrimaryPart.Position + Vector3.new(0, 2, 0))
            end
            
            task.wait(0.3)
            
            -- Try to trigger the prompt multiple times
            for attempt = 1, 5 do
                Jail.Shared.updateStatus("Triggering (attempt "..attempt.."/5)...", Color3.fromRGB(246, 189, 59))
                local triggered = triggerProximityPrompt(prompt)
                
                if triggered then
                    Jail.Shared.updateStatus("Jail activated!", Color3.fromRGB(59, 246, 105))
                    success = true
                    break
                end
                
                task.wait(0.3)
            end
        else
            Jail.Shared.updateStatus("No prompt found, trying to interact anyway...", Color3.fromRGB(246, 189, 59))
            
            -- Try to click on the cage
            if cage:IsA("BasePart") then
                -- Move close to the cage
                Jail.Shared.hrp.CFrame = CFrame.new(cage.Position + Vector3.new(0, 2, 3))
                task.wait(0.5)
                
                -- Try to use the jaladaDePeloCharge on the cage
                pcall(function()
                    Jail.Shared.ReplicatedStorage:WaitForChild("JALADADEPELOEVENT"):FireServer()
                end)
                
                success = true
            end
        end
        
        -- PHASE 7: Wait a moment for jail to process
        Jail.Shared.updateStatus("Phase 7: Processing...", Color3.fromRGB(246, 189, 59))
        task.wait(2)
        
        if success then
            Jail.Shared.updateStatus("Successfully jailed "..target.Name, Color3.fromRGB(59, 246, 105))
        else
            Jail.Shared.updateStatus("Jail attempted on "..target.Name, Color3.fromRGB(246, 189, 59))
        end
        
        -- PHASE 8: Return to original position
        Jail.Shared.updateStatus("Phase 8: Returning...", Color3.fromRGB(246, 189, 59))
        Jail.Shared.smoothTP(originalPosition)
        
        Jail.Shared.updateStatus("Jail operation complete", Color3.fromRGB(59, 246, 105))
        
        task.wait(1)
        Jail.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
    end)
end

return Jail
