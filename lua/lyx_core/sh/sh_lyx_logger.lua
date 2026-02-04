local logger = {}

local infoColor = Color(255, 255, 255)
local warnColor = Color(255, 255, 0)
local errorColor = Color(255, 0, 0)

-- Store logs for the UI
lyx.LogHistory = lyx.LogHistory or {}
lyx.MaxLogHistory = 500  -- Maximum number of logs to keep

do
    function logger:Log(message, level)
        -- First argument is the message, second (optional) is log level
        -- Log level is ignored for now but could be used for filtering
        if type(message) ~= "string" then
            message = tostring(message)
        end
        MsgC(self.color, "[" .. self.name .. "] ", infoColor, message, "\n")
        
        -- Store log entry
        table.insert(lyx.LogHistory, {
            time = os.time(),
            addon = self.name,
            message = message,
            level = "info",
            color = self.color
        })
        
        -- Trim log history if too large
        if #lyx.LogHistory > lyx.MaxLogHistory then
            table.remove(lyx.LogHistory, 1)
        end
        
        -- Send to clients if on server
        if SERVER then
            lyx.SendLogToClients(self.name, message, "info", self.color)
        end
    end

    function logger:Warn(...)
        local args = {...}
        local message = ""
        for i = 1, #args do
            message = message .. tostring(args[i])
        end
        MsgC(self.color, "[" .. self.name .. "] ", warnColor, message, "\n")
        
        -- Store log entry
        table.insert(lyx.LogHistory, {
            time = os.time(),
            addon = self.name,
            message = message,
            level = "warn",
            color = self.color
        })
        
        -- Trim log history if too large
        if #lyx.LogHistory > lyx.MaxLogHistory then
            table.remove(lyx.LogHistory, 1)
        end
        
        -- Send to clients if on server
        if SERVER then
            lyx.SendLogToClients(self.name, message, "warn", self.color)
        end
    end

    function logger:Error(...)
        local args = {...}
        local message = ""
        for i = 1, #args do
            message = message .. tostring(args[i])
        end
        MsgC(self.color, "[" .. self.name .. "] ", errorColor, message, "\n")
        
        -- Store log entry
        table.insert(lyx.LogHistory, {
            time = os.time(),
            addon = self.name,
            message = message,
            level = "error",
            color = self.color
        })
        
        -- Trim log history if too large
        if #lyx.LogHistory > lyx.MaxLogHistory then
            table.remove(lyx.LogHistory, 1)
        end
        
        -- Send to clients if on server
        if SERVER then
            lyx.SendLogToClients(self.name, message, "error", self.color)
        end
    end

    function lyx.CreateLogger(name, color)
        local newLogger = {}
        setmetatable(newLogger, {__index = logger})
        newLogger.name = name
        newLogger.color = color
        return newLogger
    end
end

lyx.Logger = lyx.CreateLogger("LYX", Color(230, 40, 10))

-- Network string for log synchronization
if SERVER then
    util.AddNetworkString("lyx:logger:sync")
    util.AddNetworkString("lyx:logger:requesthistory")
    
    function lyx.SendLogToClients(addon, message, level, color)
        -- Only send to admins
        local admins = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsAdmin() then
                table.insert(admins, ply)
            end
        end
        
        if #admins > 0 then
            net.Start("lyx:logger:sync")
            net.WriteString(addon)
            net.WriteString(message)
            net.WriteString(level)
            net.WriteColor(color)
            net.WriteUInt(os.time(), 32)
            net.Send(admins)
        end
    end
    
    -- Send log history when requested
    net.Receive("lyx:logger:requesthistory", function(len, ply)
        if not ply:IsAdmin() then return end
        
        -- Send recent logs (last 100)
        local logsToSend = {}
        local startIndex = math.max(1, #lyx.LogHistory - 100)
        for i = startIndex, #lyx.LogHistory do
            table.insert(logsToSend, lyx.LogHistory[i])
        end
        
        net.Start("lyx:logger:sync")
        net.WriteBool(true) -- Indicates this is a history dump
        net.WriteUInt(#logsToSend, 16)
        for _, log in ipairs(logsToSend) do
            net.WriteString(log.addon)
            net.WriteString(log.message)
            net.WriteString(log.level)
            net.WriteColor(log.color)
            net.WriteUInt(log.time, 32)
        end
        net.Send(ply)
    end)
else
    -- Client-side: receive log updates
    net.Receive("lyx:logger:sync", function()
        local isHistory = net.ReadBool()
        
        if isHistory then
            -- Clear and rebuild history
            local count = net.ReadUInt(16)
            for i = 1, count do
                local log = {
                    addon = net.ReadString(),
                    message = net.ReadString(),
                    level = net.ReadString(),
                    color = net.ReadColor(),
                    time = net.ReadUInt(32)
                }
                table.insert(lyx.LogHistory, log)
            end
        else
            -- Single log update
            local log = {
                addon = net.ReadString(),
                message = net.ReadString(),
                level = net.ReadString(),
                color = net.ReadColor(),
                time = net.ReadUInt(32)
            }
            table.insert(lyx.LogHistory, log)
            
            -- Trim if too large
            if #lyx.LogHistory > lyx.MaxLogHistory then
                table.remove(lyx.LogHistory, 1)
            end
            
            -- Trigger UI update if logs panel is open
            hook.Run("Lyx.LogUpdated", log)
        end
    end)
end