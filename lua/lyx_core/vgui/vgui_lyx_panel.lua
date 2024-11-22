lyx = lyx or {}
gm3 = gm3 or {}

local PANEL = {}

lyx.RegisterFont("LYX.Title", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Button", "Open Sans SemiBold", 20)

function PANEL:Init()
    self:SetSize(lyx.Scale(1280), lyx.Scale(720))
    self:Center()
    self:SetTitle("Lyx: Revamped")
    self:MakePopup()

    local sidebar = self:CreateSidebar("Dashboard", nil, nil, lyx.Scale(10), lyx.Scale(10))

    sidebar:AddItem("Dashboard", "Dashboard", "NwmR5Gc", function() self:ChangeTab("LYX.Pages.Dashboard", "Dashboard") end)
    -- addons
    sidebar:AddItem("Addons", "Addons", "QzMxgOj", function() self:ChangeTab("GM3.Pages.Addons", "Addons") end)
    if LocalPlayer():GetUserGroup() == "superadmin" then
        sidebar:AddItem("Ranks", "Ranks", "J9YZQgp", function() self:ChangeTab("GM3.Pages.Ranks", "Ranks") end)
    end
end

function PANEL:ChangeTab(pnl, tabName)
    if self.ContentPanel and self.ContentPanel:IsValid() then
        self.ContentPanel:Remove()
    end

    self.ContentPanel = vgui.Create(pnl, self)
        self.ContentPanel:Dock(FILL)
        self.ContentPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
        self:SetTitle("Lyx: Revamped - " .. tabName)

    self.SideBar:SelectItem(tabName)
end

vgui.Register("LYX.Menu", PANEL, "lyx.Frame2")

lyx:NetAdd("lyx:menu:open", { 
    func = function()
        net.Start("lyx:sync:request")
        net.SendToServer()

        timer.Simple(0.1, function()
            if IsValid(lyx.Menu) then
                lyx.Menu:Remove()
            end

            lyx.Menu = vgui.Create("LYX.Menu")
        end)
    end
})