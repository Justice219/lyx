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

function lyx:NetAdd(name, tbl)
    net.Receive(name, function()
        
    end)
end