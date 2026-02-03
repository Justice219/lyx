--[[
	LYXUI Query Popup
	Ported from PIXEL UI. Multi-button query dialog.
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

    self.BottomPanel = vgui.Create("Panel", self)
    self.ButtonHolder = vgui.Create("Panel", self.BottomPanel)

    self.Buttons = {}
end

function PANEL:AddOption(name, callback)
    callback = callback or function() end

    local btn = vgui.Create("LYXUI.TextButton", self.ButtonHolder)
    btn:SetText(name)
    btn.DoClick = function()
        self:Close(true)
        callback()
    end
    table.insert(self.Buttons, btn)
end

function PANEL:LayoutContent(w, h)
    self.Message:SetSize(self.Message:CalculateSize())
    self.Message:Dock(TOP)
    self.Message:DockMargin(0, 0, 0, lyx.Scale(8))

    for k,v in ipairs(self.Buttons) do
        v:SizeToText()
        v:Dock(LEFT)
        v:DockMargin(lyx.Scale(4), 0, lyx.Scale(4), 0)
    end

    self.ButtonHolder:SizeToChildren(true)

    local firstBtn = self.Buttons[1]

    self.BottomPanel:Dock(TOP)
    self.BottomPanel:SetTall(firstBtn:GetTall())
    self.ButtonHolder:SetTall(firstBtn:GetTall())

    self.ButtonHolder:CenterHorizontal()

    if self.ButtonHolder:GetWide() < firstBtn:GetWide() then
        self.ButtonHolder:SetWide(firstBtn:GetWide())
    end

    if self.BottomPanel:GetWide() < self.ButtonHolder:GetWide() then
        self.BottomPanel:SetWide(self.ButtonHolder:GetWide())
    end

    if self:GetWide() < lyx.Scale(240) then
        self:SetWide(240)
        self:Center()
    end

    if self.HasSized and self.HasSized > 1 then return end
    self.HasSized = (self.HasSized or 0) + 1

    self:SizeToChildren(true, true)
    self:Center()
end

function PANEL:SetText(text) self.Message:SetText(text) end
function PANEL:GetText(text) return self.Message:GetText() end

vgui.Register("LYXUI.Query", PANEL, "LYXUI.Frame")

LYXUI.UI.Overrides.Derma_Query = LYXUI.UI.Overrides.Derma_Query or Derma_Query

Derma_Query = LYXUI.UI.CreateToggleableOverride(LYXUI.UI.Overrides.Derma_Query, function(text, title, ...)
    local msg = vgui.Create("LYXUI.Query")
    msg:SetTitle(title)
    msg:SetText(text)

    local args = {...}
    for i = 1, #args, 2 do
        msg:AddOption(args[i], args[i + 1])
    end

    msg:MakePopup()
    msg:DoModal()

    return msg
end, LYXUI.UI.ShouldOverrideDermaPopups)
