local PANEL = {}

lyx.RegisterFont("LYX.Logs.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Logs.Text", "Open Sans", lyx.Scale(14))

function PANEL:Init()
    -- Store logs
    self.Logs = {}
    
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("System Logs", "LYX.Logs.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
        
        -- Log count
        draw.SimpleText(#self.Logs .. " entries", "LYX.Logs.Text", w - lyx.Scale(250), lyx.Scale(22), lyx.Colors.SecondaryText)
    end
    
    -- Filter dropdown
    local filterDropdown = vgui.Create("DComboBox", headerPanel)
    filterDropdown:SetPos(headerPanel:GetWide() - lyx.Scale(150), lyx.Scale(15))
    filterDropdown:SetSize(lyx.Scale(120), lyx.Scale(30))
    filterDropdown:SetValue("All Types")
    filterDropdown:AddChoice("All Types")
    filterDropdown:AddChoice("INFO")
    filterDropdown:AddChoice("WARNING")
    filterDropdown:AddChoice("ERROR")
    filterDropdown:AddChoice("DEBUG")
    filterDropdown.OnSelect = function(_, _, value)
        self:FilterLogs(value)
    end
    
    -- Position filter after panel gets width
    headerPanel.PerformLayout = function(pnl, w, h)
        if filterDropdown and IsValid(filterDropdown) then
            filterDropdown:SetPos(w - lyx.Scale(140), lyx.Scale(15))
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
        self.Logs = {}
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
    self.LogList:AddColumn("Type", lyx.Scale(80))
    self.LogList:AddColumn("Source", lyx.Scale(150))
    self.LogList:AddColumn("Message", lyx.Scale(500))
    
    -- Custom row colors based on log type
    local oldAddRow = self.LogList.AddRow
    self.LogList.AddRow = function(list, ...)
        local row = oldAddRow(list, ...)
        local values = {...}
        local logType = values[2]
        
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
            
            -- Type indicator color
            local typeColor = lyx.Colors.SecondaryText
            if logType == "ERROR" then
                typeColor = lyx.Colors.Negative or Color(231, 76, 60)
            elseif logType == "WARNING" then
                typeColor = lyx.Colors.Warning or Color(241, 196, 15)
            elseif logType == "INFO" then
                typeColor = lyx.Colors.Positive or Color(46, 204, 113)
            elseif logType == "DEBUG" then
                typeColor = Color(155, 89, 182)
            end
            
            -- Color bar on left
            draw.RoundedBox(2, 0, 0, lyx.Scale(3), h, typeColor)
            
            -- Draw values
            local x = lyx.Scale(5)
            for i, header in ipairs(list.Headers) do
                local value = values[i] or ""
                local textColor = i == 2 and typeColor or lyx.Colors.SecondaryText
                draw.SimpleText(tostring(value), "LYX.List.Text", x + lyx.Scale(10), h/2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                x = x + header.Width
            end
        end
        
        return row
    end
    
    -- Load logs
    self:LoadLogs()
    
    -- Hook into Lyx logger
    hook.Add("Lyx.LogAdded", "LyxLogsPanel", function(level, message, source)
        if IsValid(self) then
            self:AddLog(level, message, source)
        end
    end)
end

function PANEL:LoadLogs()
    -- Pull from Lyx log system if available
    if lyx.Logger and lyx.Logger.GetLogs then
        local logs = lyx.Logger:GetLogs()
        for _, log in ipairs(logs) do
            local logType = "INFO"
            if log.level == 1 then logType = "INFO"
            elseif log.level == 2 then logType = "WARNING"
            elseif log.level == 3 then logType = "ERROR"
            elseif log.level == 4 then logType = "DEBUG"
            end
            
            self:AddLog(logType, log.message, log.source or "System")
        end
    else
        -- Add some sample logs
        self:AddLog("INFO", "Lyx Admin Panel initialized", "System")
        self:AddLog("INFO", "Configuration loaded successfully", "Config")
        self:AddLog("WARNING", "Rate limiting threshold reached", "Network")
        self:AddLog("DEBUG", "Cache cleared", "Performance")
    end
end

function PANEL:AddLog(logType, message, source)
    local time = os.date("%H:%M:%S")
    
    -- Store log
    table.insert(self.Logs, {
        time = time,
        type = logType,
        source = source or "Unknown",
        message = message
    })
    
    -- Limit log history
    if #self.Logs > 1000 then
        table.remove(self.Logs, 1)
    end
    
    -- Add to list
    self.LogList:AddRow(time, logType, source or "Unknown", message)
    
    -- Auto-scroll to bottom
    if self.LogList.ScrollPanel then
        self.LogList.ScrollPanel:ScrollToChild(self.LogList.RowContainer)
    end
end

function PANEL:FilterLogs(filterType)
    self.LogList:Clear()
    
    for _, log in ipairs(self.Logs) do
        if filterType == "All Types" or log.type == filterType then
            self.LogList:AddRow(log.time, log.type, log.source, log.message)
        end
    end
end

function PANEL:ExportLogs()
    local logText = "Lyx System Logs - Exported " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    logText = logText .. string.rep("=", 80) .. "\n\n"
    
    for _, log in ipairs(self.Logs) do
        logText = logText .. string.format("[%s] [%s] [%s] %s\n", 
            log.time, log.type, log.source, log.message)
    end
    
    -- Copy to clipboard
    SetClipboardText(logText)
    notification.AddLegacy("Logs exported to clipboard!", NOTIFY_GENERIC, 3)
end

function PANEL:OnRemove()
    hook.Remove("Lyx.LogAdded", "LyxLogsPanel")
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Logs", PANEL)