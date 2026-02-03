--[[
	LYXUI Sidebar Elements
	Ported from PIXEL UI. Sidebar navigation with icon+text items and scroll support.
]]

local PANEL = {}

AccessorFunc(PANEL, "Name", "Name", FORCE_STRING)
AccessorFunc(PANEL, "ImageURL", "ImageURL", FORCE_STRING)
AccessorFunc(PANEL, "DrawOutline", "DrawOutline", FORCE_BOOL)
AccessorFunc(PANEL, "ImgurID", "ImgurID", FORCE_STRING)

function PANEL:SetImgurID(id)
    self:SetImageURL("https://i.imgur.com/" .. id .. ".png")
    self.ImgurID = id
end

function PANEL:GetImgurID()
    return self:GetImageURL():match("https://i.imgur.com/(.-).png")
end

lyx.RegisterFont("LYXUI.SidebarItem", "Open Sans Bold", 19)

function PANEL:Init()
    self:SetName("N/A")
    self:SetDrawOutline(true)

    self.TextCol = lyx.CopyColor(LYXUI.Colors.SecondaryText)
    self.BackgroundCol = lyx.CopyColor(LYXUI.Colors.Transparent)
    self.BackgroundHoverCol = ColorAlpha(LYXUI.Colors.Scroller, 80)
end

function PANEL:Paint(w, h)
    local textCol = LYXUI.Colors.SecondaryText
    local backgroundCol = LYXUI.Colors.Transparent

    if self:IsHovered() then
        textCol = LYXUI.Colors.PrimaryText
        backgroundCol = self.BackgroundHoverCol
    end

    if self:IsDown() or self:GetToggle() then
        textCol = LYXUI.Colors.PrimaryText
        backgroundCol = self.BackgroundHoverCol
    end

    local animTime = FrameTime() * 12
    self.TextCol = lyx.LerpColor(animTime, self.TextCol, textCol)
    self.BackgroundCol = lyx.LerpColor(animTime, self.BackgroundCol, backgroundCol)

    if self:GetDrawOutline() then LYXUI.DrawRoundedBox(lyx.Scale(4), 0, 0, w, h, self.BackgroundCol, lyx.Scale(1)) end

    local imageURL = self:GetImageURL()
    if imageURL then
        local iconSize = h * .65
        LYXUI.DrawImage(lyx.Scale(10), (h - iconSize) / 2, iconSize, iconSize, imageURL, self.TextCol)
        lyx.DrawSimpleText(self:GetName(), "LYXUI.SidebarItem", lyx.Scale(20) + iconSize, h / 2, self.TextCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        return
    end

    lyx.DrawSimpleText(self:GetName(), "LYXUI.SidebarItem", lyx.Scale(10), h / 2, self.TextCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("LYXUI.SidebarItem", PANEL, "LYXUI.Button")

PANEL = {}

AccessorFunc(PANEL, "ImageURL", "ImageURL", FORCE_STRING)
AccessorFunc(PANEL, "ImageScale", "ImageScale", FORCE_NUMBER)
AccessorFunc(PANEL, "ImageOffset", "ImageOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "ButtonOffset", "ButtonOffset", FORCE_NUMBER)

AccessorFunc(PANEL, "ImgurID", "ImgurID", FORCE_STRING)
AccessorFunc(PANEL, "ImgurScale", "ImgurScale", FORCE_NUMBER)
AccessorFunc(PANEL, "ImgurOffset", "ImgurOffset", FORCE_NUMBER)

function PANEL:SetImgurID(id)
    self:SetImageURL("https://i.imgur.com/" .. id .. ".png")
    self.ImgurID = id
end

function PANEL:GetImgurID()
    return self:GetImageURL():match("https://i.imgur.com/(.-).png")
end

function PANEL:SetImgurScale(scale)
    self:SetImageScale(scale)
    self.ImgurScale = scale
end

function PANEL:GetImgurScale()
    return self:GetImageScale()
end

function PANEL:SetImgurOffset(offset)
    self:SetImageOffset(offset)
    self.ImgurOffset = offset
end

function PANEL:GetImgurOffset()
    return self:GetImageOffset()
end

function PANEL:Init()
    self.Items = {}

    self.Scroller = vgui.Create("LYXUI.ScrollPanel", self)
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

    self:SetImageScale(.6)
    self:SetImageOffset(0)
    self:SetButtonOffset(0)

    self.BackgroundCol = lyx.CopyColor(LYXUI.Colors.Header)
end

function PANEL:AddItem(id, name, imageURL, doClick, order)
    local btn = vgui.Create("LYXUI.SidebarItem", self.Scroller)

    btn:SetZPos(order or table.Count(self.Items) + 1)
    btn:SetName(name)
    if imageURL then
        local imgurMatch = (imageURL or ""):match("^[a-zA-Z0-9]+$")
        if imgurMatch then
            imageURL = "https://i.imgur.com/" .. imageURL .. ".png"
        end

        btn:SetImageURL(imageURL)
    end
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

function PANEL:PerformLayout(w, h)
    local sideSpacing = lyx.Scale(7)
    local topSpacing = lyx.Scale(7)
    self:DockPadding(sideSpacing, self:GetImageURL() and w * self:GetImageScale() + self:GetImageOffset() + self:GetButtonOffset() + topSpacing * 2 or topSpacing, sideSpacing, topSpacing)

    self.Scroller:Dock(FILL)
    self.Scroller:GetCanvas():DockPadding(0, 0, self.Scroller.VBar.Enabled and sideSpacing or 0, 0)
end

function PANEL:Paint(w, h)
    LYXUI.DrawRoundedBoxEx(lyx.Scale(6), 0, 0, w, h, self.BackgroundCol, false, false, true)

    local imageURL = self:GetImageURL()
    if imageURL then
        local imageSize = w * self:GetImageScale()
        LYXUI.DrawImage((w - imageSize) / 2, self:GetImageOffset() + lyx.Scale(15), imageSize, imageSize, imageURL, color_white)
    end
end

vgui.Register("LYXUI.Sidebar", PANEL, "Panel")
