--[[
	LYXUI Checkbox Element
	Ported from PIXEL UI. Toggle checkbox with checkmark icon.
]]

local PANEL = {}

function PANEL:Init()
    self:SetIsToggle(true)

    local boxSize = lyx.Scale(20)
    self:SetSize(boxSize, boxSize)

    self:SetImageURL("https://pixel-cdn.lythium.dev/i/7u6uph3x6g")

    self:SetNormalColor(LYXUI.Colors.Transparent)
    self:SetHoverColor(LYXUI.Colors.PrimaryText)
    self:SetClickColor(LYXUI.Colors.PrimaryText)
    self:SetDisabledColor(LYXUI.Colors.Transparent)

    self:SetImageSize(.8)

    self.BackgroundCol = lyx.CopyColor(LYXUI.Colors.Primary)
end

function PANEL:PaintBackground(w, h)
    if not self:IsEnabled() then
        LYXUI.DrawRoundedBox(lyx.Scale(4), 0, 0, w, h, LYXUI.Colors.Disabled)
        self:PaintExtra(w, h)
        return
    end

    local bgCol = LYXUI.Colors.Primary

    if self:IsDown() or self:GetToggle() then
        bgCol = LYXUI.Colors.Positive
    end

    local animTime = FrameTime() * 12
    self.BackgroundCol = lyx.LerpColor(animTime, self.BackgroundCol, bgCol)

    LYXUI.DrawRoundedBox(lyx.Scale(4), 0, 0, w, h, self.BackgroundCol)
end

vgui.Register("LYXUI.Checkbox", PANEL, "LYXUI.ImageButton")
