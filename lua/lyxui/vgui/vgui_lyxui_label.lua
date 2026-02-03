--[[
	LYXUI Label Element
	Ported from PIXEL UI. Text label with alignment, auto-sizing, wrapping, and ellipsis.
]]

local PANEL = {}

AccessorFunc(PANEL, "Text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "Font", "Font", FORCE_STRING)
AccessorFunc(PANEL, "TextAlign", "TextAlign", FORCE_NUMBER)
AccessorFunc(PANEL, "TextColor", "TextColor")
AccessorFunc(PANEL, "Ellipses", "Ellipses", FORCE_BOOL)
AccessorFunc(PANEL, "AutoHeight", "AutoHeight", FORCE_BOOL)
AccessorFunc(PANEL, "AutoWidth", "AutoWidth", FORCE_BOOL)
AccessorFunc(PANEL, "AutoWrap", "AutoWrap", FORCE_BOOL)

lyx.RegisterFont("LYXUI.Label", "Open Sans SemiBold", 14)

function PANEL:Init()
    self:SetText("Label")
    self:SetFont("LYXUI.Label")
    self:SetTextAlign(TEXT_ALIGN_LEFT)
    self:SetTextColor(LYXUI.Colors.SecondaryText)
end

function PANEL:SetText(text)
    self.Text = text
    self.OriginalText = text
end

function PANEL:CalculateSize()
    lyx.SetFont(self:GetFont())
    return lyx.GetTextSize(self:GetText())
end

function PANEL:PerformLayout(w, h)
    local desiredW, desiredH = self:CalculateSize()

    if self:GetAutoWidth() then
        self:SetWide(desiredW)
    end

    if self:GetAutoHeight() then
        self:SetTall(desiredH)
    end

    if self:GetAutoWrap() then
        self.Text = lyx.WrapText(self.OriginalText, w, self:GetFont())
    end
end

function PANEL:Paint(w, h)
    local align = self:GetTextAlign()
    local text = self:GetEllipses() and lyx.EllipsesText(self:GetText(), w, self:GetFont()) or self:GetText()

    if align == TEXT_ALIGN_CENTER then
        lyx.DrawText(text, self:GetFont(), w / 2, 0, self:GetTextColor(), TEXT_ALIGN_CENTER)
        return
    elseif align == TEXT_ALIGN_RIGHT then
        lyx.DrawText(text, self:GetFont(), w, 0, self:GetTextColor(), TEXT_ALIGN_RIGHT)
        return
    end

    lyx.DrawText(text, self:GetFont(), 0, 0, self:GetTextColor())
end

vgui.Register("LYXUI.Label", PANEL, "Panel")
