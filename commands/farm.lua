--// Farm Command
local Farm = {}

-- Local variables
local originalPositionForFarm = nil
local currentNPC = nil
local lastBotName = ""
local elapsed = 0

function Farm.init(Shared)
    Farm.Shared = Shared
end

function Farm.start()
    if Farm.Shared.farming then return end
    
    -- Save position before starting
    originalPositionForFarm = Farm.Shared.savePosition()
    Farm.Shared.farming = true
    
    -- Update GUI button
    if Farm.Shared.updateStatus then
        Farm.Shared.updateStatus("Starting farm...", Color3.fromRGB(246, 189, 59))
    end
    
    -- Choose initial NPC
    currentNPC = Farm.Shared.chooseRandomNPC()
    
    -- Follow connection
    Farm.Shared.followConnection = Farm.Shared.RunService.Heartbeat:Connect(function(dt)
        if not Farm.Shared.farming or not Farm.Shared.hrp or not Farm.Shared.hrp.Parent then 
            Farm.stop()
            return 
        end
        
        elapsed += dt
        if elapsed >= Farm.Shared.BOT_REFRESH_INTERVAL then
            currentNPC = Farm.Shared.chooseRandomNPC()
            elapsed = 0
            
            -- Update status with bot name if changed
            if currentNPC and currentNPC.Name ~= lastBotName then
                lastBotName = currentNPC.Name
                if Farm.Shared.updateStatus then
                    Farm.Shared.updateStatus("Farming: "..currentNPC.Name, Color3.fromRGB(59, 246, 105))
                end
            end
        end
        
        local npcHRP = currentNPC and currentNPC:FindFirstChild("HumanoidRootPart")
        if npcHRP and npcHRP.Parent then
            Farm.Shared.hrp.CFrame = CFrame.new(
                npcHRP.Position + Vector3.new(0, Farm.Shared.HEIGHT, 0) + npcHRP.CFrame.LookVector * Farm.Shared.BACK_OFFSET, 
                npcHRP.Position
            )
        else
            -- If NPC is gone, choose another random one
            currentNPC = Farm.Shared.chooseRandomNPC()
        end
    end)

    -- Attack connection
    Farm.Shared.attackConnection = Farm.Shared.RunService.Heartbeat:Connect(function()
        if not Farm.Shared.farming or not Farm.Shared.hrp or not Farm.Shared.hrp.Parent then return end
        
        -- Check if we've reached 100% charge
        local charge = Farm.Shared.getCharge()
        if charge >= 100 then 
            if Farm.Shared.updateStatus then
                Farm.Shared.updateStatus("Charge reached 100%!", Color3.fromRGB(59, 246, 105))
            end
            task.wait(0.5)
            Farm.stop()
            return 
        end
        
        -- Attack with ALL 3 methods
        Farm.Shared.useAllAttackRemotes()
        
        -- Update status with charge percentage
        if tick() % 2 < 0.1 then -- Update every ~2 seconds
            local botName = currentNPC and currentNPC.Name or "no bot"
            if Farm.Shared.updateStatus then
                Farm.Shared.updateStatus("Farming "..botName..": "..charge.."%", Color3.fromRGB(59, 246, 105))
            end
        end
    end)
    
    if Farm.Shared.updateStatus then
        Farm.Shared.updateStatus("Farming random bot", Color3.fromRGB(59, 246, 105))
    end
end

function Farm.stop()
    Farm.Shared.farming = false
    Farm.Shared.cleanupAllConnections()
    
    -- Teleport back to original position
    if originalPositionForFarm then
        if Farm.Shared.updateStatus then
            Farm.Shared.updateStatus("Returning to original position...", Color3.fromRGB(246, 189, 59))
        end
        Farm.Shared.smoothTP(originalPositionForFarm)
        originalPositionForFarm = nil
    end
    
    if Farm.Shared.updateStatus then
        Farm.Shared.updateStatus("Farming stopped", Color3.fromRGB(246, 59, 59))
    end
end

function Farm.onCharacterAdded()
    -- Reset farm state when character respawns
    Farm.Shared.farming = false
    originalPositionForFarm = nil
    currentNPC = nil
    lastBotName = ""
    elapsed = 0
end

return Farm
