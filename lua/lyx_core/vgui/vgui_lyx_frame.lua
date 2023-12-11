local PANEL = {}

function PANEL:Init()
    self:ShowCloseButton(false)
    self:SetTitle("")
    self:SetDraggable(true)

    self:TDLib()
    self:ClearPaint()
        :Background(lyx.Colors1["Primary"], 6)

    self.Navbar = self:Add("lyx_navbar")

    function self:ScaleW(size)
        return ScrW() * size/1920
    end

    function self:ScaleH(size)
        return ScrH() * size/1080
    end

end

function PANEL:CreateTopBar()
    local top = vgui.Create("DPanel", self)
    top:SetSize(self:GetWide(), self:ScaleH(40))
    top:SetPos(self:ScaleW(0), self:ScaleH(0))
    top:SetBackgroundColor(lyx.Colors1["Topbar"])

    local title = vgui.Create("DLabel", top)
    title:SetFont("lyx.font.title")
    title:SetText(self:GetTitle())
    title:SetTextColor(lyx.Colors1["White"])
    title:SetPos(self:ScaleW(10), self:ScaleH(5))
    title:SizeToContents()

    local whiteDivider = top:Add("DPanel")
    whiteDivider:Dock(BOTTOM)
    whiteDivider:SetTall(self:ScaleH(1))
    whiteDivider:TDLib()
    whiteDivider:ClearPaint()
        :Background(lyx.Colors1.White, 6)

    local close = vgui.Create("DImageButton", top)
    close:SetSize(self:ScaleW(40), self:ScaleH(40))
    close:SetPos(self:GetWide() - self:ScaleW(40), self:ScaleH(0))
    close:SetText("")
    close.DoClick = function()
        self:Remove()
    end
    close.Paint = function(self, w, h)
        surface.SetMaterial(lyx.Materials1["Cross"])
        surface.SetDrawColor(Color(255, 255, 255))
        surface.DrawTexturedRect(0, 0, w, h)
    end

end

function PANEL:ShowNavbar(bool)
    self.ShowNavbar = bool
end

function PANEL:Setup()
    -- Just setting up the panel itself.
    self:MakePopup()
    self:SetSize(ScrW() * 0.5, ScrH() * 0.5)
    self:Center()

    -- Lets create the frames elements.
    self:CreateTopBar()

    if self.ShowNavbar then
        self.Navbar:Setup()
    end
end


vgui.Register("lyx_frame", PANEL, "DFrame")

concommand.Add("lyx_frame", function()
    local frame = vgui.Create("lyx_frame")
    frame:ShowNavbar(true)
    frame:SetTitle("Lyx Library")

    -- Lets setup our navbar.
    frame.Navbar:AddButton("Player", lyx.Colors1.Primary, lyx.Icons.Player, function(pnl)
        pnl:Clear()
        
        local label = pnl:Add("DLabel")
        label:SetText("Player Options")
        label:SetFont("lyx.font.title")
        label:SetTextColor(lyx.Colors1.White)
        label:SetPos(lyx.Scaling.ScaleW(10), lyx.Scaling.ScaleH(5))
        label:SizeToContents()


        local playerOptions = vgui.Create("lyx_list", pnl)
        playerOptions:SetSize(pnl:GetWide() - lyx.Scaling.ScaleW(30), lyx.Scaling.ScaleH(240))
        playerOptions:SetPos(lyx.Scaling.ScaleW(15), lyx.Scaling.ScaleH(25))

        playerOptions:AddCheckbox("Toggle", {
            value = true,
            callback = function(box, value)
                chat.AddText("Toggled " .. tostring(value))
            end
        })
        playerOptions:AddSlider("Slider", {
            value = 2,
            min = 1,
            max = 3,
            callback = function(box, value)
                print("yo")
            end
        })
        playerOptions:AddButton("Button", {
            buttonText = "Send",
            callback = function(box, value)
                chat.AddText("Hello World!")
            end
        })
        playerOptions:AddEntry("Entry", {
            value = "Hello World!",
            callback = function(box, value)
                chat.AddText(value)
            end,
        })

        playerOptions:Setup()
    end)
    frame.Navbar:AddButton("Server", lyx.Colors1.Primary, lyx.Icons.Server, function(pnl)
        pnl:Clear()

        local label = pnl:Add("DLabel")
        label:SetText("Server Options")
        label:SetFont("lyx.font.title")
        label:SetTextColor(lyx.Colors1.White)
        label:SetPos(lyx.Scaling.ScaleW(10), lyx.Scaling.ScaleH(5))
        label:SizeToContents()


        local serverOptions = vgui.Create("lyx_list", pnl)
        serverOptions:SetSize(pnl:GetWide() - lyx.Scaling.ScaleW(30), lyx.Scaling.ScaleH(240))
        serverOptions:SetPos(lyx.Scaling.ScaleW(15), lyx.Scaling.ScaleH(25))

        serverOptions:AddButton("Chat Message", {
            buttonText = "Send",
            callback = function(box, value)
                chat.AddText("Hello World!")
            end
        })
        serverOptions:Setup()
    end)
    frame.Navbar:AddButton("World", lyx.Colors1.Primary, lyx.Icons.World, function(pnl)
        pnl:Clear()
    end)

    frame:Setup()
    frame.Navbar:SetTab(1)
end)

concommand.Add("lyx_popup", function()
    local frame = vgui.Create("lyx_popup")
    frame:SetTitle("Lyx Library")
    frame:Setup()
    frame:CreatePop()

    frame:CreateOptions({
        ["button1"] = {
            text = "Button 1",
            func = function()
                print("Button 1")
            end
        },
        ["button2"] = {
            text = "Button 2",
            func = function()
                print("Button 2")
            end
        }
    })
end)