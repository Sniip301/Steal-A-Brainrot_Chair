--[[
    STEAL A BRAINROT - Cheat Script
    Main Loader & Initialization
]]

-- Environment check
local PlaceId = game.PlaceId
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Anti-detection
if getgenv then
    getgenv().script_key = "BRAINROT_FREE_2024"
end

-- Load order
local script_path = "script"

-- Load config first
local config = loadfile(script_path .. "/config.lua")()

-- Load libraries
local library = loadfile(script_path .. "/lib.lua")()
local features = loadfile(script_path .. "/features.lua")()
local teleports = loadfile(script_path .. "/teleports.lua")()
local autofarm = loadfile(script_path .. "/auto_farm.lua")()
local esp = loadfile(script_path .. "/esp.lua")()

-- Build GUI
local gui = loadfile(script_path .. "/gui.lua")()
gui:Initialize(library, features, teleports, autofarm, esp, config)

-- Welcome notification
library:Notify("Steal a Brainrot Cheat", "Loaded successfully!", 5)

print("[Brainrot Cheat] All modules loaded!")
print("[Brainrot Cheat] Welcome, " .. LocalPlayer.Name)
