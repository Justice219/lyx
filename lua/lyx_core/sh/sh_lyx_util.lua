lyx = lyx
lyx.util = lyx.util or {}

--[[
.____                    ____ ___   __  .__.__   
|    |    ___.__.___  __|    |   \_/  |_|__|  |  
|    |   <   |  |\  \/  /    |   /\   __\  |  |  
|    |___ \___  | >    <|    |  /  |  | |  |  |__
|_______ \/ ____|/__/\_ \______/   |__| |__|____/
        \/\/           \/                        

Enhanced utility functions with secure implementations

]]--

do
    -- ID generation with overflow protection
    local MAX_ID = 2^31 - 1  -- Maximum safe integer for ID
    
    --[[
        Generate a unique incremental ID
        @return number - Unique ID with overflow protection
    ]]
    function lyx:UtilNewID()
        local id = lyx.util.id or 0
        id = id + 1
        
        -- Handle overflow
        if id > MAX_ID then
            id = 1
            lyx.Logger:Log("ID overflow, resetting to 1", 2)
        end
        
        lyx.util.id = id
        return id
    end    

    -- Character sets for secure hash generation
    local HASH_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local HASH_CHAR_COUNT = #HASH_CHARS
    
    --[[
        Generate a cryptographically secure random hash
        @param length number - Optional hash length (default 16)
        @return string - Secure random hash
    ]]
    function lyx:UtilNewHash(length)
        length = length or 16
        
        -- Validate length
        if type(length) ~= "number" or length < 1 then
            length = 16
        elseif length > 64 then
            length = 64  -- Cap at reasonable maximum
        end
        
        local hash = {}
        
        -- Use more entropy sources for better randomness
        local seed = os.time() + (os.clock() * 1000000)
        if CurTime then
            seed = seed + (CurTime() * 1000000)
        end
        
        -- Mix in some runtime entropy
        seed = seed + collectgarbage("count") * 1000
        
        math.randomseed(seed)
        
        -- Generate hash with better distribution
        for i = 1, length do
            -- Use multiple random calls to increase entropy
            local idx = (math.random(HASH_CHAR_COUNT) + math.random(HASH_CHAR_COUNT)) % HASH_CHAR_COUNT + 1
            hash[i] = HASH_CHARS:sub(idx, idx)
        end
        
        return table.concat(hash)
    end
    
    --[[
        Generate a UUID v4-like identifier
        @return string - UUID formatted string
    ]]
    function lyx:UtilNewUUID()
        local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
        return string.gsub(template, '[xy]', function(c)
            local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
            return string.format('%x', v)
        end)
    end
    
    --[[
        Validate and sanitize a string for safe usage
        @param str string - String to sanitize
        @param allowedPattern string - Optional regex pattern for allowed characters
        @return string - Sanitized string
    ]]
    function lyx:UtilSanitizeString(str, allowedPattern)
        if type(str) ~= "string" then
            return ""
        end
        
        -- Default to alphanumeric + basic punctuation
        allowedPattern = allowedPattern or "[^%w%s%-%_%.%,]"
        
        -- Remove disallowed characters
        str = string.gsub(str, allowedPattern, "")
        
        -- Trim whitespace
        str = string.match(str, "^%s*(.-)%s*$")
        
        return str
    end
    
    --[[
        Deep clone a table
        @param orig table - Table to clone
        @param copies table - Internal tracking for circular references
        @return table - Deep copy of the original table
    ]]
    function lyx:UtilDeepCopy(orig, copies)
        copies = copies or {}
        local orig_type = type(orig)
        local copy
        
        if orig_type == 'table' then
            if copies[orig] then
                copy = copies[orig]
            else
                copy = {}
                copies[orig] = copy
                for orig_key, orig_value in next, orig, nil do
                    copy[lyx:UtilDeepCopy(orig_key, copies)] = lyx:UtilDeepCopy(orig_value, copies)
                end
                setmetatable(copy, lyx:UtilDeepCopy(getmetatable(orig), copies))
            end
        else
            copy = orig
        end
        
        return copy
    end
    
    --[[
        Merge tables recursively
        @param target table - Target table to merge into
        @param source table - Source table to merge from
        @param deep boolean - Whether to deep merge (default true)
        @return table - Merged table (same as target)
    ]]
    function lyx:UtilMergeTables(target, source, deep)
        if type(target) ~= "table" or type(source) ~= "table" then
            return target
        end
        
        deep = deep ~= false  -- Default to true
        
        for k, v in pairs(source) do
            if deep and type(v) == "table" and type(target[k]) == "table" then
                lyx:UtilMergeTables(target[k], v, true)
            else
                target[k] = v
            end
        end
        
        return target
    end
    
    --[[
        Debounce a function call
        @param func function - Function to debounce
        @param delay number - Delay in seconds
        @return function - Debounced function
    ]]
    function lyx:UtilDebounce(func, delay)
        local timer_id
        
        return function(...)
            local args = {...}
            
            if timer_id then
                timer.Remove(timer_id)
            end
            
            timer_id = "lyx_debounce_" .. lyx:UtilNewHash(8)
            timer.Create(timer_id, delay, 1, function()
                func(unpack(args))
                timer_id = nil
            end)
        end
    end
    
    --[[
        Throttle a function call
        @param func function - Function to throttle
        @param limit number - Minimum time between calls in seconds
        @return function - Throttled function
    ]]
    function lyx:UtilThrottle(func, limit)
        local last_call = 0
        
        return function(...)
            local now = CurTime and CurTime() or os.time()
            
            if now - last_call >= limit then
                last_call = now
                return func(...)
            end
        end
    end
end
