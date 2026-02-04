lyx = lyx

local PANEL = {}

AccessorFunc(PANEL, "Name", "Name", FORCE_STRING)
AccessorFunc(PANEL, "ImgurID", "ImgurID", FORCE_STRING)
AccessorFunc(PANEL, "DrawOutline", "DrawOutline", FORCE_BOOL)

lyx.RegisterFont("SidebarItem", "Open Sans Bold", 19)

function PANEL:Init()
    self:SetName("N/A")
    self:SetDrawOutline(true)

    self.TextCol = lyx.CopyColor(lyx.Colors.SecondaryText)
    self.BackgroundCol = lyx.CopyColor(lyx.Colors.Transparent)
    self.BackgroundHoverCol = ColorAlpha(lyx.Colors.Scroller, 80)
end

function PANEL:Paint(w, h)
    local textCol = lyx.Colors.SecondaryText
    local backgroundCol = lyx.Colors.Transparent

    if self:IsHovered() then
        textCol = lyx.Colors.PrimaryText
        backgroundCol = self.BackgroundHoverCol
    end

    if self:IsDown() or self:GetToggle() then
        textCol = lyx.Colors.PrimaryText
        backgroundCol = self.BackgroundHoverCol
    end

    local animTime = FrameTime() * 12
    self.TextCol = lyx.LerpColor(animTime, self.TextCol, textCol)
    self.BackgroundCol = lyx.LerpColor(animTime, self.BackgroundCol, backgroundCol)

    if self:GetDrawOutline() then lyx.DrawRoundedBox(lyx.Scale(4), 0, 0, w, h, self.BackgroundCol, lyx.Scale(1)) end

    local imgurID = self:GetImgurID()
    if imgurID then
        local iconSize = h * .65
        lyx.DrawImgur(lyx.Scale(10), (h - iconSize) * 0.5, iconSize, iconSize, imgurID, self.TextCol)
        lyx.DrawSimpleText(self:GetName(), "SidebarItem", lyx.Scale(20) + iconSize, h * 0.5, self.TextCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        return
    end

    lyx.DrawSimpleText(self:GetName(), "SidebarItem", lyx.Scale(10), h * 0.5, self.TextCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("lyx.SidebarItem2", PANEL, "lyx.Button2")

PANEL = {}

AccessorFunc(PANEL, "ImgurID", "ImgurID", FORCE_STRING)
AccessorFunc(PANEL, "ImgurScale", "ImgurScale", FORCE_NUMBER)
AccessorFunc(PANEL, "ImgurOffset", "ImgurOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "ButtonOffset", "ButtonOffset", FORCE_NUMBER)

function PANEL:Init()
    self.Items = {}

    self.Scroller = vgui.Create("lyx.ScrollPanel2", self)
    self.Scroller:SetBarDockShouldOffset(true)
    self.Scroller.LayoutContent = function(s, w, h)
        local spacing = lyx.Scale(8)
        local height = lyx.Scale(35)
        for k,v in pairs(self.Items) do
            v:SetTall(height)
            v:Dock(TOP)
            v:DockMargin(0, 0, 0, spacing)
        end
    end

    self:SetImgurScale(.6)
    self:SetImgurOffset(0)
    self:SetButtonOffset(0)

    self.BackgroundCol = lyx.CopyColor(lyx.Colors.Foreground)
end

function PANEL:AddItem(id, name, imgurID, doClick, order)
    local btn = vgui.Create("lyx.SidebarItem2", self.Scroller)

    btn:SetZPos(order or table.Count(self.Items) + 1)
    btn:SetName(name)
    if imgurID then btn:SetImgurID(imgurID) end
    btn.Function = doClick

    btn.DoClick = function(s)
        self:SelectItem(id)
    end

    self.Items[id] = btn

    return btn
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

function PANEL:SetBottomText(text)
    self.BottomText = text
end

function PANEL:SetBottomTextColor(col)
    self.BottomTextColor = col
end

function PANEL:SetBottomTextFont(font)
    self.BottomTextFont = font
end

function PANEL:PerformLayout(w, h)
    local sideSpacing = lyx.Scale(7)
    local topSpacing = lyx.Scale(7)
    self:DockPadding(sideSpacing, self:GetImgurID() and w * self:GetImgurScale() + self:GetImgurOffset() + self:GetButtonOffset() + topSpacing * 2 or topSpacing, sideSpacing, topSpacing)

    self.Scroller:Dock(FILL)
    self.Scroller:GetCanvas():DockPadding(0, 0, self.Scroller.VBar.Enabled and sideSpacing or 0, 0)
end

function PANEL:PaintExtra(w, h)
end

function PANEL:Paint(w, h)
    lyx.DrawRoundedBoxEx(lyx.Scale(6), 0, 0, w, h, self.BackgroundCol, false, false, true)

    local imgurID = self:GetImgurID()
    if imgurID then
        local imageSize = w * self:GetImgurScale()
        lyx.DrawImgur((w - imageSize) * 0.5 + lyx.Scale(5), self:GetImgurOffset() + lyx.Scale(0), imageSize, imageSize, imgurID, color_white)
    end

    if (self.BottomText) then
        lyx.DrawSimpleText(self.BottomText, self.BottomTextFont or lyx.GetRealFont("Moon:Bold@20"), w * 0.5, h - lyx.Scale(15), self.BottomTextColor or lyx.Colors.SecondaryText, 1, 1)
    end

    self:PaintExtra(w, h)
end

vgui.Register("lyx.Sidebar2", PANEL, "Panel")