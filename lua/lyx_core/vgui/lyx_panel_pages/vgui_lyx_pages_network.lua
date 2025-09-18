local PANEL = {}

lyx.RegisterFont("LYX.Network.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Network.Text", "Open Sans", lyx.Scale(14))
lyx.RegisterFont("LYX.Network.Number", "Courier New", lyx.Scale(16))

function PANEL:Init()
    -- Track network messages
    self.NetworkStats = {}
    self.TotalBytesIn = 0
    self.TotalBytesOut = 0
    self.MessageHistory = {}
    
    -- Header
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Network Message Monitor", "LYX.Network.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
        
        -- Live stats
        local bytesIn = net.BytesReceived and net.BytesReceived() or 0
        local bytesOut = net.BytesWritten and net.BytesWritten() or 0
        
        draw.SimpleText("In: " .. string.NiceSize(bytesIn), "LYX.Network.Text", w - lyx.Scale(200), lyx.Scale(15), lyx.Colors.Positive or Color(46, 204, 113))
        draw.SimpleText("Out: " .. string.NiceSize(bytesOut), "LYX.Network.Text", w - lyx.Scale(200), lyx.Scale(35), lyx.Colors.Warning or Color(241, 196, 15))
    end
    
    -- Clear button
    local clearBtn = vgui.Create("lyx.TextButton2", headerPanel)
    clearBtn:SetText("Clear Stats")
    clearBtn:Dock(RIGHT)
    clearBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(12), lyx.Scale(12))
    clearBtn:SetWide(lyx.Scale(100))
    clearBtn.DoClick = function()
        self:ClearStats()
        notification.AddLegacy("Network stats cleared!", NOTIFY_GENERIC, 2)
    end
    
    -- Main container
    local container = vgui.Create("DPanel", self)
    container:Dock(FILL)
    container:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    container.Paint = function() end
    
    -- Stats overview
    local statsPanel = vgui.Create("DPanel", container)
    statsPanel:Dock(TOP)
    statsPanel:SetTall(lyx.Scale(100))
    statsPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    statsPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        draw.SimpleText("Network Statistics", "LYX.Network.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
        
        -- Calculate stats
        local totalMessages = 0
        local totalBytes = 0
        local activeMessages = 0
        
        for name, stats in pairs(self.NetworkStats) do
            totalMessages = totalMessages + stats.count
            totalBytes = totalBytes + stats.bytes
            if stats.count > 0 then
                activeMessages = activeMessages + 1
            end
        end
        
        -- Display stats
        local stats = {
            {"Total Messages", totalMessages, lyx.Colors.Primary or Color(52, 152, 219)},
            {"Active Types", activeMessages, lyx.Colors.Positive or Color(46, 204, 113)},
            {"Total Data", string.NiceSize(totalBytes), lyx.Colors.Warning or Color(241, 196, 15)},
            {"Avg Size", totalMessages > 0 and string.NiceSize(totalBytes / totalMessages) or "0 B", Color(155, 89, 182)}
        }
        
        for i, stat in ipairs(stats) do
            local x = lyx.Scale(15 + (i-1) * 150)
            draw.SimpleText(stat[1], "LYX.Network.Text", x, lyx.Scale(40), lyx.Colors.SecondaryText)
            draw.SimpleText(tostring(stat[2]), "LYX.Network.Number", x, lyx.Scale(60), stat[3])
        end
    end
    
    -- Message list
    local listPanel = vgui.Create("DPanel", container)
    listPanel:Dock(FILL)
    listPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Message Traffic", "LYX.Network.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
    end
    
    -- Use our custom list view
    self.MessageList = vgui.Create("lyx.ListView", listPanel)
    self.MessageList:Dock(FILL)
    self.MessageList:DockMargin(lyx.Scale(10), lyx.Scale(40), lyx.Scale(10), lyx.Scale(10))
    
    -- Add columns
    self.MessageList:AddColumn("Message Name", lyx.Scale(250))
    self.MessageList:AddColumn("Count", lyx.Scale(80))
    self.MessageList:AddColumn("Total Size", lyx.Scale(100))
    self.MessageList:AddColumn("Avg Size", lyx.Scale(100))
    self.MessageList:AddColumn("Last Seen", lyx.Scale(120))
    self.MessageList:AddColumn("Rate/min", lyx.Scale(80))
    
    -- Hook into network messages
    self:StartTracking()
    
    -- Auto-refresh
    timer.Create("LyxNetworkRefresh", 1, 0, function()
        if IsValid(self) then
            self:RefreshList()
        else
            timer.Remove("LyxNetworkRefresh")
        end
    end)
end

function PANEL:StartTracking()
    -- Hook into net library
    if not self.OriginalStart then
        self.OriginalStart = net.Start
        
        net.Start = function(messageName)
            -- Track outgoing message
            if self and IsValid(self) then
                self:TrackMessage(messageName, "out", 0)
            end
            
            return self.OriginalStart(messageName)
        end
    end
    
    -- Track incoming messages (requires server cooperation)
    net.Receive("lyx:net:stats", function()
        local messageName = net.ReadString()
        local size = net.ReadUInt(16)
        
        if IsValid(self) then
            self:TrackMessage(messageName, "in", size)
        end
    end)
    
    -- Request current stats from server
    if CLIENT then
        net.Start("lyx:net:request_stats")
        net.SendToServer()
    end
end

function PANEL:TrackMessage(messageName, direction, size)
    if not self.NetworkStats[messageName] then
        self.NetworkStats[messageName] = {
            count = 0,
            bytes = 0,
            firstSeen = CurTime(),
            lastSeen = CurTime(),
            incoming = 0,
            outgoing = 0
        }
    end
    
    local stats = self.NetworkStats[messageName]
    stats.count = stats.count + 1
    stats.bytes = stats.bytes + size
    stats.lastSeen = CurTime()
    
    if direction == "in" then
        stats.incoming = stats.incoming + 1
        self.TotalBytesIn = self.TotalBytesIn + size
    else
        stats.outgoing = stats.outgoing + 1
        self.TotalBytesOut = self.TotalBytesOut + size
    end
    
    -- Add to history
    table.insert(self.MessageHistory, {
        name = messageName,
        direction = direction,
        size = size,
        time = CurTime()
    })
    
    -- Limit history size
    if #self.MessageHistory > 1000 then
        table.remove(self.MessageHistory, 1)
    end
end

function PANEL:RefreshList()
    self.MessageList:Clear()
    
    -- Sort by count
    local sorted = {}
    for name, stats in pairs(self.NetworkStats) do
        table.insert(sorted, {name = name, stats = stats})
    end
    
    table.sort(sorted, function(a, b)
        return a.stats.count > b.stats.count
    end)
    
    -- Add rows
    for _, data in ipairs(sorted) do
        local stats = data.stats
        local timeDiff = CurTime() - stats.firstSeen
        local rate = timeDiff > 0 and math.Round((stats.count / timeDiff) * 60, 1) or 0
        
        self.MessageList:AddRow(
            data.name,
            stats.count,
            string.NiceSize(stats.bytes),
            stats.count > 0 and string.NiceSize(stats.bytes / stats.count) or "0 B",
            os.date("%H:%M:%S", stats.lastSeen),
            tostring(rate)
        )
    end
end

function PANEL:ClearStats()
    self.NetworkStats = {}
    self.TotalBytesIn = 0
    self.TotalBytesOut = 0
    self.MessageHistory = {}
    self.MessageList:Clear()
end

function PANEL:OnRemove()
    timer.Remove("LyxNetworkRefresh")
    
    -- Restore original net.Start
    if self.OriginalStart then
        net.Start = self.OriginalStart
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Network", PANEL)