local PANEL = {}

lyx.RegisterFont("LYX.Logs.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Logs.Text", "Open Sans", lyx.Scale(14))

function PANEL:Init()
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("System Logs", "LYX.Logs.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
    end
    
    -- Clear logs button - use docking for proper positioning
    local clearBtn = vgui.Create("lyx.TextButton2", headerPanel)
    clearBtn:SetText("Clear Logs")
    clearBtn:Dock(RIGHT)
    clearBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(12), lyx.Scale(12))
    clearBtn:SetWide(lyx.Scale(100))
    clearBtn.DoClick = function()
        self.LogList:Clear()
        notification.AddLegacy("Logs cleared!", NOTIFY_GENERIC, 3)
    end
    
    -- Logs list
    self.LogList = vgui.Create("DListView", self)
    self.LogList:Dock(FILL)
    self.LogList:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    self.LogList:SetMultiSelect(false)
    
    self.LogList:AddColumn("Time"):SetWidth(lyx.Scale(100))
    self.LogList:AddColumn("Type"):SetWidth(lyx.Scale(100))
    self.LogList:AddColumn("Message")
    
    -- Load sample logs (in production, would pull from actual log system)
    self:LoadLogs()
end

function PANEL:LoadLogs()
    -- Pull from Lyx log system if available
    if lyx.GetLogs then
        local logs = lyx:GetLogs()
        for _, log in ipairs(logs) do
            self.LogList:AddLine(log.time, log.type, log.message)
        end
    else
        -- Sample logs for demonstration
        self.LogList:AddLine(os.date("%H:%M:%S"), "INFO", "System initialized")
        self.LogList:AddLine(os.date("%H:%M:%S"), "AUTH", "Admin panel accessed by " .. LocalPlayer():Nick())
        self.LogList:AddLine(os.date("%H:%M:%S"), "SQL", "Database connection established")
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Logs", PANEL)