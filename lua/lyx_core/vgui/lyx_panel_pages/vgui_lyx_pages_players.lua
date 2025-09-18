local PANEL = {}

lyx.RegisterFont("LYX.Players.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Players.Text", "Open Sans", lyx.Scale(14))

function PANEL:Init()
    self.PlayerData = {}
    
    -- Top controls
    local controlPanel = vgui.Create("DPanel", self)
    controlPanel:Dock(TOP)
    controlPanel:SetTall(lyx.Scale(60))
    controlPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    controlPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Player Management", "LYX.Players.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
        
        -- Player count
        local count = #player.GetAll()
        local max = game.MaxPlayers()
        draw.SimpleText(count .. "/" .. max .. " players", "LYX.Players.Text", w - lyx.Scale(320), lyx.Scale(22), lyx.Colors.SecondaryText)
    end
    
    -- Search box
    local searchBox = vgui.Create("lyx.TextEntry2", controlPanel)
    searchBox:Dock(RIGHT)
    searchBox:DockMargin(0, lyx.Scale(12), lyx.Scale(12), lyx.Scale(12))
    searchBox:SetWide(lyx.Scale(200))
    searchBox:SetPlaceholderText("Search players...")
    searchBox.OnChange = function(s)
        self:FilterPlayers(s:GetText())
    end
    
    -- Refresh button
    local refreshBtn = vgui.Create("lyx.TextButton2", controlPanel)
    refreshBtn:SetText("Refresh")
    refreshBtn:Dock(RIGHT)
    refreshBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(5), lyx.Scale(12))
    refreshBtn:SetWide(lyx.Scale(80))
    refreshBtn.DoClick = function()
        self:RefreshPlayers()
        notification.AddLegacy("Player list refreshed!", NOTIFY_GENERIC, 2)
    end
    
    -- Main player list panel
    local listPanel = vgui.Create("DPanel", self)
    listPanel:Dock(FILL)
    listPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    listPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
    end
    
    -- Use custom ListView
    self.PlayerList = vgui.Create("lyx.ListView2", listPanel)
    self.PlayerList:Dock(FILL)
    self.PlayerList:DockMargin(lyx.Scale(5), lyx.Scale(5), lyx.Scale(5), lyx.Scale(5))
    
    -- Add columns
    self.PlayerList:AddColumn("Name", lyx.Scale(200))
    self.PlayerList:AddColumn("SteamID", lyx.Scale(150))
    self.PlayerList:AddColumn("Rank", lyx.Scale(100))
    self.PlayerList:AddColumn("Ping", lyx.Scale(60))
    self.PlayerList:AddColumn("Playtime", lyx.Scale(100))
    self.PlayerList:AddColumn("Health", lyx.Scale(60))
    self.PlayerList:AddColumn("Armor", lyx.Scale(60))
    self.PlayerList:AddColumn("Kills", lyx.Scale(60))
    self.PlayerList:AddColumn("Deaths", lyx.Scale(60))
    
    -- Override row painting for rank colors
    local oldAddRow = self.PlayerList.AddRow
    self.PlayerList.AddRow = function(list, ...)
        local row = oldAddRow(list, ...)
        local values = {...}
        local rank = values[3] -- Rank is 3rd column
        
        -- Store player reference
        row.PlayerData = self.PlayerData[values[2]] -- Use SteamID as key
        
        -- Override paint for rank-based coloring
        local oldPaint = row.Paint
        row.Paint = function(pnl, w, h)
            -- Background
            local bgColor = lyx.Colors.Background
            
            if pnl == list.SelectedRow then
                bgColor = Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 40)
            elseif pnl:IsHovered() then
                bgColor = Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 20)
            end
            
            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            
            -- Rank color indicator
            local rankColor = lyx.Colors.SecondaryText
            if rank == "superadmin" then
                rankColor = Color(255, 0, 0)
            elseif rank == "admin" then
                rankColor = Color(255, 100, 0)
            elseif rank == "moderator" or rank == "operator" then
                rankColor = Color(0, 255, 0)
            elseif rank == "vip" then
                rankColor = Color(255, 255, 0)
            end
            
            -- Color bar on left
            draw.RoundedBox(2, 0, 0, lyx.Scale(3), h, rankColor)
            
            -- Draw values with rank highlighting
            local x = lyx.Scale(5)
            for i, header in ipairs(list.Headers) do
                local value = values[i] or ""
                local textColor = (i == 3) and rankColor or lyx.Colors.SecondaryText
                draw.SimpleText(tostring(value), "LYX.List.Text", x + lyx.Scale(10), h/2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                x = x + header.Width
            end
        end
        
        return row
    end
    
    -- Right-click menu
    self.PlayerList.OnRowRightClick = function(list, index, row)
        if not row.PlayerData then return end
        local ply = row.PlayerData.entity
        
        if not IsValid(ply) then 
            self:RefreshPlayers()
            return 
        end
        
        local menu = DermaMenu()
        
        -- Basic actions
        menu:AddOption("Copy SteamID", function()
            SetClipboardText(ply:SteamID())
            notification.AddLegacy("SteamID copied to clipboard!", NOTIFY_GENERIC, 2)
        end):SetIcon("icon16/page_copy.png")
        
        menu:AddOption("Copy SteamID64", function()
            SetClipboardText(ply:SteamID64())
            notification.AddLegacy("SteamID64 copied to clipboard!", NOTIFY_GENERIC, 2)
        end):SetIcon("icon16/page_copy.png")
        
        menu:AddOption("Copy Name", function()
            SetClipboardText(ply:Nick())
            notification.AddLegacy("Name copied to clipboard!", NOTIFY_GENERIC, 2)
        end):SetIcon("icon16/page_copy.png")
        
        menu:AddSpacer()
        
        menu:AddOption("View Profile", function()
            ply:ShowProfile()
        end):SetIcon("icon16/user.png")
        
        menu:AddOption("Spectate", function()
            RunConsoleCommand("ulx", "spectate", ply:Nick())
        end):SetIcon("icon16/eye.png")
        
        -- Admin actions
        if LocalPlayer():IsAdmin() then
            menu:AddSpacer()
            
            local adminMenu = menu:AddSubMenu("Admin Actions")
            adminMenu:SetIcon("icon16/shield.png")
            
            adminMenu:AddOption("Kick", function()
                Derma_StringRequest("Kick Player", "Enter kick reason:", "", function(reason)
                    net.Start("lyx:admin:kick")
                    net.WriteEntity(ply)
                    net.WriteString(reason or "No reason provided")
                    net.SendToServer()
                end)
            end):SetIcon("icon16/door_out.png")
            
            adminMenu:AddOption("Ban", function()
                Derma_StringRequest("Ban Player", "Enter ban duration (minutes, 0 = perma):", "60", function(time)
                    Derma_StringRequest("Ban Reason", "Enter ban reason:", "", function(reason)
                        net.Start("lyx:admin:ban")
                        net.WriteEntity(ply)
                        net.WriteUInt(tonumber(time) or 60, 16)
                        net.WriteString(reason or "No reason provided")
                        net.SendToServer()
                    end)
                end)
            end):SetIcon("icon16/delete.png")
            
            adminMenu:AddOption("Freeze", function()
                net.Start("lyx:admin:freeze")
                net.WriteEntity(ply)
                net.SendToServer()
            end):SetIcon("icon16/lock.png")
            
            adminMenu:AddOption("Teleport To", function()
                net.Start("lyx:admin:goto")
                net.WriteEntity(ply)
                net.SendToServer()
            end):SetIcon("icon16/arrow_right.png")
            
            adminMenu:AddOption("Bring", function()
                net.Start("lyx:admin:bring")
                net.WriteEntity(ply)
                net.SendToServer()
            end):SetIcon("icon16/arrow_left.png")
            
            adminMenu:AddOption("Return", function()
                net.Start("lyx:admin:return")
                net.WriteEntity(ply)
                net.SendToServer()
            end):SetIcon("icon16/arrow_undo.png")
            
            -- Punishment submenu
            local punishMenu = adminMenu:AddSubMenu("Punishments")
            
            punishMenu:AddOption("Slay", function()
                net.Start("lyx:admin:slay")
                net.WriteEntity(ply)
                net.SendToServer()
            end):SetIcon("icon16/bomb.png")
            
            punishMenu:AddOption("Slap", function()
                Derma_StringRequest("Slap Player", "Enter damage amount:", "10", function(damage)
                    net.Start("lyx:admin:slap")
                    net.WriteEntity(ply)
                    net.WriteUInt(tonumber(damage) or 10, 8)
                    net.SendToServer()
                end)
            end):SetIcon("icon16/hand_paper.png")
            
            punishMenu:AddOption("Ignite", function()
                Derma_StringRequest("Ignite Player", "Enter duration (seconds):", "10", function(duration)
                    net.Start("lyx:admin:ignite")
                    net.WriteEntity(ply)
                    net.WriteUInt(tonumber(duration) or 10, 8)
                    net.SendToServer()
                end)
            end):SetIcon("icon16/fire.png")
        end
        
        -- Superadmin actions
        if LocalPlayer():IsSuperAdmin() then
            menu:AddSpacer()
            
            local rankMenu = menu:AddSubMenu("Set Rank")
            rankMenu:SetIcon("icon16/user_edit.png")
            
            local ranks = {"user", "vip", "moderator", "operator", "admin", "superadmin"}
            
            for _, rank in ipairs(ranks) do
                local icon = "icon16/user.png"
                if rank == "superadmin" then icon = "icon16/user_red.png"
                elseif rank == "admin" then icon = "icon16/user_orange.png"
                elseif rank == "moderator" or rank == "operator" then icon = "icon16/user_green.png"
                elseif rank == "vip" then icon = "icon16/user_yellow.png"
                end
                
                rankMenu:AddOption(rank:gsub("^%l", string.upper), function()
                    net.Start("lyx:rank:setuser")
                    net.WriteEntity(ply)
                    net.WriteString(rank)
                    net.SendToServer()
                    
                    notification.AddLegacy("Changed " .. ply:Nick() .. "'s rank to " .. rank, NOTIFY_GENERIC, 3)
                    
                    timer.Simple(0.5, function()
                        if IsValid(self) then
                            self:RefreshPlayers()
                        end
                    end)
                end):SetIcon(icon)
            end
            
            menu:AddSpacer()
            
            -- Give weapons submenu
            local weaponMenu = menu:AddSubMenu("Give Weapon")
            weaponMenu:SetIcon("icon16/gun.png")
            
            local weapons = {
                {"Physgun", "weapon_physgun"},
                {"Tool Gun", "gmod_tool"},
                {"Gravity Gun", "weapon_physcannon"},
                {"Crowbar", "weapon_crowbar"},
                {"Stunstick", "weapon_stunstick"},
                {"Pistol", "weapon_pistol"},
                {"357", "weapon_357"},
                {"SMG", "weapon_smg1"},
                {"AR2", "weapon_ar2"},
                {"Shotgun", "weapon_shotgun"},
                {"Crossbow", "weapon_crossbow"},
                {"RPG", "weapon_rpg"},
            }
            
            for _, wep in ipairs(weapons) do
                weaponMenu:AddOption(wep[1], function()
                    net.Start("lyx:admin:giveweapon")
                    net.WriteEntity(ply)
                    net.WriteString(wep[2])
                    net.SendToServer()
                end)
            end
        end
        
        menu:Open()
    end
    
    -- Populate list
    self:RefreshPlayers()
    
    -- Auto-refresh timer
    timer.Create("LyxPlayerListRefresh", 1, 0, function()
        if IsValid(self) then
            self:RefreshPlayers()
        else
            timer.Remove("LyxPlayerListRefresh")
        end
    end)
end

function PANEL:RefreshPlayers()
    -- Store selected player
    local selectedRow = self.PlayerList:GetSelectedRow()
    local selectedSteamID = nil
    if selectedRow and selectedRow.PlayerData then
        selectedSteamID = selectedRow.PlayerData.steamid
    end
    
    self.PlayerList:Clear()
    self.PlayerData = {}
    
    for _, ply in ipairs(player.GetAll()) do
        local steamID = ply:SteamID()
        
        -- Store player data
        self.PlayerData[steamID] = {
            entity = ply,
            steamid = steamID,
            nick = ply:Nick(),
            rank = ply:GetUserGroup()
        }
        
        -- Add row
        local row = self.PlayerList:AddRow(
            ply:Nick(),
            steamID,
            ply:GetUserGroup(),
            ply:Ping(),
            string.NiceTime(ply.GetUTimeTotalTime and ply:GetUTimeTotalTime() or 0),
            ply:Health(),
            ply:Armor(),
            ply:Frags(),
            ply:Deaths()
        )
        
        -- Restore selection
        if selectedSteamID == steamID then
            self.PlayerList:SelectRow(row)
        end
    end
end

function PANEL:FilterPlayers(search)
    search = search:lower()
    
    for _, row in ipairs(self.PlayerList.Rows) do
        if row.PlayerData then
            local visible = search == "" or 
                           row.PlayerData.nick:lower():find(search, 1, true) or
                           row.PlayerData.steamid:lower():find(search, 1, true) or
                           row.PlayerData.rank:lower():find(search, 1, true)
            
            row:SetVisible(visible)
        end
    end
end

function PANEL:OnRemove()
    timer.Remove("LyxPlayerListRefresh")
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Players", PANEL)