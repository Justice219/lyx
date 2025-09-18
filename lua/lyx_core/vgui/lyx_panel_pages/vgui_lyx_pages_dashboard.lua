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
        {title = "Map", value = game.GetMap()}
    }
    
    for i, stat in ipairs(stats) do
        local statPanel = vgui.Create("DButton", statsLayout)
        statPanel:SetText("")
        statPanel:SetSize(lyx.Scale(280), lyx.Scale(120))
        statPanel.Paint = function(pnl, w, h)
            local hover = pnl:IsHovered() and 10 or 0
            draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
            
            -- Hover effect
            if pnl:IsHovered() then
                draw.RoundedBox(4, 0, 0, w, h, Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 30))
            end
            
            -- Stats
            draw.SimpleText(stat.title, "LYX.Dashboard.Text", lyx.Scale(10), lyx.Scale(15), lyx.Colors.SecondaryText)
            draw.SimpleText(stat.value, "LYX.Dashboard.Header", lyx.Scale(10), lyx.Scale(40), lyx.Colors.PrimaryText)
        end
    end
    
    -- Quick Actions
    local actionsPanel = vgui.Create("DPanel", self.ScrollPanel)
    actionsPanel:Dock(TOP)
    actionsPanel:SetTall(lyx.Scale(200))
    actionsPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    actionsPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Quick Actions", "LYX.Dashboard.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
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
    self.ActivityList = vgui.Create("DListView", activityPanel)
    self.ActivityList:Dock(FILL)
    self.ActivityList:DockMargin(lyx.Scale(10), lyx.Scale(40), lyx.Scale(10), lyx.Scale(10))
    self.ActivityList:SetMultiSelect(false)
    
    -- Style the list view
    self.ActivityList.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
    end
    
    local oldLine = self.ActivityList.AddLine
    self.ActivityList.AddLine = function(list, ...)
        local line = oldLine(list, ...)
        line.Paint = function(pnl, w, h)
            if pnl:IsHovered() then
                draw.RoundedBox(0, 0, 0, w, h, Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 30))
            end
        end
        for _, col in pairs(line.Columns) do
            col:SetTextColor(lyx.Colors.SecondaryText)
        end
        return line
    end
    
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
                    self.ActivityList:AddLine(
                        os.date("%H:%M:%S"),
                        "Player Joined",
                        ply:Nick() .. " (" .. ply:SteamID() .. ")"
                    )
                end
            end)
        end
    end)
    
    hook.Add("PlayerDisconnected", "Lyx.Dashboard.PlayerLeave", function(ply)
        if IsValid(self) and IsValid(self.ActivityList) then
            timer.Simple(0, function()
                if IsValid(self) and IsValid(self.ActivityList) then
                    self.ActivityList:AddLine(
                        os.date("%H:%M:%S"),
                        "Player Left",
                        ply:Nick()
                    )
                end
            end)
        end
    end)
    
    -- Sort by time and add to list
    table.sort(activities, function(a, b) return a.time > b.time end)
    
    for _, activity in ipairs(activities) do
        self.ActivityList:AddLine(activity.time, activity.event, activity.details)
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

vgui.Register("LYX.Pages.Dashboard", PANEL)