local PANEL = {}

lyx.RegisterFont("LYX.Commands.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Commands.Text", "Open Sans", lyx.Scale(14))

function PANEL:Init()
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Command Center", "LYX.Commands.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
    end
    
    -- Commands list
    self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
    self.ScrollPanel:Dock(FILL)
    self.ScrollPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    
    -- Show available commands
    local commands = {
        {"!kick", "Kick a player from the server"},
        {"!ban", "Ban a player from the server"},
        {"!mute", "Mute a player's voice chat"},
        {"!freeze", "Freeze a player in place"},
        {"!bring", "Bring a player to you"},
        {"!goto", "Go to a player"},
        {"!slay", "Kill a player"},
        {"!god", "Enable god mode for a player"}
    }
    
    for _, cmd in ipairs(commands) do
        local cmdPanel = vgui.Create("DPanel", self.ScrollPanel)
        cmdPanel:Dock(TOP)
        cmdPanel:SetTall(lyx.Scale(50))
        cmdPanel:DockMargin(0, lyx.Scale(5), lyx.Scale(10), 0)
        cmdPanel.Paint = function(pnl, w, h)
            draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
            draw.SimpleText(cmd[1], "LYX.Commands.Text", lyx.Scale(10), lyx.Scale(10), lyx.Colors.PrimaryText)
            draw.SimpleText(cmd[2], "LYX.Commands.Text", lyx.Scale(10), lyx.Scale(28), lyx.Colors.SecondaryText)
        end
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Commands", PANEL)