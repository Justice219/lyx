--[[
	LYXUI - Ported from PIXEL UI
	Arc Drawing Library
	https://gist.github.com/theawesomecoder61/d2c3a3d42bbce809ca446a85b4dda754

	Provides arc drawing utilities for circular UI elements.
	Arcs can be precached for performance or drawn directly.
]]

--- Draws an uncached arc directly to the screen
-- @param cx number Center X position
-- @param cy number Center Y position
-- @param radius number Outer radius
-- @param thickness number Ring thickness
-- @param startang number Start angle in degrees
-- @param endang number End angle span in degrees
-- @param roughness number Triangle density (1-360, lower = smoother)
-- @param color Color Arc color
function LYXUI.DrawUncachedArc(cx, cy, radius, thickness, startang, endang, roughness, color)
    surface.SetDrawColor(color)
    LYXUI.DrawArc(LYXUI.PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness))
end

--- Precalculates arc triangle vertices for repeated drawing
-- @param cx number Center X position
-- @param cy number Center Y position
-- @param radius number Outer radius
-- @param thickness number Ring thickness
-- @param startang number Start angle in degrees
-- @param endang number End angle span in degrees
-- @param roughness number Triangle density (1-360, lower = smoother)
-- @return table Array of triangle vertex tables for use with DrawArc
function LYXUI.PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness)
    local triarc = {}
    roughness = math.max(roughness or 1, 1)
    local step = roughness
    startang, endang = startang or 0, endang or 0
    endang = startang + endang

    if startang > endang then
        step = math.abs(step) * -1
    end

    local inner = {}
    local r = radius - thickness

    for deg = startang, endang, step do
        local rad = math.rad(deg)
        local ox, oy = cx + (math.cos(rad) * r), cy + (-math.sin(rad) * r)

        table.insert(inner, {
            x = ox,
            y = oy,
            u = (ox - cx) / radius + .5,
            v = (oy - cy) / radius + .5
        })
    end

    local outer = {}

    for deg = startang, endang, step do
        local rad = math.rad(deg)
        local ox, oy = cx + (math.cos(rad) * radius), cy + (-math.sin(rad) * radius)

        table.insert(outer, {
            x = ox,
            y = oy,
            u = (ox - cx) / radius + .5,
            v = (oy - cy) / radius + .5
        })
    end

    for tri = 1, #inner * 2 do
        local p1, p2, p3
        p1 = outer[math.floor(tri / 2) + 1]
        p3 = inner[math.floor((tri + 1) / 2) + 1]

        if tri % 2 == 0 then
            p2 = outer[math.floor((tri + 1) / 2)]
        else
            p2 = inner[math.floor((tri + 1) / 2)]
        end

        table.insert(triarc, {p1, p2, p3})
    end

    return triarc
end

--- Draws a precached arc (array of triangle polygons)
-- @param arc table Precached arc from PrecacheArc
function LYXUI.DrawArc(arc)
    for k, v in ipairs(arc) do
        surface.DrawPoly(v)
    end
end
