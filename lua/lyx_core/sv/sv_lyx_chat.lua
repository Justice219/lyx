lyx = lyx
lyx.chat = lyx.chat or {}
lyx.chatCooldowns = lyx.chatCooldowns or {}

--[[
.____                   _________ .__            __   
|    |    ___.__.___  __\_   ___ \|  |__ _____ _/  |_ 
|    |   <   |  |\  \/  /    \  \/|  |  \\__  \\   __\
|    |___ \___  | >    <\     \___|   Y  \/ __ \|  |  
|_______ \/ ____|/__/\_ \\______  /___|  (____  /__|  
        \/\/           \/       \/     \/     \/      

Enhanced chat command framework with security, permissions, and rate limiting

]]--

do
    -- Configuration
    local MAX_COMMAND_LENGTH = 32
    local MAX_ARG_LENGTH = 256
    local DEFAULT_COOLDOWN = 1  -- Default cooldown in seconds
    
    --[[
        Add a new chat command with validation and options
        @param name string - Command name (without prefix)
        @param data table - Command configuration
        @param debug boolean - Enable debug logging (optional)
        @return boolean - True if command was added successfully
    ]]
    function lyx:ChatAddCommand(name, data, debug)
        -- Validate command name
        if type(name) ~= "string" or #name == 0 or #name > MAX_COMMAND_LENGTH then
            lyx.Logger:Log("Invalid command name: " .. tostring(name), 3)
            return false
        end
        
        -- Validate command data
        if type(data) ~= "table" then
            lyx.Logger:Log("Invalid command data for: " .. name, 3)
            return false
        end
        
        if type(data.func) ~= "function" then
            lyx.Logger:Log("Command missing function: " .. name, 3)
            return false
        end
        
        if type(data.prefix) ~= "string" or #data.prefix == 0 then
            lyx.Logger:Log("Command missing or invalid prefix: " .. name, 3)
            return false
        end
        
        -- Check if command already exists
        if lyx.chat[name] then
            lyx.Logger:Log("Chat command already exists: " .. name, 2)
            return false
        end
        
        -- Store command with enhanced options
        lyx.chat[name] = {
            prefix = data.prefix,
            invoke = data.func,
            description = data.description or "No description provided",
            usage = data.usage or data.prefix .. name,
            permission = data.permission,  -- Optional permission/rank requirement
            cooldown = data.cooldown or DEFAULT_COOLDOWN,
            enabled = data.enabled ~= false,  -- Default to enabled
            hidden = data.hidden or false,  -- Hide from help commands
            args = data.args or {},  -- Argument validation rules
            debug = debug or false
        }
        
        if debug then
            lyx.Logger:Log("Added chat command: " .. data.prefix .. name .. " - " .. (data.description or ""))
        else
            lyx.Logger:Log("Added chat command: " .. name)
        end
        
        return true
    end
    
    --[[
        Remove a chat command
        @param name string - Command name to remove
        @return boolean - True if removed successfully
    ]]
    function lyx:ChatRemoveCommand(name)
        if not lyx.chat[name] then
            lyx.Logger:Log("Command does not exist: " .. name, 2)
            return false
        end
        
        lyx.chat[name] = nil
        lyx.Logger:Log("Removed chat command: " .. name)
        return true
    end
    
    --[[
        Check if a player is on cooldown for a command
        @param ply Player - Player to check
        @param name string - Command name
        @param cooldown number - Cooldown duration
        @return boolean - True if player can use command
    ]]
    local function CheckCooldown(ply, name, cooldown)
        if not IsValid(ply) then return false end
        
        local sid = ply:SteamID()
        local now = CurTime()
        
        -- Initialize cooldown tracking
        lyx.chatCooldowns[sid] = lyx.chatCooldowns[sid] or {}
        
        -- Check cooldown
        local lastUse = lyx.chatCooldowns[sid][name] or 0
        if now - lastUse < cooldown then
            local remaining = math.ceil(cooldown - (now - lastUse))
            ply:ChatPrint("Please wait " .. remaining .. " second(s) before using this command again.")
            return false
        end
        
        -- Update last use time
        lyx.chatCooldowns[sid][name] = now
        return true
    end
    
    --[[
        Run a chat command with full validation
        @param name string - Command name
        @param ply Player - Player executing the command
        @param args table - Command arguments
        @return boolean - True if command executed successfully
    ]]
    function lyx:ChatRunCommand(name, ply, args)
        -- Validate player
        if not IsValid(ply) then
            lyx.Logger:Log("Invalid player for command: " .. name, 3)
            return false
        end
        
        -- Check if command exists
        local cmd = lyx.chat[name]
        if not cmd then
            lyx.Logger:Log("Chat command does not exist: " .. name, 2)
            return false
        end
        
        -- Check if command is enabled
        if not cmd.enabled then
            ply:ChatPrint("This command is currently disabled.")
            return false
        end
        
        -- Check permissions
        if cmd.permission then
            if type(cmd.permission) == "string" then
                -- Check rank-based permission
                if lyx.CheckRank and not lyx:CheckRank(ply, cmd.permission) then
                    ply:ChatPrint("You don't have permission to use this command.")
                    return false
                end
            elseif type(cmd.permission) == "function" then
                -- Custom permission check
                if not cmd.permission(ply) then
                    ply:ChatPrint("You don't have permission to use this command.")
                    return false
                end
            end
        end
        
        -- Check cooldown
        if not CheckCooldown(ply, name, cmd.cooldown) then
            return false
        end
        
        -- Validate arguments
        if cmd.args and #cmd.args > 0 then
            for i, argRule in ipairs(cmd.args) do
                local arg = args[i + 1]  -- Skip command itself
                
                -- Check required arguments
                if argRule.required and not arg then
                    ply:ChatPrint("Usage: " .. (cmd.usage or cmd.prefix .. name))
                    return false
                end
                
                -- Validate argument type
                if arg and argRule.type then
                    if argRule.type == "number" and not tonumber(arg) then
                        ply:ChatPrint("Argument " .. i .. " must be a number.")
                        return false
                    elseif argRule.type == "player" then
                        -- Validate player argument
                        local target = nil
                        for _, p in ipairs(player.GetAll()) do
                            if string.lower(p:Nick()) == string.lower(arg) then
                                target = p
                                break
                            end
                        end
                        if not target then
                            ply:ChatPrint("Player '" .. arg .. "' not found.")
                            return false
                        end
                        args[i + 1] = target  -- Replace with player object
                    end
                end
                
                -- Validate argument length
                if arg and #arg > MAX_ARG_LENGTH then
                    ply:ChatPrint("Argument " .. i .. " is too long.")
                    return false
                end
            end
        end
        
        -- Execute command with error handling
        local success, err = pcall(cmd.invoke, ply, args)
        if not success then
            lyx.Logger:Log("Error executing command " .. name .. ": " .. tostring(err), 3)
            ply:ChatPrint("An error occurred while executing this command.")
            return false
        end
        
        -- Log command usage if debug mode
        if cmd.debug then
            lyx.Logger:Log("Player " .. ply:Nick() .. " used command: " .. cmd.prefix .. name)
        end
        
        return true
    end
    
    --[[
        Get all available commands for a player
        @param ply Player - Player to check permissions for
        @return table - Array of available command names
    ]]
    function lyx:ChatGetAvailableCommands(ply)
        local available = {}
        
        for name, cmd in pairs(lyx.chat) do
            if not cmd.hidden and cmd.enabled then
                -- Check permissions
                local hasPermission = true
                if cmd.permission then
                    if type(cmd.permission) == "string" then
                        hasPermission = lyx.CheckRank and lyx:CheckRank(ply, cmd.permission)
                    elseif type(cmd.permission) == "function" then
                        hasPermission = cmd.permission(ply)
                    end
                end
                
                if hasPermission then
                    table.insert(available, {
                        name = name,
                        prefix = cmd.prefix,
                        description = cmd.description,
                        usage = cmd.usage
                    })
                end
            end
        end
        
        return available
    end
    
    -- Hook for processing chat messages
    hook.Add("PlayerSay", "lyx_chat_commands", function(ply, text, team)
        -- Sanitize input
        text = string.Trim(text)
        if #text == 0 or #text > 512 then  -- Reasonable max message length
            return
        end
        
        -- Parse arguments safely
        local args = string.Explode(" ", text)
        if #args == 0 then return end
        
        local fullCmd = args[1]
        
        -- Check all registered commands
        for name, cmd in pairs(lyx.chat) do
            if cmd.enabled and (cmd.prefix .. name) == fullCmd then
                -- Found matching command
                lyx:ChatRunCommand(name, ply, args)
                return ""  -- Suppress message
            end
        end
    end)
    
    -- Clean up cooldowns on player disconnect
    hook.Add("PlayerDisconnected", "lyx_chat_cooldown_cleanup", function(ply)
        if IsValid(ply) then
            lyx.chatCooldowns[ply:SteamID()] = nil
        end
    end)
    
    -- Built-in help command
    lyx:ChatAddCommand("help", {
        prefix = "!",
        func = function(ply, args)
            local commands = lyx:ChatGetAvailableCommands(ply)
            
            if #commands == 0 then
                ply:ChatPrint("No commands available.")
                return
            end
            
            ply:ChatPrint("=== Available Commands ===")
            for _, cmd in ipairs(commands) do
                ply:ChatPrint(cmd.prefix .. cmd.name .. " - " .. cmd.description)
            end
            ply:ChatPrint("=======================")
        end,
        description = "Show available commands",
        cooldown = 5
    })
    
    -- Example test command with enhanced features
    lyx:ChatAddCommand("test", {
        prefix = "!",
        func = function(ply, args)
            ply:ChatPrint("Hello " .. ply:Nick() .. "! You said: " .. table.concat(args, " ", 2))
        end,
        description = "Test command",
        usage = "!test [message]",
        cooldown = 2
    })
end