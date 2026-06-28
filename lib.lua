--[[
    Library Module
    Core utilities, notifications, and helper functions
]]

local Library = {}
Library.__index = Library

function Library.new()
    local self = setmetatable({}, Library)
    self.ConnectionCache = {}
    return self
end

-- Notification system
function Library:Notify(title, message, duration)
    local StarterGui = game:GetService("StarterGui")
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Brainrot Cheat",
            Text = message or "",
            Duration = duration or 3
        })
    end)
    print(string.format("[%s] %s", title, message))
end

-- Safe connection with auto-cache
function Library:Connect(signal, callback)
    if not signal then return nil end
    local conn = signal:Connect(callback)
    table.insert(self.ConnectionCache, conn)
    return conn
end

-- Disconnect all
function Library:DisconnectAll()
    for _, conn in ipairs(self.ConnectionCache) do
        pcall(function() conn:Disconnect() end)
    end
    self.ConnectionCache = {}
end

-- Get nearest player
function Library:GetNearestPlayer(range)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local nearest = nil
    local shortest = range or math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and localRoot then
                local dist = (root.Position - localRoot.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    nearest = player
                end
            end
        end
    end
    return nearest, shortest
end

-- World to screen (for ESP)
function Library:WorldToScreen(position)
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local screenPos, onScreen = camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

-- Tween movement
function Library:TweenTo(part, target, speed)
    local tweenInfo = TweenInfo.new(
        (target - part.Position).Magnitude / (speed or 50),
        Enum.EasingStyle.Linear
    )
    local tween = game:GetService("TweenService"):Create(part, tweenInfo, {
        CFrame = CFrame.new(target)
    })
    tween:Play()
    return tween
end

-- Get all alive characters in workspace
function Library:GetAliveCharacters()
    local chars = {}
    local Players = game:GetService("Players")
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            if humanoid.Health > 0 then
                table.insert(chars, player.Character)
            end
        end
    end
    return chars
end

-- Simple random string
function Library:RandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, (length or 10) do
        local rand = math.random(1, #chars)
        result = result .. chars:sub(rand, rand)
    end
    return result
end

-- Is in game check
function Library:IsInGame()
    return game.PlaceId ~= nil and game:IsLoaded()
end

return Library
