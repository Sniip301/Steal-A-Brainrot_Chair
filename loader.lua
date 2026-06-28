--[[
    STEAL A BRAINROT - Loader
    Downloads required modules to workspace and executes main.lua
]]

local repo_url = "https://raw.githubusercontent.com/Sniip301/Steal-A-Brainrot_Chair/main/"
local script_path = "script"

-- Create folder structure
if not isfolder(script_path) then
    makefolder(script_path)
end

-- Modules list
local modules = {
    "config.lua",
    "lib.lua",
    "features.lua",
    "auto_farm.lua",
    "esp.lua",
    "gui.lua",
    "main.lua"
}

-- Download modules
for _, file in ipairs(modules) do
    local local_file_path = script_path .. "/" .. file
    local remote_url = repo_url .. file
    
    local success, content = pcall(game.HttpGet, game, remote_url)
    if success and content then
        writefile(local_file_path, content)
    else
        warn("[Loader] Failed to download: " .. file)
    end
end

-- Run main entrypoint
local main_path = script_path .. "/main.lua"
if isfile(main_path) then
    loadfile(main_path)()
else
    error("[Loader] main.lua not found, execution aborted.")
end
