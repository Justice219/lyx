local PANEL = {}

lyx.RegisterFont("LYX.Config.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Config.Text", "Open Sans", lyx.Scale(14))
lyx.RegisterFont("LYX.Config.Small", "Open Sans", lyx.Scale(12))

function PANEL:Init()
    -- Settings cache
    self.Settings = {}
    self.OriginalSettings = {}
    
    -- Header
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Lyx Configuration", "LYX.Config.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
        
        -- Show if changes are pending
        if self:HasChanges() then
            draw.SimpleText("● Unsaved Changes", "LYX.Config.Small", w - lyx.Scale(150), lyx.Scale(22), Color(241, 196, 15))
        else
            draw.SimpleText("● All Saved", "LYX.Config.Small", w - lyx.Scale(100), lyx.Scale(22), Color(46, 204, 113))
        end
    end
    
    -- Action buttons
    local saveBtn = vgui.Create("lyx.TextButton2", headerPanel)
    saveBtn:SetText("Save Changes")
    saveBtn:Dock(RIGHT)
    saveBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(12), lyx.Scale(12))
    saveBtn:SetWide(lyx.Scale(120))
    saveBtn.DoClick = function()
        self:SaveSettings()
    end
    
    local resetBtn = vgui.Create("lyx.TextButton2", headerPanel)
    resetBtn:SetText("Reset")
    resetBtn:Dock(RIGHT)
    resetBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(5), lyx.Scale(12))
    resetBtn:SetWide(lyx.Scale(80))
    resetBtn.DoClick = function()
        self:ResetSettings()
    end
    
    -- Main scroll panel
    self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
    self.ScrollPanel:Dock(FILL)
    self.ScrollPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    
    -- General Settings
    local generalPanel = vgui.Create("DPanel", self.ScrollPanel)
    generalPanel:Dock(TOP)
    generalPanel:SetTall(lyx.Scale(250))
    generalPanel:DockMargin(0, 0, lyx.Scale(10), lyx.Scale(10))
    generalPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("General Settings", "LYX.Config.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
    end
    
    -- Server Name
    local serverNameLabel = vgui.Create("DLabel", generalPanel)
    serverNameLabel:SetText("Server Name:")
    serverNameLabel:SetPos(lyx.Scale(15), lyx.Scale(45))
    if lyx.GetRealFont then
        serverNameLabel:SetFont(lyx.GetRealFont("LYX.Config.Text") or "DermaDefault")
    else
        serverNameLabel:SetFont("DermaDefault")
    end
    serverNameLabel:SetTextColor(lyx.Colors.SecondaryText)
    serverNameLabel:SizeToContents()
    
    local serverNameEntry = vgui.Create("lyx.TextEntry2", generalPanel)
    serverNameEntry:SetPos(lyx.Scale(15), lyx.Scale(70))
    serverNameEntry:SetSize(lyx.Scale(400), lyx.Scale(30))
    serverNameEntry:SetPlaceholderText("Enter server name...")
    serverNameEntry.OnChange = function(s)
        self.Settings["server_name"] = s:GetText()
    end
    self.serverNameEntry = serverNameEntry
    
    -- Welcome Message
    local welcomeLabel = vgui.Create("DLabel", generalPanel)
    welcomeLabel:SetText("Welcome Message:")
    welcomeLabel:SetPos(lyx.Scale(15), lyx.Scale(110))
    if lyx.GetRealFont then
        welcomeLabel:SetFont(lyx.GetRealFont("LYX.Config.Text") or "DermaDefault")
    else
        welcomeLabel:SetFont("DermaDefault")
    end
    welcomeLabel:SetTextColor(lyx.Colors.SecondaryText)
    welcomeLabel:SizeToContents()
    
    local welcomeEntry = vgui.Create("lyx.TextEntry2", generalPanel)
    welcomeEntry:SetPos(lyx.Scale(15), lyx.Scale(135))
    welcomeEntry:SetSize(lyx.Scale(400), lyx.Scale(30))
    welcomeEntry:SetPlaceholderText("Enter welcome message...")
    welcomeEntry.OnChange = function(s)
        self.Settings["welcome_message"] = s:GetText()
    end
    self.welcomeEntry = welcomeEntry
    
    -- Enable Logging checkbox
    local loggingCheck = vgui.Create("lyx.Checkbox2", generalPanel)
    loggingCheck:SetPos(lyx.Scale(15), lyx.Scale(180))
    loggingCheck.OnToggled = function(s, val)
        self.Settings["enable_logging"] = val
    end
    self.loggingCheck = loggingCheck
    
    local loggingLabel = vgui.Create("DLabel", generalPanel)
    loggingLabel:SetText("Enable System Logging")
    loggingLabel:SetPos(lyx.Scale(45), lyx.Scale(182))
    if lyx.GetRealFont then
        loggingLabel:SetFont(lyx.GetRealFont("LYX.Config.Text") or "DermaDefault")
    else
        loggingLabel:SetFont("DermaDefault")
    end
    loggingLabel:SetTextColor(lyx.Colors.SecondaryText)
    loggingLabel:SizeToContents()
    
    -- Enable Debug Mode checkbox
    local debugCheck = vgui.Create("lyx.Checkbox2", generalPanel)
    debugCheck:SetPos(lyx.Scale(15), lyx.Scale(210))
    debugCheck.OnToggled = function(s, val)
        self.Settings["debug_mode"] = val
    end
    self.debugCheck = debugCheck
    
    local debugLabel = vgui.Create("DLabel", generalPanel)
    debugLabel:SetText("Enable Debug Mode")
    debugLabel:SetPos(lyx.Scale(45), lyx.Scale(212))
    if lyx.GetRealFont then
        debugLabel:SetFont(lyx.GetRealFont("LYX.Config.Text") or "DermaDefault")
    else
        debugLabel:SetFont("DermaDefault")
    end
    debugLabel:SetTextColor(lyx.Colors.SecondaryText)
    debugLabel:SizeToContents()
    
    -- Security Settings
    local securityPanel = vgui.Create("DPanel", self.ScrollPanel)
    securityPanel:Dock(TOP)
    securityPanel:SetTall(lyx.Scale(200))
    securityPanel:DockMargin(0, 0, lyx.Scale(10), lyx.Scale(10))
    securityPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Security Settings", "LYX.Config.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
    end
    
    -- Anti-Exploit checkbox
    local antiExploitCheck = vgui.Create("lyx.Checkbox2", securityPanel)
    antiExploitCheck:SetPos(lyx.Scale(15), lyx.Scale(45))
    antiExploitCheck.OnToggled = function(s, val)
        self.Settings["anti_exploit"] = val
    end
    self.antiExploitCheck = antiExploitCheck
    
    local antiExploitLabel = vgui.Create("DLabel", securityPanel)
    antiExploitLabel:SetText("Enable Anti-Exploit System")
    antiExploitLabel:SetPos(lyx.Scale(45), lyx.Scale(47))
    if lyx.GetRealFont then
        antiExploitLabel:SetFont(lyx.GetRealFont("LYX.Config.Text") or "DermaDefault")
    else
        antiExploitLabel:SetFont("DermaDefault")
    end
    antiExploitLabel:SetTextColor(lyx.Colors.SecondaryText)
    antiExploitLabel:SizeToContents()
    
    -- Rate Limiting checkbox
    local rateLimitCheck = vgui.Create("lyx.Checkbox2", securityPanel)
    rateLimitCheck:SetPos(lyx.Scale(15), lyx.Scale(75))
    rateLimitCheck.OnToggled = function(s, val)
        self.Settings["rate_limiting"] = val
    end
    self.rateLimitCheck = rateLimitCheck
    
    local rateLimitLabel = vgui.Create("DLabel", securityPanel)
    rateLimitLabel:SetText("Enable Rate Limiting")
    rateLimitLabel:SetPos(lyx.Scale(45), lyx.Scale(77))
    if lyx.GetRealFont then
        rateLimitLabel:SetFont(lyx.GetRealFont("LYX.Config.Text") or "DermaDefault")
    else
        rateLimitLabel:SetFont("DermaDefault")
    end
    rateLimitLabel:SetTextColor(lyx.Colors.SecondaryText)
    rateLimitLabel:SizeToContents()
    
    -- Max Rate Limit
    local maxRateLabel = vgui.Create("DLabel", securityPanel)
    maxRateLabel:SetText("Max Requests Per Minute:")
    maxRateLabel:SetPos(lyx.Scale(15), lyx.Scale(110))
    if lyx.GetRealFont then
        maxRateLabel:SetFont(lyx.GetRealFont("LYX.Config.Text") or "DermaDefault")
    else
        maxRateLabel:SetFont("DermaDefault")
    end
    maxRateLabel:SetTextColor(lyx.Colors.SecondaryText)
    maxRateLabel:SizeToContents()
    
    local maxRateEntry = vgui.Create("lyx.TextEntry2", securityPanel)
    maxRateEntry:SetPos(lyx.Scale(15), lyx.Scale(135))
    maxRateEntry:SetSize(lyx.Scale(100), lyx.Scale(30))
    maxRateEntry:SetNumeric(true)
    maxRateEntry:SetPlaceholderText("60")
    maxRateEntry.OnChange = function(s)
        local val = tonumber(s:GetText())
        if val then
            self.Settings["max_rate_limit"] = val
        end
    end
    self.maxRateEntry = maxRateEntry
    
    -- Performance Settings
    local perfPanel = vgui.Create("DPanel", self.ScrollPanel)
    perfPanel:Dock(TOP)
    perfPanel:SetTall(lyx.Scale(180))
    perfPanel:DockMargin(0, 0, lyx.Scale(10), lyx.Scale(10))
    perfPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Performance Settings", "LYX.Config.Header", lyx.Scale(15), lyx.Scale(10), lyx.Colors.PrimaryText)
    end
    
    -- Cache Lifetime
    local cacheLabel = vgui.Create("DLabel", perfPanel)
    cacheLabel:SetText("Cache Lifetime (seconds):")
    cacheLabel:SetPos(lyx.Scale(15), lyx.Scale(45))
    if lyx.GetRealFont then
        cacheLabel:SetFont(lyx.GetRealFont("LYX.Config.Text") or "DermaDefault")
    else
        cacheLabel:SetFont("DermaDefault")
    end
    cacheLabel:SetTextColor(lyx.Colors.SecondaryText)
    cacheLabel:SizeToContents()
    
    local cacheEntry = vgui.Create("lyx.TextEntry2", perfPanel)
    cacheEntry:SetPos(lyx.Scale(15), lyx.Scale(70))
    cacheEntry:SetSize(lyx.Scale(100), lyx.Scale(30))
    cacheEntry:SetNumeric(true)
    cacheEntry:SetPlaceholderText("300")
    cacheEntry.OnChange = function(s)
        local val = tonumber(s:GetText())
        if val then
            self.Settings["cache_lifetime"] = val
        end
    end
    self.cacheEntry = cacheEntry
    
    -- Auto Save checkbox
    local autoSaveCheck = vgui.Create("lyx.Checkbox2", perfPanel)
    autoSaveCheck:SetPos(lyx.Scale(15), lyx.Scale(115))
    autoSaveCheck.OnToggled = function(s, val)
        self.Settings["auto_save"] = val
    end
    self.autoSaveCheck = autoSaveCheck
    
    local autoSaveLabel = vgui.Create("DLabel", perfPanel)
    autoSaveLabel:SetText("Enable Auto Save")
    autoSaveLabel:SetPos(lyx.Scale(45), lyx.Scale(117))
    if lyx.GetRealFont then
        autoSaveLabel:SetFont(lyx.GetRealFont("LYX.Config.Text") or "DermaDefault")
    else
        autoSaveLabel:SetFont("DermaDefault")
    end
    autoSaveLabel:SetTextColor(lyx.Colors.SecondaryText)
    autoSaveLabel:SizeToContents()
    
    -- Load settings from server
    self:LoadSettings()
end

function PANEL:LoadSettings()
    if CLIENT then
        -- Request all settings from server
        net.Start("lyx:settings:getall")
        net.SendToServer()
    end
end

function PANEL:SaveSettings()
    if not LocalPlayer():IsSuperAdmin() then
        notification.AddLegacy("Only superadmins can save settings!", NOTIFY_ERROR, 3)
        return
    end
    
    -- Save each changed setting
    for key, value in pairs(self.Settings) do
        if self.OriginalSettings[key] ~= value then
            net.Start("lyx:settings:set")
            net.WriteString(key)
            net.WriteString(util.TableToJSON({value = value}))
            net.SendToServer()
        end
    end
    
    -- Update original settings
    self.OriginalSettings = table.Copy(self.Settings)
    
    notification.AddLegacy("Settings saved successfully!", NOTIFY_GENERIC, 3)
end

function PANEL:ResetSettings()
    -- Reset to original values
    self.Settings = table.Copy(self.OriginalSettings)
    
    -- Update UI elements
    if self.serverNameEntry then self.serverNameEntry:SetText(self.Settings["server_name"] or "") end
    if self.welcomeEntry then self.welcomeEntry:SetText(self.Settings["welcome_message"] or "") end
    if self.loggingCheck then self.loggingCheck:SetToggle(self.Settings["enable_logging"] or false) end
    if self.debugCheck then self.debugCheck:SetToggle(self.Settings["debug_mode"] or false) end
    if self.antiExploitCheck then self.antiExploitCheck:SetToggle(self.Settings["anti_exploit"] or false) end
    if self.rateLimitCheck then self.rateLimitCheck:SetToggle(self.Settings["rate_limiting"] or false) end
    if self.maxRateEntry then self.maxRateEntry:SetText(tostring(self.Settings["max_rate_limit"] or 60)) end
    if self.cacheEntry then self.cacheEntry:SetText(tostring(self.Settings["cache_lifetime"] or 300)) end
    if self.autoSaveCheck then self.autoSaveCheck:SetToggle(self.Settings["auto_save"] or false) end
    
    notification.AddLegacy("Settings reset to last saved values", NOTIFY_GENERIC, 3)
end

function PANEL:HasChanges()
    for key, value in pairs(self.Settings) do
        if self.OriginalSettings[key] ~= value then
            return true
        end
    end
    return false
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

-- Listen for settings sync from server
if CLIENT then
    net.Receive("lyx:settings:sync", function()
        local key = net.ReadString()
        local valueJson = net.ReadString()
        local data = util.JSONToTable(valueJson)
        
        if IsValid(lyx.ConfigPanel) then
            if key == "__ALL__" then
                -- Received all settings
                lyx.ConfigPanel.Settings = data or {}
                lyx.ConfigPanel.OriginalSettings = table.Copy(lyx.ConfigPanel.Settings)
                
                -- Update UI elements
                local s = lyx.ConfigPanel.Settings
                if lyx.ConfigPanel.serverNameEntry then lyx.ConfigPanel.serverNameEntry:SetText(s["server_name"] or "") end
                if lyx.ConfigPanel.welcomeEntry then lyx.ConfigPanel.welcomeEntry:SetText(s["welcome_message"] or "") end
                if lyx.ConfigPanel.loggingCheck then lyx.ConfigPanel.loggingCheck:SetToggle(s["enable_logging"] or false) end
                if lyx.ConfigPanel.debugCheck then lyx.ConfigPanel.debugCheck:SetToggle(s["debug_mode"] or false) end
                if lyx.ConfigPanel.antiExploitCheck then lyx.ConfigPanel.antiExploitCheck:SetToggle(s["anti_exploit"] or false) end
                if lyx.ConfigPanel.rateLimitCheck then lyx.ConfigPanel.rateLimitCheck:SetToggle(s["rate_limiting"] or false) end
                if lyx.ConfigPanel.maxRateEntry then lyx.ConfigPanel.maxRateEntry:SetText(tostring(s["max_rate_limit"] or 60)) end
                if lyx.ConfigPanel.cacheEntry then lyx.ConfigPanel.cacheEntry:SetText(tostring(s["cache_lifetime"] or 300)) end
                if lyx.ConfigPanel.autoSaveCheck then lyx.ConfigPanel.autoSaveCheck:SetToggle(s["auto_save"] or false) end
            else
                -- Single setting update
                if data and data.value ~= nil then
                    lyx.ConfigPanel.Settings[key] = data.value
                    lyx.ConfigPanel.OriginalSettings[key] = data.value
                end
            end
        end
    end)
end

function PANEL:OnRemove()
    lyx.ConfigPanel = nil
end

function PANEL:OnShow()
    lyx.ConfigPanel = self
end

vgui.Register("LYX.Pages.Config", PANEL)