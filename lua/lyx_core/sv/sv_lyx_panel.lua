lyx = lyx

-- Network strings
util.AddNetworkString("lyx:menu:open")
util.AddNetworkString("lyx:panel:video")
util.AddNetworkString("lyx:rank:add")
util.AddNetworkString("lyx:rank:remove")
util.AddNetworkString("lyx:rank:getall")
util.AddNetworkString("lyx:rank:sync")
util.AddNetworkString("lyx:config:save")
util.AddNetworkString("lyx:config:load")


do
    -- Networking
    lyx:NetAdd("lyx:panel:video", {
        func = function(ply)
            if !lyx:CheckRank(ply) then return end

            local ent = net.ReadEntity()
            if IsValid(ent) then
                lyx:VideoSend(net.ReadString(), ent, {
                    width = 1920,
                    height = 1080,
                })
            else
                lyx:VideoBroadcast(net.ReadString(), {
                    width = 1920,
                    height = 1080,
                })
            end
        end
    })

    lyx:NetAdd("lyx:rank:add", {
        func = function(ply)
            if !lyx:CheckRank(ply) then return end
            local rank = net.ReadString()
        
            lyx:AddRank(rank)
            
            -- Send updated ranks to all admins
            timer.Simple(0.5, function()
                local ranks = lyx.GetAllRanks and lyx:GetAllRanks() or {"superadmin", "admin", "user"}
                for _, p in ipairs(player.GetAll()) do
                    if p:IsAdmin() then
                        net.Start("lyx:rank:sync")
                        net.WriteTable(ranks)
                        net.Send(p)
                    end
                end
            end)
        end
    })

    lyx:NetAdd("lyx:rank:remove", {
        func = function(ply)
            if !lyx:CheckRank(ply) then return end
            local rank = net.ReadString()
        
            lyx:RemoveRank(rank)
            
            -- Send updated ranks to all admins
            timer.Simple(0.5, function()
                local ranks = lyx.GetAllRanks and lyx:GetAllRanks() or {"superadmin", "admin", "user"}
                for _, p in ipairs(player.GetAll()) do
                    if p:IsAdmin() then
                        net.Start("lyx:rank:sync")
                        net.WriteTable(ranks)
                        net.Send(p)
                    end
                end
            end)
        end
    })
    
    lyx:NetAdd("lyx:rank:getall", {
        func = function(ply)
            if !lyx:CheckRank(ply) then return end
            
            local ranks = {}
            
            -- Get ranks from the system
            if lyx.GetAllRanks then
                ranks = lyx:GetAllRanks() or {}
            end
            
            -- If no ranks found, use default ranks
            if #ranks == 0 then
                ranks = {"superadmin", "admin", "moderator", "user"}
            end
            
            -- Send ranks to requesting player
            net.Start("lyx:rank:sync")
            net.WriteTable(ranks)
            net.Send(ply)
            
            lyx.Logger:Log(ply:Nick() .. " requested ranks list")
        end
    })

    lyx:NetAdd("lyx:webhook:send", {
        func = function(ply)
            if !lyx:CheckRank(ply) then return end
            local h = net.ReadString()
        
            lyx:DiscordWebhook(h, {
                content = text, 
                username = ply:Nick()
            })
        end
    })
    
    lyx:NetAdd("lyx:config:save", {
        func = function(ply)
            if !lyx:CheckRank(ply) then return end
            
            local settings = net.ReadTable()
            
            -- Save settings using Lyx system
            if lyx.BulkSetSettings then
                lyx:BulkSetSettings(settings)
                lyx.Logger:Log(ply:Nick() .. " updated server configuration")
            end
            
            -- You can add additional processing here
            -- For example, applying certain settings immediately
            if settings.max_players then
                RunConsoleCommand("maxplayers", tostring(settings.max_players))
            end
        end
    })

    -- Lets create our chat command!
    lyx:ChatAddCommand("lyx", {
        prefix = "!",
        func = function(ply, args)
            if !lyx:CheckRank(ply) then return end
            net.Start("lyx:menu:open")
            net.Send(ply)
        end
    }, false) 
end