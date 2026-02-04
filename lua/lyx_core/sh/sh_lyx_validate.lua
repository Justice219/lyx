lyx = lyx
lyx.validate = lyx.validate or {}

--[[
.____                   ____   ____      .__  .__    .___       __          
|    |     ___.__.___  _\   \ /   /____  |  | |__| __| _/____ _/  |_  ____  
|    |    <   |  |\  \/  \   Y   /\__  \ |  | |  |/ __ |\__  \\   __\/ __ \ 
|    |___ \___  | >    <  \     /  / __ \|  |_|  / /_/ | / __ \|  | \  ___/ 
|_______ \/ ____|/__/\_ \  \___/  (____  /____/__\____ |(____  /__|  \___  >
        \/\/           \/              \/             \/     \/          \/ 

Comprehensive validation library for secure input handling and type checking

]]--

do
    -- Configuration
    local MAX_STRING_LENGTH = 65536  -- 64KB max string
    local MAX_TABLE_DEPTH = 10  -- Maximum recursion depth for tables
    local MAX_ARRAY_SIZE = 10000  -- Maximum array size
    
    -- Common regex patterns
    local patterns = {
        email = "^[%w%._%+%-]+@[%w%.%-]+%.%w+$",
        steamid = "^STEAM_[0-5]:[01]:%d+$",
        steamid64 = "^7656119%d{10}$",
        ipv4 = "^%d+%.%d+%.%d+%.%d+$",
        url = "^https?://[%w%.%-]+%.%w+",
        alphanumeric = "^[%w]+$",
        numeric = "^%-?%d+%.?%d*$",
        hexcolor = "^#%x%x%x%x%x%x$",
        filename = "^[%w%-%_%.]+$"
    }
    
    --[[
        Validate a value's type
        @param value any - Value to validate
        @param expectedType string - Expected type
        @return boolean - True if valid
    ]]
    function lyx:ValidateType(value, expectedType)
        return type(value) == expectedType
    end
    
    --[[
        Validate a string with various options
        @param str any - Value to validate as string
        @param options table - Validation options
        @return boolean, string - Valid status and error message
    ]]
    function lyx:ValidateString(str, options)
        options = options or {}
        
        -- Check if it's a string
        if type(str) ~= "string" then
            return false, "Value is not a string"
        end
        
        -- Check length constraints
        local len = #str
        if options.minLength and len < options.minLength then
            return false, "String too short (min: " .. options.minLength .. ")"
        end
        
        if options.maxLength and len > options.maxLength then
            return false, "String too long (max: " .. options.maxLength .. ")"
        end
        
        if len > MAX_STRING_LENGTH then
            return false, "String exceeds maximum allowed length"
        end
        
        -- Check if empty strings are allowed
        if not options.allowEmpty and len == 0 then
            return false, "Empty string not allowed"
        end
        
        -- Check against pattern
        if options.pattern then
            if not string.match(str, options.pattern) then
                return false, "String does not match required pattern"
            end
        end
        
        -- Check against predefined patterns
        if options.format then
            local pattern = patterns[options.format]
            if pattern and not string.match(str, pattern) then
                return false, "Invalid " .. options.format .. " format"
            end
        end
        
        -- Check allowed characters
        if options.allowedChars then
            if string.match(str, "[^" .. options.allowedChars .. "]") then
                return false, "String contains invalid characters"
            end
        end
        
        -- Check blacklisted characters
        if options.blacklistChars then
            if string.match(str, "[" .. options.blacklistChars .. "]") then
                return false, "String contains blacklisted characters"
            end
        end
        
        return true, nil
    end
    
    --[[
        Validate a number with various constraints
        @param num any - Value to validate as number
        @param options table - Validation options
        @return boolean, string - Valid status and error message
    ]]
    function lyx:ValidateNumber(num, options)
        options = options or {}
        
        -- Check if it's a number
        if type(num) ~= "number" then
            return false, "Value is not a number"
        end
        
        -- Check for NaN
        if num ~= num then
            return false, "Value is NaN"
        end
        
        -- Check for infinity
        if not options.allowInfinity and (num == math.huge or num == -math.huge) then
            return false, "Infinite values not allowed"
        end
        
        -- Check min/max bounds
        if options.min and num < options.min then
            return false, "Number below minimum (" .. options.min .. ")"
        end
        
        if options.max and num > options.max then
            return false, "Number above maximum (" .. options.max .. ")"
        end
        
        -- Check if integer is required
        if options.integer and num % 1 ~= 0 then
            return false, "Number must be an integer"
        end
        
        -- Check if positive/negative
        if options.positive and num <= 0 then
            return false, "Number must be positive"
        end
        
        if options.negative and num >= 0 then
            return false, "Number must be negative"
        end
        
        -- Check if it's in allowed values
        if options.enum and type(options.enum) == "table" then
            local found = false
            for _, v in ipairs(options.enum) do
                if v == num then
                    found = true
                    break
                end
            end
            if not found then
                return false, "Number not in allowed values"
            end
        end
        
        return true, nil
    end
    
    --[[
        Validate a table with various constraints
        @param tbl any - Value to validate as table
        @param options table - Validation options
        @param depth number - Current recursion depth (internal)
        @return boolean, string - Valid status and error message
    ]]
    function lyx:ValidateTable(tbl, options, depth)
        options = options or {}
        depth = depth or 0
        
        -- Check if it's a table
        if type(tbl) ~= "table" then
            return false, "Value is not a table"
        end
        
        -- Check recursion depth
        if depth > MAX_TABLE_DEPTH then
            return false, "Table nesting too deep"
        end
        
        -- Count elements
        local count = 0
        for _ in pairs(tbl) do
            count = count + 1
            if count > MAX_ARRAY_SIZE then
                return false, "Table too large"
            end
        end
        
        -- Check size constraints
        if options.minSize and count < options.minSize then
            return false, "Table too small (min: " .. options.minSize .. ")"
        end
        
        if options.maxSize and count > options.maxSize then
            return false, "Table too large (max: " .. options.maxSize .. ")"
        end
        
        -- Check if it should be an array
        if options.array then
            for i = 1, count do
                if tbl[i] == nil then
                    return false, "Table is not a valid array"
                end
            end
        end
        
        -- Validate keys if specified
        if options.keys then
            for k, _ in pairs(tbl) do
                local keyValid, keyErr = lyx:ValidateValue(k, options.keys)
                if not keyValid then
                    return false, "Invalid key: " .. keyErr
                end
            end
        end
        
        -- Validate values if specified
        if options.values then
            for _, v in pairs(tbl) do
                local valValid, valErr = lyx:ValidateValue(v, options.values, depth + 1)
                if not valValid then
                    return false, "Invalid value: " .. valErr
                end
            end
        end
        
        -- Check required fields
        if options.required and type(options.required) == "table" then
            for _, field in ipairs(options.required) do
                if tbl[field] == nil then
                    return false, "Missing required field: " .. field
                end
            end
        end
        
        -- Validate schema if provided
        if options.schema and type(options.schema) == "table" then
            for field, fieldOptions in pairs(options.schema) do
                if tbl[field] ~= nil or fieldOptions.required then
                    local valid, err = lyx:ValidateValue(tbl[field], fieldOptions, depth + 1)
                    if not valid then
                        return false, "Field '" .. field .. "': " .. err
                    end
                end
            end
        end
        
        return true, nil
    end
    
    --[[
        Validate a boolean value
        @param val any - Value to validate
        @param options table - Validation options
        @return boolean, string - Valid status and error message
    ]]
    function lyx:ValidateBoolean(val, options)
        options = options or {}
        
        if type(val) ~= "boolean" then
            return false, "Value is not a boolean"
        end
        
        return true, nil
    end
    
    --[[
        Validate a function
        @param func any - Value to validate
        @param options table - Validation options
        @return boolean, string - Valid status and error message
    ]]
    function lyx:ValidateFunction(func, options)
        options = options or {}
        
        if type(func) ~= "function" then
            return false, "Value is not a function"
        end
        
        return true, nil
    end
    
    --[[
        Validate a Player entity
        @param ply any - Value to validate
        @param options table - Validation options
        @return boolean, string - Valid status and error message
    ]]
    function lyx:ValidatePlayer(ply, options)
        options = options or {}
        
        if not IsValid(ply) then
            return false, "Invalid player entity"
        end
        
        if not ply:IsPlayer() then
            return false, "Entity is not a player"
        end
        
        -- Check if player is fully spawned
        if options.spawned and ply.Lyx_FullySpawned and not ply:Lyx_FullySpawned() then
            return false, "Player not fully spawned"
        end
        
        -- Check if player is alive
        if options.alive and not ply:Alive() then
            return false, "Player is not alive"
        end
        
        -- Check team
        if options.team then
            if type(options.team) == "number" then
                if ply:Team() ~= options.team then
                    return false, "Player is not on required team"
                end
            elseif type(options.team) == "table" then
                local found = false
                for _, t in ipairs(options.team) do
                    if ply:Team() == t then
                        found = true
                        break
                    end
                end
                if not found then
                    return false, "Player is not on allowed teams"
                end
            end
        end
        
        -- Check rank
        if options.rank and lyx.CheckRank then
            if not lyx:CheckRank(ply, options.rank) then
                return false, "Player does not have required rank"
            end
        end
        
        return true, nil
    end
    
    --[[
        Validate an Entity
        @param ent any - Value to validate
        @param options table - Validation options
        @return boolean, string - Valid status and error message
    ]]
    function lyx:ValidateEntity(ent, options)
        options = options or {}
        
        if not IsValid(ent) then
            return false, "Invalid entity"
        end
        
        -- Check class
        if options.class then
            if type(options.class) == "string" then
                if ent:GetClass() ~= options.class then
                    return false, "Entity class mismatch"
                end
            elseif type(options.class) == "table" then
                local found = false
                for _, c in ipairs(options.class) do
                    if ent:GetClass() == c then
                        found = true
                        break
                    end
                end
                if not found then
                    return false, "Entity class not in allowed list"
                end
            end
        end
        
        -- Check model
        if options.model and ent:GetModel() ~= options.model then
            return false, "Entity model mismatch"
        end
        
        return true, nil
    end
    
    --[[
        Generic validation function that routes to specific validators
        @param value any - Value to validate
        @param options table - Validation options with 'type' field
        @param depth number - Recursion depth for nested validation
        @return boolean, string - Valid status and error message
    ]]
    function lyx:ValidateValue(value, options, depth)
        if not options or type(options) ~= "table" then
            return true, nil  -- No validation rules
        end
        
        -- Check if nil is allowed
        if value == nil then
            if options.optional or options.nullable then
                return true, nil
            else
                return false, "Value is nil"
            end
        end
        
        -- Route to specific validator based on type
        local valueType = options.type or type(value)
        
        if valueType == "string" then
            return lyx:ValidateString(value, options)
        elseif valueType == "number" then
            return lyx:ValidateNumber(value, options)
        elseif valueType == "table" then
            return lyx:ValidateTable(value, options, depth)
        elseif valueType == "boolean" then
            return lyx:ValidateBoolean(value, options)
        elseif valueType == "function" then
            return lyx:ValidateFunction(value, options)
        elseif valueType == "Player" then
            return lyx:ValidatePlayer(value, options)
        elseif valueType == "Entity" then
            return lyx:ValidateEntity(value, options)
        else
            -- Check actual type
            if type(value) ~= valueType then
                return false, "Type mismatch (expected " .. valueType .. ", got " .. type(value) .. ")"
            end
        end
        
        return true, nil
    end
    
    --[[
        Validate multiple values at once
        @param values table - Table of values to validate
        @param rules table - Table of validation rules (same keys as values)
        @return boolean, table - Valid status and table of errors
    ]]
    function lyx:ValidateBatch(values, rules)
        if type(values) ~= "table" or type(rules) ~= "table" then
            return false, {["_error"] = "Invalid parameters"}
        end
        
        local errors = {}
        local hasErrors = false
        
        for key, rule in pairs(rules) do
            local valid, err = lyx:ValidateValue(values[key], rule)
            if not valid then
                errors[key] = err
                hasErrors = true
            end
        end
        
        return not hasErrors, errors
    end
    
    --[[
        Create a validator function with preset rules
        @param rules table - Validation rules
        @return function - Validator function
    ]]
    function lyx:CreateValidator(rules)
        return function(value)
            return lyx:ValidateValue(value, rules)
        end
    end
    
    --[[
        Sanitize a string by removing dangerous characters
        @param str string - String to sanitize
        @param level string - Sanitization level ("strict", "moderate", "loose")
        @return string - Sanitized string
    ]]
    function lyx:SanitizeString(str, level)
        if type(str) ~= "string" then
            return ""
        end
        
        level = level or "moderate"
        
        if level == "strict" then
            -- Only alphanumeric and spaces
            str = string.gsub(str, "[^%w%s]", "")
        elseif level == "moderate" then
            -- Alphanumeric, spaces, and basic punctuation
            str = string.gsub(str, "[^%w%s%.,%-%_]", "")
        elseif level == "loose" then
            -- Remove only dangerous characters
            str = string.gsub(str, "[<>\"'`\\]", "")
        end
        
        -- Trim whitespace
        str = string.Trim(str)
        
        -- Limit length
        if #str > MAX_STRING_LENGTH then
            str = string.sub(str, 1, MAX_STRING_LENGTH)
        end
        
        return str
    end
    
    --[[
        Coerce a value to a specific type with validation
        @param value any - Value to coerce
        @param targetType string - Target type
        @return any, boolean - Coerced value and success status
    ]]
    function lyx:CoerceType(value, targetType)
        if targetType == "string" then
            return tostring(value), true
        elseif targetType == "number" then
            local num = tonumber(value)
            return num, num ~= nil
        elseif targetType == "boolean" then
            if type(value) == "boolean" then
                return value, true
            elseif type(value) == "number" then
                return value ~= 0, true
            elseif type(value) == "string" then
                local lower = string.lower(value)
                if lower == "true" or lower == "1" or lower == "yes" then
                    return true, true
                elseif lower == "false" or lower == "0" or lower == "no" then
                    return false, true
                end
            end
            return nil, false
        elseif targetType == "table" then
            if type(value) == "table" then
                return value, true
            elseif type(value) == "string" then
                -- Try to parse as JSON
                local success, result = pcall(util.JSONToTable, value)
                if success and result then
                    return result, true
                end
            end
            return nil, false
        end
        
        return value, type(value) == targetType
    end
end