local PANEL = {}

lyx.RegisterFont("LYX.Debug.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Debug.Text", "Courier New", lyx.Scale(14))

function PANEL:Init()
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Debug Tools", "LYX.Debug.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
    end
    
    -- Clear console button - dock it instead of absolute positioning
    local clearBtn = vgui.Create("lyx.TextButton2", headerPanel)
    clearBtn:SetText("Clear Console")
    clearBtn:Dock(RIGHT)
    clearBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(12), lyx.Scale(12))
    clearBtn:SetWide(lyx.Scale(120))
    clearBtn.DoClick = function()
        if self.ConsoleOutput then
            self.ConsoleOutput:SetText("")
        end
        notification.AddLegacy("Console cleared!", NOTIFY_GENERIC, 3)
    end
    
    -- Debug info panel
    local infoPanel = vgui.Create("DPanel", self)
    infoPanel:Dock(TOP)
    infoPanel:SetTall(lyx.Scale(100))
    infoPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    infoPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        -- Debug info
        draw.SimpleText("Lua Memory: " .. math.Round(collectgarbage("count") / 1024, 2) .. " MB", "LYX.Debug.Text", 
            lyx.Scale(10), lyx.Scale(10), lyx.Colors.SecondaryText)
        draw.SimpleText("Entities: " .. #ents.GetAll(), "LYX.Debug.Text", 
            lyx.Scale(10), lyx.Scale(30), lyx.Colors.SecondaryText)
        draw.SimpleText("Players: " .. #player.GetAll() .. "/" .. game.MaxPlayers(), "LYX.Debug.Text", 
            lyx.Scale(10), lyx.Scale(50), lyx.Colors.SecondaryText)
        draw.SimpleText("Hooks: " .. table.Count(hook.GetTable()), "LYX.Debug.Text", 
            lyx.Scale(10), lyx.Scale(70), lyx.Colors.SecondaryText)
        
        -- Performance stats
        draw.SimpleText("FPS: " .. math.Round(1 / RealFrameTime()), "LYX.Debug.Text", 
            lyx.Scale(250), lyx.Scale(10), lyx.Colors.PrimaryText)
        draw.SimpleText("Ping: " .. LocalPlayer():Ping() .. "ms", "LYX.Debug.Text", 
            lyx.Scale(250), lyx.Scale(30), lyx.Colors.SecondaryText)
        draw.SimpleText("Tickrate: " .. math.Round(1 / engine.TickInterval()), "LYX.Debug.Text", 
            lyx.Scale(250), lyx.Scale(50), lyx.Colors.SecondaryText)
    end
    
    -- Console output
    local consolePanel = vgui.Create("DPanel", self)
    consolePanel:Dock(FILL)
    consolePanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    consolePanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
    end
    
    self.ConsoleOutput = vgui.Create("RichText", consolePanel)
    self.ConsoleOutput:Dock(FILL)
    self.ConsoleOutput:DockMargin(lyx.Scale(5), lyx.Scale(5), lyx.Scale(5), lyx.Scale(45))
    self.ConsoleOutput:SetVerticalScrollbarEnabled(true)
    
    -- Command input
    local inputPanel = vgui.Create("DPanel", consolePanel)
    inputPanel:Dock(BOTTOM)
    inputPanel:SetTall(lyx.Scale(40))
    inputPanel:DockMargin(lyx.Scale(5), 0, lyx.Scale(5), lyx.Scale(5))
    inputPanel.Paint = function() end
    
    local cmdInput = vgui.Create("lyx.TextEntry2", inputPanel)
    cmdInput:Dock(FILL)
    cmdInput:DockMargin(0, lyx.Scale(5), lyx.Scale(100), lyx.Scale(5))
    cmdInput:SetPlaceholderText("Enter console command...")
    
    local execBtn = vgui.Create("lyx.TextButton2", inputPanel)
    execBtn:SetText("Execute")
    execBtn:Dock(RIGHT)
    execBtn:SetWide(lyx.Scale(90))
    execBtn:DockMargin(lyx.Scale(5), lyx.Scale(5), 0, lyx.Scale(5))
    execBtn.DoClick = function()
        local cmd = cmdInput:GetText()
        if cmd and cmd ~= "" then
            self.ConsoleOutput:InsertColorChange(100, 200, 255, 255)
            self.ConsoleOutput:AppendText("> " .. cmd .. "\n")
            
            -- Execute command
            RunConsoleCommand(cmd)
            
            cmdInput:SetText("")
        end
    end
    
    -- Add some initial debug info
    self.ConsoleOutput:InsertColorChange(200, 200, 200, 255)
    self.ConsoleOutput:AppendText("Debug console initialized\n")
    self.ConsoleOutput:AppendText("Lyx version: 2.0\n")
    self.ConsoleOutput:AppendText("Garry's Mod version: " .. VERSION .. "\n")
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Debug", PANEL)