lyx = lyx

function lyx:Menu()
    local frame = vgui.Create("lyx_frame")
    frame:ShowNavbar(true)
    frame:SetTitle("Lyx Library v1.23")

    -- Lets setup our navbar.
    frame.Navbar:AddButton("Video", lyx.Colors.Primary, lyx.Icons.Player, function(pnl)
        pnl:Clear()
        local ply = nil
        local url = "https://www.youtube.com/watch?v=OqBuXQLR4Y8&ab_channel=RexOrangeCounty"
        
        local label = pnl:Add("DLabel")
        label:SetText("Video Player")
        label:SetFont("lyx.font.title")
        label:SetTextColor(lyx.Colors.White)
        label:SetPos(lyx.Scaling.ScaleW(10), lyx.Scaling.ScaleH(5))
        label:SizeToContents()

        local videoOptions = vgui.Create("lyx_list", pnl)
        videoOptions:SetSize(pnl:GetWide() - lyx.Scaling.ScaleW(30), lyx.Scaling.ScaleH(100))
        videoOptions:SetPos(lyx.Scaling.ScaleW(15), lyx.Scaling.ScaleH(25))

        videoOptions:AddEntry("Video URL", {
            value = "https://www.youtube.com/watch?v=OqBuXQLR4Y8&ab_channel=RexOrangeCounty",
            callback = function(box, value)
                url = value
            end,
        })
        videoOptions:Setup()

        local playerOptions = vgui.Create("lyx_list", pnl)
        playerOptions:SetSize(pnl:GetWide() - lyx.Scaling.ScaleW(30), lyx.Scaling.ScaleH(100))
        playerOptions:SetPos(lyx.Scaling.ScaleW(15), lyx.Scaling.ScaleH(120))

        for k,v in pairs(player.GetAll()) do
            playerOptions:AddButton(v:SteamID64() .. ":" .. v:Nick(), {
                buttonText = "Select",
                callback = function(box, value)
                    ply = v
                    chat.AddText(lyx.Colors.Red, "[LYX] ", lyx.Colors.White, "Selected " .. v:Nick())
                end
            })
        end
        playerOptions:Setup()

        local sendToPlayer = pnl:Add("lyx_button")
        sendToPlayer:SetText("Send to Player")
        sendToPlayer:SetPos(lyx.Scaling.ScaleW(10), lyx.Scaling.ScaleH(230))
        sendToPlayer:SetSize(lyx.Scaling.ScaleW(1240), lyx.Scaling.ScaleH(15))
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
        button:SetPos(lyx.Scaling.ScaleW(10), lyx.Scaling.ScaleH(250))
        button:SetSize(lyx.Scaling.ScaleW(1240), lyx.Scaling.ScaleH(15))
        button.DoClick = function()
            net.Start("lyx:panel:video")
                net.WriteEntity(nil)
                net.WriteString(url)
            net.SendToServer()
        end

        
    end)
    frame.Navbar:AddButton("Ranks", lyx.Colors.Primary, lyx.Icons.Server, function(pnl)
        pnl:Clear()
        local r = "admin"

        local label = pnl:Add("DLabel")
        label:SetText("Panel Rank Options")
        label:SetFont("lyx.font.title")
        label:SetTextColor(lyx.Colors.White)
        label:SetPos(lyx.Scaling.ScaleW(10), lyx.Scaling.ScaleH(5))
        label:SizeToContents()


        local rankOptions = vgui.Create("lyx_list", pnl)
        rankOptions:SetSize(pnl:GetWide() - lyx.Scaling.ScaleW(30), lyx.Scaling.ScaleH(40))
        rankOptions:SetPos(lyx.Scaling.ScaleW(15), lyx.Scaling.ScaleH(25))

        rankOptions:AddEntry("Rank Name", {
            value = "admin",
            callback = function(box, value)
                r = value
            end,
        })
        rankOptions:Setup()

        local button = pnl:Add("lyx_button")
        button:SetText("Add Rank")
        button:SetPos(lyx.Scaling.ScaleW(10), lyx.Scaling.ScaleH(70))
        button:SetSize(lyx.Scaling.ScaleW(1235), lyx.Scaling.ScaleH(15))
        button.DoClick = function()
            if r then
                net.Start("lyx:rank:add")
                    net.WriteString(r)
                net.SendToServer()
                chat.AddText(lyx.Colors.Red, "[LYX] ", lyx.Colors.White, "Added rank " .. r)
                frame:Remove()
            end
        end

        local rankList = vgui.Create("lyx_list", pnl)
        rankList:SetSize(pnl:GetWide() - lyx.Scaling.ScaleW(30), lyx.Scaling.ScaleH(150))
        rankList:SetPos(lyx.Scaling.ScaleW(15), lyx.Scaling.ScaleH(90))
        for k,v in pairs(lyx.ranks.ranks) do
            rankList:AddButton(k, {
                buttonText = "Select",
                callback = function(box, value)
                    r = k
                    chat.AddText(lyx.Colors.Red, "[LYX] ", lyx.Colors.White, "Selected rank " .. k .. " for deletion.")
                    frame:Remove()
                end
            })
        end
        rankList:Setup()

        local button2 = pnl:Add("lyx_button")
        button2:SetText("Remove Rank")
        button2:SetPos(lyx.Scaling.ScaleW(10), lyx.Scaling.ScaleH(245))
        button2:SetSize(lyx.Scaling.ScaleW(1235), lyx.Scaling.ScaleH(15))
        button2.DoClick = function()
            net.Start("lyx:rank:remove")
                net.WriteString(r)
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