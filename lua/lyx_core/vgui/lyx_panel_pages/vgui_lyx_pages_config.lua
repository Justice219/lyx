local PANEL = {}

lyx.RegisterFont("LYX.Config.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Config.Text", "Open Sans", lyx.Scale(14))
lyx.RegisterFont("LYX.Config.Category", "Open Sans Bold", lyx.Scale(16))

function PANEL:Init()
    self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
    self.ScrollPanel:Dock(FILL)
    self.ScrollPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    
    -- Header
    local headerPanel = vgui.Create("DPanel", self.ScrollPanel)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(0, 0, 0, lyx.Scale(10))
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 40, 200))
        draw.SimpleText("Server Configuration", "LYX.Config.Header", lyx.Scale(15), lyx.Scale(20), Color(255, 255, 255))
        
        -- Save status
        if pnl.SaveStatus then
            local color = pnl.SaveStatus == "saved" and Color(46, 204, 113) or Color(241, 196, 15)
            local text = pnl.SaveStatus == "saved" and "✓ Settings Saved" or "⚠ Unsaved Changes"
            draw.SimpleText(text, "LYX.Config.Text", w - lyx.Scale(150), lyx.Scale(22), color)
        end
    end
    
    self.HeaderPanel = headerPanel
    self.Settings = {}
    
    -- General Settings
    self:AddCategory("General Settings")
    self:AddSetting("string", "server_name", "Server Name", GetHostName())
    self:AddSetting("string", "server_password", "Server Password", "")
    self:AddSetting("number", "max_players", "Max Players", game.MaxPlayers(), 1, 128)
    self:AddSetting("bool", "enable_voice", "Enable Voice Chat", true)
    self:AddSetting("bool", "enable_flashlight", "Enable Flashlight", true)
    
    -- Gameplay Settings
    self:AddCategory("Gameplay Settings")
    self:AddSetting("number", "respawn_time", "Respawn Time (seconds)", 5, 0, 60)
    self:AddSetting("bool", "friendly_fire", "Friendly Fire", false)
    self:AddSetting("bool", "fall_damage", "Fall Damage", true)
    self:AddSetting("number", "walk_speed", "Walk Speed", 200, 50, 500)
    self:AddSetting("number", "run_speed", "Run Speed", 400, 100, 1000)
    
    -- Lyx Settings
    self:AddCategory("Lyx Framework Settings")
    self:AddSetting("bool", "lyx_debug", "Debug Mode", false)
    self:AddSetting("bool", "lyx_logging", "Enable Logging", true)
    self:AddSetting("bool", "lyx_performance", "Performance Monitoring", true)
    self:AddSetting("number", "lyx_cache_time", "Cache Lifetime (seconds)", 5, 1, 60)
    self:AddSetting("bool", "lyx_chat_commands", "Enable Chat Commands", true)
    
    -- Security Settings
    self:AddCategory("Security Settings")
    self:AddSetting("bool", "enable_anticheat", "Enable Anti-Cheat", true)
    self:AddSetting("number", "rate_limit", "Network Rate Limit (msg/sec)", 10, 1, 100)
    self:AddSetting("bool", "sql_logging", "Log SQL Queries", false)
    self:AddSetting("bool", "validate_input", "Validate All Input", true)
    
    -- Advanced Settings
    if LocalPlayer():GetUserGroup() == "superadmin" then
        self:AddCategory("Advanced Settings")
        self:AddSetting("bool", "developer_mode", "Developer Mode", GetConVar("developer"):GetInt() > 0)
        self:AddSetting("bool", "allow_lua", "Allow Lua Execution", false)
        self:AddSetting("string", "webhook_url", "Discord Webhook URL", "")
        self:AddSetting("bool", "auto_save", "Auto-Save Settings", true)
    end
    
    -- Control buttons
    local controlPanel = vgui.Create("DPanel", self.ScrollPanel)
    controlPanel:Dock(TOP)
    controlPanel:SetTall(lyx.Scale(60))
    controlPanel:DockMargin(0, lyx.Scale(20), 0, lyx.Scale(10))
    controlPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 40, 200))
    end
    
    local saveBtn = vgui.Create("lyx.TextButton2", controlPanel)
    saveBtn:SetText("Save Settings")
    saveBtn:SetSize(lyx.Scale(150), lyx.Scale(40))
    saveBtn:SetPos(lyx.Scale(10), lyx.Scale(10))
    saveBtn.DoClick = function()
        self:SaveSettings()
    end
    
    local resetBtn = vgui.Create("lyx.TextButton2", controlPanel)
    resetBtn:SetText("Reset to Default")
    resetBtn:SetSize(lyx.Scale(150), lyx.Scale(40))
    resetBtn:SetPos(lyx.Scale(170), lyx.Scale(10))
    resetBtn.DoClick = function()
        Derma_Query("Are you sure you want to reset all settings to default?", "Reset Settings",
            "Yes", function() self:ResetSettings() end,
            "No", function() end
        )
    end
    
    local exportBtn = vgui.Create("lyx.TextButton2", controlPanel)
    exportBtn:SetText("Export Settings")
    exportBtn:SetSize(lyx.Scale(150), lyx.Scale(40))
    exportBtn:SetPos(lyx.Scale(330), lyx.Scale(10))
    exportBtn.DoClick = function()
        self:ExportSettings()
    end
    
    local importBtn = vgui.Create("lyx.TextButton2", controlPanel)
    importBtn:SetText("Import Settings")
    importBtn:SetSize(lyx.Scale(150), lyx.Scale(40))
    importBtn:SetPos(lyx.Scale(490), lyx.Scale(10))
    importBtn.DoClick = function()
        self:ImportSettings()
    end
end

function PANEL:AddCategory(name)
    local catPanel = vgui.Create("DPanel", self.ScrollPanel)
    catPanel:Dock(TOP)
    catPanel:SetTall(lyx.Scale(40))
    catPanel:DockMargin(0, lyx.Scale(10), 0, 0)
    catPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 50, 200))
        draw.SimpleText(name, "LYX.Config.Category", lyx.Scale(15), h/2, Color(186, 32, 55), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

function PANEL:AddSetting(type, key, label, default, min, max)
    local settingPanel = vgui.Create("DPanel", self.ScrollPanel)
    settingPanel:Dock(TOP)
    settingPanel:SetTall(lyx.Scale(50))
    settingPanel:DockMargin(0, lyx.Scale(5), 0, 0)
    settingPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 40, 150))
    end
    
    -- Label
    local lbl = vgui.Create("DLabel", settingPanel)
    lbl:SetText(label)
    lbl:SetFont("LYX.Config.Text")
    lbl:SetTextColor(Color(200, 200, 200))
    lbl:SetPos(lyx.Scale(15), lyx.Scale(15))
    lbl:SizeToContents()
    
    local value = default
    local control
    
    if type == "bool" then
        control = vgui.Create("lyx.CheckBox2", settingPanel)
        control:SetPos(settingPanel:GetWide() - lyx.Scale(60), lyx.Scale(12))
        control:SetChecked(default)
        control.OnChange = function(s, val)
            value = val
            self:MarkUnsaved()
        end
    elseif type == "string" then
        control = vgui.Create("lyx.TextEntry2", settingPanel)
        control:SetSize(lyx.Scale(300), lyx.Scale(30))
        control:SetPos(settingPanel:GetWide() - lyx.Scale(320), lyx.Scale(10))
        control:SetText(default)
        control.OnChange = function(s)
            value = s:GetText()
            self:MarkUnsaved()
        end
    elseif type == "number" then
        control = vgui.Create("lyx.Slider2", settingPanel)
        control:SetSize(lyx.Scale(300), lyx.Scale(30))
        control:SetPos(settingPanel:GetWide() - lyx.Scale(320), lyx.Scale(10))
        control:SetMin(min or 0)
        control:SetMax(max or 100)
        control:SetValue(default)
        control:SetDecimals(0)
        control.OnValueChanged = function(s, val)
            value = math.Round(val)
            self:MarkUnsaved()
        end
    end
    
    self.Settings[key] = {
        control = control,
        value = value,
        default = default,
        type = type
    }
end

function PANEL:MarkUnsaved()
    self.HeaderPanel.SaveStatus = "unsaved"
end

function PANEL:SaveSettings()
    local settings = {}
    for key, data in pairs(self.Settings) do
        settings[key] = data.value
    end
    
    -- Send to server
    net.Start("lyx:config:save")
    net.WriteTable(settings)
    net.SendToServer()
    
    self.HeaderPanel.SaveStatus = "saved"
    notification.AddLegacy("Settings saved successfully!", NOTIFY_GENERIC, 3)
    
    -- If using lyx settings system
    if lyx.BulkSetSettings then
        lyx:BulkSetSettings(settings)
    end
end

function PANEL:ResetSettings()
    for key, data in pairs(self.Settings) do
        data.value = data.default
        if data.type == "bool" then
            data.control:SetChecked(data.default)
        elseif data.type == "string" then
            data.control:SetText(data.default)
        elseif data.type == "number" then
            data.control:SetValue(data.default)
        end
    end
    
    self:MarkUnsaved()
    notification.AddLegacy("Settings reset to default!", NOTIFY_GENERIC, 3)
end

function PANEL:ExportSettings()
    local settings = {}
    for key, data in pairs(self.Settings) do
        settings[key] = data.value
    end
    
    local json = util.TableToJSON(settings, true)
    SetClipboardText(json)
    notification.AddLegacy("Settings exported to clipboard!", NOTIFY_GENERIC, 3)
end

function PANEL:ImportSettings()
    Derma_StringRequest("Import Settings", "Paste JSON settings:", "", function(text)
        local success, settings = pcall(util.JSONToTable, text)
        if success and settings then
            for key, value in pairs(settings) do
                if self.Settings[key] then
                    self.Settings[key].value = value
                    local data = self.Settings[key]
                    if data.type == "bool" then
                        data.control:SetChecked(value)
                    elseif data.type == "string" then
                        data.control:SetText(value)
                    elseif data.type == "number" then
                        data.control:SetValue(value)
                    end
                end
            end
            self:MarkUnsaved()
            notification.AddLegacy("Settings imported successfully!", NOTIFY_GENERIC, 3)
        else
            notification.AddLegacy("Invalid JSON format!", NOTIFY_ERROR, 3)
        end
    end)
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, lyx.Colors.Background or Color(20, 20, 30))
end

vgui.Register("LYX.Pages.Config", PANEL)