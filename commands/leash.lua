--// Leash Command
local Leash = {}

function Leash.init(Shared)
    Leash.Shared = Shared
end

function Leash.execute(targetText)
    task.spawn(function()
        local originalPosition = Leash.Shared.savePosition()
        
        if Leash.Shared.updateStatus then
            Leash.Shared.updateStatus("Starting Leash...", Color3.fromRGB(246, 189, 59))
        end
        
        local target = Leash.Shared.findPlayerSmart(targetText)
        
        if not target then
            if Leash.Shared.updateStatus then
                Leash.Shared.updateStatus("Player not found", Color3.fromRGB(246, 59, 59))
            end
            Leash.Shared.smoothTP(originalPosition)
            task.wait(1.5)
            if Leash.Shared.updateStatus then
                Leash.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
            end
            return
        end

        local tChar = target.Character
        if not tChar then
            if Leash.Shared.updateStatus then
                Leash.Shared.updateStatus("Target has no character", Color3.fromRGB(246, 59, 59))
            end
            Leash.Shared.smoothTP(originalPosition)
            return
        end

        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then
            if Leash.Shared.updateStatus then
                Leash.Shared.updateStatus("Target has no HRP", Color3.fromRGB(246, 59, 59))
            end
            Leash.Shared.smoothTP(originalPosition)
            return
        end

        -- FOLLOW TARGET
        local followTarget
        followTarget = Leash.Shared.RunService.Heartbeat:Connect(function()
            if not tHRP or not tHRP.Parent or not Leash.Shared.hrp or not Leash.Shared.hrp.Parent then
                if followTarget then followTarget:Disconnect() end
                return
            end
            Leash.Shared.hrp.CFrame = CFrame.new(
                tHRP.Position + Vector3.new(0, Leash.Shared.HEIGHT, 0) + tHRP.CFrame.LookVector * Leash.Shared.BACK_OFFSET, 
                tHRP.Position
            )
        end)

        task.wait(0.5)

        -- ATTACK UNTIL RAGDOLLED
        if Leash.Shared.updateStatus then
            Leash.Shared.updateStatus("Attacking until ragdoll...", Color3.fromRGB(246, 189, 59))
        end
        
        local ragdolled = false
        local attempts = 0
        local maxAttempts = 30

        while not ragdolled and attempts < maxAttempts and Leash.Shared.hrp and Leash.Shared.hrp.Parent do
            if not tHRP or not tHRP.Parent then 
                if Leash.Shared.updateStatus then
                    Leash.Shared.updateStatus("Target disappeared", Color3.fromRGB(246, 59, 59))
                end
                break 
            end
            
            -- Check if ragdolled
            if tChar:FindFirstChild("RagdollTrigger", true) then 
                ragdolled = true 
                if Leash.Shared.updateStatus then
                    Leash.Shared.updateStatus("Target ragdolled!", Color3.fromRGB(59, 246, 105))
                end
                break 
            end
            
            -- Attack with ALL 3 methods
            Leash.Shared.useAllAttackRemotes()
            
            attempts += 1
            task.wait(0.2)
            
            -- Update status every 5 attempts
            if attempts % 5 == 0 then
                if Leash.Shared.updateStatus then
                    Leash.Shared.updateStatus("Attacking... ("..attempts.."/"..maxAttempts..")", Color3.fromRGB(246, 189, 59))
                end
            end
        end

        if followTarget then 
            followTarget:Disconnect() 
        end

        -- DOG LEASH USING TARGET'S USERID
        if ragdolled and target and Leash.Shared.hrp and Leash.Shared.hrp.Parent then
            if Leash.Shared.updateStatus then
                Leash.Shared.updateStatus("Waiting 1 second...", Color3.fromRGB(246, 189, 59))
            end
            task.wait(1) -- 1 second delay before using Dog Leash
            
            if Leash.Shared.updateStatus then
                Leash.Shared.updateStatus("Using Dog Leash...", Color3.fromRGB(246, 189, 59))
            end
            
            -- Get target's UserId
            local targetUserId = target.UserId
            if Leash.Shared.updateStatus then
                Leash.Shared.updateStatus("Target: "..target.Name.. " (ID: "..targetUserId..")", Color3.fromRGB(246, 189, 59))
            end
            
            -- Try the remote call with proper formatting
            local success, errorMsg = pcall(function()
                local args = {
                    targetUserId,  -- Target's UserId as number
                    "Dog Leash"    -- Item name as string
                }
                
                if Leash.Shared.updateStatus then
                    Leash.Shared.updateStatus("Sending args: "..tostring(args[1])..", "..tostring(args[2]), Color3.fromRGB(246, 189, 59))
                end
                
                local remote = Leash.Shared.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/dogLeashEvent")
                remote:FireServer(unpack(args))
                
                if Leash.Shared.updateStatus then
                    Leash.Shared.updateStatus("Dog Leash sent!", Color3.fromRGB(59, 246, 105))
                end
            end)
            
            if not success then
                if Leash.Shared.updateStatus then
                    Leash.Shared.updateStatus("Failed: "..tostring(errorMsg), Color3.fromRGB(246, 59, 59))
                end
                
                -- Try alternative format
                task.wait(0.5)
                if Leash.Shared.updateStatus then
                    Leash.Shared.updateStatus("Trying alternative format...", Color3.fromRGB(246, 189, 59))
                end
                
                pcall(function()
                    local args2 = {
                        tostring(targetUserId),  -- UserId as string
                        "Dog Leash"             -- Item name
                    }
                    
                    if Leash.Shared.updateStatus then
                        Leash.Shared.updateStatus("Sending args: "..args2[1]..", "..args2[2], Color3.fromRGB(246, 189, 59))
                    end
                    
                    local remote2 = Leash.Shared.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/dogLeashEvent")
                    remote2:FireServer(unpack(args2))
                    
                    if Leash.Shared.updateStatus then
                        Leash.Shared.updateStatus("Dog Leash sent (alt)!", Color3.fromRGB(59, 246, 105))
                    end
                end)
            end
        else
            if attempts >= maxAttempts then
                if Leash.Shared.updateStatus then
                    Leash.Shared.updateStatus("Timeout - could not ragdoll", Color3.fromRGB(246, 59, 59))
                end
            else
                if Leash.Shared.updateStatus then
                    Leash.Shared.updateStatus("Failed to ragdoll target", Color3.fromRGB(246, 59, 59))
                end
            end
        end

        -- Return to original position
        if Leash.Shared.updateStatus then
            Leash.Shared.updateStatus("Returning...", Color3.fromRGB(246, 189, 59))
        end
        Leash.Shared.smoothTP(originalPosition)
        
        task.wait(1)
        if Leash.Shared.updateStatus then
            Leash.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
        end
    end)
end

return Leash
