--[[
	LYXUI Text Button Element
	Ported from PIXEL UI. Button with centered text label.
]]

local PANEL = {}

AccessorFunc(PANEL, "Text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "TextAlign", "TextAlign", FORCE_NUMBER)
AccessorFunc(PANEL, "TextSpacing", "TextSpacing", FORCE_NUMBER)
AccessorFunc(PANEL, "Font", "Font", FORCE_STRING)

lyx.RegisterFont("LYXUI.TextButton", "Open Sans SemiBold", 20)

function PANEL:Init()
    self:SetText("Button")
    self:SetTextAlign(TEXT_ALIGN_CENTER)
    self:SetTextSpacing(lyx.Scale(6))
    self:SetFont("LYXUI.TextButton")

    self:SetSize(lyx.Scale(100), lyx.Scale(30))
end

function PANEL:SizeToText()
    lyx.SetFont(self:GetFont())
    self:SetSize(lyx.GetTextSize(self:GetText()) + lyx.Scale(14), lyx.Scale(30))
end

function PANEL:PaintExtra(w, h)
    local textAlign = self:GetTextAlign()
    local textX = (textAlign == TEXT_ALIGN_CENTER and w / 2) or (textAlign == TEXT_ALIGN_RIGHT and w - self:GetTextSpacing()) or self:GetTextSpacing()

    if not self:IsEnabled() then
        lyx.DrawSimpleText(self:GetText(), self:GetFont(), textX, h / 2, LYXUI.Colors.DisabledText, textAlign, TEXT_ALIGN_CENTER)
        return
    end

    lyx.DrawSimpleText(self:GetText(), self:GetFont(), textX, h / 2, LYXUI.Colors.PrimaryText, textAlign, TEXT_ALIGN_CENTER)
end

vgui.Register("LYXUI.TextButton", PANEL, "LYXUI.Button")
