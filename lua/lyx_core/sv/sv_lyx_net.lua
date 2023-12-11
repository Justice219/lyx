lyx = lyx

do
    lyx:NetAdd("lyx:test:net", {
        func = function(ply)
            print(ply)
        end
    })
    
    lyx:NetAdd("lyx:sync:request", {
        func = function(ply)
            net.Start("lyx:sync:request")
            
            -- Lets write specific data to the net message
            local ranks = {ranks = lyx.ranks}

    
            net.WriteTable(ranks)
            net.WriteTable(lyx.Addons)

            net.Send(ply)
            lyx.Logger:Log("Synced data for " .. ply:Nick())
        end
    }) 
end