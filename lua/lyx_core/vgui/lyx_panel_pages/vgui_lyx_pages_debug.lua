local PANEL = {}

lyx.RegisterFont("LYX.Debug.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Debug.Text", "Courier New", lyx.Scale(14))

function PANEL:Init()
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 40, 200))
        draw.SimpleText("Debug Tools", "LYX.Debug.Header", lyx.Scale(15), lyx.Scale(20), Color(255, 255, 255))
    end
    
    -- Clear console button
    local clearBtn = vgui.Create("lyx.TextButton2", headerPanel)
    clearBtn:SetText("Clear Console")
    clearBtn:SetSize(lyx.Scale(120), lyx.Scale(35))
    clearBtn:SetPos(headerPanel:GetWide() - lyx.Scale(140), lyx.Scale(12))
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
        draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 50, 200))
        
        -- Debug info
        draw.SimpleText("Lua Memory: " .. math.Round(collectgarbage("count") / 1024, 2) .. " MB", "LYX.Debug.Text", 
            lyx.Scale(10), lyx.Scale(10), Color(200, 200, 200))
        draw.SimpleText("Entities: " .. #ents.GetAll(), "LYX.Debug.Text", 
            lyx.Scale(10), lyx.Scale(30), Color(200, 200, 200))
        draw.SimpleText("Players: " .. #player.GetAll() .. "/" .. game.MaxPlayers(), "LYX.Debug.Text", 
            lyx.Scale(10), lyx.Scale(50), Color(200, 200, 200))
        draw.SimpleText("Hooks: " .. table.Count(hook.GetTable()), "LYX.Debug.Text", 
            lyx.Scale(10), lyx.Scale(70), Color(200, 200, 200))
        
        -- Performance stats
        draw.SimpleText("FPS: " .. math.Round(1 / RealFrameTime()), "LYX.Debug.Text", 
            lyx.Scale(250), lyx.Scale(10), Color(200, 200, 200))
        draw.SimpleText("Ping: " .. LocalPlayer():Ping() .. "ms", "LYX.Debug.Text", 
            lyx.Scale(250), lyx.Scale(30), Color(200, 200, 200))
        draw.SimpleText("Tickrate: " .. math.Round(1 / engine.TickInterval()), "LYX.Debug.Text", 
            lyx.Scale(250), lyx.Scale(50), Color(200, 200, 200))
    end
    
    -- Console output
    local consolePanel = vgui.Create("DPanel", self)
    consolePanel:Dock(FILL)
    consolePanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    consolePanel.Paint = function(pnl, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 30, 240))
    end
    
    self.ConsoleOutput = vgui.Create("RichText", consolePanel)
    self.ConsoleOutput:Dock(FILL)
    self.ConsoleOutput:DockMargin(lyx.Scale(5), lyx.Scale(5), lyx.Scale(5), lyx.Scale(5))
    self.ConsoleOutput:SetVerticalScrollbarEnabled(true)
    
    -- Command input
    local inputPanel = vgui.Create("DPanel", consolePanel)
    inputPanel:Dock(BOTTOM)
    inputPanel:SetTall(lyx.Scale(40))
    inputPanel.Paint = function() end
    
    local cmdInput = vgui.Create("lyx.TextEntry2", inputPanel)
    cmdInput:Dock(FILL)
    cmdInput:DockMargin(lyx.Scale(5), lyx.Scale(5), lyx.Scale(100), lyx.Scale(5))
    cmdInput:SetPlaceholderText("Enter console command...")
    
    local execBtn = vgui.Create("lyx.TextButton2", inputPanel)
    execBtn:SetText("Execute")
    execBtn:Dock(RIGHT)
    execBtn:SetWide(lyx.Scale(90))
    execBtn:DockMargin(0, lyx.Scale(5), lyx.Scale(5), lyx.Scale(5))
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
    draw.RoundedBox(8, 0, 0, w, h, lyx.Colors.Background or Color(20, 20, 30))
end

vgui.Register("LYX.Pages.Debug", PANEL)