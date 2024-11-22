local PANEL = {}

function PANEL:Init()
    self.ScrollPanel = vgui.Create("DScrollPanel", self)
    self.ScrollPanel:Dock(FILL)
    self.ScrollPanel:DockMargin(lyx.ScaleW(10), lyx.Scale(10), lyx.ScaleW(10), lyx.Scale(10))

    self.DashboardText = vgui.Create("RichText", self)
    self.DashboardText:Dock(TOP)
    self.DashboardText:DockMargin(lyx.ScaleW(10), lyx.Scale(0), lyx.ScaleW(10), lyx.Scale(0))
    self.DashboardText:SetTall(lyx.Scale(200))
    function self.DashboardText:PerformLayout()
        self:SetFontInternal("Roboto Black")
    end
    self.DashboardText:InsertColorChange(186, 32, 55, 255)
    self.DashboardText:AppendText("Welcome to Lyx: Revamped!\n")
    self.DashboardText:InsertColorChange(255, 255, 255, 255)
    -- lyx is a lua library for gmod, it's pretty cool
    self.DashboardText:AppendText("lyx is a lua library for gmod, it's pretty cool\n")
    
end

function PANEL:SetPlayer(ply)
   
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
end


vgui.Register("LYX.Pages.Dashboard", PANEL)
