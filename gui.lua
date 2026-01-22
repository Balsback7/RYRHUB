--// RYR Hub GUI with Tabs
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local GUI = {}

-- State
local player = Players.LocalPlayer
local gui, mainFrame, inputBox, funInputBox
local tabButtons = {}
local tabContents = {}
local currentTab = "attack" -- Default tab

-- Buttons
local farmBtn, bringBtn, annoyBtn, leashBtn, jailBtn, protectBtn, resetBtn, clickToggle
local statusLabel, statusIcon
local Shared = nil

-- Update status function
local updateStatus = function(text, color)
    if statusLabel then
        statusLabel.Text = text
        if statusIcon then
            statusIcon.BackgroundColor3 = color
        end
    end
end

-- Click-to-select feature
local clickSelectionEnabled = false
local clickSelectionConnection = nil

local function setupClickSelection()
    if clickSelectionConnection then
        clickSelectionConnection:Disconnect()
        clickSelectionConnection = nil
    end
    
    if not clickSelectionEnabled then return end
    
    clickSelectionConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = player:GetMouse()
            local target = mouse.Target
            
            if target then
                -- Find the player from the clicked part
                local model = target:FindFirstAncestorOfClass("Model")
                if model then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr.Character == model and plr ~= player then
                            -- Put player name in textbox based on current tab
                            if currentTab == "attack" and inputBox then
                                inputBox.Text = plr.Name
                            elseif currentTab == "fun" and funInputBox then
                                funInputBox.Text = plr.Name
                            end
                            
                            updateStatus("Selected: "..plr.Name, Color3.fromRGB(59, 189, 246))
                            
                            -- Flash the input box to show selection
                            local targetBox = (currentTab == "attack") and inputBox or funInputBox
                            if targetBox then
                                local originalColor = targetBox.BackgroundColor3
                                for i = 1, 3 do
                                    targetBox.BackgroundColor3 = Color3.fromRGB(59, 189, 246)
                                    task.wait(0.1)
                                    targetBox.BackgroundColor3 = originalColor
                                    task.wait(0.1)
                                end
                            end
                            return
                        end
                    end
                end
            end
        end
    end)
end

local function toggleClickSelection()
    clickSelectionEnabled = not clickSelectionEnabled
    
    if clickToggle then
        if clickSelectionEnabled then
            clickToggle.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
            clickToggle.Text = "ON"
            updateStatus("Click-to-select: ON", Color3.fromRGB(59, 246, 105))
        else
            clickToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            clickToggle.Text = "OFF"
            updateStatus("Click-to-select: OFF", Color3.fromRGB(246, 59, 59))
        end
    end
    
    setupClickSelection()
end

-- Switch tabs
local function switchTab(tabName)
    currentTab = tabName
    
    -- Update tab button colors
    for name, btn in pairs(tabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(59, 130, 246) -- Active tab
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45) -- Inactive tab
        end
    end
    
    -- Show/hide tab contents
    for name, content in pairs(tabContents) do
        content.Visible = (name == tabName)
    end
end

-- Get current input box based on active tab
local function getCurrentInputBox()
    if currentTab == "attack" then
        return inputBox
    elseif currentTab == "fun" then
        return funInputBox
    end
    return nil
end

-- Create GUI
function GUI.create()
    -- Clean up old GUI if exists
    if gui then
        gui:Destroy()
    end
    
    -- Create new GUI
    gui = Instance.new("ScreenGui")
    gui.Name = "RYRHub"
    gui.Parent = player:WaitForChild("PlayerGui")
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false

    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.fromOffset(380, 500) -- Slightly wider for tabs
    mainFrame.Position = UDim2.fromScale(0.5, 0.5)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    -- Top Bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.fromOffset(15, 0)
    title.BackgroundTransparency = 1
    title.Text = "RYR HUB"
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(30, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 24
    closeBtn.Parent = topBar
    closeBtn.MouseButton1Click:Connect(function() 
        if Shared and Shared.cleanupAllConnections then
            Shared.cleanupAllConnections()
        end
        gui:Destroy() 
    end)

    -- Tabs
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Size = UDim2.new(1, -20, 0, 40)
    tabsFrame.Position = UDim2.fromOffset(10, 50)
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.Parent = mainFrame

    local tabNames = {"attack", "fun", "farm", "settings"}
    local tabDisplayNames = {"⚔️ ATTACK", "🎉 FUN", "🌾 FARM", "⚙️ SETTINGS"}
    
    for i, tabName in ipairs(tabNames) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0.24, 0, 1, 0)
        tabBtn.Position = UDim2.new((i-1) * 0.25, 0, 0, 0)
        tabBtn.BackgroundColor3 = (tabName == currentTab) and Color3.fromRGB(59, 130, 246) or Color3.fromRGB(40, 40, 45)
        tabBtn.Text = tabDisplayNames[i]
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.TextSize = 11
        tabBtn.Parent = tabsFrame
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tabBtn
        
        tabBtn.MouseButton1Click:Connect(function()
            switchTab(tabName)
        end)
        
        tabButtons[tabName] = tabBtn
    end

    -- Tab contents container
    local tabsContentContainer = Instance.new("Frame")
    tabsContentContainer.Size = UDim2.new(1, -20, 1, -100)
    tabsContentContainer.Position = UDim2.fromOffset(10, 100)
    tabsContentContainer.BackgroundTransparency = 1
    tabsContentContainer.Parent = mainFrame

    -- Create tab contents
    tabContents = {}
    
    -- ATTACK TAB
    local attackTab = Instance.new("Frame")
    attackTab.Name = "AttackTab"
    attackTab.Size = UDim2.new(1, 0, 1, 0)
    attackTab.BackgroundTransparency = 1
    attackTab.Visible = (currentTab == "attack")
    attackTab.Parent = tabsContentContainer
    tabContents["attack"] = attackTab
    
    -- Input box for attack tab
    inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -20, 0, 35)
    inputBox.Position = UDim2.fromOffset(0, 0)
    inputBox.PlaceholderText = "Enter player name..."
    inputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 14
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = attackTab

    local cornerInput = Instance.new("UICorner")
    cornerInput.CornerRadius = UDim.new(0, 6)
    cornerInput.Parent = inputBox

    -- Annoy Player Button
    annoyBtn = Instance.new("TextButton")
    annoyBtn.Size = UDim2.new(1, 0, 0, 35)
    annoyBtn.Position = UDim2.fromOffset(0, 45)
    annoyBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
    annoyBtn.Text = "START ANNOY PLAYER"
    annoyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    annoyBtn.Font = Enum.Font.GothamSemibold
    annoyBtn.TextSize = 14
    annoyBtn.Parent = attackTab
    local annoyCorner = Instance.new("UICorner")
    annoyCorner.CornerRadius = UDim.new(0, 6)
    annoyCorner.Parent = annoyBtn

    -- Protect Player Button
    protectBtn = Instance.new("TextButton")
    protectBtn.Size = UDim2.new(1, 0, 0, 35)
    protectBtn.Position = UDim2.fromOffset(0, 90)
    protectBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
    protectBtn.Text = "🛡️ PROTECT PLAYER"
    protectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    protectBtn.Font = Enum.Font.GothamSemibold
    protectBtn.TextSize = 14
    protectBtn.Parent = attackTab
    local protectCorner = Instance.new("UICorner")
    protectCorner.CornerRadius = UDim.new(0, 6)
    protectCorner.Parent = protectBtn

    -- FUN TAB
    local funTab = Instance.new("Frame")
    funTab.Name = "FunTab"
    funTab.Size = UDim2.new(1, 0, 1, 0)
    funTab.BackgroundTransparency = 1
    funTab.Visible = (currentTab == "fun")
    funTab.Parent = tabsContentContainer
    tabContents["fun"] = funTab
    
    -- Input box for fun tab
    funInputBox = Instance.new("TextBox")
    funInputBox.Size = UDim2.new(1, -20, 0, 35)
    funInputBox.Position = UDim2.fromOffset(0, 0)
    funInputBox.PlaceholderText = "Enter player name..."
    funInputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    funInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    funInputBox.Font = Enum.Font.Gotham
    funInputBox.TextSize = 14
    funInputBox.ClearTextOnFocus = false
    funInputBox.Parent = funTab

    local funCornerInput = Instance.new("UICorner")
    funCornerInput.CornerRadius = UDim.new(0, 6)
    funCornerInput.Parent = funInputBox
    
    -- Bring Player Button
    bringBtn = Instance.new("TextButton")
    bringBtn.Size = UDim2.new(1, 0, 0, 35)
    bringBtn.Position = UDim2.fromOffset(0, 45)
    bringBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    bringBtn.Text = "BRING PLAYER"
    bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bringBtn.Font = Enum.Font.GothamSemibold
    bringBtn.TextSize = 14
    bringBtn.Parent = funTab
    local bringCorner = Instance.new("UICorner")
    bringCorner.CornerRadius = UDim.new(0, 6)
    bringCorner.Parent = bringBtn

    -- Leash Player Button
    leashBtn = Instance.new("TextButton")
    leashBtn.Size = UDim2.new(1, 0, 0, 35)
    leashBtn.Position = UDim2.fromOffset(0, 90)
    leashBtn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    leashBtn.Text = "LEASH PLAYER"
    leashBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    leashBtn.Font = Enum.Font.GothamSemibold
    leashBtn.TextSize = 14
    leashBtn.Parent = funTab
    local leashCorner = Instance.new("UICorner")
    leashCorner.CornerRadius = UDim.new(0, 6)
    leashCorner.Parent = leashBtn

    -- Jail Player Button
    jailBtn = Instance.new("TextButton")
    jailBtn.Size = UDim2.new(1, 0, 0, 35)
    jailBtn.Position = UDim2.fromOffset(0, 135)
    jailBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
    jailBtn.Text = "🚔 JAIL PLAYER"
    jailBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    jailBtn.Font = Enum.Font.GothamSemibold
    jailBtn.TextSize = 14
    jailBtn.Parent = funTab
    local jailCorner = Instance.new("UICorner")
    jailCorner.CornerRadius = UDim.new(0, 6)
    jailCorner.Parent = jailBtn

    -- FARM TAB
    local farmTab = Instance.new("Frame")
    farmTab.Name = "FarmTab"
    farmTab.Size = UDim2.new(1, 0, 1, 0)
    farmTab.BackgroundTransparency = 1
    farmTab.Visible = (currentTab == "farm")
    farmTab.Parent = tabsContentContainer
    tabContents["farm"] = farmTab
    
    -- Blue Recharge Button
    farmBtn = Instance.new("TextButton")
    farmBtn.Size = UDim2.new(1, 0, 0, 35)
    farmBtn.Position = UDim2.fromOffset(0, 0)
    farmBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    farmBtn.Text = Shared and Shared.farming and "STOP FARM" or "START BLUE RECHARGE"
    farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    farmBtn.Font = Enum.Font.GothamSemibold
    farmBtn.TextSize = 14
    farmBtn.Parent = farmTab
    local farmCorner = Instance.new("UICorner")
    farmCorner.CornerRadius = UDim.new(0, 6)
    farmCorner.Parent = farmBtn

    -- SETTINGS TAB
    local settingsTab = Instance.new("Frame")
    settingsTab.Name = "SettingsTab"
    settingsTab.Size = UDim2.new(1, 0, 1, 0)
    settingsTab.BackgroundTransparency = 1
    settingsTab.Visible = (currentTab == "settings")
    settingsTab.Parent = tabsContentContainer
    tabContents["settings"] = settingsTab
    
    -- Click Selection Toggle
    local clickRow = Instance.new("Frame")
    clickRow.Size = UDim2.new(1, 0, 0, 35)
    clickRow.Position = UDim2.fromOffset(0, 0)
    clickRow.BackgroundTransparency = 1
    clickRow.Parent = settingsTab

    local clickLabel = Instance.new("TextLabel")
    clickLabel.Size = UDim2.new(0.6, 0, 1, 0)
    clickLabel.Position = UDim2.fromOffset(0, 0)
    clickLabel.BackgroundTransparency = 1
    clickLabel.Text = "Click-to-select player:"
    clickLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    clickLabel.Font = Enum.Font.Gotham
    clickLabel.TextSize = 14
    clickLabel.TextXAlignment = Enum.TextXAlignment.Left
    clickLabel.Parent = clickRow

    clickToggle = Instance.new("TextButton")
    clickToggle.Size = UDim2.new(0.35, 0, 1, 0)
    clickToggle.Position = UDim2.new(0.65, 0, 0, 0)
    clickToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    clickToggle.Text = "OFF"
    clickToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    clickToggle.Font = Enum.Font.GothamSemibold
    clickToggle.TextSize = 14
    clickToggle.Parent = clickRow
    local clickCorner = Instance.new("UICorner")
    clickCorner.CornerRadius = UDim.new(0, 6)
    clickCorner.Parent = clickToggle

    -- Reset Button
    resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(1, 0, 0, 35)
    resetBtn.Position = UDim2.fromOffset(0, 45)
    resetBtn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    resetBtn.Text = "🔄 RESET SCRIPT"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.GothamSemibold
    resetBtn.TextSize = 14
    resetBtn.Parent = settingsTab
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 6)
    resetCorner.Parent = resetBtn

    -- Status (at bottom of main frame)
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 25)
    statusLabel.Position = UDim2.fromOffset(10, 465)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Idle"
    statusLabel.TextColor3 = Color3.fromRGB(59, 246, 105)
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextSize = 14
    statusLabel.Parent = mainFrame

    statusIcon = Instance.new("Frame")
    statusIcon.Size = UDim2.fromOffset(12, 12)
    statusIcon.Position = UDim2.fromOffset(5, 6)
    statusIcon.BackgroundColor3 = Color3.fromRGB(59, 246, 105)
    statusIcon.Parent = statusLabel
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(1, 0)
    statusCorner.Parent = statusIcon

    -- Connect buttons to commands
    farmBtn.MouseButton1Click:Connect(function()
        if Shared and Shared.Commands and Shared.Commands.farm then
            if Shared.farming then
                Shared.Commands.farm.stop()
                farmBtn.Text = "START BLUE RECHARGE"
                farmBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
            else
                Shared.Commands.farm.start()
                farmBtn.Text = "STOP FARM"
                farmBtn.BackgroundColor3 = Color3.fromRGB(246, 59, 59)
            end
        end
    end)

    bringBtn.MouseButton1Click:Connect(function()
        local currentInput = getCurrentInputBox()
        if currentInput and currentInput.Text ~= "" and Shared and Shared.Commands and Shared.Commands.bring then
            Shared.Commands.bring.execute(currentInput.Text)
        else
            updateStatus("Enter a player name", Color3.fromRGB(246, 59, 59))
            task.wait(1.5)
            updateStatus("Idle", Color3.fromRGB(59, 246, 105))
        end
    end)

    annoyBtn.MouseButton1Click:Connect(function()
        local currentInput = getCurrentInputBox()
        if currentInput and currentInput.Text ~= "" and Shared and Shared.Commands and Shared.Commands.annoy then
            if Shared.annoying then
                Shared.Commands.annoy.stop()
                annoyBtn.Text = "START ANNOY PLAYER"
                annoyBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
            else
                Shared.Commands.annoy.start(currentInput.Text)
                annoyBtn.Text = "STOP ANNOY"
                annoyBtn.BackgroundColor3 = Color3.fromRGB(246, 59, 59)
            end
        else
            updateStatus("Enter a player name", Color3.fromRGB(246, 59, 59))
            task.wait(1.5)
            updateStatus("Idle", Color3.fromRGB(59, 246, 105))
        end
    end)

    leashBtn.MouseButton1Click:Connect(function()
        local currentInput = getCurrentInputBox()
        if currentInput and currentInput.Text ~= "" and Shared and Shared.Commands and Shared.Commands.leash then
            Shared.Commands.leash.execute(currentInput.Text)
        else
            updateStatus("Enter a player name", Color3.fromRGB(246, 59, 59))
            task.wait(1.5)
            updateStatus("Idle", Color3.fromRGB(59, 246, 105))
        end
    end)

    jailBtn.MouseButton1Click:Connect(function()
        local currentInput = getCurrentInputBox()
        if currentInput and currentInput.Text ~= "" and Shared and Shared.Commands and Shared.Commands.jail then
            Shared.Commands.jail.execute(currentInput.Text)
        else
            updateStatus("Enter a player name", Color3.fromRGB(246, 59, 59))
            task.wait(1.5)
            updateStatus("Idle", Color3.fromRGB(59, 246, 105))
        end
    end)

    protectBtn.MouseButton1Click:Connect(function()
        local currentInput = getCurrentInputBox()
        if currentInput and currentInput.Text ~= "" and Shared and Shared.Commands and Shared.Commands.protect then
            if Shared.protecting then
                Shared.Commands.protect.stop()
                protectBtn.Text = "🛡️ PROTECT PLAYER"
                protectBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
            else
                Shared.Commands.protect.start(currentInput.Text)
                protectBtn.Text = "STOP PROTECT"
                protectBtn.BackgroundColor3 = Color3.fromRGB(246, 59, 59)
            end
        else
            updateStatus("Enter a player name", Color3.fromRGB(246, 59, 59))
            task.wait(1.5)
            updateStatus("Idle", Color3.fromRGB(59, 246, 105))
        end
    end)

    clickToggle.MouseButton1Click:Connect(toggleClickSelection)

    resetBtn.MouseButton1Click:Connect(function()
        -- Full reset
        if Shared then
            Shared.cleanupAllConnections()
            Shared.farming = false
            Shared.annoying = false
            Shared.protecting = false
            
            -- Reset button states
            farmBtn.Text = "START BLUE RECHARGE"
            farmBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
            
            annoyBtn.Text = "START ANNOY PLAYER"
            annoyBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
            
            protectBtn.Text = "🛡️ PROTECT PLAYER"
            protectBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
        end
        
        updateStatus("Script reset! Ready", Color3.fromRGB(59, 246, 105))
    end)

    updateStatus("Ready", Color3.fromRGB(59, 246, 105))
end

-- Initialize function
function GUI.init(sharedData)
    Shared = sharedData
    Shared.updateStatus = updateStatus
    
    -- Create GUI
    GUI.create()
    
    -- Set up death restart
    local deathConnection = nil
    
    local function setupDeathRestart()
        if deathConnection then
            deathConnection:Disconnect()
        end
        
        deathConnection = Shared.humanoid.Died:Connect(function()
            updateStatus("You died! Restarting...", Color3.fromRGB(246, 59, 59))
            
            Shared.cleanupAllConnections()
            
            -- Reset GUI buttons
            if farmBtn then
                farmBtn.Text = "START BLUE RECHARGE"
                farmBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
            end
            
            if annoyBtn then
                annoyBtn.Text = "START ANNOY PLAYER"
                annoyBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
            end
            
            if protectBtn then
                protectBtn.Text = "🛡️ PROTECT PLAYER"
                protectBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
            end
            
            Shared.farming = false
            Shared.annoying = false
            Shared.protecting = false
            
            -- Wait for respawn
            task.wait(3)
            
            -- Get new character
            Shared.char = Shared.player.CharacterAdded:Wait()
            Shared.humanoid = Shared.char:WaitForChild("Humanoid")
            Shared.hrp = Shared.char:WaitForChild("HumanoidRootPart")
            
            -- Re-setup death connection
            setupDeathRestart()
            
            updateStatus("Restarted! Ready", Color3.fromRGB(59, 246, 105))
        end)
    end
    
    setupDeathRestart()
    
    -- Handle character respawns
    Shared.player.CharacterAdded:Connect(function(newChar)
        Shared.char = newChar
        Shared.humanoid = newChar:WaitForChild("Humanoid")
        Shared.hrp = newChar:WaitForChild("HumanoidRootPart")
        
        -- Recreate GUI if it was destroyed
        if not gui or not gui.Parent then
            GUI.create()
        end
        
        setupDeathRestart()
        updateStatus("Character respawned! Ready", Color3.fromRGB(59, 246, 105))
    end)
end

return GUI
