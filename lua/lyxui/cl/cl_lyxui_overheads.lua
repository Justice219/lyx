--[[
	LYXUI Overhead Drawing
	Ported from PIXEL UI.

	Provides 3D overhead text/label rendering above entities and NPCs.
	Uses lyx.* for font, text, and scaling utilities; LYXUI.* for drawing.

	Functions:
	  LYXUI.DrawEntOverhead(ent, text, angleOverride, posOverride, scaleOverride)
	  LYXUI.DrawNPCOverhead(ent, text, angleOverride, offsetOverride, scaleOverride)
	  LYXUI.EnableIconOverheads(imageURL) - Enables icon mode for overhead labels
]]

lyx.RegisterFontUnscaled("LYXUI.Overhead", "Open Sans Bold", 100)

local localPly
--- Checks if the local player is too far from an entity to render overhead
-- @param ent Entity The entity to check distance to
-- @return boolean True if too far (should skip rendering)
local function checkDistance(ent)
    if not IsValid(localPly) then localPly = LocalPlayer() end
    if localPly:GetPos():DistToSqr(ent:GetPos()) > 200000 then return true end
end

local disableClipping = DisableClipping
local start3d2d, end3d2d = cam.Start3D2D, cam.End3D2D
local Icon = icon

--- Internal: Renders an overhead label above a world position
local function drawOverhead(ent, pos, text, ang, scale)
    if ang then
        ang = ent:LocalToWorldAngles(ang)
    else
        ang = (pos - localPly:GetPos()):Angle()
        ang:SetUnpacked(0, ang[2] - 90, 90)
    end

    lyx.SetFont("LYXUI.Overhead")
    local w, h = lyx.GetTextSize(text)
    w = w + 40
    h = h + 6

    local x, y = -(w * .5), -h

    local oldClipping = disableClipping(true)

    start3d2d(pos, ang, scale or 0.05)
    if not Icon then
        LYXUI.DrawRoundedBox(12, x, y, w, h, LYXUI.Colors.Primary)
        lyx.DrawText(text, "LYXUI.Overhead", 0, y + 1, LYXUI.Colors.PrimaryText, TEXT_ALIGN_CENTER)
    else
        x = x - 40
        LYXUI.DrawRoundedBox(12, x, y, h, h, LYXUI.Colors.Primary)
        LYXUI.DrawRoundedBoxEx(12, x + (h - 12), y + h - 20, w + 15, 20, LYXUI.Colors.Primary, false, false, false, true)
        lyx.DrawText(text, "LYXUI.Overhead", x + h + 15, y + 8, LYXUI.Colors.PrimaryText)
        LYXUI.DrawImage(x + 10, y + 10, h - 20, h - 20, Icon, color_white)
    end
    end3d2d()

    disableClipping(oldClipping)
end

local entOffset = 2

--- Draws an overhead text label above an entity
-- @param ent Entity The entity to draw above
-- @param text string Text to display
-- @param angleOverride Angle Optional custom angle
-- @param posOverride Vector Optional local position offset
-- @param scaleOverride number Optional 3D2D scale (default 0.05)
function LYXUI.DrawEntOverhead(ent, text, angleOverride, posOverride, scaleOverride)
    if checkDistance(ent) then return end

    if posOverride then
        drawOverhead(ent, ent:LocalToWorld(posOverride), text, angleOverride, scaleOverride)
        return
    end

    local pos = ent:OBBMaxs()
    pos:SetUnpacked(0, 0, pos[3] + entOffset)

    drawOverhead(ent, ent:LocalToWorld(pos), text, angleOverride, scaleOverride)
end

local eyeOffset = Vector(0, 0, 7)
local fallbackOffset = Vector(0, 0, 73)

--- Draws an overhead text label above an NPC (using eye attachment for position)
-- @param ent Entity The NPC entity
-- @param text string Text to display
-- @param angleOverride Angle Optional custom angle
-- @param offsetOverride Vector Optional eye offset (default Vector(0,0,7))
-- @param scaleOverride number Optional 3D2D scale
function LYXUI.DrawNPCOverhead(ent, text, angleOverride, offsetOverride, scaleOverride)
    if checkDistance(ent) then return end

    local eyeId = ent:LookupAttachment("eyes")
    if eyeId then
        local eyes = ent:GetAttachment(eyeId)
        if eyes then
            eyes.Pos:Add(offsetOverride or eyeOffset)
            drawOverhead(ent, eyes.Pos, text, angleOverride, scaleOverride)
            return
        end
    end

    drawOverhead(ent, ent:GetPos() + fallbackOffset, text, angleOverride, scaleOverride)
end

--- Enables or disables icon mode for overhead labels
-- @param new string|nil Image URL or Imgur ID for the icon. nil to disable.
-- @return string|nil The previous icon URL
function LYXUI.EnableIconOverheads(new)
    local oldIcon = Icon
    local imgurMatch = (new or ""):match("^[a-zA-Z0-9]+$")
    if imgurMatch then
        new = "https://i.imgur.com/" .. new .. ".png"
    end
    Icon = new
    return oldIcon
end
