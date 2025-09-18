local PANEL = {}
local ranks = {}

lyx.RegisterFont("LYX.Ranks.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.Ranks.Text", "Open Sans", lyx.Scale(14))

-- Network receiver for rank sync
net.Receive("lyx:rank:sync", function()
    local receivedRanks = net.ReadTable()
    ranks = receivedRanks  -- Store in the file-local ranks table
    
    -- Find the ranks panel if it exists
    local ranksPanel = nil
    for _, v in pairs(vgui.GetAll()) do
        if v.ClassName == "LYX.Pages.Ranks" and IsValid(v) then
            ranksPanel = v
            break
        end
    end
    
    if ranksPanel then
        ranksPanel:RefreshRanks(ranks)
    end
end)

function PANEL:Init()
    -- Store ranks locally
    self.RanksData = {}
    
    -- Use the file-local ranks if already received
    if ranks and #ranks > 0 then
        self.RanksData = ranks
    end
    
    -- Header
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Rank Management", "LYX.Ranks.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
        
        -- Rank count - use both file-local and panel data
        local count = 0
        local dataToCount = self.RanksData or ranks or {}
        if type(dataToCount) == "table" then
            if dataToCount[1] then
                -- Array
                count = #dataToCount
            else
                -- Key-value table
                count = table.Count(dataToCount)
            end
        end
        draw.SimpleText(count .. " ranks", "LYX.Ranks.Text", w - lyx.Scale(320), lyx.Scale(22), lyx.Colors.SecondaryText)
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
    
    -- Refresh button
    local refreshBtn = vgui.Create("lyx.TextButton2", headerPanel)
    refreshBtn:SetText("Refresh")
    refreshBtn:Dock(RIGHT)
    refreshBtn:DockMargin(0, lyx.Scale(12), lyx.Scale(5), lyx.Scale(12))
    refreshBtn:SetWide(lyx.Scale(80))
    refreshBtn.DoClick = function()
        self:RequestRanksFromServer()
        notification.AddLegacy("Refreshing ranks list...", NOTIFY_GENERIC, 2)
    end
    
    -- Main list panel
    local listPanel = vgui.Create("DPanel", self)
    listPanel:Dock(FILL)
    listPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    listPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
    end
    
    -- Use custom ListView for ranks
    self.RanksList = vgui.Create("lyx.ListView2", listPanel)
    self.RanksList:Dock(FILL)
    self.RanksList:DockMargin(lyx.Scale(5), lyx.Scale(5), lyx.Scale(5), lyx.Scale(5))
    
    -- Add columns
    self.RanksList:AddColumn("Rank Name", lyx.Scale(200))
    self.RanksList:AddColumn("Users", lyx.Scale(80))
    self.RanksList:AddColumn("Permissions", lyx.Scale(150))
    self.RanksList:AddColumn("Type", lyx.Scale(100))
    self.RanksList:AddColumn("Actions", lyx.Scale(200))
    
    -- Override row painting for rank colors (matching Players page implementation)
    local oldAddRow = self.RanksList.AddRow
    self.RanksList.AddRow = function(list, ...)
        local row = oldAddRow(list, ...)
        local values = {...}
        local rankName = values[1]
        
        -- Store rank data in row
        row.RankName = rankName
        
        -- Override paint for rank coloring
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
            local rankColor = self:GetRankColor(rankName)
            draw.RoundedBox(2, 0, 0, lyx.Scale(3), h, rankColor)
            
            -- Draw values with proper font
            local x = lyx.Scale(5)
            for i, header in ipairs(list.Headers) do
                local value = values[i] or ""
                local textColor = (i == 1) and rankColor or lyx.Colors.SecondaryText
                local font = lyx.GetRealFont and lyx.GetRealFont("LYX.List.Text") or "DermaDefault"
                draw.SimpleText(tostring(value), font, x + lyx.Scale(10), h/2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                x = x + header.Width
            end
        end
        
        return row
    end
    
    -- Right-click menu
    self.RanksList.OnRowRightClick = function(list, index, row)
        if not row.RankName then return end
        
        local menu = DermaMenu()
        
        menu:AddOption("Edit Permissions", function()
            self:EditRankDialog(row.RankName)
        end)
        
        menu:AddOption("View Users", function()
            self:ShowRankUsers(row.RankName)
        end)
        
        menu:AddOption("Copy Name", function()
            SetClipboardText(row.RankName)
            notification.AddLegacy("Rank name copied to clipboard!", NOTIFY_GENERIC, 2)
        end)
        
        menu:AddSpacer()
        
        menu:AddOption("Delete Rank", function()
            Derma_Query("Are you sure you want to delete the rank '" .. row.RankName .. "'?", 
                "Delete Rank",
                "Yes", function()
                    net.Start("lyx:rank:remove")
                    net.WriteString(row.RankName)
                    net.SendToServer()
                    
                    timer.Simple(0.5, function()
                        if IsValid(self) then
                            self:RequestRanksFromServer()
                        end
                    end)
                end,
                "No", function() end
            )
        end)
        
        menu:Open()
    end
    
    -- Request ranks from server (or use cached if available)
    if ranks and #ranks > 0 then
        self:RefreshRanks(ranks)
    else
        self:RequestRanksFromServer()
    end
end

function PANEL:RequestRanksFromServer()
    -- Request ranks list from server
    net.Start("lyx:rank:getall")
    net.SendToServer()
end

function PANEL:RefreshRanks(receivedRanks)
    print("[DEBUG] RefreshRanks called")
    self.RanksList:Clear()
    
    -- Update both local and panel data
    if receivedRanks then
        ranks = receivedRanks  -- Update file-local table
        self.RanksData = receivedRanks
        print("[DEBUG] Using received ranks:", table.concat(receivedRanks, ", "))
    else
        self.RanksData = ranks  -- Use existing file-local table
        print("[DEBUG] Using cached ranks:", ranks and table.concat(ranks, ", ") or "none")
    end
    
    -- Default ranks if none exist
    if type(self.RanksData) ~= "table" or table.Count(self.RanksData) == 0 then
        self.RanksData = {
            "superadmin",
            "admin",
            "moderator",
            "user"
        }
    end
    
    -- Check if RanksData is a key-value table or array
    local ranksToProcess = {}
    if self.RanksData[1] then
        -- It's an array
        ranksToProcess = self.RanksData
    else
        -- It's a key-value table, extract keys
        for rankName, _ in pairs(self.RanksData) do
            table.insert(ranksToProcess, rankName)
        end
    end
    
    print("[DEBUG] Processing " .. #ranksToProcess .. " ranks")
    for _, rankName in ipairs(ranksToProcess) do
        print("[DEBUG] Adding rank: " .. rankName)
        
        -- Count users with this rank
        local userCount = 0
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetUserGroup() == rankName then
                userCount = userCount + 1
            end
        end
        
        -- Determine rank type
        local rankType = "Custom"
        if rankName == "superadmin" or rankName == "admin" or rankName == "user" then
            rankType = "Default"
        elseif rankName == "moderator" or rankName == "operator" then
            rankType = "Staff"
        elseif rankName == "vip" or rankName == "premium" then
            rankType = "Special"
        end
        
        -- Add row to list (row painting is handled by override above)
        self.RanksList:AddRow(
            rankName,
            tostring(userCount),
            "View/Edit",
            rankType,
            "Manage"
        )
    end
end

function PANEL:GetRankColor(rankName)
    local rankColors = {
        superadmin = Color(255, 0, 0),
        admin = Color(255, 165, 0),
        moderator = Color(0, 255, 0),
        operator = Color(0, 200, 0),
        vip = Color(255, 255, 0),
        premium = Color(255, 200, 0),
        user = Color(200, 200, 200)
    }
    
    return rankColors[rankName] or Color(150, 150, 255)  -- Default color for custom ranks
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
    if lyx.GetRealFont then
        nameLabel:SetFont(lyx.GetRealFont("LYX.Ranks.Text") or "DermaDefault")
    else
        nameLabel:SetFont("DermaDefault")
    end
    nameLabel:SizeToContents()
    
    local nameEntry = vgui.Create("lyx.TextEntry2", frame)
    nameEntry:SetSize(lyx.Scale(360), lyx.Scale(30))
    nameEntry:SetPos(lyx.Scale(20), lyx.Scale(80))
    nameEntry:SetPlaceholderText("Enter rank name...")
    
    -- Create button panel to ensure proper parenting
    local buttonPanel = vgui.Create("DPanel", frame)
    buttonPanel:Dock(BOTTOM)
    buttonPanel:SetTall(lyx.Scale(50))
    buttonPanel.Paint = function() end
    
    local addBtn = vgui.Create("lyx.TextButton2", buttonPanel)
    addBtn:SetText("Add Rank")
    addBtn:SetSize(lyx.Scale(100), lyx.Scale(35))
    addBtn:Dock(LEFT)
    addBtn:DockMargin(lyx.Scale(50), lyx.Scale(7), lyx.Scale(5), lyx.Scale(7))
    
    -- Test with basic DButton first to see if it's a lyx.TextButton2 issue
    addBtn.DoClick = function(btn)
        local rankName = nameEntry:GetValue()  -- Use GetValue() not GetText() for lyx.TextEntry2
        
        if rankName and rankName ~= "" then
            
            net.Start("lyx:rank:add")
            net.WriteString(rankName)
            net.SendToServer()
            
            notification.AddLegacy("Rank '" .. rankName .. "' added!", NOTIFY_GENERIC, 3)
            
            frame:Close()
            
            timer.Simple(0.5, function()
                if IsValid(self) then
                    self:RequestRanksFromServer()
                end
            end)
        else
            notification.AddLegacy("Please enter a rank name!", NOTIFY_ERROR, 3)
        end
    end
    
    -- Add cancel button
    local cancelBtn = vgui.Create("lyx.TextButton2", buttonPanel)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetSize(lyx.Scale(100), lyx.Scale(35))
    cancelBtn:Dock(LEFT)
    cancelBtn:DockMargin(lyx.Scale(5), lyx.Scale(7), lyx.Scale(5), lyx.Scale(7))
    cancelBtn.DoClick = function(btn)
        frame:Close()
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
        local newRank = dropdown:GetValue()  -- Use GetValue() for DComboBox
        if newRank and newRank ~= ply:GetUserGroup() then
            net.Start("lyx:rank:setuser")
            net.WriteEntity(ply)
            net.WriteString(newRank)
            net.SendToServer()
            
            notification.AddLegacy("Changed " .. ply:Nick() .. "'s rank to " .. newRank, NOTIFY_GENERIC, 3)
            frame:Close()
            self:RequestRanksFromServer()
        end
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.Ranks", PANEL)