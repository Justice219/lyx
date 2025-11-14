
local scale
do
    local scrh = ScrH
    local scrw = ScrW
    local max = math.max

    -- Scale helper with nil/string safety for legacy calls
    scale = function(value)
        if value == nil then return 1 end
        if type(value) == "string" then value = tonumber(value) end
        if type(value) ~= "number" then return 1 end
        return max(value * (scrh() / 1080), 1)
    end
    lyx.Scale = scale

    scalew = function(value)
        if value == nil then return 1 end
        if type(value) == "string" then value = tonumber(value) end
        if type(value) ~= "number" then return 1 end
        return max(value * (scrw() / 1920), 1)
    end
    lyx.ScaleW = scalew    
end

local constants = {}
local scaledConstants = {}
function lyx:RegisterScaledConstant(varName, size)
    constants[varName] = size
    scaledConstants[varName] = scale(size)
end

function lyx.GetScaledConstant(varName)
    return scaledConstants[varName]
end

hook.Add("OnScreenSizeChanged", "lyx.UpdateScaledConstants", function()
    for varName, size in pairs(constants) do
        scaledConstants[varName] = scale(size)
    end
end)
