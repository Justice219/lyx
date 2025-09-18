lyx = lyx
lyx.hooks = lyx.hooks or {}
lyx.hookStats = lyx.hookStats or {}

--[[
.____                     ___ ___                __            
|    |    ___.__.___  ___/   |   \  ____   ____ |  | __  ______
|    |   <   |  |\  \/  /    ~    \/  _ \ /  _ \|  |/ / /  ___/
|    |___ \___  | >    <\    Y    (  <_> |  <_> )    <  \___ \ 
|_______ \/ ____|/__/\_ \\___|_  / \____/ \____/|__|_ \/____  >
        \/\/           \/      \/                    \/     \/ 

Enhanced hook management system with error handling, performance monitoring,
and automatic cleanup.

--]]
do
    -- Configuration
    local HOOK_DEBUG = false  -- Enable detailed hook debugging
    local PERFORMANCE_TRACKING = true  -- Track hook execution times
    local MAX_HOOK_TIME = 0.1  -- Warning threshold for slow hooks (100ms)
    
    --[[
        Call a hook with error handling and performance monitoring
        @param name string - Hook name
        @param ... any - Arguments to pass to hook
        @return any - Return value from hook.Run
    ]]
    function lyx:HookCall(name, ...)
        -- Validate hook name
        if type(name) ~= "string" or #name == 0 then
            lyx.Logger:Log("Invalid hook name provided to HookCall", 3)
            return
        end
        
        -- Track performance if enabled
        local startTime
        if PERFORMANCE_TRACKING then
            startTime = SysTime and SysTime() or os.clock()
        end
        
        -- Call the hook with error protection
        local results = {pcall(hook.Run, name, ...)}
        local success = results[1]
        
        if not success then
            lyx.Logger:Log("Error in hook '" .. name .. "': " .. tostring(results[2]), 3)
            return
        end
        
        -- Track execution time
        if PERFORMANCE_TRACKING and startTime then
            local executionTime = (SysTime and SysTime() or os.clock()) - startTime
            
            -- Update statistics
            lyx.hookStats[name] = lyx.hookStats[name] or {calls = 0, totalTime = 0, maxTime = 0}
            lyx.hookStats[name].calls = lyx.hookStats[name].calls + 1
            lyx.hookStats[name].totalTime = lyx.hookStats[name].totalTime + executionTime
            lyx.hookStats[name].maxTime = math.max(lyx.hookStats[name].maxTime, executionTime)
            
            -- Warn about slow hooks
            if executionTime > MAX_HOOK_TIME then
                lyx.Logger:Log("Slow hook detected: " .. name .. " took " .. math.Round(executionTime * 1000, 2) .. "ms", 2)
            end
        end
        
        if HOOK_DEBUG then
            lyx.Logger:Log("Hook called: " .. name)
        end
        
        -- Return results (excluding success boolean)
        return unpack(results, 2)
    end
    
    --[[
        Start a new hook with automatic ID generation and error handling
        @param name string - Hook name
        @param func function - Function to call
        @param priority number - Optional priority (lower runs first)
        @return number - Unique hook ID
    ]]
    function lyx:HookStart(name, func, priority)
        -- Validate inputs
        if type(name) ~= "string" or #name == 0 then
            lyx.Logger:Log("Invalid hook name provided to HookStart", 3)
            return nil
        end
        
        if type(func) ~= "function" then
            lyx.Logger:Log("Invalid function provided to HookStart for hook: " .. name, 3)
            return nil
        end
        
        -- Generate unique ID
        local id = lyx:UtilNewID()
        local identifier = "lyx_hook_" .. id
        
        -- Wrap function with error handling
        local wrappedFunc = function(...)
            local success, result = pcall(func, ...)
            if not success then
                lyx.Logger:Log("Error in hook '" .. name .. "' (ID: " .. id .. "): " .. tostring(result), 3)
                return
            end
            return result
        end
        
        -- Add the hook
        if priority and type(priority) == "number" then
            -- GMod doesn't support priority in hook.Add directly, but we can track it
            hook.Add(name, identifier, wrappedFunc)
        else
            hook.Add(name, identifier, wrappedFunc)
        end
        
        -- Track the hook
        lyx.hooks[id] = {
            name = name,
            identifier = identifier,
            func = func,
            priority = priority or 0,
            created = CurTime and CurTime() or os.time()
        }
        
        if HOOK_DEBUG then
            lyx.Logger:Log("Hook started: " .. name .. " (ID: " .. id .. ")")
        end
        
        return id
    end
    
    --[[
        Remove a hook by ID
        @param name string - Hook name
        @param id number - Hook ID returned by HookStart
        @return boolean - True if removed successfully
    ]]
    function lyx:HookRemove(name, id)
        -- Validate inputs
        if type(name) ~= "string" or type(id) ~= "number" then
            lyx.Logger:Log("Invalid parameters for HookRemove", 3)
            return false
        end
        
        -- Check if hook exists
        if not lyx.hooks[id] then
            lyx.Logger:Log("Hook ID " .. id .. " not found", 2)
            return false
        end
        
        -- Verify hook name matches
        if lyx.hooks[id].name ~= name then
            lyx.Logger:Log("Hook name mismatch for ID " .. id, 2)
            return false
        end
        
        -- Remove the hook
        hook.Remove(name, lyx.hooks[id].identifier)
        
        -- Clean up tracking
        lyx.hooks[id] = nil
        
        if HOOK_DEBUG then
            lyx.Logger:Log("Hook removed: " .. name .. " (ID: " .. id .. ")")
        end
        
        return true
    end
    
    --[[
        Remove all hooks with a specific name
        @param name string - Hook name
        @return number - Number of hooks removed
    ]]
    function lyx:HookRemoveAll(name)
        if type(name) ~= "string" then
            return 0
        end
        
        local removed = 0
        for id, hookData in pairs(lyx.hooks) do
            if hookData.name == name then
                if lyx:HookRemove(name, id) then
                    removed = removed + 1
                end
            end
        end
        
        lyx.Logger:Log("Removed " .. removed .. " hooks for: " .. name)
        return removed
    end
    
    --[[
        Get all active hooks
        @param name string - Optional filter by hook name
        @return table - Table of hook information
    ]]
    function lyx:HookGetActive(name)
        local active = {}
        
        for id, hookData in pairs(lyx.hooks) do
            if not name or hookData.name == name then
                table.insert(active, {
                    id = id,
                    name = hookData.name,
                    priority = hookData.priority,
                    created = hookData.created
                })
            end
        end
        
        return active
    end
    
    --[[
        Get hook performance statistics
        @param name string - Optional specific hook name
        @return table - Performance statistics
    ]]
    function lyx:HookGetStats(name)
        if name then
            return lyx.hookStats[name]
        end
        
        -- Return all stats
        local stats = {}
        for hookName, data in pairs(lyx.hookStats) do
            stats[hookName] = {
                calls = data.calls,
                avgTime = data.totalTime / data.calls,
                maxTime = data.maxTime,
                totalTime = data.totalTime
            }
        end
        
        return stats
    end
    
    --[[
        Clear hook statistics
        @param name string - Optional specific hook to clear
    ]]
    function lyx:HookClearStats(name)
        if name then
            lyx.hookStats[name] = nil
        else
            lyx.hookStats = {}
        end
        
        lyx.Logger:Log("Cleared hook statistics" .. (name and " for: " .. name or ""))
    end
    
    --[[
        Enable/disable hook debugging
        @param enabled boolean - Enable or disable debug mode
    ]]
    function lyx:HookSetDebug(enabled)
        HOOK_DEBUG = enabled
        lyx.Logger:Log("Hook debugging " .. (enabled and "enabled" or "disabled"))
    end
    
    --[[
        Create a one-time hook that removes itself after execution
        @param name string - Hook name
        @param func function - Function to call
        @return number - Hook ID
    ]]
    function lyx:HookOnce(name, func)
        local id
        id = lyx:HookStart(name, function(...)
            lyx:HookRemove(name, id)
            return func(...)
        end)
        return id
    end
    
    --[[
        Create a conditional hook that only runs if condition is met
        @param name string - Hook name
        @param condition function - Condition checker function
        @param func function - Function to call if condition is true
        @return number - Hook ID
    ]]
    function lyx:HookConditional(name, condition, func)
        return lyx:HookStart(name, function(...)
            if condition(...) then
                return func(...)
            end
        end)
    end
    
    // Full Spawn Hook \\
    local meta = FindMetaTable("Player")
    
    if SERVER then
        hook.Add("PlayerInitialSpawn", "lyx:PISFull", function(ply)
            local PlayerHookID = string.format("lyx:PISFull:%s", ply:SteamID())
            hook.Add("SetupMove", PlayerHookID, function(pl2, _, mvc)
                if (!IsValid(pl2)) then return end
                if (ply != pl2) then return end
                if mvc:IsForced() then return end
    
                hook.Run("lyx:FullSpawn", ply)
                hook.Remove("SetupMove", PlayerHookID)
                ply:SetNWBool("lyx:FullSpawn", true)
            end)
        end)
    end
    
    function meta:Lyx_FullySpawned()
        if not IsValid(self) then return false end
        return self:GetNWBool("lyx:FullSpawn", false)
    end
end
----------------------------------------------------------------------------------------------------------------------
--Going to be honest, this honestly doesnt do anything the normal gmod hook library cant do. You could use either 🤷.
--The real plus of using the lyx library is auto generating IDs for your hooks.

-- Here is an example of how to use the lyx hook library.
----------------------------------------------------------------------------------------------------------------------
--local function ExampleHook()
--  lyx:HookCall("lyx_test", "Hello World!")            -- This or the hook.Run function can be used.
--end

--local test = lyx:HookStart("lyx_test", function(...)  -- Lets actually start the hook.
--    local args = {...}                                -- This returns an ID for the hook to ease removing it.
--    print(args[1])                                    -- Takes all arguments, you need to know what index to use.
--end)                                                  -- This is a sort of example on how to access arguments.

--ExampleHook()                                         -- Lets call the function to create a hook call.

--lyx:HookRemove("lyx_test", test)                      -- Lets remove just to keep random hooks off the server.
----------------------------------------------------------------------------------------------------------------------