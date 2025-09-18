local PANEL = {}

lyx.RegisterFont("LYX.Perf.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Perf.Text", "Open Sans", lyx.Scale(14))
lyx.RegisterFont("LYX.Perf.Number", "Courier New", lyx.Scale(16))

function PANEL:Init()
    self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
    self.ScrollPanel:Dock(FILL)
    self.ScrollPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    
    -- FPS Monitor
    local fpsPanel = vgui.Create("DPanel", self.ScrollPanel)
    fpsPanel:Dock(TOP)
    fpsPanel:SetTall(lyx.Scale(120))
    fpsPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    fpsPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        -- Title
        draw.SimpleText("Frame Rate Monitor", "LYX.Perf.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
        
        local fps = math.Round(1 / RealFrameTime())
        local color = Color(46, 204, 113)  -- Green
        if fps < 30 then
            color = Color(231, 76, 60)  -- Red
        elseif fps < 60 then
            color = Color(241, 196, 15)  -- Yellow
        end
        
        -- FPS Display
        draw.SimpleText(fps .. " FPS", "LYX.Perf.Number", lyx.Scale(15), lyx.Scale(40), color)
        draw.SimpleText("Frame Time: " .. math.Round(RealFrameTime() * 1000, 2) .. "ms", "LYX.Perf.Text", 
            lyx.Scale(15), lyx.Scale(70), lyx.Colors.SecondaryText)
        
        -- Graph background
        local graphX = lyx.Scale(250)
        local graphW = w - graphX - lyx.Scale(20)
        local graphH = h - lyx.Scale(20)
        
        surface.SetDrawColor(lyx.Colors.Background.r, lyx.Colors.Background.g, lyx.Colors.Background.b, lyx.Colors.Background.a)
        surface.DrawRect(graphX, lyx.Scale(10), graphW, graphH)
        
        -- Draw FPS graph
        if not pnl.fpsHistory then pnl.fpsHistory = {} end
        table.insert(pnl.fpsHistory, fps)
        if #pnl.fpsHistory > 60 then
            table.remove(pnl.fpsHistory, 1)
        end
        
        for i = 2, #pnl.fpsHistory do
            local x1 = graphX + ((i-2) / 59) * graphW
            local x2 = graphX + ((i-1) / 59) * graphW
            local y1 = lyx.Scale(10) + graphH - (pnl.fpsHistory[i-1] / 144) * graphH
            local y2 = lyx.Scale(10) + graphH - (pnl.fpsHistory[i] / 144) * graphH
            
            surface.SetDrawColor(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 255)
            surface.DrawLine(x1, y1, x2, y2)
        end
    end
    
    -- Memory Usage
    local memPanel = vgui.Create("DPanel", self.ScrollPanel)
    memPanel:Dock(TOP)
    memPanel:SetTall(lyx.Scale(100))
    memPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    memPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        draw.SimpleText("Memory Usage", "LYX.Perf.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
        
        local memUsage = collectgarbage("count") / 1024  -- Convert to MB
        draw.SimpleText(math.Round(memUsage, 2) .. " MB", "LYX.Perf.Number", 
            lyx.Scale(15), lyx.Scale(40), lyx.Colors.Primary or Color(155, 89, 182))
        
        -- Memory bar
        local barX = lyx.Scale(150)
        local barW = w - barX - lyx.Scale(20)
        local barH = lyx.Scale(20)
        local barY = lyx.Scale(45)
        
        surface.SetDrawColor(lyx.Colors.Background.r, lyx.Colors.Background.g, lyx.Colors.Background.b, lyx.Colors.Background.a)
        surface.DrawRect(barX, barY, barW, barH)
        
        local memPercent = math.min(memUsage / 512, 1)  -- Assume 512MB max
        surface.SetDrawColor(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 255)
        surface.DrawRect(barX, barY, barW * memPercent, barH)
        
        draw.SimpleText(math.Round(memPercent * 100) .. "%", "LYX.Perf.Text", 
            barX + barW / 2, barY + barH / 2, lyx.Colors.PrimaryText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Hook Performance
    if lyx.HookGetStats then
        local hookPanel = vgui.Create("DPanel", self.ScrollPanel)
        hookPanel:Dock(TOP)
        hookPanel:SetTall(lyx.Scale(300))
        hookPanel:DockMargin(0, 0, 0, lyx.Scale(10))
        hookPanel.Paint = function(pnl, w, h)
            draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
            draw.SimpleText("Hook Performance", "LYX.Perf.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
        end
        
        local hookList = vgui.Create("lyx.ListView2", hookPanel)
        hookList:Dock(FILL)
        hookList:DockMargin(lyx.Scale(10), lyx.Scale(40), lyx.Scale(10), lyx.Scale(10))
        
        hookList:AddColumn("Hook Name", lyx.Scale(200))
        hookList:AddColumn("Calls", lyx.Scale(80))
        hookList:AddColumn("Avg Time (ms)", lyx.Scale(120))
        hookList:AddColumn("Total Time (s)", lyx.Scale(120))
        hookList:AddColumn("Max Time (ms)", lyx.Scale(120))
        
        self.HookList = hookList
        self:UpdateHookStats()
    end
    
    -- Entity Count
    local entityPanel = vgui.Create("DPanel", self.ScrollPanel)
    entityPanel:Dock(TOP)
    entityPanel:SetTall(lyx.Scale(150))
    entityPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    entityPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Entity Statistics", "LYX.Perf.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
        
        local entities = ents.GetAll()
        local props = 0
        local npcs = 0
        local weapons = 0
        local vehicles = 0
        
        for _, ent in ipairs(entities) do
            if ent:GetClass():find("prop_") then props = props + 1
            elseif ent:IsNPC() then npcs = npcs + 1
            elseif ent:IsWeapon() then weapons = weapons + 1
            elseif ent:IsVehicle() then vehicles = vehicles + 1
            end
        end
        
        local stats = {
            {"Total Entities", #entities, lyx.Colors.Primary or Color(52, 152, 219)},
            {"Props", props, lyx.Colors.Positive or Color(46, 204, 113)},
            {"NPCs", npcs, lyx.Colors.Warning or Color(241, 196, 15)},
            {"Weapons", weapons, Color(155, 89, 182)},
            {"Vehicles", vehicles, lyx.Colors.Negative or Color(231, 76, 60)}
        }
        
        for i, stat in ipairs(stats) do
            local y = lyx.Scale(40 + (i-1) * 20)
            draw.SimpleText(stat[1] .. ":", "LYX.Perf.Text", lyx.Scale(15), y, lyx.Colors.SecondaryText)
            draw.SimpleText(tostring(stat[2]), "LYX.Perf.Text", lyx.Scale(150), y, stat[3])
        end
    end
    
    -- Control buttons
    local controlPanel = vgui.Create("DPanel", self.ScrollPanel)
    controlPanel:Dock(TOP)
    controlPanel:SetTall(lyx.Scale(60))
    controlPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    controlPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
    end
    
    local btnGC = vgui.Create("lyx.TextButton2", controlPanel)
    btnGC:SetText("Force Garbage Collection")
    btnGC:Dock(LEFT)
    btnGC:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(5), lyx.Scale(10))
    btnGC:SetWide(lyx.Scale(200))
    btnGC.DoClick = function()
        collectgarbage("collect")
        notification.AddLegacy("Garbage collection completed!", NOTIFY_GENERIC, 2)
    end
    
    local btnClearStats = vgui.Create("lyx.TextButton2", controlPanel)
    btnClearStats:SetText("Clear Performance Stats")
    btnClearStats:Dock(LEFT)
    btnClearStats:DockMargin(lyx.Scale(5), lyx.Scale(10), lyx.Scale(5), lyx.Scale(10))
    btnClearStats:SetWide(lyx.Scale(200))
    btnClearStats.DoClick = function()
        if lyx.PerfClear then
            lyx:PerfClear()
            notification.AddLegacy("Performance stats cleared!", NOTIFY_GENERIC, 2)
            self:UpdateHookStats()
        end
    end
    
    local btnExport = vgui.Create("lyx.TextButton2", controlPanel)
    btnExport:SetText("Export Performance Report")
    btnExport:Dock(LEFT)
    btnExport:DockMargin(lyx.Scale(5), lyx.Scale(10), lyx.Scale(5), lyx.Scale(10))
    btnExport:SetWide(lyx.Scale(200))
    btnExport.DoClick = function()
        if lyx.PerfPrintReport then
            lyx:PerfPrintReport()
            notification.AddLegacy("Performance report printed to console!", NOTIFY_GENERIC, 2)
        end
    end
    
    -- Auto refresh
    timer.Create("LyxPerfRefresh", 0.5, 0, function()
        if IsValid(self) then
            self:UpdateHookStats()
        else
            timer.Remove("LyxPerfRefresh")
        end
    end)
end

function PANEL:UpdateHookStats()
    if not self.HookList or not lyx.HookGetStats then return end
    
    self.HookList:Clear()
    
    local stats = lyx:HookGetStats()
    if not stats then return end
    
    -- Convert to sorted array
    local sorted = {}
    for hookName, data in pairs(stats) do
        if data and data.calls and data.calls > 0 then
            table.insert(sorted, {
                name = hookName,
                calls = data.calls,
                avgTime = math.Round((data.totalTime / data.calls) * 1000, 3),
                totalTime = math.Round(data.totalTime, 3),
                maxTime = math.Round(data.maxTime * 1000, 3)
            })
        end
    end
    
    -- Sort by total time descending
    table.sort(sorted, function(a, b)
        return a.totalTime > b.totalTime
    end)
    
    -- Add rows with color coding based on performance
    for _, data in ipairs(sorted) do
        local row = self.HookList:AddRow(
            data.name,
            data.calls,
            data.avgTime,
            data.totalTime,
            data.maxTime
        )
        
        -- Override paint for performance color coding
        local oldPaint = row.Paint
        row.Paint = function(pnl, w, h)
            -- Background
            local bgColor = lyx.Colors.Background
            
            if pnl == self.HookList.SelectedRow then
                bgColor = Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 40)
            elseif pnl:IsHovered() then
                bgColor = Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 20)
            end
            
            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            
            -- Performance indicator color
            local perfColor = lyx.Colors.Positive or Color(46, 204, 113)
            if data.avgTime > 10 then
                perfColor = lyx.Colors.Negative or Color(231, 76, 60)
            elseif data.avgTime > 5 then
                perfColor = lyx.Colors.Warning or Color(241, 196, 15)
            end
            
            -- Color bar on left
            draw.RoundedBox(2, 0, 0, lyx.Scale(3), h, perfColor)
            
            -- Draw values
            local x = lyx.Scale(5)
            for i, header in ipairs(self.HookList.Headers) do
                local values = {data.name, data.calls, data.avgTime, data.totalTime, data.maxTime}
                local value = values[i] or ""
                local textColor = (i == 3 and data.avgTime > 5) and perfColor or lyx.Colors.SecondaryText
                draw.SimpleText(tostring(value), "LYX.List.Text", x + lyx.Scale(10), h/2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                x = x + header.Width
            end
        end
    end
end

function PANEL:OnRemove()
    timer.Remove("LyxPerfRefresh")
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Performance", PANEL)