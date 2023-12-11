lyx = lyx

--[[
.____                   ____   ____.__    .___            
|    |    ___.__.___  __\   \ /   /|__| __| _/____  ____  
|    |   <   |  |\  \/  /\   Y   / |  |/ __ |/ __ \/  _ \ 
|    |___ \___  | >    <  \     /  |  / /_/ \  ___(  <_> )
|_______ \/ ____|/__/\_ \  \___/   |__\____ |\___  >____/ 
        \/\/           \/                  \/    \/       

Video Library for allowing you to play videos in your game.

]]--

do
    util.AddNetworkString("lyx_video_start")
    util.AddNetworkString("lyx_video_stop")
    
    function lyx:VideoSend(url, ply, tbl)
        if !IsValid(ply) then return end
    
        net.Start("lyx_video_start")
            net.WriteString(url)
            net.WriteInt(tbl.width, 32)
            net.WriteInt(tbl.height, 32)
        net.Send(ply)
    end
    
    function lyx:VideoStop(ply)
        if !IsValid(ply) then return end
    
        net.Start("lyx_video_stop")
        net.Send(ply)
    end
    
    function lyx:VideoBroadcast(url, tbl)
        net.Start("lyx_video_start")
            net.WriteString(url)
            net.WriteInt(tbl.width, 32)
            net.WriteInt(tbl.height, 32)
        net.Broadcast() 
    
        lyx.Logger:Log("Broadcasting video: " .. url)
    end
    
    function lyx:VideoStopBroadcast()
        net.Start("lyx_video_stop")
        net.Broadcast()
    end 
end