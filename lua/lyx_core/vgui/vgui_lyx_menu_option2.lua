lyx = lyx

local PANEL = {}

AccessorFunc(PANEL, "m_pMenu", "Menu")
AccessorFunc(PANEL, "m_bChecked", "Checked")
AccessorFunc(PANEL, "m_bCheckable", "IsCheckable")

AccessorFunc(PANEL, "Text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "TextAlign", "TextAlign", FORCE_NUMBER)
AccessorFunc(PANEL, "Font", "Font", FORCE_STRING)

lyx.RegisterFont("UI.MenuOption", "Open Sans SemiBold", 18)

function PANEL:Init()
    self:SetTextAlign(TEXT_ALIGN_LEFT)
    self:SetFont("UI.MenuOption")
    self:SetChecked(false)

    self.NormalCol = lyx.Colors.Transparent
    self.HoverCol = lyx.Colors.Scroller

    self.BackgroundCol = lyx.CopyColor(self.NormalCol)
end

function PANEL:SetIcon(path)
    if not path or path == "" then
        self.IconMaterial = nil
        return
    end
    self.IconMaterial = Material(path, "smooth")
end

function PANEL:SetSubMenu(menu)
    self.SubMenu = menu
end

function PANEL:AddSubMenu()
    local subMenu = vgui.Create("lyx.Menu2", self)
    subMenu:SetVisible(false)
    subMenu:SetParent(self)

    self:SetSubMenu(subMenu)

    return subMenu
end

function PANEL:OnCursorEntered()
    local parent = self.ParentMenu
    if not IsValid(parent) then parent = self:GetParent() end
    if not IsValid(parent) then return end

    if not parent.OpenSubMenu then return end
    parent:OpenSubMenu(self, self.SubMenu)
end

function PANEL:OnCursorExited() end

function PANEL:Paint(w, h)
    self.BackgroundCol = lyx.LerpColor(FrameTime() * 12, self.BackgroundCol, self:IsHovered() and self.HoverCol or self.NormalCol)

    surface.SetDrawColor(self.BackgroundCol)
    surface.DrawRect(0, 0, w, h)

    local textX = lyx.Scale(14)
    if self.IconMaterial then
        local iconSize = lyx.Scale(16)
        local iconX = lyx.Scale(8)
        local iconY = (h - iconSize) * 0.5
        surface.SetMaterial(self.IconMaterial)
        surface.SetDrawColor(255, 255, 255, self:IsEnabled() and 255 or 140)
        surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
        textX = iconX + iconSize + lyx.Scale(6)
    end

    lyx.DrawSimpleText(self:GetText(), self:GetFont(), textX, h * 0.5, lyx.Colors.PrimaryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    if not self.SubMenu then return end
    local dropBtnSize = lyx.Scale(8)
    lyx.DrawImgur(w - dropBtnSize - lyx.Scale(6), h * 0.5 - dropBtnSize * 0.5, dropBtnSize, dropBtnSize, "gXg3U6X", lyx.Colors.PrimaryText)
end

function PANEL:OnPressed(mousecode)
    self.m_MenuClicking = true
end

function PANEL:OnReleased(mousecode)
    if not self.m_MenuClicking and mousecode == MOUSE_LEFT then return end
    self.m_MenuClicking = false
    CloseDermaMenus()
end

function PANEL:DoRightClick()
    if self:GetIsCheckable() then
        self:ToggleCheck()
    end
end

function PANEL:DoClickInternal()
    if self:GetIsCheckable() then
        self:ToggleCheck()
    end

    if not self.m_pMenu then return end
    self.m_pMenu:OptionSelectedInternal(self)
end

function PANEL:ToggleCheck()
    self:SetChecked(not self:GetChecked())
    self:OnChecked(self:GetChecked())
end

function PANEL:OnChecked(enabled) end

function PANEL:CalculateWidth()
    lyx.SetFont(self:GetFont())
    return lyx.GetTextSize(self:GetText()) + lyx.Scale(34)
end

function PANEL:PerformLayout(w, h)
    self:SetSize(math.max(self:CalculateWidth(), self:GetWide()), lyx.Scale(32))
end

vgui.Register("lyx.MenuOption2", PANEL, "lyx.Button2")

PANEL = {}

AccessorFunc(PANEL, "ConVar", "ConVar")
AccessorFunc(PANEL, "ValueOn", "ValueOn")
AccessorFunc(PANEL, "ValueOff", "ValueOff")

function PANEL:Init()
    self:SetChecked(false)
    self:SetIsCheckable(true)
    self:SetValueOn("1")
    self:SetValueOff("0")
end

function PANEL:Think()
    if not self.ConVar then return end
    self:SetChecked(GetConVar(self.ConVar):GetString() == self.ValueOn)
end

function PANEL:OnChecked(checked)
    if not self.ConVar then return end
    RunConsoleCommand(self.ConVar, checked and self.ValueOn or self.ValueOff)
end

vgui.Register("lyx.MenuOptionCVar2", PANEL, "lyx.MenuOption2")
