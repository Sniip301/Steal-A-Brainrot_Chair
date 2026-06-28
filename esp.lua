--[[
    ESP Module
    Player, item, and entity highlighting
]]

local ESP = {}
ESP.__index = ESP

function ESP.new()
    local self = setmetatable({}, ESP)
    self.IsEnabled = false
    self.ESPItems = {}
    self.Connection = nil
    self.PlayerESP = {}
    self.ItemESP = {}
    return self
end

-- Create box ESP for players
function ESP:CreatePlayerESP(player, config)
    local espData = {}
    
    -- Create highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = config.ESP_BoxColor or Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = config.ESP_BoxColor or Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = config.ESP_Transparency or 0.7
    highlight.OutlineTransparency = 0.5
    highlight.Adornee = player.Character
    highlight.Parent = player.Character
    
    -- Create billboard gui for name
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = player.Character
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = config.ESP_NameColor or Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.Text = player.Name
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.Parent = billboard
    
    -- Distance label
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 1, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = config.ESP_DistanceColor or Color3.fromRGB(0, 255, 0)
    distLabel.TextStrokeTransparency = 0
    distLabel.Text = "0m"
    distLabel.Font = Enum.Font.SourceSans
    distLabel.TextScaled = true
    distLabel.Parent = billboard
    
    espData = {
        Player = player,
        Highlight = highlight,
        Billboard = billboard,
        DistanceLabel = distLabel
    }
    
    table.insert(self.PlayerESP, espData)
    return espData
end

-- Remove ESP for a specific player
function ESP:RemovePlayerESP(player)
    for i, espData in ipairs(self.PlayerESP) do
        if espData.Player == player then
            if espData.Highlight then espData.Highlight:Destroy() end
            if espData.Billboard then espData.Billboard:Destroy() end
            table.remove(self.PlayerESP, i)
            break
        end
    end
end

-- Update all player ESP distances
function ESP:UpdateDistances()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    for _, espData in ipairs(self.PlayerESP) do
        if espData.DistanceLabel and espData.Player.Character then
            local targetRoot = espData.Player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot and localRoot then
                local dist = math.floor((targetRoot.Position - localRoot.Position).Magnitude)
                espData.DistanceLabel.Text = dist .. "m"
            end
        end
    end
end

-- Item ESP
function ESP:CreateItemESP(item)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ItemESP"
    highlight.FillColor = Color3.fromRGB(255, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 200, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.3
    highlight.Adornee = item
    highlight.Parent = item
    
    table.insert(self.ItemESP, highlight)
    return highlight
end

function ESP:ClearItemESP()
    for _, highlight in ipairs(self.ItemESP) do
        pcall(function() highlight:Destroy() end)
    end
    self.ItemESP = {}
end

-- Enable ESP system
function ESP:Enable(config)
    self.IsEnabled = true
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    
    -- Clear existing
    self:Disable()
    
    -- ESP for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            self:CreatePlayerESP(player, config)
        end
    end
    
    -- Listen for new players
    self.PlayerAddedConn = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            if self.IsEnabled and player ~= Players.LocalPlayer then
                task.wait(0.5)
                self:CreatePlayerESP(player, config)
            end
        end)
    end)
    
    -- Listen for players leaving
    self.PlayerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayerESP(player)
    end)
    
    -- Update loop
    self.Connection = RunService.RenderStepped:Connect(function()
        if not self.IsEnabled then return end
        self:UpdateDistances()
        
        -- Re-check for characters without ESP
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and player.Character then
                local hasESP = false
                for _, espData in ipairs(self.PlayerESP) do
                    if espData.Player == player then
                        hasESP = true
                        break
                    end
                end
                if not hasESP then
                    self:CreatePlayerESP(player, config)
                end
            end
        end
    end)
    
    print("[ESP] Enabled")
end

function ESP:Disable()
    self.IsEnabled = false
    
    -- Disconnect updates
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    if self.PlayerAddedConn then
        self.PlayerAddedConn:Disconnect()
        self.PlayerAddedConn = nil
    end
    if self.PlayerRemovingConn then
        self.PlayerRemovingConn:Disconnect()
        self.PlayerRemovingConn = nil
    end
    
    -- Remove all player ESP
    for _, espData in ipairs(self.PlayerESP) do
        if espData.Highlight then espData.Highlight:Destroy() end
        if espData.Billboard then espData.Billboard:Destroy() end
    end
    self.PlayerESP = {}
    
    -- Remove item ESP
    self:ClearItemESP()
    
    print("[ESP] Disabled")
end

function ESP:ToggleItemESP(enabled)
    if enabled then
        self:ClearItemESP()
        -- Scan for collectible items
        for _, descendant in ipairs(workspace:GetDescendants()) do
            if descendant:IsA("BasePart") and (
                descendant.Name:lower():find("coin") or
                descendant.Name:lower():find("gem") or
                descendant.Name:lower():find("loot") or
                descendant.Name:lower():find("item")
            ) then
                self:CreateItemESP(descendant)
            end
        end
        print("[ESP] Item ESP enabled")
    else
        self:ClearItemESP()
        print("[ESP] Item ESP disabled")
    end
end

return ESP
