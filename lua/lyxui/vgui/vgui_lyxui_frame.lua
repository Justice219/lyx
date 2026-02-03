--[[
	LYXUI Frame Element
	Ported from PIXEL UI. Draggable, resizable window frame with header and sidebar support.
]]

local PANEL = {}

AccessorFunc(PANEL, "Draggable", "Draggable", FORCE_BOOL)
AccessorFunc(PANEL, "Sizable", "Sizable", FORCE_BOOL)
AccessorFunc(PANEL, "MinWidth", "MinWidth", FORCE_NUMBER)
AccessorFunc(PANEL, "MinHeight", "MinHeight", FORCE_NUMBER)
AccessorFunc(PANEL, "ScreenLock", "ScreenLock", FORCE_BOOL)
AccessorFunc(PANEL, "RemoveOnClose", "RemoveOnClose", FORCE_BOOL)

AccessorFunc(PANEL, "Title", "Title", FORCE_STRING)
AccessorFunc(PANEL, "ImgurID", "ImgurID", FORCE_STRING)
AccessorFunc(PANEL, "ImageURL", "ImageURL", FORCE_STRING)

function PANEL:SetImgurID(id)
    self:SetImageURL("https://i.imgur.com/" .. id .. ".png")
    self.ImgurID = id
end

function PANEL:GetImgurID()
    return self:GetImageURL():match("https://i.imgur.com/(.-).png")
end

lyx.RegisterFont("LYXUI.FrameTitle", "Open Sans Bold", 22)

function PANEL:Init()
    self.CloseButton = vgui.Create("LYXUI.ImageButton", self)
    self.CloseButton:SetImageURL("https://pixel-cdn.lythium.dev/i/fh640z2o")
    self.CloseButton:SetNormalColor(LYXUI.Colors.PrimaryText)
    self.CloseButton:SetHoverColor(LYXUI.Colors.Negative)
    self.CloseButton:SetClickColor(LYXUI.Colors.Negative)
    self.CloseButton:SetDisabledColor(LYXUI.Colors.DisabledText)

    self.CloseButton.DoClick = function(s)
        self:Close()
    end

    self.ExtraButtons = {}

    self:SetTitle("LYXUI Frame")

    self:SetDraggable(true)
    self:SetScreenLock(true)
    self:SetRemoveOnClose(true)

    local size = lyx.Scale(200)
    self:SetMinWidth(size)
    self:SetMinHeight(size)

    local oldMakePopup = self.MakePopup
    function self:MakePopup()
        oldMakePopup(self)
        self:Open()
    end
end

function PANEL:DragThink(targetPanel, hoverPanel)
    local scrw, scrh = ScrW(), ScrH()
    local mousex, mousey = math.Clamp(gui.MouseX(), 1, scrw - 1), math.Clamp(gui.MouseY(), 1, scrh - 1)

    if targetPanel.Dragging then
        local x = mousex - targetPanel.Dragging[1]
        local y = mousey - targetPanel.Dragging[2]

        if targetPanel:GetScreenLock() then
            x = math.Clamp(x, 0, scrw - targetPanel:GetWide())
            y = math.Clamp(y, 0, scrh - targetPanel:GetTall())
        end

        targetPanel:SetPos(x, y)
    end

    local _, screenY = targetPanel:LocalToScreen(0, 0)
    if (hoverPanel or targetPanel).Hovered and targetPanel:GetDraggable() and mousey < (screenY + lyx.Scale(30)) then
        targetPanel:SetCursor("sizeall")
        return true
    end
end

function PANEL:SizeThink(targetPanel, hoverPanel)
    local scrw, scrh = ScrW(), ScrH()
    local mousex, mousey = math.Clamp(gui.MouseX(), 1, scrw - 1), math.Clamp(gui.MouseY(), 1, scrh - 1)

    if targetPanel.Sizing then
        local x = mousex - targetPanel.Sizing[1]
        local y = mousey - targetPanel.Sizing[2]
        local px, py = targetPanel:GetPos()

        local screenLock = self:GetScreenLock()
        if x < targetPanel.MinWidth then x = targetPanel.MinWidth elseif x > scrw - px and screenLock then x = scrw - px end
        if y < targetPanel.MinHeight then y = targetPanel.MinHeight elseif y > scrh - py and screenLock then y = scrh - py end

        targetPanel:SetSize(x, y)
        targetPanel:SetCursor("sizenwse")
        return true
    end

    local screenX, screenY = targetPanel:LocalToScreen(0, 0)
    if (hoverPanel or targetPanel).Hovered and targetPanel.Sizable and mousex > (screenX + targetPanel:GetWide() - lyx.Scale(20)) and mousey > (screenY + targetPanel:GetTall() - lyx.Scale(20)) then
        (hoverPanel or targetPanel):SetCursor("sizenwse")
        return true
    end
end

function PANEL:Think()
    if self:DragThink(self) then return end
    if self:SizeThink(self) then return end

    self:SetCursor("arrow")

    if self.y < 0 then
        self:SetPos(self.x, 0)
    end
end

function PANEL:OnMousePressed()
    local screenX, screenY = self:LocalToScreen(0, 0)
    local mouseX, mouseY = gui.MouseX(), gui.MouseY()

    if self.Sizable and mouseX > (screenX + self:GetWide() - lyx.Scale(30)) and mouseY > (screenY + self:GetTall() - lyx.Scale(30)) then
        self.Sizing = {mouseX - self:GetWide(), mouseY - self:GetTall()}
        self:MouseCapture(true)
        return
    end

    if self:GetDraggable() and mouseY < (screenY + lyx.Scale(30)) then
        self.Dragging = {mouseX - self.x, mouseY - self.y}
        self:MouseCapture(true)
        return
    end
end

function PANEL:OnMouseReleased()
    self.Dragging = nil
    self.Sizing = nil
    self:MouseCapture(false)
end

function PANEL:CreateSidebar(defaultItem, imageURL, imageScale, imageYOffset, buttonYOffset)
    if IsValid(self.SideBar) then return end
    self.SideBar = vgui.Create("LYXUI.Sidebar", self)

    if defaultItem then
        timer.Simple(0, function()
            if not IsValid(self.SideBar) then return end
            self.SideBar:SelectItem(defaultItem)
        end)
    end

    if imageURL then
        local imgurMatch = (imageURL or ""):match("^[a-zA-Z0-9]+$")
        if imgurMatch then
            imageURL = "https://i.imgur.com/" .. imageURL .. ".png"
        end

        self.SideBar:SetImageURL(imageURL)
    end

    if imageScale then self.SideBar:SetImageScale(imageScale) end
    if imageYOffset then self.SideBar:SetImageOffset(imageYOffset) end
    if buttonYOffset then self.SideBar:SetButtonOffset(buttonYOffset) end

    return self.SideBar
end

function PANEL:AddHeaderButton(elem, size)
    elem.HeaderIconSize = size or .45
    return table.insert(self.ExtraButtons, elem)
end

function PANEL:LayoutContent(w, h) end

function PANEL:PerformLayout(w, h)
    local headerH = lyx.Scale(30)
    local btnPad = lyx.Scale(6)
    local btnSpacing = lyx.Scale(6)

    if IsValid(self.CloseButton) then
        local btnSize = headerH * .45
        self.CloseButton:SetSize(btnSize, btnSize)
        self.CloseButton:SetPos(w - btnSize - btnPad, (headerH - btnSize) / 2)

        btnPad = btnPad + btnSize + btnSpacing
    end

    for _, btn in ipairs(self.ExtraButtons) do
        local btnSize = headerH * btn.HeaderIconSize
        btn:SetSize(btnSize, btnSize)
        btn:SetPos(w - btnSize - btnPad, (headerH - btnSize) / 2)
        btnPad = btnPad + btnSize + btnSpacing
    end

    if IsValid(self.SideBar) then
        self.SideBar:SetPos(0, headerH)
        self.SideBar:SetSize(lyx.Scale(200), h - headerH)
    end

    local padding = lyx.Scale(6)
    self:DockPadding(self.SideBar and lyx.Scale(200) + padding or padding, headerH + padding, padding, padding)

    self:LayoutContent(w, h)
end

function PANEL:Open()
    self:SetAlpha(0)
    self:SetVisible(true)
    self:AlphaTo(255, .1, 0)
end

function PANEL:Close()
    self:AlphaTo(0, .1, 0, function(anim, pnl)
        if not IsValid(pnl) then return end
        pnl:SetVisible(false)
        pnl:OnClose()
        if pnl:GetRemoveOnClose() then pnl:Remove() end
    end)
end

function PANEL:OnClose() end

function PANEL:PaintHeader(x, y, w, h)
    LYXUI.DrawRoundedBoxEx(lyx.Scale(6), x, y, w, h, LYXUI.Colors.Header, true, true)

    local imageURL = self:GetImageURL()
    if imageURL then
        local iconSize = h * .6
        LYXUI.DrawImage(lyx.Scale(6), x + (h - iconSize) / 2, y + iconSize, iconSize, imageURL, color_white)
        lyx.DrawSimpleText(self:GetTitle(), "LYXUI.FrameTitle", x + lyx.Scale(12) + iconSize, y + h / 2, LYXUI.Colors.PrimaryText, nil, TEXT_ALIGN_CENTER)
        return
    end

    lyx.DrawSimpleText(self:GetTitle(), "LYXUI.FrameTitle", x + lyx.Scale(6), y + h / 2, LYXUI.Colors.PrimaryText, nil, TEXT_ALIGN_CENTER)
end

function PANEL:Paint(w, h)
    self:PaintBefore(w, h)
    LYXUI.DrawRoundedBox(lyx.Scale(4), 0, 0, w, h, LYXUI.Colors.Background)
    self:PaintHeader(0, 0, w, lyx.Scale(30))
end

function PANEL:PaintBefore(w, h)
end

vgui.Register("LYXUI.Frame", PANEL, "EditablePanel")
