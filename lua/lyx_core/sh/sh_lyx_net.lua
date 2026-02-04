lyx = lyx
lyx.netMessages = lyx.netMessages or {}
lyx.netRateLimits = lyx.netRateLimits or {}

--[[
.____                    _______          __   
|    |    ___.__.___  ___\      \   _____/  |_ 
|    |   <   |  |\  \/  //   |   \_/ __ \   __\
|    |___ \___  | >    </    |    \  ___/|  |  
|_______ \/ ____|/__/\_ \____|__  /\___  >__|  
        \/\/           \/       \/     \/      

Secure client-server networking library with rate limiting and validation

]]--

-- Network security configuration
lyx.NET_MAX_MESSAGE_SIZE = 524288 -- 64KB max message size (len is in bits)
lyx.NET_RATE_LIMIT_WINDOW = 1 -- Rate limit window in seconds
lyx.NET_DEFAULT_RATE_LIMIT = 10 -- Default messages per window
do
    --[[
        Check if a player is rate limited for a specific network message
        @param ply Player - The player to check
        @param msgName string - The network message name
        @param limit number - Optional rate limit (uses default if not provided)
        @return boolean - True if allowed, false if rate limited
    ]]
    local function CheckRateLimit(ply, msgName, limit)
        if not IsValid(ply) then return false end
        
        limit = limit or lyx.NET_DEFAULT_RATE_LIMIT
        local sid = ply:SteamID()
        local now = CurTime()
        
        -- Initialize rate limit tracking
        lyx.netRateLimits[sid] = lyx.netRateLimits[sid] or {}
        lyx.netRateLimits[sid][msgName] = lyx.netRateLimits[sid][msgName] or {count = 0, reset = now + lyx.NET_RATE_LIMIT_WINDOW}
        
        local rateData = lyx.netRateLimits[sid][msgName]
        
        -- Reset counter if window expired
        if now >= rateData.reset then
            rateData.count = 0
            rateData.reset = now + lyx.NET_RATE_LIMIT_WINDOW
        end
        
        -- Check if rate limit exceeded
        if rateData.count >= limit then
            lyx.Logger:Log("Rate limit exceeded for " .. sid .. " on message " .. msgName, 2)
            return false
        end
        
        rateData.count = rateData.count + 1
        return true
    end
    
    if SERVER then
        -- Clean up rate limits for disconnected players
        hook.Add("PlayerDisconnected", "lyx_net_cleanup", function(ply)
            if IsValid(ply) then
                lyx.netRateLimits[ply:SteamID()] = nil
            end
        end)
        
        --[[
            Register a server-side network message handler with security features
            @param name string - Network message name
            @param tbl table - Handler configuration with func, auth, rateLimit
        ]]
        function lyx:NetAdd(name, tbl)
            -- Validate input
            if not name or type(name) ~= "string" then
                lyx.Logger:Log("Invalid network message name", 3)
                return
            end

            tbl = tbl or {}
            if type(tbl) ~= "table" then
                lyx.Logger:Log("Invalid network handler table for " .. name, 3)
                return
            end

            local hasHandler = type(tbl.func) == "function"
            if tbl.func ~= nil and not hasHandler then
                lyx.Logger:Log("Invalid network handler for " .. name, 3)
                return
            end

            -- Store message configuration (for dashboards/telemetry)
            lyx.netMessages[name] = tbl
            util.AddNetworkString(name)

            if not hasHandler then
                lyx.Logger:Log("Registered network message: " .. name .. " (no handler)")
                return
            end

            -- Register receiver immediately (no timer delay)
            net.Receive(name, function(len, ply)
                -- Validate message size
                if len > lyx.NET_MAX_MESSAGE_SIZE then
                    lyx.Logger:Log("Oversized network message from " .. (IsValid(ply) and ply:SteamID() or "unknown"), 2)
                    return
                end
                
                -- Check authentication if required
                if tbl.auth then
                    if not IsValid(ply) then
                        lyx.Logger:Log("Invalid player for authenticated message " .. name, 2)
                        return
                    end
                    
                    -- Call custom auth function if provided
                    if type(tbl.auth) == "function" then
                        if not tbl.auth(ply) then
                            lyx.Logger:Log("Auth failed for " .. ply:SteamID() .. " on message " .. name, 2)
                            return
                        end
                    elseif type(tbl.auth) == "string" then
                        -- Check rank-based auth
                        if lyx.CheckRank and not lyx:CheckRank(ply, tbl.auth) then
                            lyx.Logger:Log("Rank auth failed for " .. ply:SteamID() .. " on message " .. name, 2)
                            return
                        end
                    end
                end
                
                -- Check rate limiting
                if SERVER and IsValid(ply) then
                    if not CheckRateLimit(ply, name, tbl.rateLimit) then
                        return
                    end
                end
                
                -- Execute handler with error protection
                local success, err = pcall(tbl.func, ply, len)
                if not success then
                    lyx.Logger:Log("Network handler error for " .. name .. ": " .. tostring(err), 3)
                end
            end)
            
            lyx.Logger:Log("Registered network message: " .. name)
        end
        
    elseif CLIENT then
        --[[
            Register a client-side network message handler
            @param name string - Network message name
            @param tbl table - Handler configuration with func
        ]]
        function lyx:NetAdd(name, tbl)
            -- Validate input
            if not name or type(name) ~= "string" then
                return
            end
            
            if not tbl or type(tbl) ~= "table" or not tbl.func then
                return
            end
            
            -- Register receiver immediately (no timer delay)
            net.Receive(name, function(len)
                -- Validate message size
                if len > lyx.NET_MAX_MESSAGE_SIZE then
                    return
                end
                
                -- Execute handler with error protection
                local success, err = pcall(tbl.func, len)
                if not success then
                    lyx.Logger:Log("Client network handler error for " .. name .. ": " .. tostring(err), 3)
                end
            end)
        end
    end
    
    -- Determine if a value looks like a net target (Player or player table)
    local function IsNetTarget(value)
        if value == nil then return false end
        if IsValid and IsValid(value) and value:IsPlayer() then return true end
        if type(value) ~= "table" then return false end

        -- accept player arrays but ignore payload tables
        local count = 0
        for key, ply in pairs(value) do
            if type(key) ~= "number" or not (IsValid and IsValid(ply)) or not ply:IsPlayer() then
                return false
            end
            count = count + 1
        end
        return count > 0
    end
    
    --[[
        Send a network message with validation
        Supports both callback writers and automatic payload packing when a value/table is provided.
        @param name string - Network message name
        @param arg2 any - Target, payload, or writer depending on usage
        @param arg3 any - Optional target or writer
        @return boolean - True if sent successfully
    ]]
    function lyx:NetSend(name, arg2, arg3)
        if not name or type(name) ~= "string" then
            return false
        end
        
        local target
        local payload
        local writeFunc
        
        if type(arg2) == "function" then
            writeFunc = arg2
        elseif type(arg3) == "function" then
            target = arg2
            writeFunc = arg3
        elseif arg2 ~= nil and not IsNetTarget(arg2) then
            payload = arg2
            target = arg3
        else
            target = arg2
            payload = arg3
        end
        
        -- Start the message
        net.Start(name)
        
        if writeFunc then
            local success, err = pcall(writeFunc)
            if not success then
                lyx.Logger:Log("Error writing network message " .. name .. ": " .. tostring(err), 3)
                return false
            end
        elseif payload ~= nil then
            local success, err = pcall(net.WriteType, payload)
            if not success then
                lyx.Logger:Log("Error packing payload for " .. name .. ": " .. tostring(err), 3)
                return false
            end
        end
        
        -- Send the message
        if SERVER then
            if not target then
                net.Broadcast()
            elseif type(target) == "table" then
                net.Send(target)
            elseif IsValid(target) then
                net.Send(target)
            else
                return false
            end
        else
            net.SendToServer()
        end
        
        return true
    end
end

--[[
    Simple receive helper for automatically packed payloads.
    Calls the supplied callback with (ply, payload) where payload is decoded via net.ReadType.
]]
function lyx.NetReceive(name, callback)
    if not name or type(name) ~= "string" then
        if lyx.Logger then
            lyx.Logger:Log("Invalid NetReceive name", 3)
        end
        return
    end
    
    if type(callback) ~= "function" then
        if lyx.Logger then
            lyx.Logger:Log("Invalid NetReceive handler for " .. name, 3)
        end
        return
    end
    
    net.Receive(name, function(len, ply)
        local payload
        
        if len > 0 then
            local success, data = pcall(net.ReadType)
            if success then
                payload = data
            else
                if lyx.Logger then
                    lyx.Logger:Log("Failed to decode payload for " .. name .. ": " .. tostring(data), 3)
                end
                payload = nil
            end
        end
        
        local ok, err = pcall(callback, ply, payload)
        if not ok and lyx.Logger then
            lyx.Logger:Log("NetReceive handler error for " .. name .. ": " .. tostring(err), 3)
        end
    end)
    
    if lyx.Logger then
        lyx.Logger:Log("Registered NetReceive handler: " .. name)
    end
end

--[[ 
    EXAMPLE: Secure network message with authentication and rate limiting
    
    -- Server-side handler with authentication
    lyx:NetAdd("lyx:example:secure", {
        func = function(ply, len)
            local data = net.ReadString()
            -- Process secure data here
            print(ply:Nick() .. " sent: " .. data)
        end,
        auth = "admin", -- Requires admin rank
        rateLimit = 5 -- Max 5 messages per second
    })
    
    -- Client-side sender
    lyx:NetSend("lyx:example:secure", nil, function()
        net.WriteString("Hello from client!")
    end)
]]--
