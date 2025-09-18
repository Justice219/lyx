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
lyx.NET_MAX_MESSAGE_SIZE = 65536 -- 64KB max message size
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
            
            if not tbl or type(tbl) ~= "table" or not tbl.func then
                lyx.Logger:Log("Invalid network handler for " .. name, 3)
                return
            end
            
            -- Store message configuration
            lyx.netMessages[name] = tbl
            util.AddNetworkString(name)
            
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
    
    --[[
        Send a network message with validation
        @param name string - Network message name
        @param target any - Player/table of players (server) or nil (client)
        @param writeFunc function - Function to write data to the message
        @return boolean - True if sent successfully
    ]]
    function lyx:NetSend(name, target, writeFunc)
        if not name or type(name) ~= "string" then
            return false
        end
        
        -- Start the message
        net.Start(name)
        
        -- Write data with error protection
        if writeFunc and type(writeFunc) == "function" then
            local success, err = pcall(writeFunc)
            if not success then
                lyx.Logger:Log("Error writing network message " .. name .. ": " .. tostring(err), 3)
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