lyx = lyx
lyx.netMessages = lyx.netMessages or {}

--[[
.____                    _______          __   
|    |    ___.__.___  ___\      \   _____/  |_ 
|    |   <   |  |\  \/  //   |   \_/ __ \   __\
|    |___ \___  | >    </    |    \  ___/|  |  
|_______ \/ ____|/__/\_ \____|__  /\___  >__|  
        \/\/           \/       \/     \/      

Stuff for handling client-server networking

]]--

-- This is the client-side networking library. It is used to send and receive
-- messages from the server. It is also used to send and receive messages
-- from other clients.
do
    if SERVER then
        -- Add a network string for the client to send the server
        util.AddNetworkString("lyx:net:addnetstring")
    
        -- Add a network string for the server to send the client
        -- Adds network string
        function lyx:NetAdd(name, tbl)
            lyx.netMessages[name] = tbl
            util.AddNetworkString(name)
            timer.Simple(0.5, function()
                net.Receive(name, function(len, ply)
                    tbl.func(ply)
                end)
            end)
        end
    elseif CLIENT then
        -- Adds a client-side net receiver
        function lyx:NetAdd(name, tbl)
            timer.Simple(0.5, function()
                net.Receive(name, function(len)
                    tbl.func(len)
                end)
            end)
        end
    end 
end

--[[ 
    HERE IS AN EXAMPLE NET MESSAGE ( WORKS ON BOTH CLIENT AND SERVER )
    lyx:NetAdd("lyx:net:addnetstring", {
        func = function(ply)
            if !lyx:CheckRank(ply) then return end
            local str = net.ReadString()
            util.AddNetworkString(str)
        end
    })
]]--