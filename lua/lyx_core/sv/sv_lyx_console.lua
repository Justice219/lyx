lyx = lyx
lyx.console = lyx.console or {}

--[[
.____                   _________                            .__          
|    |    ___.__.___  __\_   ___ \  ____   ____   __________ |  |   ____  
|    |   <   |  |\  \/  /    \  \/ /  _ \ /    \ /  ___/  _ \|  | _/ __ \ 
|    |___ \___  | >    <\     \___(  <_> )   |  \\___ (  <_> )  |_\  ___/ 
|_______ \/ ____|/__/\_ \\______  /\____/|___|  /____  >____/|____/\___  >
        \/\/           \/       \/            \/     \/                \/ 

Debug console commands for doing cool shit ig.

]]--

do
    function lyx:AddConsoleCommand(name, func, help)
        if not self.console.commands then self.console.commands = {} end
        self.console.commands[name] = {func = func, help = help}
    end
    
    concommand.Add("lyx_add_rank", function(ply, cmd, args)
        lyx:AddRank(args[1])
        lyx.Logger:Log("Added rank " .. args[1])
    end)
    
    concommand.Add("lyx_remove_rank", function(ply, cmd, args)
        if !args[1] then return end
    
        lyx:RemoveRank(args[1])
        lyx.Logger:Log("Removed rank " .. args[1])
    end)
    
    concommand.Add("lyx_npc_spawn", function(ply, cmd ,args)
        if !lyx:CheckRank(ply) then return end
    
        lyx:NPCSpawn("npc_monk", {
            pos = Vector(294.992615, 45.469769, -84.019943),
            ang = Angle(0, 0, 0),
            health = 5,
            death = function(npc, attacker, inflictor)
                attacker:ChatPrint("You have killed the npc!")
            end
        })
    end)
    
    concommand.Add("lyx_message_server", function(ply, cmd, args)
        if !lyx:CheckRank(ply) then return end
        if !args[1] then return end
        if !args[2] then return end
    
        lyx:MessageServer({
            ["type"] = "header",
            ["color1"] = Color(255,0,0),
            ["header"] = args[1],
            ["color2"] = Color(255,255,255),
            ["text"] = args[2]
        })
    end)
    
    concommand.Add("lyx_message_server_single", function(ply, cmd, args)
        if !lyx:CheckRank(ply) then return end
        if !args[1] then return end
    
        lyx:MessageServer({
            ["type"] = "single",
            ["color"] = Color(255,0,0),
            ["text"] = args[1]
        })
    end)
    
    concommand.Add("lyx_message_player", function(ply, cmd, args)
        if !lyx:CheckRank(ply) then return end
        if !args[1] then return end
        if !args[2] then return end
    
        lyx:MessagePlayer({
            ["type"] = "header",
            ["color1"] = Color(255,0,0),
            ["header"] = args[1],
            ["color2"] = Color(255,255,255),
            ["text"] = args[2],
            ["ply"] = ply
        })
    end)
    
    
    concommand.Add("lyx_video_play", function(ply, cmd, args)
        if !lyx:CheckRank(ply) then return end
        if !args[1] then return end
    
        lyx:VideoSend(ply, args[1], {
            width = 1920,
            height = 1080,
        })
    end)
    
    concommand.Add("lyx_video_play_global", function(ply, cmd, args)
        if !lyx:CheckRank(ply) then return end
        if !args[1] then return end
    
        lyx:VideoBroadcast(args[1], {
            width = 1920,
            height = 1080,
        })
    end)
    
    concommand.Add("lyx_video_stop", function(ply, cmd, args)
        if !lyx:CheckRank(ply) then return end
    
        lyx:VideoStop(ply)
    end) 

    concommand.Add("lyx_debug_print", function()
        PrintTable(lyx)
    end)
end