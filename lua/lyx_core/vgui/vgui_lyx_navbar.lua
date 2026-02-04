local PANEL = {}

function PANEL:Init()
    self.NavButtons = {}
    self.Parent = self:GetParent()

    function self:ScaleW(size)
        return ScrW() * size/1920
    end
    function self:ScaleH(size)
        return ScrH() * size/1080
    end
end

function PANEL:CreateNav()
    self:SetPos(self:ScaleW(15), self:ScaleH(50))
    self:SetSize(self.Parent:GetWide() - self:ScaleW(750), self.Parent:GetTall() - self:ScaleH(60))

    self:TDLib()
    self:ClearPaint()
        :Background(lyx.Colors1["Secondary"], 0)

    self.NavPanel = self:Add("DScrollPanel")
    self.NavPanel:Dock(FILL)
    self.NavPanel:DockMargin(0, 0, 0, 0)

    self.NavFrame = self.Parent:Add("DPanel")
    self.NavFrame:SetPos(self:GetWide() + self:ScaleW(25), self:ScaleH(50))
    self.NavFrame:SetSize(self.Parent:GetWide() - self:GetWide() - self:ScaleW(40), self.Parent:GetTall() - self:ScaleH(60))
    self.NavFrame:TDLib()
    self.NavFrame:ClearPaint()
        :Background(lyx.Colors1["Secondary"], 0)
end

function PANEL:AddButton(name, color, icon, callback)
    table.insert(self.NavButtons, {Name = name, Color = color, Icon = icon, Callback = callback})
end

function PANEL:SetTab(tab)
    self.NavButtons[tab].Callback(self.NavFrame)
    self.NavButtons[tab].Button:ClearPaint()
    :Background(self.NavButtons[tab].Color, 6)
    :SideBlock(Color(255, 255, 255), 4, LEFT)
    :CircleClick(lyx.Colors1.White, 3, 200)
end

function PANEL:ShowIcons(bool)
    self.ShowIcons = bool
end

function PANEL:Setup()
    self:CreateNav()
    for k,v in pairs(self.NavButtons) do

        v.Button = vgui.Create("DButton", self.NavPanel)
        v.Button:Dock(TOP)
        v.Button:DockMargin(5, 5, 5, 5)
        v.Button:SetTall(self:ScaleH(50))
        v.Button.DoClick = function()
            v.Callback(self.NavFrame)
            v.Button:ClearPaint()
                :Background(v.Color, 6)
                :SideBlock(Color(255, 255, 255), 4, LEFT)
                :CircleClick(lyx.Colors1.White, 3, 200)

            for k,i in pairs(self.NavButtons) do
                if i.Button != v.Button then
                    i.Button:ClearPaint()
                        :Background(i.Color, 0)
                        :CircleClick(lyx.Colors1.White, 3, 200)
                end
            end
        end
        v.Button:SetText(v.Name)
        v.Button:SetFont("lyx.font.button")
        v.Button:SetTextColor(lyx.Colors1.White)
        v.Button:TDLib()
        v.Button:ClearPaint()
            :Background(v.Color, 6)
            :BarHover(lyx.Colors1.White, 3)
            :CircleClick(lyx.Colors1.White, 3, 200)

        if self.ShowIcons then
            v.Image = vgui.Create("DImage", v.Button)
            v.Image:SetSize(self:ScaleW(30), self:ScaleH(30))
            if ScrW() == 1920 then
                v.Image:SetPos(v.Button:GetWide() - self:ScaleW(30), v.Button:GetTall() / self:ScaleH(2) - self:ScaleH(15))
            end
            if ScrW() < 1920 then
                v.Image:SetPos(v.Button:GetWide() - self:ScaleW(50), v.Button:GetTall() / self:ScaleH(2) - self:ScaleH(25))
            end
            if ScrW() < 1400 then
                v.Image:SetPos(v.Button:GetWide() - self:ScaleW(70), v.Button:GetTall() / self:ScaleH(2) - self:ScaleH(25))
            end
    
            v.Image:SetImage(v.Icon)
        end

    end
end

vgui.Register("lyx_navbar", PANEL, "DPanel")