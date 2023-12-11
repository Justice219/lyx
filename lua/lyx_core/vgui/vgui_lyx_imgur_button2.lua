lyx = lyx

local PANEL = {}

AccessorFunc(PANEL, "ImgurID", "ImgurID", FORCE_STRING)
AccessorFunc(PANEL, "ImageSize", "ImageSize", FORCE_NUMBER)
AccessorFunc(PANEL, "NormalColor", "NormalColor")
AccessorFunc(PANEL, "HoverColor", "HoverColor")
AccessorFunc(PANEL, "ClickColor", "ClickColor")
AccessorFunc(PANEL, "DisabledColor", "DisabledColor")

function PANEL:Init()
    self.ImageCol = lyx.CopyColor(color_white)
    self:SetImgurID("635PPvg")

    self:SetNormalColor(color_white)
    self:SetHoverColor(color_white)
    self:SetClickColor(color_white)
    self:SetDisabledColor(color_white)

    self:SetImageSize(1)
end

function PANEL:PaintBackground(w, h) end

function PANEL:Paint(w, h)
    self:PaintBackground(w, h)

    local imageSize = h * self:GetImageSize()
    local imageOffset = (h - imageSize) * 0.5

    if not self:IsEnabled() then
        lyx.DrawImgur(imageOffset, imageOffset, imageSize, imageSize, self:GetImgurID(), self:GetDisabledColor())
        return
    end

    local col = self:GetNormalColor()

    if self:IsHovered() then
        col = self:GetHoverColor()
    end

    if self:IsDown() or self:GetToggle() then
        col = self:GetClickColor()
    end

    self.ImageCol = lyx.LerpColor(FrameTime() * 12, self.ImageCol, col)

    lyx.DrawImgur(imageOffset, imageOffset, imageSize, imageSize, self:GetImgurID(), self.ImageCol)
end

vgui.Register("lyx.ImgurButton2", PANEL, "lyx.Button2")