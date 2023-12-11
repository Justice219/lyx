local PANEL = {}

function PANEL:Init()
    self.Items = {}

    function self:ScaleW(size)
        return ScrW() * size/1920
    end

    function self:ScaleH(size)
        return ScrH() * size/1080
    end
end

function PANEL:Setup()
        self:TDLib()
        self:ClearPaint()
        if self.ListRounded then
            self:Background(lyx.Colors1.Primary, self.ListRoundedSize)
        else
            self:Background(lyx.Colors1.Primary, 0)
        end

        if self.ShowListOutline then
            self:Outline(lyx.Colors1.White, self.ListOutlineRadius)
        end

    for k,v in pairs(self.Items) do
        if v.Type == "checkbox" then
            local container = self:Add("DPanel")
            container:Dock(TOP)
            container:DockMargin(5,5,5,5)
            container:SetTall(self:ScaleH(60))
            container:TDLib()
            container:ClearPaint()
                :Background(lyx.Colors1.Secondary, 5)

            local whiteDivider = container:Add("DPanel")
            whiteDivider:Dock(TOP)
            whiteDivider:SetTall(self:ScaleH(2))
            whiteDivider:TDLib()
            whiteDivider:ClearPaint()
                :Background(lyx.Colors1.White, 6)

            local title = container:Add("DLabel")
            title:SetFont("lyx.font.button")
            title:SetTextColor(lyx.Colors1.White)
            title:SetText(v.Name)
            title:Dock(LEFT)
            title:DockMargin(self:ScaleW(15),0,self:ScaleW(15),0)
            title:SizeToContents()

            local checkbox = container:Add("DCheckBox")
            -- Set checkbox all the way to the right
            
            checkbox:Dock(RIGHT)
            checkbox:DockMargin(15,15,10,15)
            checkbox:SetValue(v.Data.value)
            checkbox:TDLib()
            checkbox:ClearPaint()
                :CircleCheckbox(lyx.Colors1.Green)
            function checkbox:OnChange(val)
                v.Data.callback(checkbox, val)        
            end
            
        elseif v.Type == "slider" then
            local container = self:Add("DPanel")
            container:Dock(TOP)
            container:DockMargin(5,5,5,5)
            container:SetTall(self:ScaleH(60))
            container:TDLib()
            container:ClearPaint()
                :Background(lyx.Colors1.Secondary, 5)

            local title = container:Add("DLabel")
            title:SetFont("lyx.font.button")
            title:SetTextColor(lyx.Colors1.White)
            title:SetText(v.Name)
            title:Dock(LEFT)
            title:DockMargin(self:ScaleW(15),0,self:ScaleW(15),0)
            title:SizeToContents()

            local whiteDivider = container:Add("DPanel")
            whiteDivider:Dock(TOP)
            whiteDivider:SetTall(self:ScaleH(2))
            whiteDivider:TDLib()
            whiteDivider:ClearPaint()
                :Background(lyx.Colors1.White, 6)

            local slider = container:Add("DNumSlider")
            slider:Dock(RIGHT)
            slider:DockMargin(self:ScaleW(15),self:ScaleH(15),self:ScaleW(10),self:ScaleH(15))
            slider:SetMin(v.Data.min)
            slider:SetMax(v.Data.max)
            slider:SetValue(v.Data.value)
            slider:SetSize(self:ScaleW(100),0)
            slider.OnValueChanged = function(val)
                v.Data.callback(slider, val)
            end
            slider:TDLib()
            slider:ClearPaint()
                :Background(lyx.Colors1.Primary, 5)
        elseif v.Type == "button" then
            local container = self:Add("DPanel")
            container:Dock(TOP)
            container:DockMargin(5,5,5,5)
            container:SetTall(self:ScaleH(60))
            container:TDLib()
            container:ClearPaint()
                :Background(lyx.Colors1.Secondary, 5)

            local whiteDivider = container:Add("DPanel")
            whiteDivider:Dock(TOP)
            whiteDivider:SetTall(self:ScaleH(2))
            whiteDivider:TDLib()
            whiteDivider:ClearPaint()
                :Background(lyx.Colors1.White, 6)

            local title = container:Add("DLabel")
            title:SetFont("lyx.font.button")
            title:SetTextColor(lyx.Colors1.White)
            title:SetText(v.Name)
            title:Dock(LEFT)
            title:DockMargin(self:ScaleW(15),0,self:ScaleW(15),0)
            title:SizeToContents()

            local button = container:Add("lyx_button")
            button:SetText(v.Data.buttonText)
            button:Dock(RIGHT)
            button:DockMargin(self:ScaleW(15),self:ScaleH(15),self:ScaleW(10),self:ScaleH(15))
            button:SetSize(self:ScaleW(100),0)
            button.DoClick = function()
                v.Data.callback(button)
            end
            button:SetFont("lyx.font.button")
        elseif v.Type == "entry" then

            local container = self:Add("DPanel")
            container:Dock(TOP)
            container:DockMargin(5,5,5,5)
            container:SetTall(self:ScaleH(60))
            container:TDLib()
            container:ClearPaint()
                :Background(lyx.Colors1.Secondary, 5)

            local whiteDivider = container:Add("DPanel")
            whiteDivider:Dock(TOP)
            whiteDivider:SetTall(self:ScaleH(2))
            whiteDivider:TDLib()
            whiteDivider:ClearPaint()
                :Background(lyx.Colors1.White, 6)
            
            local title = container:Add("DLabel")
            title:SetFont("lyx.font.button")
            title:SetTextColor(lyx.Colors1.White)
            title:SetText(v.Name)
            title:Dock(LEFT)
            title:DockMargin(self:ScaleW(15),0,self:ScaleW(15),0)
            title:SizeToContents()

            local entry = container:Add("lyx_entry")
            entry:Dock(RIGHT)
            entry:DockMargin(self:ScaleW(15),self:ScaleH(15),self:ScaleW(10),self:ScaleH(15))
            entry:SetText(v.Data.value)
            entry:SetUpdateOnType(true)
            entry:SetSize(self:ScaleW(100),0)
            entry.OnValueChange = function(self)
                v.Data.callback(entry, self:GetValue())
            end
            entry:SetFont("lyx.font.button")
        end     
    end
end

function PANEL:ShowListOutline(bool, radius)
    self.ShowListOutline = bool
    self.ListOutlineRadius = radius
end

function PANEL:ListRounded(bool, size)
    self.ListRounded = bool
    self.ListRoundedSize = size
end

function PANEL:AddCheckbox(name, tbl)
    table.insert(self.Items, {Name = name, Type = "checkbox", Data = tbl})
end
function PANEL:AddSlider(name, tbl)
    table.insert(self.Items, {Name = name, Type = "slider", Data = tbl})
end
function PANEL:AddButton(name, tbl)
    table.insert(self.Items, {Name = name, Type = "button", Data = tbl})
end
function PANEL:AddEntry(name, tbl)
    table.insert(self.Items, {Name = name, Type = "entry", Data = tbl})
end

-- Used to clear all items in the panel so it can be re-used
function PANEL:ClearItems()
    self.Items = {}
end

vgui.Register("lyx_list", PANEL, "DScrollPanel")