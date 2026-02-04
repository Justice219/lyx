lyx = lyx
lyx.configHandlers = lyx.configHandlers or {}

--[[
    Lyx Configuration Handlers
    Applies configuration settings to the server in real-time
]]--

-- Initialize default settings
local function InitializeDefaultSettings()
    -- General Settings
    if not lyx:HasSetting("server_name") then
        lyx:SetSetting("server_name", GetHostName())
    end
    
    if not lyx:HasSetting("welcome_message") then
        lyx:SetSetting("welcome_message", "Welcome to our Lyx-powered server!")
    end
    
    if not lyx:HasSetting("enable_logging") then
        lyx:SetSetting("enable_logging", true)
    end
    
    if not lyx:HasSetting("debug_mode") then
        lyx:SetSetting("debug_mode", false)
    end
    
    -- Security Settings
    if not lyx:HasSetting("anti_exploit") then
        lyx:SetSetting("anti_exploit", true)
    end
    
    if not lyx:HasSetting("rate_limiting") then
        lyx:SetSetting("rate_limiting", true)
    end
    
    if not lyx:HasSetting("max_rate_limit") then
        lyx:SetSetting("max_rate_limit", 60)
    end
    
    -- Performance Settings
    if not lyx:HasSetting("cache_lifetime") then
        lyx:SetSetting("cache_lifetime", 300)
    end
    
    if not lyx:HasSetting("auto_save") then
        lyx:SetSetting("auto_save", true)
    end
    
    -- Panel Access Settings
    if not lyx:HasSetting("panel_ranks") then
        lyx:SetSetting("panel_ranks", {"superadmin", "admin", "operator"})
    end
end

-- Apply server name
lyx.configHandlers["server_name"] = function(value)
    if type(value) == "string" and #value > 0 then
        RunConsoleCommand("hostname", value)
        lyx.Logger:Log("Server name updated to: " .. value)
    end
end

-- Apply welcome message
lyx.configHandlers["welcome_message"] = function(value)
    if type(value) == "string" then
        -- Store for player spawn hook
        lyx.welcomeMessage = value
        lyx.Logger:Log("Welcome message updated")
    end
end

-- Apply logging setting
lyx.configHandlers["enable_logging"] = function(value)
    if type(value) == "boolean" then
        lyx.Logger.enabled = value
        lyx.Logger:Log("Logging " .. (value and "enabled" or "disabled"))
    end
end

-- Apply debug mode
lyx.configHandlers["debug_mode"] = function(value)
    if type(value) == "boolean" then
        lyx.debugMode = value
        lyx.Logger:Log("Debug mode " .. (value and "enabled" or "disabled"))
    end
end

-- Apply anti-exploit setting
lyx.configHandlers["anti_exploit"] = function(value)
    if type(value) == "boolean" then
        lyx.antiExploitEnabled = value
        
        if value then
            -- Enable anti-exploit hooks
            hook.Add("PlayerNoClip", "Lyx.AntiExploit.NoClip", function(ply, desiredState)
                if desiredState and not ply:IsAdmin() then
                    lyx.Logger:Log("Blocked noclip attempt from: " .. ply:Nick(), 2)
                    return false
                end
            end)
            
            hook.Add("PlayerSpawnProp", "Lyx.AntiExploit.PropLimit", function(ply, model)
                if not ply:IsAdmin() then
                    local count = 0
                    for _, ent in ipairs(ents.GetAll()) do
                        if ent:GetClass() == "prop_physics" and ent:GetOwner() == ply then
                            count = count + 1
                        end
                    end
                    
                    if count > 50 then
                        lyx.Logger:Log("Blocked prop spawn (limit) from: " .. ply:Nick(), 2)
                        return false
                    end
                end
            end)
        else
            -- Remove anti-exploit hooks
            hook.Remove("PlayerNoClip", "Lyx.AntiExploit.NoClip")
            hook.Remove("PlayerSpawnProp", "Lyx.AntiExploit.PropLimit")
        end
        
        lyx.Logger:Log("Anti-exploit " .. (value and "enabled" or "disabled"))
    end
end

-- Apply rate limiting
lyx.configHandlers["rate_limiting"] = function(value)
    if type(value) == "boolean" then
        lyx.rateLimitingEnabled = value
        lyx.Logger:Log("Rate limiting " .. (value and "enabled" or "disabled"))
    end
end

-- Apply max rate limit
lyx.configHandlers["max_rate_limit"] = function(value)
    if type(value) == "number" and value > 0 then
        lyx.maxRateLimit = value
        lyx.Logger:Log("Max rate limit set to: " .. value .. " requests/minute")
    end
end

-- Apply cache lifetime
lyx.configHandlers["cache_lifetime"] = function(value)
    if type(value) == "number" and value > 0 then
        lyx.cacheLifetime = value
        lyx.Logger:Log("Cache lifetime set to: " .. value .. " seconds")
    end
end

-- Apply auto save
lyx.configHandlers["auto_save"] = function(value)
    if type(value) == "boolean" then
        lyx.autoSaveEnabled = value
        
        if value then
            -- Start auto-save timer
            timer.Create("Lyx.AutoSave", 300, 0, function()
                lyx:SaveAllSettings()
                lyx.Logger:Log("Auto-save completed")
            end)
        else
            -- Stop auto-save timer
            timer.Remove("Lyx.AutoSave")
        end
        
        lyx.Logger:Log("Auto-save " .. (value and "enabled" or "disabled"))
    end
end

-- Apply panel ranks
lyx.configHandlers["panel_ranks"] = function(value)
    if type(value) == "table" then
        lyx.panelRanks = value
        lyx.Logger:Log("Panel access ranks updated")
    end
end

-- Hook into setting changes
hook.Add("Lyx.SettingChanged", "Lyx.ConfigHandler", function(key, value)
    if lyx.configHandlers[key] then
        lyx.configHandlers[key](value)
    end
end)

-- Apply all current settings on server start
hook.Add("Initialize", "Lyx.ConfigInit", function()
    -- Initialize defaults first
    InitializeDefaultSettings()
    
    -- Apply all settings
    local settings = lyx:LoadSettings()
    for key, value in pairs(settings) do
        if lyx.configHandlers[key] then
            lyx.configHandlers[key](value)
        end
    end
    
    lyx.Logger:Log("Configuration system initialized")
end)

-- Welcome message hook
hook.Add("PlayerInitialSpawn", "Lyx.WelcomeMessage", function(ply)
    if lyx.welcomeMessage and #lyx.welcomeMessage > 0 then
        timer.Simple(1, function()
            if IsValid(ply) then
                ply:ChatPrint(lyx.welcomeMessage)
            end
        end)
    end
end)

-- Update CheckRank to use panel_ranks setting
local oldCheckRank = lyx.CheckRank
function lyx:CheckRank(ply, requiredRank)
    if requiredRank then
        -- Use original function for specific rank checks
        return oldCheckRank(self, ply, requiredRank)
    end
    
    -- Check if player can access panel
    local allowedRanks = lyx:GetSetting("panel_ranks") or {"superadmin", "admin", "operator"}
    local playerRank = ply:GetUserGroup()
    
    for _, rank in ipairs(allowedRanks) do
        if string.lower(playerRank) == string.lower(rank) then
            return true
        end
    end
    
    -- Also check superadmin always has access
    if ply:IsSuperAdmin() then
        return true
    end
    
    return false
end

-- Save all settings function
function lyx:SaveAllSettings()
    local settings = lyx:LoadSettings()
    if settings then
        -- Force write to disk
        file.Write("lyx_settings.txt", util.TableToJSON(settings, true))
        lyx.Logger:Log("All settings saved to disk")
    end
end

-- Rate limiting implementation
local playerRequestTimes = {}

hook.Add("Lyx.NetworkReceived", "Lyx.RateLimiting", function(ply, messageName)
    if not lyx.rateLimitingEnabled then return end
    
    local steamID = ply:SteamID()
    playerRequestTimes[steamID] = playerRequestTimes[steamID] or {}
    
    local now = CurTime()
    local requests = playerRequestTimes[steamID]
    
    -- Clean old requests
    for i = #requests, 1, -1 do
        if requests[i] < now - 60 then
            table.remove(requests, i)
        end
    end
    
    -- Check rate limit
    if #requests >= (lyx.maxRateLimit or 60) then
        lyx.Logger:Log("Rate limit exceeded for: " .. ply:Nick() .. " (" .. messageName .. ")", 2)
        return false -- Block the request
    end
    
    -- Add current request
    table.insert(requests, now)
end)

-- Note: SetSetting in sv_lyx_setting.lua already fires the Lyx.SettingChanged hook

lyx.Logger:Log("Config handler system loaded")