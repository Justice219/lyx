local PANEL = {}

lyx.RegisterFont("LYX.SQL.Header", "Open Sans SemiBold", lyx.Scale(18))
lyx.RegisterFont("LYX.SQL.Text", "Courier New", lyx.Scale(14))

function PANEL:Init()
    local headerPanel = vgui.Create("DPanel", self)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(lyx.Scale(60))
    headerPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    headerPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("SQL Manager", "LYX.SQL.Header", lyx.Scale(15), lyx.Scale(20), lyx.Colors.PrimaryText)
        
        -- Connection status
        local connected = sql.TableExists("lyx_settings") -- Check if connected by looking for lyx table
        local statusColor = connected and Color(46, 204, 113) or Color(231, 76, 60)
        local statusText = connected and "● Connected" or "● Disconnected"
        draw.SimpleText(statusText, "LYX.SQL.Text", w - lyx.Scale(100), lyx.Scale(22), statusColor)
    end
    
    -- Query input area
    local queryPanel = vgui.Create("DPanel", self)
    queryPanel:Dock(TOP)
    queryPanel:SetTall(lyx.Scale(150))
    queryPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
    queryPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
    end
    
    local queryLabel = vgui.Create("DLabel", queryPanel)
    queryLabel:SetText("SQL Query:")
    queryLabel:SetFont("LYX.SQL.Text")
    queryLabel:SetTextColor(lyx.Colors.SecondaryText)
    queryLabel:SetPos(lyx.Scale(10), lyx.Scale(5))
    queryLabel:SizeToContents()
    
    local queryInput = vgui.Create("DTextEntry", queryPanel)
    queryInput:SetPos(lyx.Scale(10), lyx.Scale(30))
    queryInput:SetSize(queryPanel:GetWide() - lyx.Scale(20), lyx.Scale(70))
    queryInput:SetMultiline(true)
    queryInput:SetFont("LYX.SQL.Text")
    queryInput:SetText("SELECT * FROM ")
    
    -- Execute button
    local execBtn = vgui.Create("lyx.TextButton2", queryPanel)
    execBtn:SetText("Execute Query")
    execBtn:SetSize(lyx.Scale(120), lyx.Scale(30))
    execBtn:SetPos(lyx.Scale(10), lyx.Scale(110))
    execBtn.DoClick = function()
        local query = queryInput:GetText()
        if query and query ~= "" then
            self:ExecuteQuery(query)
        end
    end
    
    -- Clear button
    local clearBtn = vgui.Create("lyx.TextButton2", queryPanel)
    clearBtn:SetText("Clear")
    clearBtn:SetSize(lyx.Scale(80), lyx.Scale(30))
    clearBtn:SetPos(lyx.Scale(140), lyx.Scale(110))
    clearBtn.DoClick = function()
        queryInput:SetText("")
        if self.ResultsList then
            self.ResultsList:Clear()
        end
    end
    
    -- Results area
    local resultsPanel = vgui.Create("DPanel", self)
    resultsPanel:Dock(FILL)
    resultsPanel:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    resultsPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText("Query Results:", "LYX.SQL.Text", lyx.Scale(10), lyx.Scale(5), lyx.Colors.SecondaryText)
    end
    
    self.ResultsList = vgui.Create("DListView", resultsPanel)
    self.ResultsList:Dock(FILL)
    self.ResultsList:DockMargin(lyx.Scale(10), lyx.Scale(30), lyx.Scale(10), lyx.Scale(10))
    self.ResultsList:SetMultiSelect(false)
    
    -- Quick queries panel
    local quickPanel = vgui.Create("DPanel", self)
    quickPanel:Dock(RIGHT)
    quickPanel:SetWide(lyx.Scale(200))
    quickPanel:DockMargin(0, lyx.Scale(10), lyx.Scale(10), lyx.Scale(10))
    quickPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
        draw.SimpleText("Quick Queries", "LYX.SQL.Text", lyx.Scale(10), lyx.Scale(10), lyx.Colors.PrimaryText)
    end
    
    local queries = {
        {"Show Tables", "SELECT name FROM sqlite_master WHERE type='table'"},
        {"Lyx Settings", "SELECT * FROM lyx_settings"},
        {"Lyx Ranks", "SELECT * FROM lyx_ranks"},
        {"Player Data", "SELECT * FROM lyx_players"},
    }
    
    for i, q in ipairs(queries) do
        local btn = vgui.Create("lyx.TextButton2", quickPanel)
        btn:SetText(q[1])
        btn:SetSize(lyx.Scale(180), lyx.Scale(30))
        btn:SetPos(lyx.Scale(10), lyx.Scale(30 + (i-1) * 35))
        btn.DoClick = function()
            queryInput:SetText(q[2])
            self:ExecuteQuery(q[2])
        end
    end
end

function PANEL:ExecuteQuery(query)
    -- Safety check - only allow SELECT queries for non-superadmins
    if LocalPlayer():GetUserGroup() ~= "superadmin" then
        query = string.Trim(query)
        if not string.StartWith(string.lower(query), "select") then
            notification.AddLegacy("Only SELECT queries are allowed!", NOTIFY_ERROR, 3)
            return
        end
    end
    
    -- Clear previous results
    self.ResultsList:Clear()
    
    -- Execute query
    local result = sql.Query(query)
    
    if result == false then
        -- Query failed
        local error = sql.LastError()
        notification.AddLegacy("SQL Error: " .. error, NOTIFY_ERROR, 5)
        return
    elseif result == nil then
        -- Query succeeded but returned no rows
        notification.AddLegacy("Query executed successfully (no results)", NOTIFY_GENERIC, 3)
        return
    elseif type(result) == "table" then
        -- Query returned results
        notification.AddLegacy("Query returned " .. #result .. " rows", NOTIFY_GENERIC, 3)
        
        -- Add columns
        if #result > 0 then
            for k, v in pairs(result[1]) do
                self.ResultsList:AddColumn(k)
            end
            
            -- Add rows
            for _, row in ipairs(result) do
                local values = {}
                for k, v in pairs(row) do
                    table.insert(values, tostring(v))
                end
                self.ResultsList:AddLine(unpack(values))
            end
        end
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Background)
end

vgui.Register("LYX.Pages.SQL", PANEL)