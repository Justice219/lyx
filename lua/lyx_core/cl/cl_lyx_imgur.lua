local materials = {}
file.CreateDir("lyx_lib")
file.CreateDir("lyx_lib/materials")

function lyx.GetImgur(id, callback, matSettings)
    if materials[id] then return callback(materials[id]) end

    if file.Exists("lyx_lib/materials/" .. id .. ".png", "DATA") then
        materials[id] = Material("../data/lyx_lib/materials/" .. id .. ".png", matSettings or "noclamp smooth mips")

        return callback(materials[id])
    end

    http.Fetch(useproxy and "https://proxy.duckduckgo.com/iu/?u=https://i.imgur.com" or "https://i.imgur.com/" .. id .. ".png", function(body, len, headers, code)
        if len > 2097152 then
            materials[id] = Material("nil")

            return callback(materials[id])
        end

        file.Write("lyx_lib/materials/" .. id .. ".png", body)
        materials[id] = Material("../data/lyx_lib/materials/" .. id .. ".png", matSettings or "noclamp smooth mips")

        return callback(materials[id])
    end, function(error)
        if useproxy then
            materials[id] = Material("nil")

            return callback(materials[id])
        end

        return lyx.GetImgur(id, callback, true)
    end)
end


local setMaterial = surface.SetMaterial
local setDrawColor = surface.SetDrawColor

local drawProgressWheel
do
    local spinnerMaterial
    local min = math.min
    local curTime = CurTime
    local drawTexturedRectRotated = surface.DrawTexturedRectRotated
    drawProgressWheel = function(x, y, w, h, col)
        local progSize = min(w, h)
        setMaterial(spinnerMaterial)
        setDrawColor(col.r, col.g, col.b, col.a)
        drawTexturedRectRotated(x + w * .5, y + h * .5, progSize, progSize, -curTime() * 100)
    end

    lyx.DrawProgressWheel = drawProgressWheel
    lyx.GetImgur("635PPvg", function(data) spinnerMaterial = data end)
end

local materials = {}
local grabbingMaterials = {}

local getImgur = lyx.GetImgur

do
    local drawTexturedRect = surface.DrawTexturedRect

    function lyx.DrawImgur(x, y, w, h, imgurId, col)
        if not materials[imgurId] then
            drawProgressWheel(x, y, w, h, col)

            if grabbingMaterials[imgurId] then return end
            grabbingMaterials[imgurId] = true

            getImgur(imgurId, function(mat)
                materials[imgurId] = mat
                grabbingMaterials[imgurId] = nil
            end)

            return
        end

        setMaterial(materials[imgurId])
        setDrawColor(col.r, col.g, col.b, col.a)
        drawTexturedRect(x, y, w, h)
    end
end

do
    local drawTexturedRectRotated = surface.DrawTexturedRectRotated
    function lyx.DrawImgurRotated(x, y, w, h, rot, imgurId, col)
        if not materials[imgurId] then
            drawProgressWheel(x - w * .5, y - h * .5, w, h, col)

            if grabbingMaterials[imgurId] then return end
            grabbingMaterials[imgurId] = true

            getImgur(imgurId, function(mat)
                materials[imgurId] = mat
                grabbingMaterials[imgurId] = nil
            end)

            return
        end

        setMaterial(materials[imgurId])
        setDrawColor(col.r, col.g, col.b, col.a)
        drawTexturedRectRotated(x, y, w, h, rot)
    end
end