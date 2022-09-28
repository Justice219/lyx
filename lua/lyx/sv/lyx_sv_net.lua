lyx = lyx

lyx:NetAdd("lyx:test:net", {
    func = function(ply)
        print(ply)
    end
})

lyx:NetAdd("lyx:sync:request", {
    func = function(ply)
        net.Start("lyx:sync:request")
        
        -- Lets write specific data to the net message
        local tbl = {
            ranks = lyx.ranks
        }

        net.WriteTable(tbl)
        net.Send(ply)
        lyx:Log("Synced data for " .. ply:Nick())
    end
})