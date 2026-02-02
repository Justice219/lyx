lyx = lyx

local PANEL = {}

AccessorFunc(PANEL, "Name", "Name", FORCE_STRING)
AccessorFunc(PANEL, "Color", "Color")

lyx.RegisterFont("UI.NavbarItem", "Open Sans SemiBold", 22)

function PANEL:Init()
    self:SetName("N/A")
    self:SetColor(lyx.Colors.Primary)

    self.NormalCol = lyx.Colors.PrimaryText
    self.HoverCol = lyx.Colors.SecondaryText

    self.TextCol = lyx.CopyColor(self.NormalCol)
end

function PANEL:GetItemSize()
    lyx.SetFont("UI.NavbarItem")
    return lyx.GetTextSize(self:GetName())
end

function PANEL:Paint(w, h)
    local textCol = self.NormalCol

    if self:IsHovered() then
        textCol = self.HoverCol
    end

    local animTime = FrameTime() * 12
    self.TextCol = lyx.LerpColor(animTime, self.TextCol, textCol)

    lyx.DrawSimpleText(self:GetName(), "UI.NavbarItem", w * 0.5, h * 0.5, self.TextCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

vgui.Register("lyx.NavbarItem2", PANEL, "lyx.Button2")

PANEL = {}

function PANEL:Init()
    self.Items = {}

    self.SelectionX = 0
    self.SelectionW = 0
    self.SelectionColor = Color(0, 0, 0)

    self.BackgroundCol = lyx.OffsetColor(lyx.Colors.Background, 10)
end

function PANEL:AddItem(id, name, doClick, order, color)
    local btn = vgui.Create("lyx.NavbarItem2", self)

    btn:SetName(name:upper())
    btn:SetZPos(order or table.Count(self.Items) + 1)
    btn:SetColor((IsColor(color) and color) or lyx.Colors.Primary)
    btn.Function = doClick

    btn.DoClick = function(s)
        self:SelectItem(id)
    end

    self.Items[id] = btn
end

function PANEL:RemoveItem(id)
    local item = self.Items[id]
    if not item then return end

    item:Remove()
    self.Items[id] = nil

    if self.SelectedItem != id then return end
    self:SelectItem(next(self.Items))
end

function PANEL:SelectItem(id)
    local item = self.Items[id]
    if not item then return end

    if self.SelectedItem and self.SelectedItem == id then return end
    self.SelectedItem = id

    for k,v in pairs(self.Items) do
        v:SetToggle(false)
    end

    item:SetToggle(true)
    item.Function(item)
end

function PANEL:PerformLayout(w, h)
    for k,v in pairs(self.Items) do
        v:Dock(LEFT)
        v:SetWide(v:GetItemSize() + lyx.Scale(30))
    end
end

function PANEL:PaintExtra(w, h)

end

function PANEL:Paint(w, h)
    if not self.SelectedItem then
        self.SelectionX = Lerp(FrameTime() * 10, self.SelectionX, 0)
        self.SelectionW = Lerp(FrameTime() * 10, self.SelectionX, 0)
        self.SelectionColor = lyx.LerpColor(FrameTime() * 10, self.SelectionColor, lyx.Colors.Primary)
        return
    end

    local selectedItem = self.Items[self.SelectedItem]
    self.SelectionX = Lerp(FrameTime() * 10, self.SelectionX, selectedItem.x)
    self.SelectionW = Lerp(FrameTime() * 10, self.SelectionW, selectedItem:GetWide())
    self.SelectionColor = lyx.LerpColor(FrameTime() * 10, self.SelectionColor, selectedItem:GetColor())

    local selectorH = lyx.Scale(6)
    surface.SetDrawColor(self.SelectionColor)
    surface.DrawRect(self.SelectionX + 2, h - selectorH + 3, self.SelectionW - 4, selectorH * 0.5)

    self:PaintExtra(w, h)
end

vgui.Register("lyx.Navbar2", PANEL, "Panel")