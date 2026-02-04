local PANEL = {}

function PANEL:Init()

end

function PANEL:Paint()
    self:SetTextColor(Color(255,255,255))
    self:TDLib()
    self:ClearPaint()
        :Background(lyx.Colors1.Primary, 6)
        :BarHover(lyx.Colors1.White, 3)
        :CircleClick(lyx.Colors1.White, 3, 200)
end

function PANEL:Inverse()
    self:SetTextColor(Color(255,255,255))
    self:TDLib()
    self:ClearPaint()
        :Background(lyx.Colors1.Secondary, 6)
        :BarHover(lyx.Colors1.White, 3)
        :CircleClick(lyx.Colors1.White, 3, 200)
end

vgui.Register("lyx_button", PANEL, "DButton")