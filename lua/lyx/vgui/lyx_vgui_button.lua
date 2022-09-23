local PANEL = {}

function PANEL:Init()

end

function PANEL:Paint()
    self:SetTextColor(Color(255,255,255))
    self:TDLib()
    self:ClearPaint()
        :Background(lyx.Colors.Primary, 6)
        :BarHover(lyx.Colors.White, 3)
        :CircleClick(lyx.Colors.White, 3, 200)
end

function PANEL:Inverse()
    self:SetTextColor(Color(255,255,255))
    self:TDLib()
    self:ClearPaint()
        :Background(lyx.Colors.Secondary, 6)
        :BarHover(lyx.Colors.White, 3)
        :CircleClick(lyx.Colors.White, 3, 200)
end

vgui.Register("lyx_button", PANEL, "DButton")