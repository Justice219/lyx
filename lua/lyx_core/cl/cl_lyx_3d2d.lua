/*
    EXAMPLE:
    local camRender = lyx.Render.Start(pos, angles, scale, distanceHide, distanceFadeStart)
        // RENDERING GOES HERE
    lyx.Render.End(camRender)
*/

do
    lyx.Render = {}

    local localPlayer 
    local render_SetBlend = render.SetBlend
    local surface_SetAlphaMultiplier = surface.SetAlphaMultiplier
    local math_Min = math.min
    local math_Remap = math.Remap
    local cam_Start3D2D = cam.Start3D2D
    local cam_End3D2D = cam.End3D2D

    local isRendering = false

    local startRender = function(pos, angles, scale, distanceHide, distanceFadeStart, showBack)
        if not IsValid(localPlayer) then
            localPlayer = LocalPlayer()
        end

        isRendering = true 

        local eyePos = localPlayer:EyePos()
        if eyePos:DistToSqr(pos) > 2000000 then return false end

        local eyePos = localPlayer:EyePos()
        local eyePosToPos = pos - eyePos
    
        --? Check that we are in front of the UI
        if (!showBack) then
            local normal = angles:Up()
            local dot = eyePosToPos:Dot(normal)
            
            if dot >= 0 then
                isRendering = false
                return false
            end
        end
    
        --? Distance based fade/hide
        if distanceHide then
            local distance = eyePosToPos:Length()
            if distance < distanceHide then
                if distanceHide and distanceFadeStart and distance > distanceFadeStart then
                    local blend = math_Min(math_Remap(distance, distanceFadeStart, distanceHide, 1, 0), 1)
                    render_SetBlend(blend)
                    surface_SetAlphaMultiplier(blend)
                    isRendering = true
                end
            else
                isRendering = false
                return false
            end
        end
        cam_Start3D2D(pos, angles, scale)
        return true
    end
    lyx.Render.Start = startRender

    function lyx.Render.StartEntity(ent, lpos, lang, scale, ...)
        return startRender(ent:LocalToWorld(lpos), ent:LocalToWorldAngles(lang), scale, ...)
    end

    function lyx.Render.End()
        if (!isRendering) then return end

        cam_End3D2D()
        render_SetBlend(1)
        surface_SetAlphaMultiplier(1)
    end

    hook.Add("PreRender", "lyx.UI3D2D.GetLocalPlayer", function()
        localPlayer = LocalPlayer()
        if (IsValid(localPlayer)) then hook.Remove("PreRender", "lyx.UI3D2D.GetLocalPlayer") end
    end)
end
