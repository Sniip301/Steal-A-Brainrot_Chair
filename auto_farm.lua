--[[
    Auto Farm Module
    Automatic collection, farming, and grinding
]]

local AutoFarm = {}
AutoFarm.__index = AutoFarm

function AutoFarm.new()
    local self = setmetatable({}, AutoFarm)
    self.FarmConnection = nil
    self.IsFarming = false
    self.ItemsFarmed = 0
    self.TargetTypes = { "Coin", "Gem", "Tool", "Part", "Loot", "Item", "Collectible" }
    return self
end

-- Start auto farming collectibles
function AutoFarm:StartFarming(range, delay)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    
    if self.FarmConnection then
        self:StopFarming()
    end
    
    self.IsFarming = true
    self.ItemsFarmed = 0
    
    self.FarmConnection = RunService.Heartbeat:Connect(function()
        if not self.IsFarming then return end
        if not LocalPlayer.Character then return end
        
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if not root or not humanoid then return end
        
        local farmRange = range or 50
        local nearest = nil
        local nearestDistance = farmRange
        
        -- Search workspace for collectible items
        for _, descendant in ipairs(workspace:GetDescendants()) do
            -- Check if it's a collectible
            local isCollectible = false
            for _, targetType in ipairs(self.TargetTypes) do
                if descendant.Name:lower():find(targetType:lower()) then
                    isCollectible = true
                    break
                end
            end
            
            -- Also check for proximity prompts
            if descendant:IsA("ProximityPrompt") then
                isCollectible = true
            end
            
            if isCollectible and descendant:IsA("BasePart") then
                local dist = (descendant.Position - root.Position).Magnitude
                if dist < nearestDistance then
                    nearestDistance = dist
                    nearest = descendant
                end
            end
        end
        
        -- Move to nearest item
        if nearest then
            humanoid:MoveTo(nearest.Position)
            
            -- If very close, try to collect
            if nearestDistance <= 5 then
                -- Fire proximity prompts
                for _, prompt in ipairs(nearest:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        pcall(function()
                            prompt:InputHoldBegin()
                            task.wait(0.1)
                            prompt:InputHoldEnd()
                        end)
                    end
                end
                
                -- Touch interest
                pcall(function()
                    firetouchinterest(root, nearest, 0)
                    task.wait(0.05)
                    firetouchinterest(root, nearest, 1)
                end)
                
                self.ItemsFarmed = self.ItemsFarmed + 1
            end
        end
        
        task.wait(delay or 0.5)
    end)
    
    print("[AutoFarm] Started farming (Range: " .. (range or 50) .. ")")
end

function AutoFarm:StopFarming()
    if self.FarmConnection then
        self.FarmConnection:Disconnect()
        self.FarmConnection = nil
    end
    self.IsFarming = false
    print("[AutoFarm] Stopped farming. Items farmed: " .. self.ItemsFarmed)
end

-- Auto click for tools
function AutoFarm:AutoClick(enabled, delay)
    local VirtualInputManager = game:GetService("VirtualInputManager")
    
    if self.ClickConnection then
        self.ClickConnection:Disconnect()
        self.ClickConnection = nil
    end
    
    if enabled then
        self.ClickConnection = game:GetService("RunService").Heartbeat:Connect(function()
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
            end)
            task.wait(delay or 0.1)
        end)
    end
end

-- Auto equip best tool
function AutoFarm:AutoEquip()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if not LocalPlayer.Backpack then return end
    
    -- Find first tool
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            LocalPlayer.Character and item.Parent = LocalPlayer.Character
            print("[AutoFarm] Equipped: " .. item.Name)
            return true
        end
    end
    return false
end

return AutoFarm
