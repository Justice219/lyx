--[[
	LYXUI Rounded Box Drawing
	Ported from PIXEL UI.

	Provides RNDX shader-based rounded box drawing functions.
	These use GPU shaders for anti-aliased, high-quality rounded rectangles
	instead of texture-based approaches.

	Functions:
	  LYXUI.DrawRoundedBox(borderSize, x, y, w, h, col)
	  LYXUI.DrawRoundedBoxEx(borderSize, x, y, w, h, col, tl, tr, bl, br)
	  LYXUI.DrawFullRoundedBox(borderSize, x, y, w, h, col)
	  LYXUI.DrawFullRoundedBoxEx(borderSize, x, y, w, h, col, tl, tr, bl, br)
]]

local RNDX_DRAW, RNDX_FLAG_TL, RNDX_FLAG_TR, RNDX_FLAG_BL, RNDX_FLAG_BR, RNDX_SHAPE_CIRCLE

--- Internal: Draws a rounded box with per-corner control using RNDX shaders
-- @param borderSize number Corner radius in pixels
-- @param x number X position
-- @param y number Y position
-- @param w number Width
-- @param h number Height
-- @param col Color Fill color
-- @param tl boolean|nil Draw top-left corner (false to skip)
-- @param tr boolean|nil Draw top-right corner (false to skip)
-- @param bl boolean|nil Draw bottom-left corner (false to skip)
-- @param br boolean|nil Draw bottom-right corner (false to skip)
local function DrawFullRoundedBoxEx(borderSize, x, y, w, h, col, tl, tr, bl, br)
    if not RNDX_DRAW then
        if not LYXUI.RNDX then return end

        RNDX_DRAW = LYXUI.RNDX.Draw
        RNDX_FLAG_TL = LYXUI.RNDX.NO_TL
        RNDX_FLAG_TR = LYXUI.RNDX.NO_TR
        RNDX_FLAG_BL = LYXUI.RNDX.NO_BL
        RNDX_FLAG_BR = LYXUI.RNDX.NO_BR
        RNDX_SHAPE_CIRCLE = LYXUI.RNDX.SHAPE_CIRCLE
    end

    local flags = RNDX_SHAPE_CIRCLE

    if tl == false then flags = flags + RNDX_FLAG_TL end
    if tr == false then flags = flags + RNDX_FLAG_TR end
    if bl == false then flags = flags + RNDX_FLAG_BL end
    if br == false then flags = flags + RNDX_FLAG_BR end

    RNDX_DRAW(borderSize, x, y, w, h, col, flags)
end

LYXUI.DrawFullRoundedBoxEx = DrawFullRoundedBoxEx

--- Draws a rounded box with per-corner rounding control
-- @param borderSize number Corner radius in pixels
-- @param x number X position
-- @param y number Y position
-- @param w number Width
-- @param h number Height
-- @param col Color Fill color
-- @param topLeft boolean Round top-left corner
-- @param topRight boolean Round top-right corner
-- @param bottomLeft boolean Round bottom-left corner
-- @param bottomRight boolean Round bottom-right corner
function LYXUI.DrawRoundedBoxEx(borderSize, x, y, w, h, col, topLeft, topRight, bottomLeft, bottomRight)
    return DrawFullRoundedBoxEx(borderSize, x, y, w, h, col, topLeft, topRight, bottomLeft, bottomRight)
end

--- Draws a rounded box with uniform corner radius
-- @param borderSize number Corner radius in pixels
-- @param x number X position
-- @param y number Y position
-- @param w number Width
-- @param h number Height
-- @param col Color Fill color
function LYXUI.DrawRoundedBox(borderSize, x, y, w, h, col)
    return DrawFullRoundedBoxEx(borderSize, x, y, w, h, col, true, true, true, true)
end

--- Alias for DrawRoundedBox with all corners rounded
function LYXUI.DrawFullRoundedBox(borderSize, x, y, w, h, col)
    return DrawFullRoundedBoxEx(borderSize, x, y, w, h, col, true, true, true, true)
end
