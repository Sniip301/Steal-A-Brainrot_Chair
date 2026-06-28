--[[
    GUI Module
    UI library using ScreenGui with tabs and toggles
]]

local GUI = {}
GUI.__index = GUI

function GUI.new()
    local self = setmetatable({}, GUI)
    self.ScreenGui = nil
    self.MainFrame = nil
    self.Tabs = {}
    self.ActiveTab = nil
    return self
end

function GUI:Initialize(library, features, teleports, autofarm, esp, config)
    self.Library = library
    self.Features = features
    self.Teleports = teleports
    self.AutoFarm = autofarm
    self.ESP = esp
    self.Config = config
    
    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "BrainrotCheat"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Parent to core GUI for safety
    if gethui then
        self.ScreenGui.Parent = gethui()
    else
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        if LocalPlayer:FindFirstChild("PlayerGui") then
            self.ScreenGui.Parent = LocalPlayer.PlayerGui
        else
            self.ScreenGui.Parent = game:GetService("CoreGui")
        end
    end
    
    -- Create main frame
    self.MainFrame = self:CreateMainFrame()
    
    -- Build tabs
    self:BuildMainTab()
    self:BuildTeleportsTab()
    self:BuildAutoFarmTab()
    self:BuildESPTab()
    self:BuildCreditsTab()
    
    -- Apply default config
    self:ApplyConfig()
    
    -- Toggle key (Right Shift to hide/show)
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            self.MainFrame.Visible = not self.MainFrame.Visible
        end
    end)
    
    -- Drag functionality
    self:MakeDraggable(self.MainFrame)
end

function GUI:CreateMainFrame()
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 500, 0, 400)
    frame.Position = UDim2.new(0.5, -250, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = self.ScreenGui
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleBottom = Instance.new("Frame")
    titleBottom.Size = UDim2.new(1, 0, 0, 8)
    titleBottom.Position = UDim2.new(0, 0, 0, 32)
    titleBottom.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    titleBottom.BorderSizePixel = 0
    titleBottom.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🧠 Steal a Brainrot - Cheat"
    titleLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 14
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self.MainFrame.Visible = false
        self.Library:Notify("GUI Hidden", "Press Right Shift to show", 3)
    end)
    
    -- Tab buttons container
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Size = UDim2.new(0, 120, 1, -50)
    self.TabContainer.Position = UDim2.new(0, 10, 0, 50)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.Parent = frame
    
    -- Content area
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1, -140, 1, -60)
    self.ContentArea.Position = UDim2.new(0, 130, 0, 50)
    self.ContentArea.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    self.ContentArea.BorderSizePixel = 0
    self.ContentArea.Parent = frame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 6)
    contentCorner.Parent = self.ContentArea
    
    return frame
end

function GUI:AddTabButton(name, position)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, position)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = self.TabContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        self:SwitchTab(name, btn)
    end)
    
    return btn
end

function GUI:SwitchTab(tabName, button)
    -- Reset all buttons
    for _, child in ipairs(self.TabContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            child.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
    
    -- Highlight active
    button.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    -- Clear content
    for _, child in ipairs(self.ContentArea:GetChildren()) do
        if child:IsA("ScrollingFrame") then
            child.Visible = false
        end
    end
    
    -- Show selected tab content
    local tabFrame = self.ContentArea:FindFirstChild(tabName)
    if tabFrame then
        tabFrame.Visible = true
    end
end

function GUI:CreateScrollingFrame(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Name = name
    sf.Size = UDim2.new(1, -10, 1, -10)
    sf.Position = UDim2.new(0, 5, 0, 5)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 6
    sf.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 255)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.Visible = false
    sf.Parent = self.ContentArea
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = sf
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.PaddingTop = UDim.new(0, 5)
    padding.Parent = sf
    
    return sf
end

function GUI:AddToggle(parent, text, default, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -10, 0, 35)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = toggleFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 40, 0, 22)
    toggle.Position = UDim2.new(1, -50, 0.5, -11)
    toggle.BackgroundColor3 = default and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 80, 80)
    toggle.Text = ""
    toggle.BorderSizePixel = 0
    toggle.Parent = toggleFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 11)
    toggleCorner.Parent = toggle
    
    local state = default or false
    
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 80, 80)
        if callback then callback(state) end
    end)
    
    if default and callback then
        task.spawn(function() callback(default) end)
    end
    
    return { Frame = toggleFrame, Toggle = toggle, State = state }
end

function GUI:AddSlider(parent, text, min, max, default, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -10, 0, 55)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = sliderFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 5, 0, 3)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame
    
    local slider = Instance.new("TextBox")
    slider.Size = UDim2.new(1, -10, 0, 22)
    slider.Position = UDim2.new(0, 5, 0, 26)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    slider.Text = tostring(default)
    slider.TextColor3 = Color3.fromRGB(255, 255, 255)
    slider.Font = Enum.Font.SourceSans
    slider.TextSize = 13
    slider.BorderSizePixel = 0
    slider.Parent = sliderFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 4)
    sliderCorner.Parent = slider
    
    slider.FocusLost:Connect(function()
        local value = tonumber(slider.Text)
        if value then
            value = math.clamp(value, min, max)
            slider.Text = tostring(value)
            label.Text = text .. ": " .. value
            if callback then callback(value) end
        else
            slider.Text = tostring(default)
        end
    end)
    
    if callback then callback(default) end
    
    return sliderFrame
end

function GUI:AddButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return btn
end

function GUI:AddLabel(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    
    return label
end

function GUI:AddTextbox(parent, placeholder, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -80, 1, -6)
    textBox.Position = UDim2.new(0, 5, 0, 3)
    textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    textBox.Text = ""
    textBox.PlaceholderText = placeholder or "Enter text..."
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 13
    textBox.BorderSizePixel = 0
    textBox.Parent = frame
    
    local textCorner = Instance.new("UICorner")
    textCorner.CornerRadius = UDim.new(0, 3)
    textCorner.Parent = textBox
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 28)
    btn.Position = UDim2.new(1, -65, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
    btn.Text = "Go"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        if callback and textBox.Text ~= "" then
            callback(textBox.Text)
        end
    end)
    
    return frame
end

function GUI:UpdateCanvas(scrollingFrame)
    local contentSize = 0
    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
            contentSize = contentSize + child.AbsoluteSize.Y + 8
        end
    end
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize + 10)
end

function GUI:MakeDraggable(frame)
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart = nil
    local frameStart = nil
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            frameStart = frame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Tab builders
function GUI:BuildMainTab()
    self:AddTabButton("Main", 0)
    local sf = self:CreateScrollingFrame("Main")
    
    self:AddToggle(sf, "Auto Attach", true, function(state)
        self.Config:Set("AutoAttach", state)
    end)
    
    self:AddToggle(sf, "FPS Unlocker", true, function(state)
        self.Config:Set("UnlockFPS", state)
        if state then
            self.Features:UnlockFPS(self.Config:Get("FPS_Cap") or 240)
        end
    end)
    
    self:AddSlider(sf, "FPS Cap", 30, 999, 240, function(value)
        self.Config:Set("FPS_Cap", value)
        if self.Config:Get("UnlockFPS") then
            self.Features:UnlockFPS(value)
        end
    end)
    
    self:AddSlider(sf, "Walk Speed", 16, 200, 16, function(value)
        self.Config:Set("WalkSpeed", value)
        self.Features:SetWalkSpeed(value)
    end)
    
    self:AddSlider(sf, "Jump Power", 50, 300, 50, function(value)
        self.Config:Set("JumpPower", value)
        self.Features:SetJumpPower(value)
    end)
    
    self:AddToggle(sf, "Infinite Jump", false, function(state)
        self.Features:InfiniteJump(state)
    end)
    
    self:AddToggle(sf, "NoClip", false, function(state)
        self.Config:Set("NoClip", state)
        self.Features:NoClip(state)
    end)
    
    self:AddToggle(sf, "Anti AFK", true, function(state)
        self.Config:Set("AntiAFK_Enabled", state)
        self.Features:AntiAFK(state)
    end)
    
    self:UpdateCanvas(sf)
    sf.Visible = true -- Default tab
end

function GUI:BuildTeleportsTab()
    self:AddTabButton("Teleports", 40)
    local sf = self:CreateScrollingFrame("Teleports")
    
    self:AddLabel(sf, "Preset Locations:")
    
    for _, loc in ipairs(self.Teleports:GetLocations()) do
        self:AddButton(sf, loc.Name .. " - " .. loc.Description, function()
            self.Teleports:TeleportTo(loc.Position)
            self.Library:Notify("Teleported", loc.Name, 2)
        end)
    end
    
    self:AddLabel(sf, "")
    self:AddLabel(sf, "Custom Teleport:")
    self:AddTextbox(sf, "Player name...", function(text)
        self.Teleports:TeleportToPlayer(text)
        self.Library:Notify("Teleported", "To player: " .. text, 2)
    end)
    
    self:AddTextbox(sf, "X, Y, Z (e.g. 0, 50, 0)", function(text)
        local parts = text:split(",")
        if #parts == 3 then
            local x = tonumber(parts[1])
            local y = tonumber(parts[2])
            local z = tonumber(parts[3])
            if x and y and z then
                self.Teleports:TeleportTo(Vector3.new(x, y, z))
                self.Library:Notify("Teleported", "To: " .. text, 2)
            end
        end
    end)
    
    self:AddButton(sf, "Save Current Position", function()
        local name = "Pos_" .. os.time()
        self.Teleports:SaveLocation(name)
        self.Library:Notify("Saved", name, 3)
    end)
    
    self:UpdateCanvas(sf)
end

function GUI:BuildAutoFarmTab()
    self:AddTabButton("AutoFarm", 80)
    local sf = self:CreateScrollingFrame("AutoFarm")
    
    self:AddToggle(sf, "Auto Farm", false, function(state)
        self.Config:Set("AutoFarm_Enabled", state)
        if state then
            self.AutoFarm:StartFarming(
                self.Config:Get("AutoFarm_Range") or 50,
                self.Config:Get("AutoFarm_Delay") or 0.5
            )
        else
            self.AutoFarm:StopFarming()
        end
    end)
    
    self:AddSlider(sf, "Farm Range", 10, 200, 50, function(value)
        self.Config:Set("AutoFarm_Range", value)
        if self.AutoFarm.IsFarming then
            self.AutoFarm:StopFarming()
            self.AutoFarm:StartFarming(value, self.Config:Get("AutoFarm_Delay") or 0.5)
        end
    end)
    
    self:AddSlider(sf, "Farm Delay (ms)", 0.1, 3, 0.5, function(value)
        self.Config:Set("AutoFarm_Delay", value)
        if self.AutoFarm.IsFarming then
            self.AutoFarm:StopFarming()
            self.AutoFarm:StartFarming(self.Config:Get("AutoFarm_Range") or 50, value)
        end
    end)
    
    self:AddToggle(sf, "Auto Click", false, function(state)
        self.AutoFarm:AutoClick(state, self.Config:Get("AutoFarm_Delay") or 0.1)
    end)
    
    self:AddButton(sf, "Auto Equip Tool", function()
        self.AutoFarm:AutoEquip()
        self.Library:Notify("AutoFarm", "Trying to equip best tool", 2)
    end)
    
    self:AddToggle(sf, "Aimbot", false, function(state)
        self.Config:Set("Aimbot_Enabled", state)
        self.Features:Aimbot(
            state,
            self.Config:Get("Aimbot_FOV") or 90,
            self.Config:Get("Aimbot_Smoothness") or 0.5,
            self.Config:Get("Aimbot_TargetPart") or "Head"
        )
    end)
    
    self:AddSlider(sf, "Aimbot FOV", 10, 360, 90, function(value)
        self.Config:Set("Aimbot_FOV", value)
        if self.Config:Get("Aimbot_Enabled") then
            self.Features:Aimbot(true, value, self.Config:Get("Aimbot_Smoothness") or 0.5, self.Config:Get("Aimbot_TargetPart") or "Head")
        end
    end)
    
    self:AddToggle(sf, "Kill Aura", false, function(state)
        self.Config:Set("KillAura_Enabled", state)
        self.Features:KillAura(state, self.Config:Get("KillAura_Range") or 15, self.Config:Get("KillAura_Delay") or 0.1)
    end)
    
    self:AddSlider(sf, "Kill Aura Range", 5, 50, 15, function(value)
        self.Config:Set("KillAura_Range", value)
        if self.Config:Get("KillAura_Enabled") then
            self.Features:KillAura(true, value, self.Config:Get("KillAura_Delay") or 0.1)
        end
    end)
    
    self:AddToggle(sf, "Fly", false, function(state)
        self.Config:Set("FlyEnabled", state)
        if state then
            self.Features:Fly(true, self.Config:Get("FlySpeed") or 50)
        else
            self.Features:StopFly()
        end
    end)
    
    self:AddSlider(sf, "Fly Speed", 10, 200, 50, function(value)
        self.Config:Set("FlySpeed", value)
    end)
    
    self:UpdateCanvas(sf)
end

function GUI:BuildESPTab()
    self:AddTabButton("ESP", 120)
    local sf = self:CreateScrollingFrame("ESP")
    
    self:AddToggle(sf, "Player ESP", false, function(state)
        self.Config:Set("ESP_Enabled", state)
        if state then
            self.ESP:Enable(self.Config)
        else
            self.ESP:Disable()
        end
    end)
    
    self:AddToggle(sf, "Item ESP", false, function(state)
        self.ESP:ToggleItemESP(state)
    end)
    
    self:AddSlider(sf, "ESP Transparency", 0, 1, 0.7, function(value)
        self.Config:Set("ESP_Transparency", value)
        if self.Config:Get("ESP_Enabled") then
            self.ESP:Disable()
            self.ESP:Enable(self.Config)
        end
    end)
    
    self:AddLabel(sf, "")
    self:AddLabel(sf, "Right Shift = Toggle GUI")
    self:AddLabel(sf, "GUI is draggable from title bar")
    
    self:UpdateCanvas(sf)
end

function GUI:BuildCreditsTab()
    self:AddTabButton("Credits", 160)
    local sf = self:CreateScrollingFrame("Credits")
    
    self:AddLabel(sf, "🧠 Steal a Brainrot Cheat")
    self:AddLabel(sf, "")
    self:AddLabel(sf, "Made with ❤️")
    self:AddLabel(sf, "")
    self:AddLabel(sf, "Features:")
    self:AddLabel(sf, "• Player ESP")
    self:AddLabel(sf, "• Item ESP")
    self:AddLabel(sf, "• Auto Farm")
    self:AddLabel(sf, "• Teleports")
    self:AddLabel(sf, "• Aimbot")
    self:AddLabel(sf, "• Kill Aura")
    self:AddLabel(sf, "• Fly")
    self:AddLabel(sf, "• NoClip")
    self:AddLabel(sf, "• Infinite Jump")
    self:AddLabel(sf, "• Anti AFK")
    self:AddLabel(sf, "• FPS Unlocker")
    self:AddLabel(sf, "")
    self:AddLabel(sf, "Use at your own risk!")
    
    self:AddButton(sf, "Disable All Features", function()
        self.Features:DisableAll()
        self.AutoFarm:StopFarming()
        self.ESP:Disable()
        self.Library:Notify("Disabled", "All features turned off", 3)
    end)
    
    self:UpdateCanvas(sf)
end

function GUI:ApplyConfig()
    -- Apply default config values
    if self.Config:Get("UnlockFPS") then
        self.Features:UnlockFPS(self.Config:Get("FPS_Cap") or 240)
    end
    
    if self.Config:Get("AntiAFK_Enabled") then
        self.Features:AntiAFK(true)
    end
    
    self.Features:SetWalkSpeed(self.Config:Get("WalkSpeed") or 16)
    self.Features:SetJumpPower(self.Config:Get("JumpPower") or 50)
end

return GUI
