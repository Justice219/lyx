local PANEL = {}

lyx.RegisterFont("LYX.Addons.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Addons.Text", "Open Sans", lyx.Scale(14))
lyx.RegisterFont("LYX.Addons.Small", "Open Sans", lyx.Scale(12))

function PANEL:Init()
    -- Header
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Lyx Addons", "LYX.Addons.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
        
        -- Count
        local addonCount = 0
        if lyx.addons then
            addonCount = table.Count(lyx.addons)
        end
        draw.SimpleText(addonCount .. " Lyx addons loaded", "LYX.Addons.Text", w - lyx.Scale(150), lyx.Scale(22), lyx.Colors.SecondaryText)
    end
    
    -- Refresh button
    local refreshBtn = vgui.Create("lyx.TextButton2", headerPanel)
    refreshBtn:SetText("Refresh")
    refreshBtn:Dock(RIGHT)
    refreshBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(12), lyx.Scale(12))
    refreshBtn:SetWide(lyx.Scale(100))
    refreshBtn.DoClick = function()
        self:RefreshAddons()
        notification.AddLegacy("Addon list refreshed!", NOTIFY_GENERIC, 3)
    end
    
    -- Create scroll panel for addon list
    self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
    self.ScrollPanel:Dock(FILL)
    self.ScrollPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    
    -- Info panel
    local infoPanel = vgui.Create("DPanel", self.ScrollPanel)
    infoPanel:Dock(TOP)
    infoPanel:SetTall(lyx.Scale(80))
    infoPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    infoPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
        
        -- System info
        draw.SimpleText("Lyx Framework Version: 2.0", "LYX.Addons.Text", lyx.Scale(15), lyx.Scale(15), lyx.Colors.SecondaryText)
        draw.SimpleText("Lua Memory: " .. math.Round(collectgarbage("count") / 1024, 2) .. " MB", "LYX.Addons.Text", 
            lyx.Scale(15), lyx.Scale(35), lyx.Colors.SecondaryText)
        draw.SimpleText("Loaded Hooks: " .. table.Count(hook.GetTable() or {}), "LYX.Addons.Text", 
            lyx.Scale(15), lyx.Scale(55), lyx.Colors.SecondaryText)
    end
    
    -- Load addons
    self:RefreshAddons()
end

function PANEL:RefreshAddons()
    -- Clear existing addon panels
    for _, child in ipairs(self.ScrollPanel:GetChildren()) do
        if child.IsAddonPanel then
            child:Remove()
        end
    end
    
    -- Get list of Lyx addons only
    local addons = {}
    
    -- Check Lyx registered addons
    if lyx.addons then
        for name, addon in pairs(lyx.addons) do
            table.insert(addons, {
                name = name,
                type = "Lyx Addon",
                version = addon.version or "Unknown",
                author = addon.author or "Unknown",
                description = addon.description or "No description"
            })
        end
    end
    
    -- Sort by name
    table.sort(addons, function(a, b) return a.name < b.name end)
    
    -- Create panels for each addon
    for _, addon in ipairs(addons) do
        local addonPanel = vgui.Create("DPanel", self.ScrollPanel)
        addonPanel:Dock(TOP)
        addonPanel:SetTall(lyx.Scale(100))
        addonPanel:DockMargin(0, 0, lyx.Scale(10), lyx.Scale(5))
        addonPanel.IsAddonPanel = true
        
        -- Lyx addons are always green
        local typeColor = lyx.Colors.Positive or Color(46, 204, 113)
        
        addonPanel.Paint = function(pnl, w, h)
            draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
            
            -- Type indicator
            draw.RoundedBox(4, 0, 0, lyx.Scale(5), h, typeColor)
            
            -- Addon info
            draw.SimpleText(addon.name, "LYX.Addons.Header", lyx.Scale(20), lyx.Scale(10), lyx.Colors.PrimaryText)
            draw.SimpleText("Type: " .. addon.type, "LYX.Addons.Small", lyx.Scale(20), lyx.Scale(35), lyx.Colors.SecondaryText)
            draw.SimpleText("Version: " .. addon.version, "LYX.Addons.Small", lyx.Scale(20), lyx.Scale(55), lyx.Colors.SecondaryText)
            draw.SimpleText("Author: " .. addon.author, "LYX.Addons.Small", lyx.Scale(20), lyx.Scale(75), lyx.Colors.SecondaryText)
            
            -- Description
            draw.SimpleText(addon.description, "LYX.Addons.Small", lyx.Scale(300), lyx.Scale(35), lyx.Colors.DisabledText)
        end
        
        -- Add action buttons for Lyx addons
        if addon.type == "Lyx Addon" then
            local reloadBtn = vgui.Create("lyx.TextButton2", addonPanel)
            reloadBtn:SetText("Reload")
            reloadBtn:SetSize(lyx.Scale(80), lyx.Scale(30))
            reloadBtn:SetPos(addonPanel:GetWide() - lyx.Scale(180), lyx.Scale(35))
            reloadBtn.DoClick = function()
                notification.AddLegacy("Reloading " .. addon.name .. "...", NOTIFY_GENERIC, 3)
                -- Addon reload logic would go here
            end
            
            local disableBtn = vgui.Create("lyx.TextButton2", addonPanel)
            disableBtn:SetText("Disable")
            disableBtn:SetSize(lyx.Scale(80), lyx.Scale(30))
            disableBtn:SetPos(addonPanel:GetWide() - lyx.Scale(90), lyx.Scale(35))
            disableBtn.DoClick = function()
                notification.AddLegacy("Disabled " .. addon.name, NOTIFY_GENERIC, 3)
                -- Addon disable logic would go here
            end
            
            -- Fix button positioning when panel gets its size
            addonPanel.PerformLayout = function(pnl, w, h)
                if reloadBtn and IsValid(reloadBtn) then
                    reloadBtn:SetPos(w - lyx.Scale(180), lyx.Scale(35))
                end
                if disableBtn and IsValid(disableBtn) then
                    disableBtn:SetPos(w - lyx.Scale(90), lyx.Scale(35))
                end
            end
        end
    end
    
    -- If no addons found
    if #addons == 0 then
        local noAddonsPanel = vgui.Create("DPanel", self.ScrollPanel)
        noAddonsPanel:Dock(TOP)
        noAddonsPanel:SetTall(lyx.Scale(100))
        noAddonsPanel.IsAddonPanel = true
        noAddonsPanel.Paint = function(pnl, w, h)
            draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
            draw.SimpleText("No addons found", "LYX.Addons.Header", w/2, h/2, lyx.Colors.DisabledText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Addons", PANEL)