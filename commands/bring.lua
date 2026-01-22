--// Bring Command
local Bring = {}

function Bring.init(Shared)
    Bring.Shared = Shared
end

function Bring.execute(targetText)
    task.spawn(function()
        local originalPosition = Bring.Shared.savePosition()
        
        local target = Bring.Shared.findPlayerSmart(targetText)
        if not target then
            if Bring.Shared.updateStatus then
                Bring.Shared.updateStatus("Player not found", Color3.fromRGB(246, 59, 59))
            end
            task.wait(1.5)
            if Bring.Shared.updateStatus then
                Bring.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
            end
            return
        end
        
        -- Check if we have enough charge
        if Bring.Shared.getCharge() < 100 then
            if Bring.Shared.updateStatus then
                Bring.Shared.updateStatus("Need 100% charge for Bring", Color3.fromRGB(246, 189, 59))
            end
            task.wait(1.5)
            if Bring.Shared.updateStatus then
                Bring.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
            end
            return
        end
        
        if Bring.Shared.updateStatus then
            Bring.Shared.updateStatus("Bringing "..target.Name.. "...", Color3.fromRGB(59, 189, 246))
        end
        
        local tChar = target.Character
        if not tChar then
            if Bring.Shared.updateStatus then
                Bring.Shared.updateStatus("No character found", Color3.fromRGB(246, 59, 59))
            end
            return
        end
        
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then
            if Bring.Shared.updateStatus then
                Bring.Shared.updateStatus("No HRP found", Color3.fromRGB(246, 59, 59))
            end
            return
        end
        
        -- WIELD BEHIND TARGET
        if Bring.Shared.updateStatus then
            Bring.Shared.updateStatus("Wielding behind target...", Color3.fromRGB(246, 189, 59))
        end
        
        -- Create follow connection to stay behind target
        local bringFollowConnection = nil
        
        bringFollowConnection = Bring.Shared.RunService.Heartbeat:Connect(function()
            if not tHRP or not tHRP.Parent or not Bring.Shared.hrp or not Bring.Shared.hrp.Parent then
                if bringFollowConnection then bringFollowConnection:Disconnect() end
                return
            end
            Bring.Shared.hrp.CFrame = CFrame.new(
                tHRP.Position + Vector3.new(0, Bring.Shared.HEIGHT, 0) + tHRP.CFrame.LookVector * Bring.Shared.BACK_OFFSET, 
                tHRP.Position
            )
            Bring.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
            Bring.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
        end)
        
        task.wait(0.5)
        
        -- Use jaladaDePeloCharge while still following
        if Bring.Shared.updateStatus then
            Bring.Shared.updateStatus("Using jaladaDePeloCharge...", Color3.fromRGB(246, 189, 59))
        end
        pcall(function()
            Bring.Shared.ReplicatedStorage:WaitForChild("JALADADEPELOEVENT"):FireServer()
        end)
        
        -- Wait for effect while still following
        task.wait(0.8)
        
        -- Disconnect follow connection
        if bringFollowConnection then
            bringFollowConnection:Disconnect()
            bringFollowConnection = nil
        end
        
        -- Return to original position
        if Bring.Shared.updateStatus then
            Bring.Shared.updateStatus("Returning to position...", Color3.fromRGB(246, 189, 59))
        end
        Bring.Shared.smoothTP(originalPosition)
        
        if Bring.Shared.updateStatus then
            Bring.Shared.updateStatus("Brought "..target.Name, Color3.fromRGB(59, 246, 105))
        end
        
        task.wait(1)
        if Bring.Shared.updateStatus then
            Bring.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
        end
    end)
end

return Bring
