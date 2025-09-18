local PANEL = {}

lyx.RegisterFont("LYX.Stats.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Stats.Text", "Open Sans", lyx.Scale(14))
lyx.RegisterFont("LYX.Stats.Big", "Open Sans Bold", lyx.Scale(32))

function PANEL:Init()
    self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
    self.ScrollPanel:Dock(FILL)
    self.ScrollPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    
    -- Server Info
    local serverPanel = vgui.Create("DPanel", self.ScrollPanel)
    serverPanel:Dock(TOP)
    serverPanel:SetTall(lyx.Scale(180))
    serverPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    serverPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        draw.SimpleText("Server Information", "LYX.Stats.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
        
        local info = {
            {"Server Name", GetHostName()},
            {"Map", game.GetMap()},
            {"Gamemode", GAMEMODE.Name or "Unknown"},
            {"Server IP", game.GetIPAddress()},
            {"Max Players", game.MaxPlayers()},
            {"Uptime", string.NiceTime(CurTime())},
            {"Tick Rate", math.Round(1 / engine.TickInterval()) .. " ticks/sec"},
            {"Server OS", jit.os .. " " .. jit.arch}
        }
        
        for i, data in ipairs(info) do
            local x = ((i - 1) % 2) * lyx.Scale(400) + lyx.Scale(15)
            local y = math.floor((i - 1) / 2) * lyx.Scale(30) + lyx.Scale(50)
            
            draw.SimpleText(data[1] .. ":", "LYX.Stats.Text", x, y, lyx.Colors.SecondaryText)
            draw.SimpleText(tostring(data[2]), "LYX.Stats.Text", x + lyx.Scale(120), y, lyx.Colors.PrimaryText)
        end
    end
    
    -- Player Statistics
    local playerStatsPanel = vgui.Create("DPanel", self.ScrollPanel)
    playerStatsPanel:Dock(TOP)
    playerStatsPanel:SetTall(lyx.Scale(150))
    playerStatsPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    playerStatsPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        draw.SimpleText("Player Statistics", "LYX.Stats.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
        
        local players = player.GetAll()
        local bots = 0
        local admins = 0
        local afk = 0
        
        for _, ply in ipairs(players) do
            if ply:IsBot() then bots = bots + 1 end
            if ply:IsAdmin() then admins = admins + 1 end
            if ply.IsAFK and ply:IsAFK() then afk = afk + 1 end
        end
        
        -- Big number display
        draw.SimpleText(#players, "LYX.Stats.Big", lyx.Scale(15), lyx.Scale(50), Color(52, 152, 219))
        draw.SimpleText("Players Online", "LYX.Stats.Text", lyx.Scale(15), lyx.Scale(90), lyx.Colors.SecondaryText)
        
        -- Stats grid
        local stats = {
            {"Humans", #players - bots, Color(46, 204, 113)},
            {"Bots", bots, Color(241, 196, 15)},
            {"Admins", admins, Color(231, 76, 60)},
            {"AFK", afk, Color(149, 165, 166)}
        }
        
        for i, stat in ipairs(stats) do
            local x = lyx.Scale(200 + (i-1) * 120)
            local y = lyx.Scale(60)
            
            draw.SimpleText(stat[2], "LYX.Stats.Header", x, y, stat[3], TEXT_ALIGN_CENTER)
            draw.SimpleText(stat[1], "LYX.Stats.Text", x, y + lyx.Scale(25), lyx.Colors.SecondaryText, TEXT_ALIGN_CENTER)
        end
        
        -- Player graph
        if not pnl.playerHistory then pnl.playerHistory = {} end
        table.insert(pnl.playerHistory, #players)
        if #pnl.playerHistory > 60 then
            table.remove(pnl.playerHistory, 1)
        end
        
        local graphX = w - lyx.Scale(300)
        local graphW = lyx.Scale(280)
        local graphH = lyx.Scale(80)
        local graphY = lyx.Scale(50)
        
        surface.SetDrawColor(lyx.Colors.Background.r, lyx.Colors.Background.g, lyx.Colors.Background.b, lyx.Colors.Background.a)
        surface.DrawRect(graphX, graphY, graphW, graphH)
        
        for i = 2, #pnl.playerHistory do
            local x1 = graphX + ((i-2) / 59) * graphW
            local x2 = graphX + ((i-1) / 59) * graphW
            local y1 = graphY + graphH - (pnl.playerHistory[i-1] / game.MaxPlayers()) * graphH
            local y2 = graphY + graphH - (pnl.playerHistory[i] / game.MaxPlayers()) * graphH
            
            surface.SetDrawColor(52, 152, 219, 255)
            surface.DrawLine(x1, y1, x2, y2)
        end
        
        draw.SimpleText("Player Count (Last 60s)", "LYX.Stats.Text", graphX + graphW/2, graphY - lyx.Scale(15), 
            lyx.Colors.SecondaryText, TEXT_ALIGN_CENTER)
    end
    
    -- Resource Usage
    local resourcePanel = vgui.Create("DPanel", self.ScrollPanel)
    resourcePanel:Dock(TOP)
    resourcePanel:SetTall(lyx.Scale(200))
    resourcePanel:DockMargin(0, 0, 0, lyx.Scale(10))
    resourcePanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        draw.SimpleText("Resource Usage", "LYX.Stats.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
        
        -- Addon count
        local addons = engine.GetAddons()
        local workshopAddons = 0
        local totalSize = 0
        
        for _, addon in ipairs(addons) do
            if addon.mounted then
                workshopAddons = workshopAddons + 1
                totalSize = totalSize + (addon.size or 0)
            end
        end
        
        local resources = {
            {"Workshop Addons", workshopAddons},
            {"Total Addon Size", string.NiceSize(totalSize)},
            {"Lua Files", #file.Find("lua/*.lua", "GAME")},
            {"Models Loaded", #util.GetModelMeshes(LocalPlayer():GetModel() or "models/player/kleiner.mdl")},
            {"Materials Cached", #(Material("debug/debugwhite"):GetKeyValues() or {})},
            {"Sounds Precached", "N/A"}
        }
        
        for i, res in ipairs(resources) do
            local y = lyx.Scale(50 + (i-1) * 25)
            draw.SimpleText(res[1] .. ":", "LYX.Stats.Text", lyx.Scale(15), y, lyx.Colors.SecondaryText)
            draw.SimpleText(tostring(res[2]), "LYX.Stats.Text", lyx.Scale(200), y, lyx.Colors.PrimaryText)
        end
    end
    
    -- Network Statistics
    local netPanel = vgui.Create("DPanel", self.ScrollPanel)
    netPanel:Dock(TOP)
    netPanel:SetTall(lyx.Scale(150))
    netPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    netPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        draw.SimpleText("Network Statistics", "LYX.Stats.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
        
        local incoming = net.BytesReceived and net.BytesReceived() or 0
        local outgoing = net.BytesWritten and net.BytesWritten() or 0
        
        local netStats = {
            {"Incoming", string.NiceSize(incoming), Color(46, 204, 113)},
            {"Outgoing", string.NiceSize(outgoing), Color(52, 152, 219)},
            {"Total Traffic", string.NiceSize(incoming + outgoing), Color(155, 89, 182)},
            {"Average Ping", math.Round(LocalPlayer():Ping()) .. "ms", Color(241, 196, 15)}
        }
        
        for i, stat in ipairs(netStats) do
            local y = lyx.Scale(50 + (i-1) * 25)
            draw.SimpleText(stat[1] .. ":", "LYX.Stats.Text", lyx.Scale(15), y, lyx.Colors.SecondaryText)
            draw.SimpleText(stat[2], "LYX.Stats.Text", lyx.Scale(150), y, stat[3])
        end
    end
    
    -- Auto refresh
    timer.Create("LyxStatsRefresh", 1, 0, function()
        if IsValid(self) then
            -- Force repaint
            self:InvalidateLayout()
        else
            timer.Remove("LyxStatsRefresh")
        end
    end)
end

function PANEL:OnRemove()
    timer.Remove("LyxStatsRefresh")
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.ServerStats", PANEL)