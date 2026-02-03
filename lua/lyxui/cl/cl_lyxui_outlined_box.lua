--[[
	LYXUI Outlined Box Drawing
	Ported from PIXEL UI.

	Provides RNDX shader-based outlined (stroke-only) rounded box drawing.

	Functions:
	  LYXUI.DrawOutlinedBox(x, y, w, h, thickness, col)
	  LYXUI.DrawOutlinedRoundedBox(borderSize, x, y, w, h, col, thickness)
	  LYXUI.DrawOutlinedRoundedBoxEx(borderSize, x, y, w, h, col, thickness, tl, tr, bl, br)
]]

local RNDX_SHAPE_CIRCLE, RNDX_NO_TL, RNDX_NO_TR, RNDX_NO_BL, RNDX_NO_BR, RNDX_DRAW_OUTLINED

--- Draws a non-rounded outlined box
-- @param x number X position
-- @param y number Y position
-- @param w number Width
-- @param h number Height
-- @param thickness number Outline stroke width
-- @param col Color Outline color
function LYXUI.DrawOutlinedBox(x, y, w, h, thickness, col)
	LYXUI.RNDX.DrawOutlined(0, x, y, w, h, col, thickness)
end

--- Internal: Draws an outlined rounded box with per-corner control
local function DrawOutlinedRoundedBoxEx(borderSize, x, y, w, h, col, thickness, tl, tr, bl, br)
	if not RNDX_DRAW_OUTLINED then
		if not LYXUI.RNDX then return end

		RNDX_SHAPE_CIRCLE = LYXUI.RNDX.SHAPE_CIRCLE
		RNDX_NO_TL = LYXUI.RNDX.NO_TL
		RNDX_NO_TR = LYXUI.RNDX.NO_TR
		RNDX_NO_BL = LYXUI.RNDX.NO_BL
		RNDX_NO_BR = LYXUI.RNDX.NO_BR
		RNDX_DRAW_OUTLINED = LYXUI.RNDX.DrawOutlined
	end

	local flags = RNDX_SHAPE_CIRCLE

	if tl == false then flags = flags + RNDX_NO_TL end
	if tr == false then flags = flags + RNDX_NO_TR end
	if bl == false then flags = flags + RNDX_NO_BL end
	if br == false then flags = flags + RNDX_NO_BR end

	RNDX_DRAW_OUTLINED(borderSize, x, y, w, h, col, thickness, flags)
end

LYXUI.DrawOutlinedRoundedBoxEx = DrawOutlinedRoundedBoxEx

--- Draws a uniformly-rounded outlined box
-- @param borderSize number Corner radius
-- @param x number X position
-- @param y number Y position
-- @param w number Width
-- @param h number Height
-- @param col Color Outline color
-- @param thickness number Outline stroke width
function LYXUI.DrawOutlinedRoundedBox(borderSize, x, y, w, h, col, thickness)
	return DrawOutlinedRoundedBoxEx(borderSize, x, y, w, h, col, thickness, true, true, true, true)
end
