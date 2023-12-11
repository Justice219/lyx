lyx = lyx

local PANEL = {}

function PANEL:Init()
    self:SetIsToggle(true)

    local boxSize = lyx.Scale(20)
    self:SetSize(boxSize, boxSize)

    self:SetImgurID("YvG7VI6")

    self:SetNormalColor(lyx.Colors.Transparent)
    self:SetHoverColor(lyx.Colors.PrimaryText)
    self:SetClickColor(lyx.Colors.PrimaryText)
    self:SetDisabledColor(lyx.Colors.Transparent)
    self:AddToggleSound()

    self:SetImageSize(.8)

    self.BackgroundCol = lyx.CopyColor(lyx.Colors.Primary)
end

function PANEL:PaintBackground(w, h)
    if not self:IsEnabled() then
        lyx.DrawRoundedBox(lyx.Scale(4), 0, 0, w, h, lyx.Colors.Disabled)
        self:PaintExtra(w, h)
        return
    end

    local bgCol = lyx.Colors.Primary

    if self:IsDown() or self:GetToggle() then
        bgCol = lyx.Colors.Positive
    end

    local animTime = FrameTime() * 12
    self.BackgroundCol = lyx.LerpColor(animTime, self.BackgroundCol, bgCol)

    lyx.DrawRoundedBox(lyx.Scale(4), 0, 0, w, h, self.BackgroundCol)
end

vgui.Register("lyx.Checkbox2", PANEL, "lyx.ImgurButton2")