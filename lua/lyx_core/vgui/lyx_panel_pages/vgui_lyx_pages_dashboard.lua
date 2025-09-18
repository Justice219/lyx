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
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        draw.SimpleText("Welcome to Lyx Enhanced Admin Suite", "LYX.Dashboard.Title", 
            lyx.Scale(20), lyx.Scale(20), lyx.Colors.PrimaryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Version 2.0 - Security Hardened Edition", "LYX.Dashboard.Text", 
            lyx.Scale(20), lyx.Scale(50), lyx.Colors.SecondaryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Logged in as: " .. LocalPlayer():Nick() .. " | Rank: " .. LocalPlayer():GetUserGroup(), 
            "LYX.Dashboard.Text", lyx.Scale(20), lyx.Scale(75), lyx.Colors.DisabledText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Quick Stats Grid
    local statsContainer = vgui.Create("DPanel", self.ScrollPanel)
    statsContainer:Dock(TOP)
    statsContainer:SetTall(lyx.Scale(150))
    statsContainer:DockMargin(0, 0, 0, lyx.Scale(10))
    statsContainer.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
    end
    
    -- Create a layout for the stats
    local statsLayout = vgui.Create("DIconLayout", statsContainer)
    statsLayout:Dock(FILL)
    statsLayout:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    statsLayout:SetSpaceX(lyx.Scale(10))
    statsLayout:SetSpaceY(lyx.Scale(10))
    
    local stats = {
        {title = "Players Online", value = #player.GetAll() .. "/" .. game.MaxPlayers()},
        {title = "Server Uptime", value = string.NiceTime(CurTime())},
        {title = "Active Hooks", value = table.Count(hook.GetTable() or {})},
        {title = "Map", value = string.sub(game.GetMap(), 1, 20)}
    }
    
    for i, stat in ipairs(stats) do
        local statPanel = vgui.Create("DPanel", statsLayout)
        statPanel:SetSize(lyx.Scale(280), lyx.Scale(120))
        statPanel.Paint = function(pnl, w, h)
            draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
            
            
            -- Stats
            draw.SimpleText(stat.title, "LYX.Dashboard.Text", lyx.Scale(10), lyx.Scale(30), lyx.Colors.SecondaryText)
            draw.SimpleText(stat.value, "LYX.Dashboard.Header", lyx.Scale(10), lyx.Scale(55), lyx.Colors.PrimaryText)
        end
    end
    
    -- Quick Actions
    local actionsPanel = vgui.Create("DPanel", self.ScrollPanel)
    actionsPanel:Dock(TOP)
    actionsPanel:SetTall(lyx.Scale(200))
    actionsPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    actionsPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Quick Actions", "LYX.Dashboard.Header", lyx.Scale(15), lyx.Scale(15), lyx.Colors.PrimaryText)
    end
    
    local actions = {
        {name = "Reload Ranks", func = function() RunConsoleCommand("lyx_rank_list") end},
        {name = "Clear Cache", func = function() RunConsoleCommand("lyx_cache_clear") end},
        {name = "Save Settings", func = function() RunConsoleCommand("lyx_settings_save") end},
        {name = "Reload Config", func = function() RunConsoleCommand("lyx_reload") end},
        {name = "Server Restart", func = function() 
            Derma_Query("Are you sure you want to restart the server?", "Server Restart", 
                "Yes", function() RunConsoleCommand("_restart") end,
                "No", function() end)
        end},
        {name = "Map Change", func = function()
            Derma_StringRequest("Map Change", "Enter map name:", game.GetMap(), 
                function(text) RunConsoleCommand("changelevel", text) end)
        end}
    }
    
    for i, action in ipairs(actions) do
        local btn = vgui.Create("lyx.TextButton2", actionsPanel)
        btn:SetText(action.name)
        btn:SetSize(lyx.Scale(150), lyx.Scale(40))
        
        local x = ((i-1) % 3) * lyx.Scale(160) + lyx.Scale(15)
        local y = math.floor((i-1) / 3) * lyx.Scale(50) + lyx.Scale(50)
        btn:SetPos(x, y)
        
        btn.DoClick = action.func
    end
    
    -- Activity Feed
    local activityPanel = vgui.Create("DPanel", self.ScrollPanel)
    activityPanel:Dock(TOP)
    activityPanel:SetTall(lyx.Scale(300))
    activityPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    activityPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        -- Title
        draw.SimpleText("Recent Activity", "LYX.Dashboard.Header", 
            lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
    end
    
    -- Activity list
    self.ActivityList = vgui.Create("lyx.ListView2", activityPanel)
    self.ActivityList:Dock(FILL)
    self.ActivityList:DockMargin(lyx.Scale(10), lyx.Scale(40), lyx.Scale(10), lyx.Scale(10))
    
    self.ActivityList:AddColumn("Time", lyx.Scale(80))
    self.ActivityList:AddColumn("Event", lyx.Scale(150))
    self.ActivityList:AddColumn("Details", lyx.Scale(400))
    
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
                event = "Settings Loaded",
                details = #keys .. " settings in cache"
            })
        end
    end
    
    -- Get recent player events
    hook.Add("PlayerInitialSpawn", "Lyx.Dashboard.PlayerJoin", function(ply)
        if IsValid(self) and IsValid(self.ActivityList) then
            timer.Simple(0, function()
                if IsValid(self) and IsValid(self.ActivityList) then
                    self:AddActivity("Player Joined", ply:Nick() .. " (" .. ply:SteamID() .. ")", "player")
                end
            end)
        end
    end)
    
    hook.Add("PlayerDisconnected", "Lyx.Dashboard.PlayerLeave", function(ply)
        if IsValid(self) and IsValid(self.ActivityList) then
            timer.Simple(0, function()
                if IsValid(self) and IsValid(self.ActivityList) then
                    self:AddActivity("Player Left", ply:Nick(), "player")
                end
            end)
        end
    end)
    
    -- Sort by time and add to list
    table.sort(activities, function(a, b) return a.time > b.time end)
    
    for _, activity in ipairs(activities) do
        self:AddActivity(activity.event, activity.details, "system")
    end
    
    -- Auto-refresh every 5 seconds
    timer.Create("Lyx.Dashboard.Refresh", 5, 0, function()
        if IsValid(self) then
            self:UpdateActivityFeed()
        else
            timer.Remove("Lyx.Dashboard.Refresh")
        end
    end)
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

function PANEL:OnRemove()
    timer.Remove("Lyx.Dashboard.Refresh")
    hook.Remove("PlayerInitialSpawn", "Lyx.Dashboard.PlayerJoin")
    hook.Remove("PlayerDisconnected", "Lyx.Dashboard.PlayerLeave")
end

function PANEL:AddActivity(event, details, activityType)
    local time = os.date("%H:%M:%S")
    
    local row = self.ActivityList:AddRow(time, event, details)
    
    -- Store activity type for painting
    row.ActivityType = activityType
    row.ActivityTime = time
    row.ActivityEvent = event
    row.ActivityDetails = details
    
    -- Override paint for activity type coloring
    local oldPaint = row.Paint
    row.Paint = function(pnl, w, h)
        -- Background
        local bgColor = lyx.Colors.Background
        
        if pnl == self.ActivityList.SelectedRow then
            bgColor = Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 40)
        elseif pnl:IsHovered() then
            bgColor = Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 20)
        end
        
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        
        -- Activity type color
        local typeColor = lyx.Colors.SecondaryText
        if pnl.ActivityType == "player" then
            typeColor = lyx.Colors.Primary or Color(52, 152, 219)
        elseif pnl.ActivityType == "system" then
            typeColor = lyx.Colors.Positive or Color(46, 204, 113)
        elseif pnl.ActivityType == "error" then
            typeColor = lyx.Colors.Negative or Color(231, 76, 60)
        elseif pnl.ActivityType == "warning" then
            typeColor = lyx.Colors.Warning or Color(241, 196, 15)
        end
        
        -- Color indicator dot
        draw.RoundedBox(4, lyx.Scale(8), h/2 - lyx.Scale(4), lyx.Scale(8), lyx.Scale(8), typeColor)
        
        -- Draw values
        local x = lyx.Scale(20)
        local values = {pnl.ActivityTime, pnl.ActivityEvent, pnl.ActivityDetails}
        for i, header in ipairs(self.ActivityList.Headers) do
            local value = values[i] or ""
            local textColor = (i == 2) and typeColor or lyx.Colors.SecondaryText
            draw.SimpleText(tostring(value), "LYX.List.Text", x + lyx.Scale(10), h/2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            x = x + header.Width
        end
    end
    
    -- Keep only last 50 activities
    if self.ActivityList:GetRowCount() > 50 then
        local firstRow = self.ActivityList.Rows[1]
        if IsValid(firstRow) then
            firstRow:Remove()
            table.remove(self.ActivityList.Rows, 1)
        end
    end
end

vgui.Register("LYX.Pages.Dashboard", PANEL)