lyx = lyx
lyx.networkStats = lyx.networkStats or {}

--[[
    Lyx Network Message Tracking System
    Monitors and tracks network message usage
]]--

-- Network strings
util.AddNetworkString("lyx:net:stats")
util.AddNetworkString("lyx:net:request_stats")

-- Track network messages
local messageStats = {}
local originalReceive = net.Receive

-- Override net.Receive to track incoming messages
net.Receive = function(messageName, callback)
    -- Create wrapper function
    local wrappedCallback = function(len, ply)
        -- Track the message
        if not messageStats[messageName] then
            messageStats[messageName] = {
                count = 0,
                totalBytes = 0,
                lastReceived = 0,
                players = {}
            }
        end
        
        local stats = messageStats[messageName]
        stats.count = stats.count + 1
        stats.totalBytes = stats.totalBytes + len
        stats.lastReceived = CurTime()
        
        -- Track per-player
        local steamID = IsValid(ply) and ply:SteamID() or "SERVER"
        stats.players[steamID] = (stats.players[steamID] or 0) + 1
        
        -- Send stats to admins with network panel open
        for _, admin in ipairs(player.GetAll()) do
            if admin:IsAdmin() then
                net.Start("lyx:net:stats")
                net.WriteString(messageName)
                net.WriteUInt(len, 16)
                net.Send(admin)
            end
        end
        
        -- Call original callback
        return callback(len, ply)
    end
    
    -- Register with original function
    return originalReceive(messageName, wrappedCallback)
end

-- Handle stats request
net.Receive("lyx:net:request_stats", function(len, ply)
    if not ply:IsAdmin() then return end
    
    -- Send current stats to player
    for messageName, stats in pairs(messageStats) do
        for i = 1, math.min(stats.count, 10) do -- Send last 10 of each
            net.Start("lyx:net:stats")
            net.WriteString(messageName)
            net.WriteUInt(stats.totalBytes / math.max(stats.count, 1), 16) -- Average size
            net.Send(ply)
        end
    end
end)

-- Console command to view network stats
concommand.Add("lyx_net_stats", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Access denied: Admin only")
        return
    end
    
    local output = "\n===== Lyx Network Statistics =====\n"
    
    -- Sort by count
    local sorted = {}
    for name, stats in pairs(messageStats) do
        table.insert(sorted, {name = name, stats = stats})
    end
    
    table.sort(sorted, function(a, b)
        return a.stats.count > b.stats.count
    end)
    
    -- Display top messages
    for i = 1, math.min(#sorted, 20) do
        local data = sorted[i]
        local avgSize = data.stats.totalBytes / math.max(data.stats.count, 1)
        
        output = output .. string.format("%2d. %-30s | Count: %5d | Total: %8s | Avg: %6s\n",
            i,
            data.name,
            data.stats.count,
            string.NiceSize(data.stats.totalBytes),
            string.NiceSize(avgSize)
        )
    end
    
    output = output .. "\nTotal messages tracked: " .. #sorted .. "\n"
    
    if IsValid(ply) then
        ply:ChatPrint(output)
    else
        print(output)
    end
end)

-- Log network stats periodically
timer.Create("Lyx.NetworkStats", 60, 0, function()
    local totalMessages = 0
    local totalBytes = 0
    
    for _, stats in pairs(messageStats) do
        totalMessages = totalMessages + stats.count
        totalBytes = totalBytes + stats.totalBytes
    end
    
    if totalMessages > 0 then
        lyx.Logger:Log("Network Stats: " .. totalMessages .. " messages, " .. string.NiceSize(totalBytes) .. " total")
    end
end)

lyx.Logger:Log("Network tracking system initialized")