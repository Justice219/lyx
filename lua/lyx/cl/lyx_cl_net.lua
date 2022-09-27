lyx = lyx

net.Receive("lyx:sync:request", function(len, ply)
    lyx:Log("Synced data from the server")
    lyx.ranks = net.ReadTable()
end)