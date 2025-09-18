local logger = {}

local infoColor = Color(255, 255, 255)
local warnColor = Color(255, 255, 0)
local errorColor = Color(255, 0, 0)

do
    function logger:Log(message, level)
        -- First argument is the message, second (optional) is log level
        -- Log level is ignored for now but could be used for filtering
        if type(message) ~= "string" then
            message = tostring(message)
        end
        MsgC(self.color, "[" .. self.name .. "] ", infoColor, message, "\n")
    end

    function logger:Warn(...)
        local args = {...}
        local message = ""
        for i = 1, #args do
            message = message .. tostring(args[i])
        end
        MsgC(self.color, "[" .. self.name .. "] ", warnColor, message, "\n")
    end

    function logger:Error(...)
        local args = {...}
        local message = ""
        for i = 1, #args do
            message = message .. tostring(args[i])
        end
        MsgC(self.color, "[" .. self.name .. "] ", errorColor, message, "\n")
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