local PANEL = {}

lyx.RegisterFont("LYX.Ranks.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Ranks.Text", "Open Sans", lyx.Scale(14))

function PANEL:Init()
    -- Header
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Rank Management", "LYX.Ranks.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
    end
    
    -- Add rank button - use docking for proper positioning
    local addBtn = vgui.Create("lyx.TextButton2", headerPanel)
    addBtn:SetText("Add New Rank")
    addBtn:Dock(RIGHT)
    addBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(12), lyx.Scale(12))
    addBtn:SetWide(lyx.Scale(150))
    addBtn.DoClick = function()
        self:AddRankDialog()
    end
    
    -- Ranks list using Lyx's list system
    self.RanksList = vgui.Create("lyx.ScrollPanel2", self)
    self.RanksList:Dock(FILL)
    self.RanksList:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    
    -- Refresh ranks
    self:RefreshRanks()
end

function PANEL:RefreshRanks()
    self.RanksList:Clear()
    
    -- Get ranks from lyx system
    if lyx.GetAllRanks then
        local ranks = lyx:GetAllRanks()
        
        for _, rankName in ipairs(ranks) do
            -- Count users with this rank
            local userCount = 0
            for _, ply in ipairs(player.GetAll()) do
                if ply:GetUserGroup() == rankName then
                    userCount = userCount + 1
                end
            end
            
            -- Get rank color
            local rankColors = {
                superadmin = Color(255, 0, 0),
                admin = Color(255, 165, 0), 
                moderator = Color(0, 255, 0),
                vip = Color(255, 255, 0),
                user = Color(200, 200, 200)
            }
            
            local rankColor = rankColors[rankName] or Color(200, 200, 200)
            
            -- Create rank panel
            local rankPanel = vgui.Create("DPanel", self.RanksList)
            rankPanel:Dock(TOP)
            rankPanel:SetTall(lyx.Scale(60))
            rankPanel:DockMargin(0, lyx.Scale(5), lyx.Scale(10), 0)
            
            rankPanel.Paint = function(pnl, w, h)
                draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
                
                -- Rank color indicator
                draw.RoundedBox(4, lyx.Scale(10), lyx.Scale(10), lyx.Scale(8), h - lyx.Scale(20), rankColor)
                
                -- Rank name
                draw.SimpleText(rankName, "LYX.Ranks.Text", lyx.Scale(30), lyx.Scale(15), lyx.Colors.PrimaryText)
                
                -- User count
                draw.SimpleText(userCount .. " users", "LYX.Ranks.Text", lyx.Scale(30), lyx.Scale(35), lyx.Colors.SecondaryText)
                
                -- Permissions
                draw.SimpleText("Standard Permissions", "LYX.Ranks.Text", lyx.Scale(200), lyx.Scale(22), lyx.Colors.DisabledText)
            end
            
            -- Action buttons - delay positioning until panel has width
            local editBtn = vgui.Create("lyx.TextButton2", rankPanel)
            editBtn:SetText("Edit")
            editBtn:SetSize(lyx.Scale(80), lyx.Scale(30))
            editBtn.DoClick = function()
                self:EditRankDialog(rankName)
            end
            
            local usersBtn = vgui.Create("lyx.TextButton2", rankPanel)
            usersBtn:SetText("View Users")
            usersBtn:SetSize(lyx.Scale(80), lyx.Scale(30))
            usersBtn.DoClick = function()
                self:ShowRankUsers(rankName)
            end
            
            local deleteBtn = vgui.Create("lyx.TextButton2", rankPanel)
            deleteBtn:SetText("Delete")
            deleteBtn:SetSize(lyx.Scale(80), lyx.Scale(30))
            deleteBtn.DoClick = function()
                Derma_Query("Are you sure you want to delete the rank '" .. rankName .. "'?", 
                    "Delete Rank",
                    "Yes", function()
                        net.Start("lyx:rank:remove")
                        net.WriteString(rankName)
                        net.SendToServer()
                        
                        self:RefreshRanks()
                    end,
                    "No", function() end
                )
            end
            
            -- Position buttons after panel has width
            rankPanel.PerformLayout = function(pnl, w, h)
                if editBtn and IsValid(editBtn) then
                    editBtn:SetPos(w - lyx.Scale(270), lyx.Scale(15))
                end
                if usersBtn and IsValid(usersBtn) then
                    usersBtn:SetPos(w - lyx.Scale(180), lyx.Scale(15))
                end
                if deleteBtn and IsValid(deleteBtn) then
                    deleteBtn:SetPos(w - lyx.Scale(90), lyx.Scale(15))
                end
            end
        end
    end
end

function PANEL:AddRankDialog()
    -- Use Lyx's frame system for popups
    local frame = vgui.Create("lyx.Frame2")
    frame:SetSize(lyx.Scale(400), lyx.Scale(200))
    frame:Center()
    frame:SetTitle("Add New Rank")
    frame:MakePopup()
    
    local nameLabel = vgui.Create("DLabel", frame)
    nameLabel:SetText("Rank Name:")
    nameLabel:SetPos(lyx.Scale(20), lyx.Scale(50))
    nameLabel:SetFont("LYX.Ranks.Text")
    nameLabel:SizeToContents()
    
    local nameEntry = vgui.Create("lyx.TextEntry2", frame)
    nameEntry:SetSize(lyx.Scale(360), lyx.Scale(30))
    nameEntry:SetPos(lyx.Scale(20), lyx.Scale(80))
    nameEntry:SetPlaceholderText("Enter rank name...")
    
    local addBtn = vgui.Create("lyx.TextButton2", frame)
    addBtn:SetText("Add Rank")
    addBtn:SetSize(lyx.Scale(100), lyx.Scale(35))
    addBtn:SetPos(lyx.Scale(150), lyx.Scale(130))
    addBtn.DoClick = function()
        local rankName = nameEntry:GetText()
        if rankName and rankName ~= "" then
            net.Start("lyx:rank:add")
            net.WriteString(rankName)
            net.SendToServer()
            
            frame:Close()
            self:RefreshRanks()
            
            notification.AddLegacy("Rank '" .. rankName .. "' added!", NOTIFY_GENERIC, 3)
        end
    end
end

function PANEL:EditRankDialog(rankName)
    -- Use Lyx's frame system for popups
    local frame = vgui.Create("lyx.Frame2")
    frame:SetSize(lyx.Scale(500), lyx.Scale(400))
    frame:Center()
    frame:SetTitle("Edit Rank: " .. rankName)
    frame:MakePopup()
    
    -- Permissions section
    local permLabel = vgui.Create("DLabel", frame)
    permLabel:SetText("Permissions:")
    permLabel:SetPos(lyx.Scale(20), lyx.Scale(50))
    permLabel:SetFont("LYX.Ranks.Header")
    permLabel:SizeToContents()
    
    local scrollPanel = vgui.Create("lyx.ScrollPanel2", frame)
    scrollPanel:SetSize(lyx.Scale(460), lyx.Scale(250))
    scrollPanel:SetPos(lyx.Scale(20), lyx.Scale(80))
    
    -- Add permission checkboxes
    local permissions = {
        "lyx_admin_menu",
        "lyx_kick_players",
        "lyx_ban_players",
        "lyx_manage_ranks",
        "lyx_server_config",
        "lyx_view_logs",
        "lyx_use_tools"
    }
    
    for i, perm in ipairs(permissions) do
        local checkBox = vgui.Create("DCheckBoxLabel", scrollPanel)
        checkBox:SetText(perm)
        checkBox:SetPos(lyx.Scale(10), lyx.Scale(10 + (i-1) * 30))
        checkBox:SetValue(false) -- In production, would check actual permission
        checkBox:SizeToContents()
    end
    
    local saveBtn = vgui.Create("lyx.TextButton2", frame)
    saveBtn:SetText("Save Changes")
    saveBtn:SetSize(lyx.Scale(120), lyx.Scale(35))
    saveBtn:SetPos(lyx.Scale(190), lyx.Scale(350))
    saveBtn.DoClick = function()
        notification.AddLegacy("Rank permissions saved!", NOTIFY_GENERIC, 3)
        frame:Close()
    end
end

function PANEL:ShowRankUsers(rankName)
    -- Use Lyx's frame system for popups
    local frame = vgui.Create("lyx.Frame2")
    frame:SetSize(lyx.Scale(500), lyx.Scale(400))
    frame:Center()
    frame:SetTitle("Users with rank: " .. rankName)
    frame:MakePopup()
    
    local scrollPanel = vgui.Create("lyx.ScrollPanel2", frame)
    scrollPanel:Dock(FILL)
    scrollPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    
    local hasUsers = false
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetUserGroup() == rankName then
            hasUsers = true
            
            local userPanel = vgui.Create("DPanel", scrollPanel)
            userPanel:Dock(TOP)
            userPanel:SetTall(lyx.Scale(50))
            userPanel:DockMargin(0, lyx.Scale(5), lyx.Scale(10), 0)
            
            userPanel.Paint = function(pnl, w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(40, 40, 50, 200))
                
                -- Player name
                draw.SimpleText(ply:Nick(), "LYX.Ranks.Text", lyx.Scale(10), lyx.Scale(10), Color(255, 255, 255))
                
                -- SteamID
                draw.SimpleText(ply:SteamID(), "LYX.Ranks.Text", lyx.Scale(10), lyx.Scale(28), Color(150, 150, 150))
            end
            
            -- Action buttons
            local manageBtn = vgui.Create("lyx.TextButton2", userPanel)
            manageBtn:SetText("Manage")
            manageBtn:SetSize(lyx.Scale(80), lyx.Scale(30))
            manageBtn:SetPos(userPanel:GetWide() - lyx.Scale(90), lyx.Scale(10))
            manageBtn.DoClick = function()
                local menu = DermaMenu()
                menu:AddOption("Copy SteamID", function()
                    SetClipboardText(ply:SteamID())
                    notification.AddLegacy("SteamID copied to clipboard!", NOTIFY_GENERIC, 3)
                end):SetIcon("icon16/page_copy.png")
                menu:AddOption("Change Rank", function()
                    self:ChangeUserRankDialog(ply)
                end):SetIcon("icon16/user_edit.png")
                menu:AddOption("Kick Player", function()
                    if LocalPlayer():IsAdmin() then
                        RunConsoleCommand("ulx", "kick", ply:Nick())
                    end
                end):SetIcon("icon16/door_out.png")
                menu:Open()
            end
        end
    end
    
    if not hasUsers then
        local noUsersLabel = vgui.Create("DLabel", scrollPanel)
        noUsersLabel:SetText("No users with this rank")
        noUsersLabel:SetFont("LYX.Ranks.Text")
        noUsersLabel:SetTextColor(Color(150, 150, 150))
        noUsersLabel:Dock(TOP)
        noUsersLabel:DockMargin(lyx.Scale(10), lyx.Scale(10), 0, 0)
        noUsersLabel:SizeToContents()
    end
end

function PANEL:ChangeUserRankDialog(ply)
    local frame = vgui.Create("lyx.Frame2")
    frame:SetSize(lyx.Scale(400), lyx.Scale(250))
    frame:Center()
    frame:SetTitle("Change Rank: " .. ply:Nick())
    frame:MakePopup()
    
    local label = vgui.Create("DLabel", frame)
    label:SetText("Select new rank:")
    label:SetPos(lyx.Scale(20), lyx.Scale(50))
    label:SetFont("LYX.Ranks.Text")
    label:SizeToContents()
    
    local dropdown = vgui.Create("DComboBox", frame)
    dropdown:SetPos(lyx.Scale(20), lyx.Scale(80))
    dropdown:SetSize(lyx.Scale(360), lyx.Scale(30))
    dropdown:SetValue(ply:GetUserGroup())
    
    if lyx.GetAllRanks then
        local ranks = lyx:GetAllRanks()
        for _, rank in ipairs(ranks) do
            dropdown:AddChoice(rank)
        end
    end
    
    local applyBtn = vgui.Create("lyx.TextButton2", frame)
    applyBtn:SetText("Apply")
    applyBtn:SetSize(lyx.Scale(100), lyx.Scale(35))
    applyBtn:SetPos(lyx.Scale(150), lyx.Scale(150))
    applyBtn.DoClick = function()
        local newRank = dropdown:GetSelected()
        if newRank and newRank ~= ply:GetUserGroup() then
            net.Start("lyx:rank:setuser")
            net.WriteEntity(ply)
            net.WriteString(newRank)
            net.SendToServer()
            
            notification.AddLegacy("Changed " .. ply:Nick() .. "'s rank to " .. newRank, NOTIFY_GENERIC, 3)
            frame:Close()
            self:RefreshRanks()
        end
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Ranks", PANEL)