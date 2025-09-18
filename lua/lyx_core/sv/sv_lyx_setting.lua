lyx = lyx

--[[
    Lyx Settings System
    Provides a cached, secure key-value storage system with validation
]]--

do
    -- Settings cache to improve performance
    local settingsCache = nil
    local cacheTimestamp = 0
    local CACHE_LIFETIME = 5  -- Cache lifetime in seconds
    local SETTINGS_FILE = "lyx_settings.txt"
    local MAX_KEY_LENGTH = 128
    local MAX_VALUE_SIZE = 65536  -- 64KB max value size
    
    --[[
        Validate a settings key
        @param key string - Key to validate
        @return boolean - True if valid
    ]]
    local function ValidateKey(key)
        if type(key) ~= "string" then
            return false
        end
        
        if #key == 0 or #key > MAX_KEY_LENGTH then
            return false
        end
        
        -- Only allow alphanumeric, underscore, dash, and dot
        if string.match(key, "[^%w%-%_%.]") then
            return false
        end
        
        return true
    end
    
    --[[
        Validate a settings value
        @param value any - Value to validate
        @return boolean - True if valid
    ]]
    local function ValidateValue(value)
        -- Allow basic types
        local vType = type(value)
        if vType == "string" then
            return #value <= MAX_VALUE_SIZE
        elseif vType == "number" or vType == "boolean" then
            return true
        elseif vType == "table" then
            -- Check table size when serialized
            local success, json = pcall(util.TableToJSON, value)
            return success and json and #json <= MAX_VALUE_SIZE
        end
        
        return false
    end
    
    --[[
        Load settings with caching support
        @param forceReload boolean - Force reload from disk
        @return table - Settings table (never nil)
    ]]
    function lyx:LoadSettings(forceReload)
        local now = CurTime and CurTime() or os.time()
        
        -- Check cache validity
        if not forceReload and settingsCache and (now - cacheTimestamp) < CACHE_LIFETIME then
            return settingsCache
        end
        
        -- Load from disk
        local settings = lyx:JSONLoad(SETTINGS_FILE, {})
        
        -- Ensure we always return a table
        if type(settings) ~= "table" then
            settings = {}
        end
        
        -- Update cache
        settingsCache = settings
        cacheTimestamp = now
        
        lyx.Logger:Log("Settings loaded (" .. table.Count(settings) .. " entries)")
        return settings
    end
    
    --[[
        Save settings to disk and update cache
        @param settings table - Settings to save
        @return boolean - True on success
    ]]
    local function SaveSettings(settings)
        if type(settings) ~= "table" then
            return false
        end
        
        -- Save to disk
        local success = lyx:JSONSave(SETTINGS_FILE, settings, true)
        
        if success then
            -- Update cache
            settingsCache = settings
            cacheTimestamp = CurTime and CurTime() or os.time()
        end
        
        return success
    end
    
    --[[
        Set a setting value with validation
        @param key string - Setting key
        @param value any - Setting value
        @return boolean - True on success
    ]]
    function lyx:SetSetting(key, value)
        -- Validate inputs
        if not ValidateKey(key) then
            lyx.Logger:Log("Invalid setting key: " .. tostring(key), 3)
            return false
        end
        
        if not ValidateValue(value) then
            lyx.Logger:Log("Invalid setting value for key: " .. key, 3)
            return false
        end
        
        -- Load current settings
        local settings = lyx:LoadSettings()
        
        -- Store old value for logging
        local oldValue = settings[key]
        
        -- Update value
        settings[key] = value
        
        -- Save to disk
        if not SaveSettings(settings) then
            lyx.Logger:Log("Failed to save setting: " .. key, 3)
            return false
        end
        
        -- Log the change
        if oldValue ~= nil then
            lyx.Logger:Log("Updated setting '" .. key .. "'")
        else
            lyx.Logger:Log("Created new setting '" .. key .. "'")
        end
        
        return true
    end
    
    --[[
        Get a setting value with optional default
        @param key string - Setting key
        @param default any - Default value if key not found
        @return any - Setting value or default
    ]]
    function lyx:GetSetting(key, default)
        -- Validate key
        if not ValidateKey(key) then
            lyx.Logger:Log("Invalid setting key: " .. tostring(key), 2)
            return default
        end
        
        -- Load settings
        local settings = lyx:LoadSettings()
        
        -- Return value or default
        local value = settings[key]
        if value ~= nil then
            return value
        end
        
        return default
    end
    
    --[[
        Remove a setting
        @param key string - Setting key to remove
        @return boolean - True if removed, false if not found or error
    ]]
    function lyx:RemoveSetting(key)
        -- Validate key
        if not ValidateKey(key) then
            lyx.Logger:Log("Invalid setting key: " .. tostring(key), 3)
            return false
        end
        
        -- Load settings
        local settings = lyx:LoadSettings()
        
        -- Check if key exists
        if settings[key] == nil then
            lyx.Logger:Log("Setting not found: " .. key, 1)
            return false
        end
        
        -- Remove key
        settings[key] = nil
        
        -- Save to disk
        if not SaveSettings(settings) then
            lyx.Logger:Log("Failed to remove setting: " .. key, 3)
            return false
        end
        
        lyx.Logger:Log("Removed setting '" .. key .. "'")
        return true
    end
    
    --[[
        Check if a setting exists
        @param key string - Setting key
        @return boolean - True if exists
    ]]
    function lyx:HasSetting(key)
        if not ValidateKey(key) then
            return false
        end
        
        local settings = lyx:LoadSettings()
        return settings[key] ~= nil
    end
    
    --[[
        Get all setting keys
        @return table - Array of setting keys
    ]]
    function lyx:GetSettingKeys()
        local settings = lyx:LoadSettings()
        local keys = {}
        
        for k, _ in pairs(settings) do
            table.insert(keys, k)
        end
        
        table.sort(keys)
        return keys
    end
    
    --[[
        Clear all settings
        @param confirm string - Must be "CONFIRM" to execute
        @return boolean - True if cleared
    ]]
    function lyx:ClearAllSettings(confirm)
        if confirm ~= "CONFIRM" then
            lyx.Logger:Log("Clear all settings requires confirmation", 2)
            return false
        end
        
        -- Clear cache
        settingsCache = {}
        cacheTimestamp = 0
        
        -- Save empty settings
        if not SaveSettings({}) then
            lyx.Logger:Log("Failed to clear settings", 3)
            return false
        end
        
        lyx.Logger:Log("All settings cleared", 2)
        return true
    end
    
    --[[
        Bulk update settings
        @param updates table - Table of key-value pairs to update
        @return boolean - True if all updates succeeded
    ]]
    function lyx:BulkSetSettings(updates)
        if type(updates) ~= "table" then
            lyx.Logger:Log("Invalid updates table for bulk set", 3)
            return false
        end
        
        -- Validate all keys and values first
        for key, value in pairs(updates) do
            if not ValidateKey(key) then
                lyx.Logger:Log("Invalid key in bulk update: " .. tostring(key), 3)
                return false
            end
            
            if not ValidateValue(value) then
                lyx.Logger:Log("Invalid value for key in bulk update: " .. key, 3)
                return false
            end
        end
        
        -- Load current settings
        local settings = lyx:LoadSettings()
        
        -- Apply all updates
        for key, value in pairs(updates) do
            settings[key] = value
        end
        
        -- Save to disk
        if not SaveSettings(settings) then
            lyx.Logger:Log("Failed to save bulk settings update", 3)
            return false
        end
        
        lyx.Logger:Log("Bulk updated " .. table.Count(updates) .. " settings")
        return true
    end
    
    -- Invalidate cache on certain hooks
    if SERVER then
        hook.Add("ShutDown", "lyx_settings_save", function()
            -- Force save on shutdown if cache is dirty
            if settingsCache then
                SaveSettings(settingsCache)
            end
        end)
    end
end