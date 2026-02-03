--[[
	LYXUI Validated Text Entry Element
	Ported from PIXEL UI. Text entry with real-time validation feedback.
]]

local PANEL = {}

function PANEL:Init()
    self.TextEntry = vgui.Create("LYXUI.TextEntry", self)
    self.Message = vgui.Create("LYXUI.Label", self)
    self.Message:SetText("")

    self.TextEntry.OnChange = function(s)
        local text = s:GetValue()
        if text == "" then
            self.Message:SetText("")
            s.OverrideCol = nil
            return
        end

        local valid, message = self:IsTextValid(text)

        self:OnValidate(valid, message)

        if valid then
            self.Message:SetText(message or "")
            self.Message:SetTextColor(LYXUI.Colors.Positive)

            s.OverrideCol = LYXUI.Colors.Positive
        else
            self.Message:SetText(message or "")
            self.Message:SetTextColor(LYXUI.Colors.Negative)

            s.OverrideCol = LYXUI.Colors.Negative
        end
    end
end

function PANEL:IsTextValid(text)
    if text == "test" then
        return true
    end

    return false, "This is invalid text lol"
end

function PANEL:OnValidate(valid, message) end

function PANEL:PerformLayout(w, h)
    self.TextEntry:SetTall(lyx.Scale(34))
    self.TextEntry:Dock(TOP)

    self.Message:Dock(TOP)
    self.Message:DockMargin(lyx.Scale(4), lyx.Scale(5), 0, 0)

    self:SizeToChildren(false, true)
end

function PANEL:SetValue(text) self.TextEntry:SetValue(text) end
function PANEL:GetValue() return self.TextEntry:GetValue() end

function PANEL:SetPlaceholderText(text) self.TextEntry:SetPlaceholderText(text) end
function PANEL:GetPlaceholderText() return self.TextEntry:GetPlaceholderText() end

vgui.Register("LYXUI.ValidatedTextEntry", PANEL, "Panel")
