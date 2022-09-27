lyx = lyx

--[[
.____                    _______          __   
|    |    ___.__.___  ___\      \   _____/  |_ 
|    |   <   |  |\  \/  //   |   \_/ __ \   __\
|    |___ \___  | >    </    |    \  ___/|  |  
|_______ \/ ____|/__/\_ \____|__  /\___  >__|  
        \/\/           \/       \/     \/      

Stuff for handling client-server networking

]]--

-- Adds a network string and serverside net receiver
function lyx:NetAdd(name, tbl)
    util.AddNetworkString(name)
    timer.Simple(0.5, function()
        net.Receive(name, function(len, ply)
            tbl.func(ply)
        end)
    end)
end

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