--[[
	LYXUI Message Popup
	Ported from PIXEL UI. Simple message dialog with a single button.
]]

local PANEL = {}

AccessorFunc(PANEL, "Text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "ButtonText", "ButtonText", FORCE_STRING)

lyx.RegisterFont("LYXUI.Message", "Open Sans SemiBold", 18)

function PANEL:Init()
    self:SetDraggable(true)
    self:SetSizable(true)

    self:SetMinWidth(lyx.Scale(240))
    self:SetMinHeight(lyx.Scale(80))

    self.Message = vgui.Create("LYXUI.Label", self)
    self.Message:SetTextAlign(TEXT_ALIGN_CENTER)
    self.Message:SetFont("LYXUI.Message")

    self.ButtonHolder = vgui.Create("Panel", self)

    self.Button = vgui.Create("LYXUI.TextButton", self.ButtonHolder)
    self.Button.DoClick = function(s, w, h)
        self:Close(true)
    end
end

function PANEL:LayoutContent(w, h)
    self.Message:SetSize(self.Message:CalculateSize())
    self.Message:Dock(TOP)
    self.Message:DockMargin(0, 0, 0, lyx.Scale(8))

    self.Button:SizeToText()
    self.ButtonHolder:Dock(TOP)
    self.ButtonHolder:SetTall(self.Button:GetTall())
    self.Button:CenterHorizontal()

    if self.ButtonHolder:GetWide() < self.Button:GetWide() then
        self.ButtonHolder:SetWide(self.Button:GetWide())
    end

    if self:GetWide() < lyx.Scale(240) then
        self:SetWide(lyx.Scale(240))
        self:Center()
    end

    if self.HasSized and self.HasSized > 1 then return end
    self.HasSized = (self.HasSized or 0) + 1

    self:SizeToChildren(true, true)
    self:Center()
end

function PANEL:SetText(text) self.Message:SetText(text) end
function PANEL:GetText(text) return self.Message:GetText() end

function PANEL:SetButtonText(text) self.Button:SetText(text) end
function PANEL:GetButtonText(text) return self.Button:GetText() end

vgui.Register("LYXUI.Message", PANEL, "LYXUI.Frame")

LYXUI.UI.Overrides.Derma_Message = LYXUI.UI.Overrides.Derma_Message or Derma_Message

Derma_Message = LYXUI.UI.CreateToggleableOverride(LYXUI.UI.Overrides.Derma_Message, function(text, title, buttonText)
    buttonText = buttonText or "OK"

    local msg = vgui.Create("LYXUI.Message")
    msg:SetTitle(title)
    msg:SetText(text)
    msg:SetButtonText(buttonText)

    msg:MakePopup()
    msg:DoModal()

    return msg
end, LYXUI.UI.ShouldOverrideDermaPopups)
