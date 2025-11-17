lyx = lyx

local PANEL = {}

AccessorFunc(PANEL, "Text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "TextAlign", "TextAlign", FORCE_NUMBER)
AccessorFunc(PANEL, "TextSpacing", "TextSpacing", FORCE_NUMBER)
AccessorFunc(PANEL, "Font", "Font", FORCE_STRING)

lyx.RegisterFont("UI.TextButton", "Open Sans SemiBold", 20)

function PANEL:Init()
    self:SetText("Button")
    self:SetTextAlign(TEXT_ALIGN_CENTER)
    self:SetTextSpacing(lyx.Scale(6))
    self:SetFont("UI.TextButton")

    self:SetSize(lyx.Scale(100), lyx.Scale(30))
end

function PANEL:SizeToText()
    lyx.SetFont(self:GetFont())
    self:SetSize(lyx.GetTextSize(self:GetText()) + lyx.Scale(14), lyx.Scale(30))
end

function PANEL:SetIcon(iconPath)
    if not iconPath or iconPath == "" then
        self.IconMaterial = nil
        return
    end
    self.IconMaterial = Material(iconPath, "smooth")
end

function PANEL:PaintExtra(w, h)
    local textAlign = self:GetTextAlign()
    local spacing = self:GetTextSpacing()
    local textX = (textAlign == TEXT_ALIGN_CENTER and w * 0.5) or (textAlign == TEXT_ALIGN_RIGHT and w - spacing) or spacing

    if self.IconMaterial then
        local iconSize = math.min(h - spacing * 2, lyx.Scale(24))
        local iconX = spacing
        local iconY = (h - iconSize) * 0.5
        surface.SetMaterial(self.IconMaterial)
        surface.SetDrawColor(255, 255, 255, self:IsEnabled() and 255 or 140)
        surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
        textX = iconX + iconSize + spacing
        textAlign = TEXT_ALIGN_LEFT
    end

    if not self:IsEnabled() then
        lyx.DrawSimpleText(self:GetText(), self:GetFont(), textX, h * 0.5, lyx.Colors.DisabledText, textAlign, TEXT_ALIGN_CENTER)
        return
    end

    lyx.DrawSimpleText(self:GetText(), self:GetFont(), textX, h * 0.5, lyx.Colors.PrimaryText, textAlign, TEXT_ALIGN_CENTER)
end

vgui.Register("lyx.TextButton2", PANEL, "lyx.Button2")
