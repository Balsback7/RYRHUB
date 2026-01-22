--// Annoy Command
local Annoy = {}

-- Local variables
local originalAnnoyPosition = nil
local annoyCount = 0

function Annoy.init(Shared)
    Annoy.Shared = Shared
end

function Annoy.start(targetText)
    task.spawn(function()
        local target = Annoy.Shared.findPlayerSmart(targetText)
        if not target then
            if Annoy.Shared.updateStatus then
                Annoy.Shared.updateStatus("Player not found", Color3.fromRGB(246, 59, 59))
            end
            return
        end
        
        -- If already annoying, stop it
        if Annoy.Shared.annoying then
            Annoy.stop()
            return
        end
        
        Annoy.Shared.annoying = true
        
        -- Save the position BEFORE starting annoy
        originalAnnoyPosition = Annoy.Shared.savePosition()
        
        if Annoy.Shared.updateStatus then
            Annoy.Shared.updateStatus("Annoying "..target.Name.. "...", Color3.fromRGB(234, 179, 8))
        end
        
        annoyCount = 0
        
        Annoy.Shared.annoyConnection = Annoy.Shared.RunService.Heartbeat:Connect(function()
            if not Annoy.Shared.annoying or not Annoy.Shared.hrp or not Annoy.Shared.hrp.Parent then 
                Annoy.stop()
                return 
            end
            
            local tChar = target.Character
            if not tChar then
                if Annoy.Shared.updateStatus then
                    Annoy.Shared.updateStatus(target.Name.." has no character", Color3.fromRGB(246, 189, 59))
                end
                
                -- Return to original position while waiting
                if originalAnnoyPosition then
                    Annoy.Shared.smoothTP(originalAnnoyPosition)
                end
                
                task.wait(1)
                return
            end
            
            local tHRP = tChar:FindFirstChild("HumanoidRootPart")
            if not tHRP or not tHRP.Parent then
                if Annoy.Shared.updateStatus then
                    Annoy.Shared.updateStatus("Waiting for "..target.Name.." to spawn...", Color3.fromRGB(246, 189, 59))
                end
                
                -- Return to original position while waiting
                if originalAnnoyPosition then
                    Annoy.Shared.smoothTP(originalAnnoyPosition)
                end
                
                task.wait(1)
                return
            end
            
            -- Teleport DIRECTLY UNDER the target
            local undergroundPosition = Vector3.new(tHRP.Position.X, tHRP.Position.Y + Annoy.Shared.UNDERGROUND_OFFSET, tHRP.Position.Z)
            Annoy.Shared.hrp.CFrame = CFrame.new(undergroundPosition)
            Annoy.Shared.hrp.AssemblyLinearVelocity = Vector3.zero
            Annoy.Shared.hrp.AssemblyAngularVelocity = Vector3.zero
            
            -- Check if target is ragdolled
            local isRagdolled = tChar:FindFirstChild("RagdollTrigger", true)
            
            if isRagdolled then
                -- If ragdolled, wait for them to get up
                if Annoy.Shared.updateStatus then
                    Annoy.Shared.updateStatus(target.Name.." is ragdolled, waiting...", Color3.fromRGB(246, 189, 59))
                end
                
                local waitStart = tick()
                while tChar:FindFirstChild("RagdollTrigger", true) and (tick() - waitStart < 30) do
                    -- Return to original position while waiting
                    if originalAnnoyPosition then
                        Annoy.Shared.smoothTP(originalAnnoyPosition)
                    end
                    task.wait(0.5)
                    if not Annoy.Shared.annoying then return end
                end
                
                if not tChar:FindFirstChild("RagdollTrigger", true) then
                    if Annoy.Shared.updateStatus then
                        Annoy.Shared.updateStatus(target.Name.." got up, attacking again...", Color3.fromRGB(234, 179, 8))
                    end
                end
            else
                -- Attack with ALL 3 methods from directly underground
                Annoy.Shared.useAllAttackRemotes()
                
                annoyCount = annoyCount + 1
                if Annoy.Shared.updateStatus then
                    Annoy.Shared.updateStatus("Attacking "..target.Name.. " (#"..annoyCount..") from directly under them", Color3.fromRGB(234, 179, 8))
                end
            end
            
            -- ALWAYS return to the ORIGINAL annoy position
            if originalAnnoyPosition then
                Annoy.Shared.smoothTP(originalAnnoyPosition)
            end
            
            -- Wait 1 second between attacks
            task.wait(1)
        end)
    end)
end

function Annoy.stop()
    Annoy.Shared.annoying = false
    if Annoy.Shared.annoyConnection then
        Annoy.Shared.annoyConnection:Disconnect()
        Annoy.Shared.annoyConnection = nil
    end
    originalAnnoyPosition = nil
    
    if Annoy.Shared.updateStatus then
        Annoy.Shared.updateStatus("Annoy stopped", Color3.fromRGB(246, 59, 59))
    end
end

function Annoy.onCharacterAdded()
    -- Reset annoy state when character respawns
    Annoy.Shared.annoying = false
    originalAnnoyPosition = nil
    annoyCount = 0
end

return Annoy
