lyx = lyx

lyx:NetAdd("lyx:sync:request", {
    func = function()
        lyx:Log("Synced data from the server")
        lyx.ranks = net.ReadTable()
    end
})