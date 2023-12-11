lyx = lyx

--[[
.____                      _____                 
|    |    ___.__.___  ___ /     \   ______ ____  
|    |   <   |  |\  \/  //  \ /  \ /  ___// ___\ 
|    |___ \___  | >    </    Y    \\___ \/ /_/  >
|_______ \/ ____|/__/\_ \____|__  /____  >___  / 
        \/\/           \/       \/     \/_____/  

Simple Player-Server Chat Messaging Framework

]]--

do
    util.AddNetworkString("lyx:message")

    function lyx:MessageServer(tbl)
        net.Start("lyx:message")
        net.WriteTable(tbl)
        net.Broadcast()
    
    end
    
    function lyx:MessagePlayer(tbl)
        net.Start("lyx:message")
        net.WriteTable(tbl)
        net.Send(tbl["ply"])
    end 
end


--[[lyx:MessageServer({
    ["type"] = "header",
    ["color1"] = Color(255,0,0),
    ["header"] = "Lyx",
    ["color2"] = Color(255,255,255),
    ["text"] = "Hello World"
})
lyx:MessageServer({
    ["type"] = "single",
    ["color"] = Color(255,0,0),
    ["text"] = "Hello World"
})
lyx:MessagePlayer({
    ["type"] = "header",
    ["color1"] = Color(255,0,0),
    ["header"] = "Lyx",
    ["color2"] = Color(255,255,255),
    ["text"] = "Hello World",
    ["ply"] = ply
})-]]