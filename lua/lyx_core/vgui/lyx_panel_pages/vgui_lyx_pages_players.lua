local PANEL = {}

lyx.RegisterFont("LYX.Players.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Players.Text", "Open Sans", lyx.Scale(14))

function PANEL:Init()
    -- Top controls
    local controlPanel = vgui.Create("DPanel", self)
    controlPanel:Dock(TOP)
    controlPanel:SetTall(lyx.Scale(60))
    controlPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    controlPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 40, 200))
        draw.SimpleText("Player Management", "LYX.Players.Header", lyx.Scale(15), lyx.Scale(20), Color(255, 255, 255))
    end
    
    -- Search box
    local searchBox = vgui.Create("lyx.TextEntry2", controlPanel)
    searchBox:SetSize(lyx.Scale(200), lyx.Scale(30))
    searchBox:SetPos(controlPanel:GetWide() - lyx.Scale(220), lyx.Scale(15))
    searchBox:SetPlaceholderText("Search players...")
    searchBox.OnChange = function(s)
        self:FilterPlayers(s:GetText())
    end
    
    -- Main player list
    self.PlayerList = vgui.Create("DListView", self)
    self.PlayerList:Dock(FILL)
    self.PlayerList:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    self.PlayerList:SetMultiSelect(false)
    
    -- Add columns
    self.PlayerList:AddColumn("Name"):SetWidth(lyx.Scale(200))
    self.PlayerList:AddColumn("SteamID"):SetWidth(lyx.Scale(150))
    self.PlayerList:AddColumn("Rank"):SetWidth(lyx.Scale(100))
    self.PlayerList:AddColumn("Ping"):SetWidth(lyx.Scale(60))
    self.PlayerList:AddColumn("Playtime"):SetWidth(lyx.Scale(100))
    self.PlayerList:AddColumn("Health"):SetWidth(lyx.Scale(60))
    self.PlayerList:AddColumn("Armor"):SetWidth(lyx.Scale(60))
    self.PlayerList:AddColumn("Kills"):SetWidth(lyx.Scale(60))
    self.PlayerList:AddColumn("Deaths"):SetWidth(lyx.Scale(60))
    
    -- Right-click menu
    self.PlayerList.OnRowRightClick = function(lst, index, row)
        local menu = DermaMenu()
        local ply = row.Player
        
        if not IsValid(ply) then return end
        
        menu:AddOption("Copy SteamID", function()
            SetClipboardText(ply:SteamID())
            notification.AddLegacy("SteamID copied to clipboard!", NOTIFY_GENERIC, 2)
        end):SetIcon("icon16/page_copy.png")
        
        menu:AddOption("Copy SteamID64", function()
            SetClipboardText(ply:SteamID64())
            notification.AddLegacy("SteamID64 copied to clipboard!", NOTIFY_GENERIC, 2)
        end):SetIcon("icon16/page_copy.png")
        
        menu:AddSpacer()
        
        menu:AddOption("View Profile", function()
            ply:ShowProfile()
        end):SetIcon("icon16/user.png")
        
        menu:AddOption("Spectate", function()
            RunConsoleCommand("ulx", "spectate", ply:Nick())
        end):SetIcon("icon16/eye.png")
        
        if LocalPlayer():GetUserGroup() == "admin" or LocalPlayer():GetUserGroup() == "superadmin" then
            menu:AddSpacer()
            
            local adminMenu = menu:AddSubMenu("Admin Actions")
            adminMenu:AddOption("Kick", function()
                Derma_StringRequest("Kick Player", "Enter kick reason:", "", function(reason)
                    RunConsoleCommand("ulx", "kick", ply:Nick(), reason)
                end)
            end):SetIcon("icon16/door_out.png")
            
            adminMenu:AddOption("Ban", function()
                Derma_StringRequest("Ban Player", "Enter ban duration (minutes, 0 = perma):", "60", function(time)
                    Derma_StringRequest("Ban Reason", "Enter ban reason:", "", function(reason)
                        RunConsoleCommand("ulx", "ban", ply:Nick(), time, reason)
                    end)
                end)
            end):SetIcon("icon16/delete.png")
            
            adminMenu:AddOption("Freeze", function()
                RunConsoleCommand("ulx", "freeze", ply:Nick())
            end):SetIcon("icon16/lock.png")
            
            adminMenu:AddOption("Teleport To", function()
                RunConsoleCommand("ulx", "goto", ply:Nick())
            end):SetIcon("icon16/arrow_right.png")
            
            adminMenu:AddOption("Bring", function()
                RunConsoleCommand("ulx", "bring", ply:Nick())
            end):SetIcon("icon16/arrow_left.png")
        end
        
        if LocalPlayer():GetUserGroup() == "superadmin" then
            menu:AddSpacer()
            
            local rankMenu = menu:AddSubMenu("Set Rank")
            local ranks = {"user", "vip", "moderator", "admin", "superadmin"}
            
            for _, rank in ipairs(ranks) do
                rankMenu:AddOption(rank:gsub("^%l", string.upper), function()
                    RunConsoleCommand("ulx", "adduser", ply:Nick(), rank)
                end):SetIcon("icon16/shield.png")
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
    local selectedLine = self.PlayerList:GetSelectedLine()
    local selectedPlayer = nil
    if selectedLine then
        local line = self.PlayerList:GetLine(selectedLine)
        if line then selectedPlayer = line.Player end
    end
    
    self.PlayerList:Clear()
    
    for _, ply in ipairs(player.GetAll()) do
        local line = self.PlayerList:AddLine(
            ply:Nick(),
            ply:SteamID(),
            ply:GetUserGroup(),
            ply:Ping(),
            string.NiceTime(ply.GetUTimeTotalTime and ply:GetUTimeTotalTime() or 0),
            ply:Health(),
            ply:Armor(),
            ply:Frags(),
            ply:Deaths()
        )
        line.Player = ply
        
        -- Color code based on rank
        local rankColors = {
            superadmin = Color(255, 0, 0),
            admin = Color(255, 100, 0),
            moderator = Color(0, 255, 0),
            vip = Color(255, 255, 0)
        }
        
        if rankColors[ply:GetUserGroup()] then
            for i = 1, 9 do
                line:SetColumnText(i, line:GetColumnText(i))
            end
            line.PaintOver = function(s, w, h)
                surface.SetDrawColor(rankColors[ply:GetUserGroup()].r, rankColors[ply:GetUserGroup()].g, rankColors[ply:GetUserGroup()].b, 20)
                surface.DrawRect(0, 0, w, h)
            end
        end
        
        -- Restore selection
        if selectedPlayer == ply then
            self.PlayerList:SelectItem(line)
        end
    end
end

function PANEL:FilterPlayers(search)
    search = search:lower()
    
    for k, line in ipairs(self.PlayerList:GetLines()) do
        local ply = line.Player
        if IsValid(ply) then
            local visible = search == "" or 
                           ply:Nick():lower():find(search, 1, true) or
                           ply:SteamID():lower():find(search, 1, true)
            line:SetVisible(visible)
        end
    end
end

function PANEL:OnRemove()
    timer.Remove("LyxPlayerListRefresh")
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, lyx.Colors.Background or Color(20, 20, 30))
end

vgui.Register("LYX.Pages.Players", PANEL)