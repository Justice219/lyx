local PANEL = {}

function PANEL:Init()
    self:ShowNavbar(false)

end

function PANEL:CreateOptions(tbl)
    local button1 = vgui.Create("lyx_button", self)
    button1:SetText(tbl["button1"].text)
    button1:SetSize(self:GetWide() / 2 - 10, 30)
    button1:SetPos(lyx.Scaling.ScaleW(5), lyx.Scaling.ScaleH(30))
    button1:Inverse()
    button1.DoClick = function()
        tbl["button1"].func()
    end

    local button2 = vgui.Create("lyx_button", self)
    button2:SetText(tbl["button2"].text)
    button2:SetSize(self:GetWide() / 2 - 10, 30)
    button2:SetPos(self:GetWide() / 2 + 5, lyx.Scaling.ScaleH(30))
    button2:Inverse()
    button2.DoClick = function()
        tbl["button2"].func()
    end
end

function PANEL:CreatePop()
    -- Lets just modify the frame to make it look more like a popup
    self:SetSize(ScrW() * 0.2, ScrH() * 0.2)
    self:Center()

    -- Lets make sure the close button is visiblere
    self:CreateTopBar()
end


vgui.Register("lyx_popup", PANEL, "lyx_frame")