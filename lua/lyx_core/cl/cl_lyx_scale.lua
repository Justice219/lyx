
local scale
do
    local scrh = ScrH
    local max = math.max
    scale = function(value)
        return max(value * (scrh() / 1080), 1)
    end
    lyx.Scale = scale

    local scrw = ScrW
    scalew = function(value)
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
