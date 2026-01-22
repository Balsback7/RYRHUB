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

function Jail.execute(targetText)
    task.spawn(function()
        local originalPosition = Jail.Shared.savePosition()
        
        local target = Jail.Shared.findPlayerSmart(targetText)
        if not target then
            if Jail.Shared.updateStatus then
                Jail.Shared.updateStatus("Player not found", Color3.fromRGB(246, 59, 59))
            end
            return
        end
        
        if Jail.Shared.updateStatus then
            Jail.Shared.updateStatus("Jailing "..target.Name.. "...", Color3.fromRGB(220, 38, 38))
        end
        
        -- PHASE 1: Teleport to target
        if Jail.Shared.updateStatus then
            Jail.Shared.updateStatus("Phase 1: Teleporting to target...", Color3.fromRGB(246, 189, 59))
        end
        
        local tChar = target.Character
        if not tChar then
            if Jail.Shared.updateStatus then
                Jail.Shared.updateStatus("Target has no character", Color3.fromRGB(246, 59, 59))
            end
            Jail.Shared.smoothTP(originalPosition)
            return
        end
        
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then
            if Jail.Shared.updateStatus then
                Jail.Shared.updateStatus("Target has no HRP", Color3.fromRGB(246, 59, 59))
            end
            Jail.Shared.smoothTP(originalPosition)
            return
        end
        
        -- Teleport BEHIND target for better charge accuracy
        local behindPosition = tHRP.Position + tHRP.CFrame.LookVector * -2 + Vector3.new(0, 2, 0)
        Jail.Shared.hrp.CFrame = CFrame.new(behindPosition, tHRP.Position)
        
        task.wait(0.3)
        
        -- PHASE 2: Attempt charge
        if Jail.Shared.updateStatus then
            Jail.Shared.updateStatus("Phase 2: Attempting charge...", Color3.fromRGB(246, 189, 59))
        end
        
        local chargeSuccess = false
        local chargeUsed = false
        
        -- Try charge
        pcall(function()
            Jail.Shared.ReplicatedStorage:WaitForChild("JALADADEPELOEVENT"):FireServer()
            if Jail.Shared.updateStatus then
                Jail.Shared.updateStatus("Charge fired!", Color3.fromRGB(59, 189, 246))
            end
            chargeUsed = true
            chargeSuccess = true
        end)
        
        if not chargeUsed then
            if Jail.Shared.updateStatus then
                Jail.Shared.updateStatus("Charge failed, using attack remotes...", Color3.fromRGB(246, 189, 59))
            end
            
            -- Use attack remotes as backup
            for i = 1, 5 do
                Jail.Shared.useAllAttackRemotes()
                task.wait(0.2)
            end
        end
        
        -- Wait for charge animation to complete
        if chargeUsed then
            if Jail.Shared.updateStatus then
                Jail.Shared.updateStatus("Waiting for charge animation...", Color3.fromRGB(246, 189, 59))
            end
            task.wait(3) -- Wait for charge animation
        else
            task.wait(2) -- Shorter wait if no charge
        end
        
        -- PHASE 3: Move to waiting position
        if Jail.Shared.updateStatus then
            Jail.Shared.updateStatus("Phase 3: Moving to waiting position...", Color3.fromRGB(246, 189, 59))
        end
        local WAIT_POSITION = CFrame.new(185, 9, 453)
        Jail.Shared.hrp.CFrame = WAIT_POSITION
        task.wait(0.5)
        
        -- PHASE 4: Move to jail position
        if Jail.Shared.updateStatus then
            Jail.Shared.updateStatus("Phase 4: Moving to jail...", Color3.fromRGB(246, 189, 59))
        end
        local JAIL_POSITION = CFrame.new(192, 9, 442)
        Jail.Shared.hrp.CFrame = JAIL_POSITION
        task.wait(0.5)
        
        -- PHASE 5: Find and trigger the proximity prompt
        if Jail.Shared.updateStatus then
            Jail.Shared.updateStatus("Phase 5: Finding jail prompt...", Color3.fromRGB(246, 189, 59))
        end
        
        local success = false
        
        -- Search for proximity prompts in PoliceStation
        local policeStation = workspace:FindFirstChild("PoliceStation")
        if policeStation then
            for _, obj in pairs(policeStation:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    if Jail.Shared.updateStatus then
                        Jail.Shared.updateStatus("Found jail prompt: "..obj.Name, Color3.fromRGB(59, 246, 105))
                    end
                    
                    -- Move closer to the prompt
                    local promptParent = obj.Parent
                    if promptParent and promptParent:IsA("BasePart") then
                        Jail.Shared.hrp.CFrame = CFrame.new(promptParent.Position + Vector3.new(0, 2, 0))
                        task.wait(0.5)
                    end
                    
                    -- Try to trigger the prompt multiple times
                    for attempt = 1, 3 do
                        triggerProximityPrompt(obj)
                        task.wait(0.2)
                    end
                    
                    success = true
                    break
                end
            end
        end
        
        if success then
            if Jail.Shared.updateStatus then
                Jail.Shared.updateStatus("Successfully jailed "..target.Name, Color3.fromRGB(59, 246, 105))
            end
        else
            if Jail.Shared.updateStatus then
                Jail.Shared.updateStatus("Failed to find jail prompt", Color3.fromRGB(246, 59, 59))
            end
        end
        
        task.wait(1)
        
        -- PHASE 6: Return to original position
        if Jail.Shared.updateStatus then
            Jail.Shared.updateStatus("Phase 6: Returning...", Color3.fromRGB(246, 189, 59))
        end
        Jail.Shared.smoothTP(originalPosition)
        
        if Jail.Shared.updateStatus then
            Jail.Shared.updateStatus("Jail operation complete", Color3.fromRGB(59, 246, 105))
        end
        
        task.wait(1)
        if Jail.Shared.updateStatus then
            Jail.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
        end
    end)
end

return Jail
