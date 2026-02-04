
lyx.RegisterFontUnscaled("UI.Overhead", "Open Sans Bold", 100)

local localPly
local function checkDistance(ent)
    if not IsValid(localPly) then localPly = LocalPlayer() end
    if localPly:GetPos():DistToSqr(ent:GetPos()) > 200000 then return true end
end

local disableClipping = DisableClipping
local start3d2d, end3d2d = lyx.Render.Start, lyx.Render.End
local Icon = icon

local drawOverhead
do
    local rand = math.Rand
    local sin = math.sin
    local curTime = CurTime
    drawOverhead = function(ent, pos, text, ang, scale, font, textColr)
        if ang then
            ang = ent:LocalToWorldAngles(ang)
        else
            ang = (pos - localPly:GetPos()):Angle()
            ang:SetUnpacked(0, ang[2] - 90, 90)
        end

        lyx.SetFont(font or "UI.Overhead")
        local w, h = lyx.GetTextSize(text)
        w = w + 40
        h = h + 6

        local x, y = -(w * .5), -h

        local oldClipping = disableClipping(true)

        if not ent.lyxOverheadOffset then ent.lyxOverheadOffset = rand(0, 10) end
        pos.z = pos.z + sin(curTime() - ent.lyxOverheadOffset) * 1.15

        local textColor
        local backgroundColor

        if MoonHud then
            backgroundColor = MoonHud.GetColor(1)
            textColor = textColr or MoonHud.GetColor(5)
        else
            backgroundColor = lyx.Colors.Background
            textColor =  lyx.Colors.PrimaryText
        end

        local camRender = start3d2d(pos, ang, scale or 0.05, 500, 200)
        if (!camRender) then return end
        
        if not Icon then
            lyx.DrawRoundedBox(12, x, y, w, h, backgroundColor)
            lyx.DrawText(text, "UI.Overhead", 0, y + 1, textColor, TEXT_ALIGN_CENTER)
        else
            x = x - 40
            lyx.DrawRoundedBox(12, x, y, w + 95, h, backgroundColor)
            lyx.DrawText(text, "UI.Overhead", x + h + 10, y, textColor)
            lyx.DrawImgur(x + 20, y + 10, h - 20, h - 20, Icon, lyx.Colors.Primary)
        end
        end3d2d()

        disableClipping(oldClipping)
    end
end

local entOffset = 2
function lyx.DrawEntOverhead(ent, text, angleOverride, posOverride, scaleOverride, mustLookAt, font, textColr)
    if !mustLookAt and checkDistance(ent) then return end
    if !textColr then textColr = lyx.Colors.PrimaryText end
    if mustLookAt then 
        local tr = util.TraceLine({
            start = localPly:EyePos(),
            endpos = localPly:EyePos() + localPly:GetAimVector() * 1000, 
            filter = {localPly}
        })

        if tr.Entity != ent then return end
    end
    
    if posOverride then
        drawOverhead(ent, ent:LocalToWorld(posOverride), text, angleOverride, scaleOverride, font, textColr)
        return
    end

    local pos = ent:OBBMaxs()
    pos:SetUnpacked(0, 0, pos[3] + entOffset)

    drawOverhead(ent, ent:LocalToWorld(pos), text, angleOverride, scaleOverride, font, textColr)
end

local eyeOffset = Vector(0, 0, 7)
local fallbackOffset = Vector(0, 0, 73)
function lyx.DrawNPCOverhead(ent, text, angleOverride, offsetOverride, scaleOverride, mustLookAt, font)
    if !mustLookAt and checkDistance(ent) then return end
    if mustLookAt then 
        local tr = util.TraceLine({
            start = localPly:EyePos(),
            endpos = localPly:EyePos() + localPly:GetAimVector() * 1000, 
            filter = {localPly}
        })

        if tr.Entity != ent then return end
    end

    local eyeId = ent:LookupAttachment("eyes")
    if eyeId then
        local eyes = ent:GetAttachment(eyeId)
        if eyes then
            eyes.Pos:Add(offsetOverride or eyeOffset)
            drawOverhead(ent, eyes.Pos, text, angleOverride, scaleOverride, font)
            return
        end
    end

    drawOverhead(ent, ent:GetPos() + fallbackOffset, text, angleOverride, scaleOverride, font)
end

function lyx.EnableIconOverheads(new)
    local oldIcon = Icon
    Icon = new
    return oldIcon
end