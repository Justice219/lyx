lyx = lyx

local PANEL = {}

function PANEL:Init()
    self.Fraction = 0

    self.Grip = vgui.Create("lyx.ImgurButton2", self)
    self.Grip:NoClipping(true)

    self.Grip:SetImgurID("E8QbV5i")
    self.Grip:SetNormalColor(lyx.CopyColor(lyx.Colors.Primary))
    self.Grip:SetHoverColor(lyx.OffsetColor(lyx.Colors.Primary, -15))
    self.Grip:SetClickColor(lyx.OffsetColor(lyx.Colors.Primary, 15))

    self.Grip.OnCursorMoved = function(pnl, x, y)
        if not pnl.Depressed then return end

        x, y = pnl:LocalToScreen(x, y)
        x = self:ScreenToLocal(x, y)

        self.Fraction = math.Clamp(x / self:GetWide(), 0, 1)

        self:OnValueChanged(self.Fraction)
        self:InvalidateLayout()
    end

    self.BackgroundCol = lyx.OffsetColor(lyx.Colors.Background, 20)
    self.FillCol = lyx.OffsetColor(lyx.Colors.Background, 10)
end

function PANEL:OnMousePressed()
    local w = self:GetWide()

    self.Fraction = math.Clamp(self:CursorPos() / w, 0, 1)
    self:OnValueChanged(self.Fraction)
    self:InvalidateLayout()
end

function PANEL:OnValueChanged(fraction) end

function PANEL:Paint(w, h)
    local rounding = h * .5
    lyx.DrawRoundedBox(rounding, 0, 0, w, h, self.BackgroundCol)
    lyx.DrawRoundedBox(rounding, 0, 0, self.Fraction * w, h, self.FillCol)
end

function PANEL:PerformLayout(w, h)
    local gripSize = h + lyx.Scale(6)
    local offset = lyx.Scale(3)
    self.Grip:SetSize(gripSize, gripSize)
    self.Grip:SetPos((self.Fraction * w) - (gripSize * .5), -offset)
end

vgui.Register("lyx.Slider2", PANEL, "lyx.Button2")