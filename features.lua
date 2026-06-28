--[[
    Features Module
    Player enhancements: speed, fly, noclip, aimbot, kill aura
]]

local Features = {}
Features.__index = Features

function Features.new()
    local self = setmetatable({}, Features)
    self.ActiveConnections = {}
    self.FlyConnection = nil
    self.AimbotConnection = nil
    self.KillAuraConnection = nil
    return self
end

-- WalkSpeed & JumpPower
function Features:SetWalkSpeed(speed)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = speed
    end
end

function Features:SetJumpPower(power)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = power
    end
end

-- Infinite Jump
function Features:InfiniteJump(enabled)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    
    if self.InfiniteJumpConn then
        self.InfiniteJumpConn:Disconnect()
        self.InfiniteJumpConn = nil
    end
    
    if enabled then
        self.InfiniteJumpConn = UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

-- NoClip
function Features:NoClip(enabled)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    
    if self.NoClipConnection then
        self.NoClipConnection:Disconnect()
        self.NoClipConnection = nil
    end
    
    if enabled then
        self.NoClipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        -- Restore collisions
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Fly
function Features:Fly(enabled, speed)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    
    if self.FlyConnection then
        self.FlyConnection:Disconnect()
        self.FlyConnection = nil
    end
    
    if enabled then
        local flying = true
        local bodyGyro, bodyVel
        
        -- Create body movers
        local function setupFly()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = LocalPlayer.Character.HumanoidRootPart
                
                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
                bodyGyro.CFrame = root.CFrame
                bodyGyro.Parent = root
                
                bodyVel = Instance.new("BodyVelocity")
                bodyVel.MaxForce = Vector3.new(400000, 400000, 400000)
                bodyVel.Velocity = Vector3.zero
                bodyVel.Parent = root
                
                LocalPlayer.Character.Humanoid.PlatformStand = true
            end
        end
        
        setupFly()
        
        -- Keyboard controls
        local keys = { W = false, A = false, S = false, D = false, Space = false, LeftControl = false }
        
        local inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.W then keys.W = true
            elseif input.KeyCode == Enum.KeyCode.A then keys.A = true
            elseif input.KeyCode == Enum.KeyCode.S then keys.S = true
            elseif input.KeyCode == Enum.KeyCode.D then keys.D = true
            elseif input.KeyCode == Enum.KeyCode.Space then keys.Space = true
            elseif input.KeyCode == Enum.KeyCode.LeftControl then keys.LeftControl = true
            end
        end)
        
        local inputEnded = UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.W then keys.W = false
            elseif input.KeyCode == Enum.KeyCode.A then keys.A = false
            elseif input.KeyCode == Enum.KeyCode.S then keys.S = false
            elseif input.KeyCode == Enum.KeyCode.D then keys.D = false
            elseif input.KeyCode == Enum.KeyCode.Space then keys.Space = false
            elseif input.KeyCode == Enum.KeyCode.LeftControl then keys.LeftControl = false
            end
        end)
        
        self.FlyConnection = RunService.RenderStepped:Connect(function()
            if not flying then return end
            if bodyGyro and bodyVel and LocalPlayer.Character then
                local camera = workspace.CurrentCamera
                if camera then
                    bodyGyro.CFrame = camera.CFrame
                    
                    local direction = Vector3.zero
                    if keys.W then direction = direction + camera.CFrame.LookVector end
                    if keys.S then direction = direction - camera.CFrame.LookVector end
                    if keys.A then direction = direction - camera.CFrame.RightVector end
                    if keys.D then direction = direction + camera.CFrame.RightVector end
                    if keys.Space then direction = direction + Vector3.new(0, 1, 0) end
                    if keys.LeftControl then direction = direction - Vector3.new(0, 1, 0) end
                    
                    bodyVel.Velocity = direction * (speed or 50)
                end
            end
        end)
        
        -- Cleanup stored refs
        self._flyInputBegan = inputBegan
        self._flyInputEnded = inputEnded
        self._flyBodyGyro = bodyGyro
        self._flyBodyVel = bodyVel
    end
end

function Features:StopFly()
    if self.FlyConnection then
        self.FlyConnection:Disconnect()
        self.FlyConnection = nil
    end
    if self._flyInputBegan then self._flyInputBegan:Disconnect() end
    if self._flyInputEnded then self._flyInputEnded:Disconnect() end
    if self._flyBodyGyro then self._flyBodyGyro:Destroy() end
    if self._flyBodyVel then self._flyBodyVel:Destroy() end
    
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.PlatformStand = false
    end
end

-- Aimbot
function Features:Aimbot(enabled, fov, smoothness, targetPart)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    if self.AimbotConnection then
        self.AimbotConnection:Disconnect()
        self.AimbotConnection = nil
    end
    
    if enabled then
        self.AimbotConnection = RunService.RenderStepped:Connect(function()
            local camera = workspace.CurrentCamera
            if not camera or not LocalPlayer.Character then return end
            
            local nearest = nil
            local nearestDistance = fov or 90
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local part = player.Character:FindFirstChild(targetPart or "Head")
                    if part then
                        local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                            local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if distance < nearestDistance then
                                nearestDistance = distance
                                nearest = part
                            end
                        end
                    end
                end
            end
            
            if nearest then
                local targetPos = nearest.Position
                local currentCFrame = camera.CFrame
                local lookAt = CFrame.new(currentCFrame.Position, targetPos)
                camera.CFrame = currentCFrame:Lerp(lookAt, smoothness or 0.5)
            end
        end)
    end
end

-- Kill Aura
function Features:KillAura(enabled, range, delay)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    if self.KillAuraConnection then
        self.KillAuraConnection:Disconnect()
        self.KillAuraConnection = nil
    end
    
    if enabled then
        local lastAttack = 0
        self.KillAuraConnection = game:GetService("RunService").Heartbeat:Connect(function(step)
            local now = tick()
            if now - lastAttack < (delay or 0.1) then return end
            lastAttack = now
            
            if not LocalPlayer.Character then return end
            local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not localRoot then return end
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if root and humanoid and humanoid.Health > 0 then
                        if (root.Position - localRoot.Position).Magnitude <= (range or 15) then
                            -- Simulate attack
                            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                            if tool and tool:FindFirstChild("Handle") then
                                tool:Activate()
                                task.wait(0.05)
                                tool:Deactivate()
                            end
                        end
                    end
                end
            end
        end)
    end
end

-- Anti AFK
function Features:AntiAFK(enabled)
    local VirtualUser = game:GetService("VirtualUser")
    
    if self.AntiAFKConnection then
        self.AntiAFKConnection:Disconnect()
        self.AntiAFKConnection = nil
    end
    
    if enabled then
        self.AntiAFKConnection = game:GetService("RunService").Heartbeat:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
end

-- FPS Unlocker
function Features:UnlockFPS(cap)
    pcall(function()
        setfpscap(cap or 240)
    end)
end

function Features:DisableAll()
    self:StopFly()
    self:InfiniteJump(false)
    self:NoClip(false)
    self:Aimbot(false)
    self:KillAura(false)
    self:AntiAFK(false)
end

return Features
