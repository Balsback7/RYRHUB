--// Bring Command
local Bring = {}

function Bring.init(Shared)
    Bring.Shared = Shared
end

function Bring.bringPlayer(target)
    local originalPosition = Bring.Shared.savePosition()
    
    local tChar = target.Character
    if not tChar then
        return false, "No character found"
    end
    
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then
        return false, "No HRP found"
    end
    
    -- WIELD BEHIND TARGET
    if Bring.Shared.updateStatus then
        Bring.Shared.updateStatus("Wielding behind "..target.Name.."...", Color3.fromRGB(246, 189, 59))
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
    
    -- Use jaladaDePeloCharge while still following (BLUE CHARGE EFFECT)
    if Bring.Shared.updateStatus then
        Bring.Shared.updateStatus("Using blue charge on "..target.Name.."...", Color3.fromRGB(59, 189, 246))
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
    
    return true, "Brought "..target.Name
end

function Bring.execute(targetText)
    task.spawn(function()
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
        
        -- Check for "all" parameter
        if targetText:lower() == "all" then
            -- Get all players except yourself
            local allPlayers = {}
            for _, player in ipairs(Bring.Shared.Players:GetPlayers()) do
                if player ~= Bring.Shared.player then
                    table.insert(allPlayers, player)
                end
            end
            
            if #allPlayers == 0 then
                if Bring.Shared.updateStatus then
                    Bring.Shared.updateStatus("No other players found", Color3.fromRGB(246, 59, 59))
                end
                task.wait(1.5)
                if Bring.Shared.updateStatus then
                    Bring.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
                end
                return
            end
            
            -- Store original status to restore at the end
            local originalStatus = "Idle"
            
            -- Bring each player one by one
            for i, player in ipairs(allPlayers) do
                if Bring.Shared.updateStatus then
                    Bring.Shared.updateStatus(string.format("Bringing all players (%d/%d)...", i, #allPlayers), Color3.fromRGB(59, 189, 246))
                end
                
                -- Bring the player with blue charge effect
                local success, message = Bring.bringPlayer(player)
                
                if not success then
                    if Bring.Shared.updateStatus then
                        Bring.Shared.updateStatus("Failed: "..message, Color3.fromRGB(246, 59, 59))
                    end
                    task.wait(1)
                else
                    if Bring.Shared.updateStatus then
                        Bring.Shared.updateStatus("Success: "..message, Color3.fromRGB(59, 246, 105))
                    end
                    task.wait(0.5) -- Small delay between players
                end
            end
            
            -- Final status
            if Bring.Shared.updateStatus then
                Bring.Shared.updateStatus(string.format("Brought all %d players", #allPlayers), Color3.fromRGB(59, 246, 105))
            end
            task.wait(1)
            if Bring.Shared.updateStatus then
                Bring.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
            end
            
            return
        end
        
        -- Original single player bring logic
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
        
        if Bring.Shared.updateStatus then
            Bring.Shared.updateStatus("Bringing "..target.Name.. "...", Color3.fromRGB(59, 189, 246))
        end
        
        local success, message = Bring.bringPlayer(target)
        
        if success then
            if Bring.Shared.updateStatus then
                Bring.Shared.updateStatus(message, Color3.fromRGB(59, 246, 105))
            end
        else
            if Bring.Shared.updateStatus then
                Bring.Shared.updateStatus(message, Color3.fromRGB(246, 59, 59))
            end
        end
        
        task.wait(1)
        if Bring.Shared.updateStatus then
            Bring.Shared.updateStatus("Idle", Color3.fromRGB(59, 246, 105))
        end
    end)
end

return Bring
