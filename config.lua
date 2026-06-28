--[[
    Configuration Module
    All customizable settings
]]

local Config = {}
Config.__index = Config

function Config.new()
    local self = setmetatable({}, Config)
    
    -- General
    self.AutoAttach = true
    self.AutoExecute = true
    self.UnlockFPS = true
    self.FPS_Cap = 240
    
    -- Visual Settings
    self.ESP_Enabled = false
    self.ESP_BoxColor = Color3.fromRGB(255, 0, 0)
    self.ESP_NameColor = Color3.fromRGB(255, 255, 255)
    self.ESP_DistanceColor = Color3.fromRGB(0, 255, 0)
    self.ESP_Transparency = 0.7
    
    -- Auto Farm
    self.AutoFarm_Enabled = false
    self.AutoFarm_Delay = 0.5
    self.AutoFarm_Range = 50
    
    -- Teleports
    self.Teleport_Instant = true
    
    -- Player
    self.WalkSpeed = 16
    self.JumpPower = 50
    self.NoClip = false
    self.FlySpeed = 50
    self.FlyEnabled = false
    
    -- Aimbot
    self.Aimbot_Enabled = false
    self.Aimbot_FOV = 90
    self.Aimbot_Smoothness = 0.5
    self.Aimbot_TargetPart = "Head"
    
    -- Kill Aura
    self.KillAura_Enabled = false
    self.KillAura_Range = 15
    self.KillAura_Delay = 0.1
    
    -- Anti AFK
    self.AntiAFK_Enabled = true
    
    return self
end

function Config:Get(key)
    return self[key]
end

function Config:Set(key, value)
    self[key] = value
end

return Config -- test trigger
