lyx = lyx

local PANEL = {}

function PANEL:Init()
    self.TextEntry = vgui.Create("lyx.TextEntryInternal2", self)
    self.TextEntry:DockMargin(lyx.Scale(4), 0, 0, 0)

    self.PlaceholderTextCol = lyx.OffsetColor(lyx.Colors.SecondaryText, -110)

    self.DisabledCol = lyx.OffsetColor(lyx.Colors.Background, 6)
    self.FocusedOutlineCol = lyx.Colors.PrimaryText

    self.OutlineCol = lyx.OffsetColor(lyx.Colors.Scroller, -10)
    self.InnerOutlineCol = lyx.CopyColor(lyx.Colors.Transparent)
end

function PANEL:PerformLayout(w, h)
    self.TextEntry:Dock(FILL)

    local xPad, yPad = lyx.Scale(4), lyx.Scale(8)
    self:DockPadding(xPad, yPad, xPad, yPad)
end

function PANEL:Paint(w, h)
    if not self:IsEnabled() then
        lyx.DrawRoundedBox(lyx.Scale(4), 0, 0, w, h, self.DisabledCol)
        lyx.DrawSimpleText("Disabled", "UI.TextEntry", lyx.Scale(4), h * 0.5, lyx.Colors.SecondaryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        return
    end

    if self:GetValue() == "" then
        lyx.DrawSimpleText(self:GetPlaceholderText() or "", "UI.TextEntry", lyx.Scale(15), h * 0.5, self.PlaceholderTextCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local outlineThickness = lyx.Scale(1)
    lyx.DrawOutlinedRoundedBox(lyx.Scale(2), 0, 0, w, h, self.OutlineCol, outlineThickness)

    local col = lyx.Colors.Transparent

    if self:IsEditing() then
        col = self.FocusedOutlineCol
    end

    if self.OverrideCol then
        col = self.OverrideCol
    end

    self.InnerOutlineCol = lyx.LerpColor(FrameTime() * 8, self.InnerOutlineCol, col)

    lyx.DrawOutlinedRoundedBox(lyx.Scale(2), outlineThickness, outlineThickness, w - outlineThickness * 2, h - outlineThickness * 2, self.InnerOutlineCol, lyx.Scale(1))
end

function PANEL:OnChange() end
function PANEL:OnValueChange(value) end

function PANEL:IsEnabled() return self.TextEntry:IsEnabled() end
function PANEL:SetEnabled(enabled) self.TextEntry:SetEnabled(enabled) end

function PANEL:GetValue() return self.TextEntry:GetValue() end
function PANEL:SetValue(value) self.TextEntry:SetValue(value) end

function PANEL:IsMultiline() return self.TextEntry:IsMultiline() end
function PANEL:SetMultiline(isMultiline) self.TextEntry:SetMultiline(isMultiline) end

function PANEL:IsEditing() return self.TextEntry:IsEditing() end

function PANEL:GetEnterAllowed() return self.TextEntry:GetEnterAllowed() end
function PANEL:SetEnterAllowed(allow) self.TextEntry:SetEnterAllowed(allow) end

function PANEL:GetUpdateOnType() return self.TextEntry:GetUpdateOnType() end
function PANEL:SetUpdateOnType(enabled) self.TextEntry:SetUpdateOnType(enabled) end

function PANEL:GetNumeric() return self.TextEntry:GetNumeric() end
function PANEL:SetNumeric(enabled) self.TextEntry:SetNumeric(enabled) end

function PANEL:GetHistoryEnabled() return self.TextEntry:GetHistoryEnabled() end
function PANEL:SetHistoryEnabled(enabled) self.TextEntry:SetHistoryEnabled(enabled) end

function PANEL:GetTabbingDisabled() return self.TextEntry:GetTabbingDisabled() end
function PANEL:SetTabbingDisabled(disabled) self.TextEntry:SetTabbingDisabled(disabled) end

function PANEL:GetPlaceholderText() return self.TextEntry:GetPlaceholderText() end
function PANEL:SetPlaceholderText(text) self.TextEntry:SetPlaceholderText(text) end

function PANEL:GetInt() return self.TextEntry:GetInt() end
function PANEL:GetFloat() return self.TextEntry:GetFloat() end

function PANEL:IsEditing() return self.TextEntry:IsEditing() end
function PANEL:SetEditable(enabled) self.TextEntry:SetEditable(enabled) end

function PANEL:AllowInput(value) end
function PANEL:GetAutoComplete(txt) end

function PANEL:OnKeyCode(code) end
function PANEL:OnEnter() end

function PANEL:OnGetFocus() end
function PANEL:OnLoseFocus() end

vgui.Register("lyx.TextEntry2", PANEL, "Panel")