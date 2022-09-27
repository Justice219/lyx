lyx = lyx

-- Network strings
util.AddNetworkString("lyx:menu:open")
util.AddNetworkString("lyx:panel:video")
util.AddNetworkString("lyx:rank:add")
util.AddNetworkString("lyx:rank:remove")


-- Networking
net.Receive("lyx:panel:video", function(len, ply)
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
end)

net.Receive("lyx:rank:add", function(len, ply)
    if !lyx:CheckRank(ply) then return end
    local rank = net.ReadString()

    lyx:AddRank(rank)
end)

net.Receive("lyx:rank:remove", function(len, ply)
    if !lyx:CheckRank(ply) then return end
    local rank = net.ReadString()

    lyx:RemoveRank(rank)
end)


-- Lets create our chat command!
lyx:ChatAddCommand("lyx", {
    prefix = "!",
    func = function(ply, args)
        if !lyx:CheckRank(ply) then return end
        net.Start("lyx:menu:open")
        net.Send(ply)
    end
}, false)