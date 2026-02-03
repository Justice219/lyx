--[[
	LYXUI Circle Drawing
	Ported from PIXEL UI.

	Provides circle drawing using URL-based image assets at various resolutions
	and polygon-based circle creation/drawing utilities.

	Functions:
	  LYXUI.DrawCircle(x, y, w, h, col) - Draws a circle using best-fit image
	  LYXUI.CreateCircle(x, y, ang, seg, pct, radius) - Creates circle polygon vertices
	  LYXUI.DrawCircleUncached(x, y, ang, seg, pct, radius) - Draws a polygon circle directly
]]

do
    -- Pre-rendered circle images at power-of-2 sizes (8px to 2048px)
    local materials = {
        "https://pixel-cdn.lythium.dev/i/srlt7tk7m",  --8
        "https://pixel-cdn.lythium.dev/i/l2km82zi",   --16
        "https://pixel-cdn.lythium.dev/i/5mqrguuxd",  --32
        "https://pixel-cdn.lythium.dev/i/yxh641f2a",  --64
        "https://pixel-cdn.lythium.dev/i/yz2n2neu",   --128
        "https://pixel-cdn.lythium.dev/i/v4sxyjdd8",  --256
        "https://pixel-cdn.lythium.dev/i/nmp8368j",   --512
        "https://pixel-cdn.lythium.dev/i/e425w7lrj",  --1024
        "https://pixel-cdn.lythium.dev/i/iinrlgj5b"   --2048
    }

    local max = math.max

    --- Draws a circle using the best-resolution cached image for the given size
    -- @param x number X position
    -- @param y number Y position
    -- @param w number Width
    -- @param h number Height
    -- @param col Color Circle color
    function LYXUI.DrawCircle(x, y, w, h, col)
        local size = max(w, h)
        local id = materials[1]

        local curSize = 8
        for i = 1, #materials do
            if size <= curSize then break end
            id = materials[i + 1] or id
            curSize = curSize + curSize
        end

        LYXUI.DrawImage(x, y, w, h, id, col)
    end
end

do
    local insert = table.insert
    local rad, sin, cos = math.rad, math.sin, math.cos

    --- Creates a circle polygon as a table of vertices
    -- @param x number Center X
    -- @param y number Center Y
    -- @param ang number Starting angle in degrees
    -- @param seg number Number of segments
    -- @param pct number Arc percentage (360 = full circle)
    -- @param radius number Circle radius
    -- @return table Vertex table for surface.DrawPoly
    function LYXUI.CreateCircle(x, y, ang, seg, pct, radius)
        local circle = {}

        insert(circle, {x = x, y = y})

        for i = 0, seg do
            local segAngle = rad((i / seg) * -pct + ang)
            insert(circle, {x = x + sin(segAngle) * radius, y = y + cos(segAngle) * radius})
        end

        return circle
    end
end

local createCircle = LYXUI.CreateCircle
local drawPoly = surface.DrawPoly

--- Draws a circle polygon directly without caching
-- @param x number Center X
-- @param y number Center Y
-- @param ang number Starting angle
-- @param seg number Number of segments
-- @param pct number Arc percentage
-- @param radius number Radius
function LYXUI.DrawCircleUncached(x, y, ang, seg, pct, radius)
    drawPoly(createCircle(x, y, ang, seg, pct, radius))
end
