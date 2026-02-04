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

function PANEL:AddPlayer(id)
    table.insert(self.Items, {Type = "player", ID = id})
end
function PANEL:AddTableItem(name, tbl)
    table.insert(self.Items, {Name = name, Type = "item", Data = tbl})
end

function PANEL:PlayerShowSteamID(bool)
    self.PlayerShowSteamID = bool
end

function PANEL:Setup()
    self:TDLib()
    self:ClearPaint()
        :Background(lyx.Colors1.Primary, 5)
        :Outline(lyx.Colors1.White,1)

    for k, v in pairs(self.Items) do
        if v.Type == "player" then
            local ply = player.GetBySteamID(v.ID)
            if !ply then continue end

            local container = self:Add("DPanel")
            container:Dock(TOP)
            container:DockMargin(5,5,5,5)
            container:SetTall(self:ScaleH(30))
            container:TDLib()
            container:ClearPaint()
                :Background(lyx.Colors1.Secondary, 0)
            
            local whiteDivider = container:Add("DPanel")
            whiteDivider:Dock(TOP)
            whiteDivider:SetTall(self:ScaleH(1))
            whiteDivider:TDLib()
            whiteDivider:ClearPaint()
                :Background(lyx.Colors1.White, 6)

            local av = container:Add("DPanel")
            av:Dock(LEFT)
            av:DockMargin(10,5,10,5)
            av:TDLib()
            av:CircleAvatar()
                :SetPlayer(ply)

            local title = container:Add("DLabel")
            title:SetFont("lyx.font.button")
            title:Dock(LEFT)
            title:SetTextColor(lyx.Colors1.White)
            title:SetText(ply:Nick())
            title:SizeToContents()

            if self.PlayerShowSteamID then
                local steamid = container:Add("lyx_button")
                steamid:Dock(RIGHT)
                steamid:DockMargin(10,5,10,5)
                steamid:SetSize(self:ScaleW(175), 0)
                steamid:SetText(ply:SteamID())
            end

        elseif v.Type == "item" then
            local container = self:Add("DPanel")
            container:Dock(TOP)
            container:DockMargin(5,5,5,5)
            container:SetTall(self:ScaleH(30))
            container:TDLib()
            container:ClearPaint()
                :Background(lyx.Colors1.Secondary, 0)
            
            local whiteDivider = container:Add("DPanel")
            whiteDivider:Dock(TOP)
            whiteDivider:SetTall(self:ScaleH(1))
            whiteDivider:TDLib()
            whiteDivider:ClearPaint()
                :Background(lyx.Colors1.White, 6)

            local title = container:Add("DLabel")
            title:SetFont("lyx.font.button")
            title:Dock(LEFT)
            title:DockMargin(15,0,15,0)
            title:SetText(v.Name)
            title:SetTextColor(lyx.Colors1.White)
            title:SizeToContents()
            
            local value = container:Add("DLabel")
            value:SetFont("lyx.font.button")
            value:Dock(RIGHT)
            value:DockMargin(15,0,15,0)
            value:SetText(v.Data.value)
            value:SetTextColor(lyx.Colors1.White)
            value:SizeToContents()

        end
    end
end

vgui.Register("lyx_table", PANEL, "DScrollPanel")