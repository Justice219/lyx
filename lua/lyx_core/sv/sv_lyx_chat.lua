lyx = lyx
lyx.chat = lyx.chat or {}

--[[
.____                   _________ .__            __   
|    |    ___.__.___  __\_   ___ \|  |__ _____ _/  |_ 
|    |   <   |  |\  \/  /    \  \/|  |  \\__  \\   __\
|    |___ \___  | >    <\     \___|   Y  \/ __ \|  |  
|_______ \/ ____|/__/\_ \\______  /___|  (____  /__|  
        \/\/           \/       \/     \/     \/      

Simple framework for creating chat commands.

]]--

do
    function lyx:ChatAddCommand(name, data, debug)
        if lyx.chat[name] then
            lyx.Logger:Log("Chat command already exists: " .. name)
        return end
    
        lyx.chat[name] = { -- Add command to server table.
            prefix = data.prefix,
            invoke = data.func,
        }
        lyx.Logger:Log("Added chat command: " .. name)
    end
    
    function lyx:ChatRunCommand(name, ply, args)
        if not lyx.chat[name] then
            lyx.Logger:Log("Chat command does not exist: " .. name)
        return end
    
        -- check if loadstring is enabled
        lyx.chat[name].invoke(ply, args)
    end
    
    hook.Add("PlayerSay", "lyx_chat_commands", function(ply, text)
        local cmds = lyx.chat
    
        local args = string.Explode(" ", text)
        local cmd = args[1]
    
        for k,v in pairs(lyx.chat) do
            if (v.prefix .. k) == cmd then
                lyx:ChatRunCommand(k, ply, args)
                return ""
            end
        end
    
    end)
    
    -- CUSTOM COMMANDS!
    lyx:ChatAddCommand("test", {
        prefix = "!",
        func = function(ply, args)
            ply:ChatPrint("Hello " .. ply:Nick() .. "!")
        end
    }, false) 
end