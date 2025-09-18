local PANEL = {}

lyx.RegisterFont("LYX.List.Header", "Open Sans SemiBold", lyx.Scale(14))
lyx.RegisterFont("LYX.List.Text", "Open Sans", lyx.Scale(13))

function PANEL:Init()
    self.Headers = {}
    self.Rows = {}
    self.SelectedRow = nil
    self.SortColumn = 1
    self.SortDescending = false
    
    -- Header panel
    self.HeaderPanel = vgui.Create("DPanel", self)
    self.HeaderPanel:Dock(TOP)
    self.HeaderPanel:SetTall(lyx.Scale(35))
    self.HeaderPanel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        
        -- Draw column separators
        local x = 0
        for i, header in ipairs(self.Headers) do
            x = x + header.Width
            if i < #self.Headers then
                surface.SetDrawColor(lyx.Colors.Background.r, lyx.Colors.Background.g, lyx.Colors.Background.b, lyx.Colors.Background.a)
                surface.DrawRect(x - 1, lyx.Scale(5), 2, h - lyx.Scale(10))
            end
        end
    end
    
    -- Scroll panel for rows
    self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
    self.ScrollPanel:Dock(FILL)
    self.ScrollPanel:DockMargin(0, lyx.Scale(5), 0, 0)
    
    self.RowContainer = vgui.Create("DPanel", self.ScrollPanel)
    self.RowContainer:Dock(TOP)
    self.RowContainer:SetTall(0)
    self.RowContainer.Paint = function() end
end

function PANEL:AddColumn(name, width)
    width = width or lyx.Scale(100)
    
    local header = {
        Name = name,
        Width = width,
        Index = #self.Headers + 1
    }
    
    table.insert(self.Headers, header)
    
    -- Create header button
    local btn = vgui.Create("DButton", self.HeaderPanel)
    btn:SetText("")
    btn:SetPos(self:GetHeaderX(header.Index), 0)
    btn:SetSize(width, lyx.Scale(35))
    btn.Paint = function(pnl, w, h)
        local hover = pnl:IsHovered()
        
        if hover then
            draw.RoundedBox(0, 0, 0, w, h, Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 20))
        end
        
        -- Draw text
        draw.SimpleText(name, "LYX.List.Header", lyx.Scale(10), h/2, lyx.Colors.PrimaryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Draw sort indicator
        if self.SortColumn == header.Index then
            local indicator = self.SortDescending and "▼" or "▲"
            draw.SimpleText(indicator, "LYX.List.Header", w - lyx.Scale(10), h/2, lyx.Colors.SecondaryText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    
    btn.DoClick = function()
        self:SortByColumn(header.Index)
    end
    
    header.Button = btn
    
    return header
end

function PANEL:GetHeaderX(index)
    local x = 0
    for i = 1, index - 1 do
        if self.Headers[i] then
            x = x + self.Headers[i].Width
        end
    end
    return x
end

function PANEL:AddRow(...)
    local values = {...}
    
    local row = vgui.Create("DButton", self.RowContainer)
    row:Dock(TOP)
    row:SetTall(lyx.Scale(35))
    row:DockMargin(0, 0, 0, lyx.Scale(2))
    row:SetText("")
    row.Values = values
    row.Index = #self.Rows + 1
    
    row.Paint = function(pnl, w, h)
        -- Background
        local bgColor = lyx.Colors.Background
        
        if pnl == self.SelectedRow then
            bgColor = Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 40)
        elseif pnl:IsHovered() then
            bgColor = Color(lyx.Colors.Primary.r, lyx.Colors.Primary.g, lyx.Colors.Primary.b, 20)
        end
        
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        
        -- Draw values
        local x = 0
        for i, header in ipairs(self.Headers) do
            local value = values[i] or ""
            draw.SimpleText(tostring(value), "LYX.List.Text", x + lyx.Scale(10), h/2, lyx.Colors.SecondaryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            x = x + header.Width
        end
    end
    
    row.DoClick = function()
        self:SelectRow(row)
    end
    
    row.DoRightClick = function()
        if self.OnRowRightClick then
            self:OnRowRightClick(row.Index, row)
        end
    end
    
    table.insert(self.Rows, row)
    
    -- Update container height
    self.RowContainer:SetTall(#self.Rows * (lyx.Scale(35) + lyx.Scale(2)))
    
    return row
end

function PANEL:Clear()
    for _, row in ipairs(self.Rows) do
        if IsValid(row) then
            row:Remove()
        end
    end
    
    self.Rows = {}
    self.SelectedRow = nil
    self.RowContainer:SetTall(0)
end

function PANEL:SelectRow(row)
    self.SelectedRow = row
    
    if self.OnRowSelected then
        self:OnRowSelected(row.Index, row)
    end
end

function PANEL:SortByColumn(column)
    if self.SortColumn == column then
        self.SortDescending = not self.SortDescending
    else
        self.SortColumn = column
        self.SortDescending = false
    end
    
    -- Sort the rows
    table.sort(self.Rows, function(a, b)
        local valA = a.Values[column] or ""
        local valB = b.Values[column] or ""
        
        -- Try to compare as numbers first
        local numA, numB = tonumber(valA), tonumber(valB)
        if numA and numB then
            if self.SortDescending then
                return numA > numB
            else
                return numA < numB
            end
        end
        
        -- Compare as strings
        if self.SortDescending then
            return tostring(valA) > tostring(valB)
        else
            return tostring(valA) < tostring(valB)
        end
    end)
    
    -- Reorder visually
    for i, row in ipairs(self.Rows) do
        row:SetZPos(i)
    end
end

function PANEL:GetSelectedRow()
    return self.SelectedRow
end

function PANEL:GetRowCount()
    return #self.Rows
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
end

vgui.Register("lyx.ListView", PANEL)