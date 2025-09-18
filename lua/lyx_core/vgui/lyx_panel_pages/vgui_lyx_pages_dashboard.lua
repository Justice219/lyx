local PANEL = {}

lyx.RegisterFont("LYX.Dashboard.Title", "Open Sans Bold", lyx.Scale(24))
lyx.RegisterFont("LYX.Dashboard.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Dashboard.Text", "Open Sans", lyx.Scale(14))

function PANEL:Init()
    self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
    self.ScrollPanel:Dock(FILL)
    self.ScrollPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    
    -- Welcome Section
    local welcomePanel = vgui.Create("DPanel", self.ScrollPanel)
    welcomePanel:Dock(TOP)
    welcomePanel:SetTall(lyx.Scale(120))
    welcomePanel:DockMargin(0, 0, 0, lyx.Scale(10))
    welcomePanel.Paint = function(pnl, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 40, 200))
        
        -- Gradient overlay
        surface.SetDrawColor(186, 32, 55, 100)
        surface.DrawRect(0, 0, w, 2)
        
        draw.SimpleText("Welcome to Lyx Enhanced Admin Suite", "LYX.Dashboard.Title", 
            lyx.Scale(20), lyx.Scale(20), Color(186, 32, 55), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Version 2.0 - Security Hardened Edition", "LYX.Dashboard.Text", 
            lyx.Scale(20), lyx.Scale(50), Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Logged in as: " .. LocalPlayer():Nick() .. " | Rank: " .. LocalPlayer():GetUserGroup(), 
            "LYX.Dashboard.Text", lyx.Scale(20), lyx.Scale(75), Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Quick Stats Grid
    local statsContainer = vgui.Create("DPanel", self.ScrollPanel)
    statsContainer:Dock(TOP)
    statsContainer:SetTall(lyx.Scale(150))
    statsContainer:DockMargin(0, 0, 0, lyx.Scale(10))
    statsContainer.Paint = function() end
    
    local stats = {
        {title = "Players Online", value = #player.GetAll() .. "/" .. game.MaxPlayers(), icon = "👥", color = Color(52, 152, 219)},
        {title = "Server Uptime", value = string.NiceTime(CurTime()), icon = "⏱️", color = Color(46, 204, 113)},
        {title = "Active Hooks", value = table.Count(lyx.hooks or {}), icon = "🔗", color = Color(155, 89, 182)},
        {title = "Map", value = game.GetMap(), icon = "🗺️", color = Color(241, 196, 15)}
    }
    
    for i, stat in ipairs(stats) do
        local statPanel = vgui.Create("DButton", statsContainer)
        statPanel:SetText("")
        statPanel:SetSize(statsContainer:GetWide() / 4 - lyx.Scale(7), lyx.Scale(140))
        statPanel:SetPos((i-1) * (statsContainer:GetWide() / 4), 0)
        statPanel.Paint = function(pnl, w, h)
            local hover = pnl:IsHovered() and 10 or 0
            draw.RoundedBox(8, 0, 0, w - lyx.Scale(5), h, Color(40 + hover, 40 + hover, 50 + hover, 200))
            
            -- Icon background
            draw.RoundedBox(8, lyx.Scale(10), lyx.Scale(10), lyx.Scale(50), lyx.Scale(50), stat.color)
            
            -- Stats
            draw.SimpleText(stat.title, "LYX.Dashboard.Text", lyx.Scale(10), lyx.Scale(75), Color(150, 150, 150))
            draw.SimpleText(stat.value, "LYX.Dashboard.Header", lyx.Scale(10), lyx.Scale(95), Color(255, 255, 255))
        end
    end
    
    -- Quick Actions
    local actionsPanel = vgui.Create("DPanel", self.ScrollPanel)
    actionsPanel:Dock(TOP)
    actionsPanel:SetTall(lyx.Scale(200))
    actionsPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    actionsPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 40, 200))
        draw.SimpleText("Quick Actions", "LYX.Dashboard.Header", lyx.Scale(15), lyx.Scale(10), Color(255, 255, 255))
    end
    
    local actions = {
        {name = "Reload Ranks", func = function() RunConsoleCommand("lyx_rank_list") end, color = Color(52, 152, 219)},
        {name = "Clear Performance Stats", func = function() if lyx.PerfClear then lyx:PerfClear() end end, color = Color(46, 204, 113)},
        {name = "View Logs", func = function() self:GetParent():GetParent():ChangeTab("LYX.Pages.Logs", "System Logs") end, color = Color(241, 196, 15)},
        {name = "Open Console", func = function() gui.OpenURL("https://wiki.facepunch.com/gmod/") end, color = Color(231, 76, 60)}
    }
    
    for i, action in ipairs(actions) do
        local btn = vgui.Create("lyx.TextButton2", actionsPanel)
        btn:SetText(action.name)
        btn:SetSize(lyx.Scale(180), lyx.Scale(40))
        btn:SetPos(lyx.Scale(15 + ((i-1) % 3) * 190), lyx.Scale(50 + math.floor((i-1) / 3) * 50))
        btn.DoClick = action.func
        btn.color = action.color
    end
    
    -- Recent Activity Feed
    local activityPanel = vgui.Create("DPanel", self.ScrollPanel)
    activityPanel:Dock(TOP)
    activityPanel:SetTall(lyx.Scale(250))
    activityPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    activityPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 40, 200))
        draw.SimpleText("Recent Activity", "LYX.Dashboard.Header", lyx.Scale(15), lyx.Scale(10), Color(255, 255, 255))
    end
    
    self.ActivityList = vgui.Create("DListView", activityPanel)
    self.ActivityList:Dock(FILL)
    self.ActivityList:DockMargin(lyx.Scale(10), lyx.Scale(40), lyx.Scale(10), lyx.Scale(10))
    self.ActivityList:SetMultiSelect(false)
    self.ActivityList:AddColumn("Time"):SetWidth(lyx.Scale(80))
    self.ActivityList:AddColumn("Event"):SetWidth(lyx.Scale(150))
    self.ActivityList:AddColumn("Details")
    
    -- Pull real activity data from Lyx systems
    self:UpdateActivityFeed()
end

function PANEL:UpdateActivityFeed()
    self.ActivityList:Clear()
    
    -- Track various Lyx system events
    local activities = {}
    
    -- Get recent hook calls if available
    if lyx.hookStats then
        for hookName, stats in pairs(lyx.hookStats) do
            if stats.calls > 0 then
                table.insert(activities, {
                    time = os.date("%H:%M:%S"),
                    event = "Hook Called",
                    details = hookName .. " (" .. stats.calls .. " times)"
                })
            end
        end
    end
    
    -- Get recent network messages
    if lyx.netMessages then
        for msgName, _ in pairs(lyx.netMessages) do
            table.insert(activities, {
                time = os.date("%H:%M:%S"),
                event = "Net Message",
                details = "Registered: " .. msgName
            })
        end
    end
    
    -- Get recent SQL operations
    if lyx.perfData and lyx.perfData.sql then
        for operation, stats in pairs(lyx.perfData.sql) do
            if stats.calls > 0 then
                table.insert(activities, {
                    time = os.date("%H:%M:%S"),
                    event = "SQL Operation",
                    details = operation .. " (" .. stats.calls .. " queries)"
                })
            end
        end
    end
    
    -- Get recent setting changes
    if lyx.GetSettingKeys then
        local keys = lyx:GetSettingKeys()
        if #keys > 0 then
            table.insert(activities, {
                time = os.date("%H:%M:%S"),
                event = "Settings",
                details = #keys .. " settings loaded"
            })
        end
    end
    
    -- Get recent rank changes
    if lyx.GetAllRanks then
        local ranks = lyx:GetAllRanks()
        table.insert(activities, {
            time = os.date("%H:%M:%S"),
            event = "Ranks System",
            details = #ranks .. " ranks active"
        })
    end
    
    -- Add player events
    for _, ply in ipairs(player.GetAll()) do
        if ply.lyx_connected_time and (CurTime() - ply.lyx_connected_time) < 300 then -- Last 5 minutes
            table.insert(activities, {
                time = os.date("%H:%M:%S", ply.lyx_connected_time),
                event = "Player Connected",
                details = ply:Nick() .. " (" .. ply:GetUserGroup() .. ")"
            })
        end
    end
    
    -- Add chat command usage if tracked
    if lyx.chatCooldowns then
        for steamid, commands in pairs(lyx.chatCooldowns) do
            for cmd, lastUse in pairs(commands) do
                if (CurTime() - lastUse) < 60 then -- Last minute
                    table.insert(activities, {
                        time = os.date("%H:%M:%S", lastUse),
                        event = "Chat Command",
                        details = "!" .. cmd .. " used"
                    })
                end
            end
        end
    end
    
    -- Sort by most recent (assuming current time for all)
    table.sort(activities, function(a, b) return a.time > b.time end)
    
    -- Add to list (limit to 50 most recent)
    for i = 1, math.min(#activities, 50) do
        local act = activities[i]
        self.ActivityList:AddLine(act.time, act.event, act.details)
    end
    
    -- If no activities, show a message
    if #activities == 0 then
        self.ActivityList:AddLine(os.date("%H:%M:%S"), "System", "No recent activity to display")
    end
end

function PANEL:Think()
    -- Update stats periodically
    if not self.NextUpdate or CurTime() > self.NextUpdate then
        self.NextUpdate = CurTime() + 2 -- Update every 2 seconds
        
        -- Refresh activity feed
        self:UpdateActivityFeed()
        
        -- Force stats panels to repaint for updated values
        if self.ScrollPanel then
            for _, child in ipairs(self.ScrollPanel:GetChildren()) do
                child:InvalidateLayout()
            end
        end
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, lyx.Colors.Background or Color(20, 20, 30))
end

-- Store player connection times
hook.Add("PlayerInitialSpawn", "lyx_dashboard_track", function(ply)
    ply.lyx_connected_time = CurTime()
end)

vgui.Register("LYX.Pages.Dashboard", PANEL)
