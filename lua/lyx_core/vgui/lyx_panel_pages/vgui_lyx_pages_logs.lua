local PANEL = {}
local MAX_VISIBLE_LOGS = 200 -- cap rows to avoid UI lag/crashes

lyx.RegisterFont("LYX.Logs.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Logs.Text", "Open Sans", lyx.Scale(14))

function PANEL:Init()
    -- Store logs
    self.Logs = {}
    self.FilteredAddon = nil
    self.MaxShownLogs = MAX_VISIBLE_LOGS
    self.CurrentFilteredTotal = 0
    self.CurrentDisplayedCount = 0
    
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("System Logs", "LYX.Logs.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
        
        -- Log count
        local totalLogs = self.CurrentFilteredTotal
        if totalLogs == 0 and lyx.LogHistory then
            totalLogs = #lyx.LogHistory
        end
        local visibleLogs = self.CurrentDisplayedCount
        if visibleLogs == 0 and totalLogs > 0 then
            visibleLogs = math.min(totalLogs, self.MaxShownLogs)
        end
        local countLabel = totalLogs > visibleLogs and
            string.format("Showing %d of %d entries", visibleLogs, totalLogs) or
            string.format("%d entries", totalLogs)
        draw.SimpleText(countLabel, "LYX.Logs.Text", w - lyx.Scale(400), lyx.Scale(22), lyx.Colors.SecondaryText)
    end
    
    -- Filter by level dropdown
    local filterDropdown = vgui.Create("DComboBox", headerPanel)
    filterDropdown:SetPos(headerPanel:GetWide() - lyx.Scale(150), lyx.Scale(15))
    filterDropdown:SetSize(lyx.Scale(100), lyx.Scale(30))
    filterDropdown:SetValue("All Levels")
    filterDropdown:AddChoice("All Levels")
    filterDropdown:AddChoice("info")
    filterDropdown:AddChoice("warn")
    filterDropdown:AddChoice("error")
    self.LevelFilter = filterDropdown
    filterDropdown.OnSelect = function(_, _, value)
        self:RefreshLogs()
    end
    
    -- Filter by addon dropdown
    local addonDropdown = vgui.Create("DComboBox", headerPanel)
    addonDropdown:SetPos(headerPanel:GetWide() - lyx.Scale(260), lyx.Scale(15))
    addonDropdown:SetSize(lyx.Scale(100), lyx.Scale(30))
    addonDropdown:SetValue("All Addons")
    addonDropdown:AddChoice("All Addons")
    
    -- Add known addons to dropdown
    local addonsFound = {}
    if lyx.LogHistory then
        for _, log in ipairs(lyx.LogHistory) do
            if log.addon and not addonsFound[log.addon] then
                addonsFound[log.addon] = true
                addonDropdown:AddChoice(log.addon)
            end
        end
    end
    
    self.AddonFilter = addonDropdown
    addonDropdown.OnSelect = function(_, _, value)
        self:RefreshLogs()
    end
    
    -- Position filters after panel gets width
    headerPanel.PerformLayout = function(pnl, w, h)
        if filterDropdown and IsValid(filterDropdown) then
            filterDropdown:SetPos(w - lyx.Scale(120), lyx.Scale(15))
        end
        if addonDropdown and IsValid(addonDropdown) then
            addonDropdown:SetPos(w - lyx.Scale(230), lyx.Scale(15))
        end
    end
    
    -- Clear logs button
    local clearBtn = vgui.Create("lyx.TextButton2", headerPanel)
    clearBtn:SetText("Clear Logs")
    clearBtn:Dock(RIGHT)
    clearBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(12), lyx.Scale(12))
    clearBtn:SetWide(lyx.Scale(100))
    clearBtn.DoClick = function()
        self.LogList:Clear()
        lyx.LogHistory = {}
        self.Logs = {}
        self.CurrentFilteredTotal = 0
        self.CurrentDisplayedCount = 0
        notification.AddLegacy("Logs cleared!", NOTIFY_GENERIC, 3)
    end
    
    -- Export button
    local exportBtn = vgui.Create("lyx.TextButton2", headerPanel)
    exportBtn:SetText("Export")
    exportBtn:Dock(RIGHT)
    exportBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(5), lyx.Scale(12))
    exportBtn:SetWide(lyx.Scale(80))
    exportBtn.DoClick = function()
        self:ExportLogs()
    end
    
    -- Log list container
    local listContainer = vgui.Create("DPanel", self)
    listContainer:Dock(FILL)
    listContainer:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    listContainer.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
    end
    
    -- Use custom list view
    self.LogList = vgui.Create("lyx.ListView2", listContainer)
    self.LogList:Dock(FILL)
    self.LogList:DockMargin(lyx.Scale(5), lyx.Scale(5), lyx.Scale(5), lyx.Scale(5))
    
    -- Add columns
    self.LogList:AddColumn("Time", lyx.Scale(100))
    self.LogList:AddColumn("Level", lyx.Scale(60))
    self.LogList:AddColumn("Addon", lyx.Scale(100))
    self.LogList:AddColumn("Message", lyx.Scale(500))
    
    -- Override row adding for custom painting
    local oldAddRow = self.LogList.AddRow
    self.LogList.AddRow = function(list, time, level, addon, message, logColor)
        local row = oldAddRow(list, time, level, addon, message)
        
        -- Store log data
        row.LogLevel = level
        row.LogAddon = addon
        row.LogColor = logColor
        
        -- Override paint for color coding
        local oldPaint = row.Paint
        row.Paint = function(pnl, w, h)
            -- Background
            local bgColor = lyx.Colors.Background
            
            if pnl == list.SelectedRow then
                bgColor = Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 40)
            elseif pnl:IsHovered() then
                bgColor = Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 20)
            end
            
            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            
            -- Level indicator color
            local levelColor = lyx.Colors.SecondaryText
            if pnl.LogLevel == "error" then
                levelColor = lyx.Colors.Negative or Color(231, 76, 60)
            elseif pnl.LogLevel == "warn" then
                levelColor = lyx.Colors.Warning or Color(241, 196, 15)
            elseif pnl.LogLevel == "info" then
                levelColor = lyx.Colors.Positive or Color(46, 204, 113)
            end
            
            -- Addon color bar on left
            local addonColor = pnl.LogColor or lyx.Colors.Primary
            draw.RoundedBox(2, 0, 0, lyx.Scale(3), h, addonColor)
            
            -- Draw values
            local x = lyx.Scale(5)
            local values = {time, pnl.LogLevel, pnl.LogAddon, message}
            for i, header in ipairs(list.Headers) do
                local value = values[i] or ""
                local textColor = lyx.Colors.SecondaryText
                if i == 2 then  -- Level column
                    textColor = levelColor
                elseif i == 3 then  -- Addon column
                    textColor = addonColor
                end
                draw.SimpleText(tostring(value), "LYX.List.Text", x + lyx.Scale(10), h/2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                x = x + header.Width
            end
        end
        
        return row
    end
    
    -- Request log history from server
    if CLIENT then
        net.Start("lyx:logger:requesthistory")
        net.SendToServer()
    end
    
    -- Load existing logs
    self:RefreshLogs()
    
    -- Hook into log updates
    hook.Add("Lyx.LogUpdated", "LyxLogsPanel" .. tostring(self), function(log)
        if IsValid(self) then
            self:AddLogEntry(log)
        end
    end)
    
    -- Auto-refresh timer
    timer.Create("LyxLogsRefresh" .. tostring(self), 1, 0, function()
        if IsValid(self) then
            self:RefreshLogs()
        else
            timer.Remove("LyxLogsRefresh" .. tostring(self))
        end
    end)
end

function PANEL:RefreshLogs()
    self.LogList:Clear()
    self.CurrentDisplayedCount = 0
    
    if not lyx.LogHistory then
        self.CurrentFilteredTotal = 0
        return
    end
    
    local filteredLogs = {}
    for _, log in ipairs(lyx.LogHistory) do
        if self:MatchesFilters(log) then
            table.insert(filteredLogs, log)
        end
    end
    
    self.CurrentFilteredTotal = #filteredLogs
    if #filteredLogs == 0 then return end
    
    local maxLogs = self.MaxShownLogs or MAX_VISIBLE_LOGS
    local startIndex = math.max(1, #filteredLogs - maxLogs + 1)
    for i = startIndex, #filteredLogs do
        self:AddLogEntry(filteredLogs[i], true)
    end
    self.CurrentDisplayedCount = math.min(#filteredLogs, maxLogs)
end

function PANEL:MatchesFilters(log)
    if not log then return false end
    
    local levelFilter = self.LevelFilter and self.LevelFilter:GetValue() or "All Levels"
    if levelFilter ~= "All Levels" and log.level ~= levelFilter then
        return false
    end
    
    local addonFilter = self.AddonFilter and self.AddonFilter:GetValue() or "All Addons"
    if addonFilter ~= "All Addons" and log.addon ~= addonFilter then
        return false
    end
    
    return true
end

function PANEL:AddLogEntry(log, bypassFilter)
    if not log then return end
    if not bypassFilter and not self:MatchesFilters(log) then return end
    
    local timeStr = os.date("%H:%M:%S", log.time or os.time())
    
    -- Add to list with color
    self.LogList:AddRow(
        timeStr,
        log.level or "info",
        log.addon or "Unknown",
        log.message or "",
        log.color
    )
    self:TrimLogRows()
    
    -- Auto-scroll to bottom
    if self.LogList.ScrollPanel then
        timer.Simple(0, function()
            if IsValid(self) and IsValid(self.LogList.ScrollPanel) then
                local vbar = self.LogList.ScrollPanel:GetVBar()
                if vbar then
                    vbar:SetScroll(vbar.CanvasSize)
                end
            end
        end)
    end
end

function PANEL:TrimLogRows()
    if not IsValid(self.LogList) then return end
    
    local maxRows = self.MaxShownLogs or MAX_VISIBLE_LOGS
    
    while self.LogList:GetRowCount() > maxRows do
        local oldestRow = table.remove(self.LogList.Rows, 1)
        if IsValid(oldestRow) then
            oldestRow:Remove()
        end
    end
    
    for idx, row in ipairs(self.LogList.Rows) do
        row.Index = idx
    end
    
    local rowHeight = lyx.Scale(35) + lyx.Scale(2)
    self.LogList.RowContainer:SetTall(#self.LogList.Rows * rowHeight)
    self.CurrentDisplayedCount = math.min(self.LogList:GetRowCount(), maxRows)
end


function PANEL:ExportLogs()
    local logText = "Lyx System Logs - Exported " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    logText = logText .. string.rep("=", 80) .. "\n\n"
    
    if lyx.LogHistory then
        for _, log in ipairs(lyx.LogHistory) do
            local timeStr = os.date("%Y-%m-%d %H:%M:%S", log.time)
            logText = logText .. string.format("[%s] [%s] [%s] %s\n", 
                timeStr, log.level or "info", log.addon or "Unknown", log.message or "")
        end
    end
    
    -- Copy to clipboard
    SetClipboardText(logText)
    notification.AddLegacy("Logs exported to clipboard!", NOTIFY_GENERIC, 3)
end

function PANEL:OnRemove()
    hook.Remove("Lyx.LogUpdated", "LyxLogsPanel" .. tostring(self))
    timer.Remove("LyxLogsRefresh" .. tostring(self))
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Logs", PANEL)
