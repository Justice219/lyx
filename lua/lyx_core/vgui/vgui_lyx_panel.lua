lyx = lyx

function lyx:Menu()
    local frame = vgui.Create("lyx_frame")
    frame:ShowNavbar(true)
    frame:SetTitle("Lyx Library v2.0")

    -- Lets setup our navbar.
    frame.Navbar:AddButton("Video", lyx.Colors1.Primary, lyx.Icons1.Player, function(pnl)
        pnl:Clear()
        local ply = nil
        local url = "https://www.youtube.com/watch?v=OqBuXQLR4Y8&ab_channel=RexOrangeCounty"
        
        local label = pnl:Add("DLabel")
        label:SetText("Video Player")
        label:SetFont("lyx.font.title")
        label:SetTextColor(lyx.Colors1.White)
        label:SetPos(lyx.Scaling1.ScaleW(10), lyx.Scaling1.ScaleH(5))
        label:SizeToContents()

        local videoOptions = vgui.Create("lyx_list", pnl)
        videoOptions:SetSize(pnl:GetWide() - lyx.Scaling1.ScaleW(30), lyx.Scaling1.ScaleH(100))
        videoOptions:SetPos(lyx.Scaling1.ScaleW(15), lyx.Scaling1.ScaleH(25))

        videoOptions:AddEntry("Video URL", {
            value = "https://www.youtube.com/watch?v=OqBuXQLR4Y8&ab_channel=RexOrangeCounty",
            callback = function(box, value)
                url = value
            end,
        })
        videoOptions:Setup()

        local playerOptions = vgui.Create("lyx_list", pnl)
        playerOptions:SetSize(pnl:GetWide() - lyx.Scaling1.ScaleW(30), lyx.Scaling1.ScaleH(100))
        playerOptions:SetPos(lyx.Scaling1.ScaleW(15), lyx.Scaling1.ScaleH(120))

        for k,v in pairs(player.GetAll()) do
            playerOptions:AddButton(v:SteamID64() .. ":" .. v:Nick(), {
                buttonText = "Select",
                callback = function(box, value)
                    ply = v
                    chat.AddText(lyx.Colors1.Red, "[LYX] ", lyx.Colors1.White, "Selected " .. v:Nick())
                end
            })
        end
        playerOptions:Setup()

        local sendToPlayer = pnl:Add("lyx_button")
        sendToPlayer:SetText("Send to Player")
        sendToPlayer:SetPos(lyx.Scaling1.ScaleW(10), lyx.Scaling1.ScaleH(230))
        sendToPlayer:SetSize(lyx.Scaling1.ScaleW(1240), lyx.Scaling1.ScaleH(15))
        sendToPlayer.DoClick = function()
            if ply then
                net.Start("lyx:panel:video")
                    net.WriteEntity(ply)
                    net.WriteString(url)
                net.SendToServer()
            end
        end

        local button = pnl:Add("lyx_button")
        button:SetText("Play Globally")
        button:SetPos(lyx.Scaling1.ScaleW(10), lyx.Scaling1.ScaleH(250))
        button:SetSize(lyx.Scaling1.ScaleW(1240), lyx.Scaling1.ScaleH(15))
        button.DoClick = function()
            net.Start("lyx:panel:video")
                net.WriteEntity(nil)
                net.WriteString(url)
            net.SendToServer()
        end

        
    end)
    frame.Navbar:AddButton("Ranks", lyx.Colors.Primary, lyx.Icons1.Server, function(pnl)
        pnl:Clear()
        local r = "admin"

        local label = pnl:Add("DLabel")
        label:SetText("Panel Rank Options")
        label:SetFont("lyx.font.title")
        label:SetTextColor(lyx.Colors.White)
        label:SetPos(lyx.Scaling1.ScaleW(10), lyx.Scaling1.ScaleH(5))
        label:SizeToContents()


        local rankOptions = vgui.Create("lyx_list", pnl)
        rankOptions:SetSize(pnl:GetWide() - lyx.Scaling1.ScaleW(30), lyx.Scaling1.ScaleH(40))
        rankOptions:SetPos(lyx.Scaling1.ScaleW(15), lyx.Scaling1.ScaleH(25))

        rankOptions:AddEntry("Rank Name", {
            value = "admin",
            callback = function(box, value)
                r = value
            end,
        })
        rankOptions:Setup()

        local button = pnl:Add("lyx_button")
        button:SetText("Add Rank")
        button:SetPos(lyx.Scaling1.ScaleW(10), lyx.Scaling1.ScaleH(70))
        button:SetSize(lyx.Scaling1.ScaleW(1235), lyx.Scaling1.ScaleH(15))
        button.DoClick = function()
            if r then
                net.Start("lyx:rank:add")
                    net.WriteString(r)
                net.SendToServer()
                chat.AddText(lyx.Colors.Red, "[LYX] ", lyx.Colors.White, "Added rank " .. r)
                frame:Remove()
                timer.Simple(0.1, function()
                    lyx:Menu()
                end)
            end
        end

        local rankList = vgui.Create("lyx_list", pnl)
        rankList:SetSize(pnl:GetWide() - lyx.Scaling1.ScaleW(30), lyx.Scaling1.ScaleH(150))
        rankList:SetPos(lyx.Scaling1.ScaleW(15), lyx.Scaling1.ScaleH(90))
        for k,v in pairs(lyx.ranks.ranks) do
            rankList:AddButton(k, {
                buttonText = "Select",
                callback = function(box, value)
                    r = k
                    chat.AddText(lyx.Colors1.Red, "[LYX] ", lyx.Colors1.White, "Selected rank " .. k .. " for deletion.")
                end
            })
        end
        rankList:Setup()

        local button2 = pnl:Add("lyx_button")
        button2:SetText("Remove Rank")
        button2:SetPos(lyx.Scaling1.ScaleW(10), lyx.Scaling1.ScaleH(245))
        button2:SetSize(lyx.Scaling1.ScaleW(1235), lyx.Scaling1.ScaleH(15))
        button2.DoClick = function()
            net.Start("lyx:rank:remove")
                net.WriteString(r)
            net.SendToServer()
            frame:Remove()
        end
    end)
    frame.Navbar:AddButton("Addons", lyx.Colors1.Primary, lyx.Icons1.Server, function(pnl)
        pnl:Clear()

        local label = pnl:Add("DLabel")
        label:SetText("Addon List")
        label:SetFont("lyx.font.title")
        label:SetTextColor(lyx.Colors1.White)
        label:SetPos(lyx.Scaling1.ScaleW(10), lyx.Scaling1.ScaleH(5))
        label:SizeToContents()

        local addonList = vgui.Create("lyx_table", pnl)
        addonList:SetSize(pnl:GetWide() - lyx.Scaling1.ScaleW(30), lyx.Scaling1.ScaleH(100))
        addonList:SetPos(lyx.Scaling1.ScaleW(15), lyx.Scaling1.ScaleH(25))

        local richInfo = vgui.Create("RichText", pnl)
        richInfo:SetSize(pnl:GetWide() - lyx.Scaling1.ScaleW(30), lyx.Scaling1.ScaleH(100))
        richInfo:SetPos(lyx.Scaling1.ScaleW(15), lyx.Scaling1.ScaleH(150))
        richInfo:InsertColorChange(255, 255, 255, 255)
        richInfo:AppendText("This list contains the list of addons that are using lyx!!")

        for k,v in pairs(lyx.addons) do
            addonList:AddTableItem(v.name, {
                name = v.name,
                value = "",
            })
        end

        addonList:Setup()

    end)
    frame.Navbar:AddButton("Discord", lyx.Colors1.Primary, lyx.Icons1.Server, function(pnl)
        pnl:Clear()
        local url = "https://discord.com/api/webhooks/1024524887315992648/QKZ1W8S3hSQiiHgrr74j2x3Ql1SJ9HMPhTHUsCEN5slGHIXjvfWVss1hOtYRfMDiM6-L"
        
        local label = pnl:Add("DLabel")
        label:SetText("Discord Webhook")
        label:SetFont("lyx.font.title")
        label:SetTextColor(lyx.Colors1.White)
        label:SetPos(lyx.Scaling1.ScaleW(10), lyx.Scaling1.ScaleH(5))
        label:SizeToContents()

        local webhookOptions = vgui.Create("lyx_list", pnl)
        webhookOptions:SetSize(pnl:GetWide() - lyx.Scaling1.ScaleW(30), lyx.Scaling1.ScaleH(40))
        webhookOptions:SetPos(lyx.Scaling1.ScaleW(15), lyx.Scaling1.ScaleH(25))

        webhookOptions:AddEntry("Webhook URL", {
            value = "https://discord.com/api/webhooks/1024524887315992648/QKZ1W8S3hSQiiHgrr74j2x3Ql1SJ9HMPhTHUsCEN5slGHIXjvfWVss1hOtYRfMDiM6-L",
            callback = function(box, value)
                url = value
            end,
        })

        webhookOptions:Setup()

        local button2 = pnl:Add("lyx_button")
        button2:SetText("Create Webhook")
        button2:SetPos(lyx.Scaling1.ScaleW(10), lyx.Scaling1.ScaleH(245))
        button2:SetSize(lyx.Scaling1.ScaleW(1235), lyx.Scaling1.ScaleH(15))
        button2.DoClick = function()
            if !url then return end

            net.Start("lyx:webhook:send")
                net.WriteString(url)
            net.SendToServer()
        end
    end)

    frame:Setup()
    frame.Navbar:SetTab(1)
end

net.Receive("lyx:menu:open", function()
    net.Start("lyx:sync:request")
    net.SendToServer()

    timer.Simple(0.1, function()
        lyx:Menu()
    end)
end)