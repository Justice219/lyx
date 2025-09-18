lyx = lyx or {}
gm3 = gm3 or {}

local PANEL = {}

lyx.RegisterFont("LYX.Title", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Button", "Open Sans SemiBold", 20)

function PANEL:Init()
    self:SetSize(lyx.Scale(1280), lyx.Scale(720))
    self:Center()
    self:SetTitle("Lyx: Enhanced Admin Suite")
    self:MakePopup()

    local sidebar = self:CreateSidebar("Dashboard", nil, nil, lyx.Scale(10), lyx.Scale(10))

    -- Main tabs available to all authorized users
    sidebar:AddItem("Dashboard", "Dashboard", "hEjgFlN", function() self:ChangeTab("LYX.Pages.Dashboard", "Dashboard") end)
    sidebar:AddItem("Server Stats", "Server Stats", "Xxasicd", function() self:ChangeTab("LYX.Pages.ServerStats", "Server Statistics") end)
    sidebar:AddItem("Players", "Players", "FIzNKgj", function() self:ChangeTab("LYX.Pages.Players", "Player Management") end)
    sidebar:AddItem("Performance", "Performance", "tkoexR7", function() self:ChangeTab("LYX.Pages.Performance", "Performance Monitor") end)
    sidebar:AddItem("Configuration", "Config", "NwmR5Gc", function() self:ChangeTab("LYX.Pages.Config", "Configuration") end)
    
    -- Admin/Superadmin only tabs
    if LocalPlayer():GetUserGroup() == "admin" or LocalPlayer():GetUserGroup() == "superadmin" then
        sidebar:AddItem("Commands", "Commands", "Kcvop3T", function() self:ChangeTab("LYX.Pages.Commands", "Command Center") end)
        sidebar:AddItem("Logs", "Logs", "fi4ItlE", function() self:ChangeTab("LYX.Pages.Logs", "System Logs") end)
        sidebar:AddItem("Network", "Network", "xYzAbCd", function() self:ChangeTab("LYX.Pages.Network", "Network Monitor") end)
        sidebar:AddItem("Addons", "Addons", "bRtYuIo", function() self:ChangeTab("LYX.Pages.Addons", "Addon Manager") end)
    end
    
    -- Superadmin only tabs
    if LocalPlayer():GetUserGroup() == "superadmin" then
        sidebar:AddItem("Ranks", "Ranks", "J9YZQgp", function() self:ChangeTab("LYX.Pages.Ranks", "Rank Management") end)
        sidebar:AddItem("Debug Tools", "Debug", "mtbhwRX", function() self:ChangeTab("LYX.Pages.Debug", "Debug Tools") end)
        sidebar:AddItem("SQL Manager", "SQL", "laJHKtH", function() self:ChangeTab("LYX.Pages.SQL", "SQL Manager") end)
    end
    
    -- Developer mode tabs (optional)
    if GetConVar("developer") and GetConVar("developer"):GetInt() > 0 then
        sidebar:AddItem("Console", "Console", "QrStUvW", function() self:ChangeTab("LYX.Pages.Console", "Developer Console") end)
    end
end

function PANEL:ChangeTab(pnl, tabName)
    if self.ContentPanel and self.ContentPanel:IsValid() then
        self.ContentPanel:Remove()
    end

    -- Check if the panel exists before trying to create it
    if not vgui.GetControlTable(pnl) then
        print("[Lyx] Warning: Panel '" .. pnl .. "' does not exist")
        return
    end

    self.ContentPanel = vgui.Create(pnl, self)
    if self.ContentPanel then
        self.ContentPanel:Dock(FILL)
        self.ContentPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
        self:SetTitle("Lyx: Revamped - " .. tabName)
        
        if self.SideBar then
            self.SideBar:SelectItem(tabName)
        end
    end
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