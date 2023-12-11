--[[
    Credit: <CODE BLUE>
    Link: https://gist.github.com/MysteryPancake/a31637af9fd531079236a2577145a754
]]--


-- Example:
--[[
lyxShadows.BeginShadow( "" )
local x, y = self:LocalToScreen( 0, 0 )
surface.SetDrawColor( Color(45, 45, 45) )
surface.DrawRect( x, y, w, h )
lyxShadows.EndShadow( "", x, y, 1, 1, 1, 255, 0, 0, false )


lyxShadows.BeginShadow( "" )
local x, y = self:LocalToScreen( 0, 0 )
lyxShadows.EndShadow( "", x, y, 1, 1, 1, 255, 0, 0, false )

]]--

lyxShadows = {}
lyxShadows.TEMP = {}

local function createShadows()
    --The original drawing layer
    lyxShadows.TEMP.ShadowRenderTarget = GetRenderTarget( "horizon_shadows_original_" .. ScrW(), ScrW(), ScrH() )
    
    --The matarial to draw the render targets on
    lyxShadows.TEMP.ShadowMaterial = CreateMaterial( "horizon_shadows_" .. ScrW(), "UnlitGeneric", {
        ["$translucent"] = 1,
        ["$vertexalpha"] = 1,
        ["alpha"] = 1
    } )

    lyxShadows.TEMP.CreatedShadows = {}
end
createShadows()

hook.Add( "OnScreenSizeChanged", "lyxShadows.OnScreenSizeChanged.BShadows", createShadows )

lyxShadows.TEMP.RTMaterials = lyxShadows.TEMP.RTMaterials or {}
local function createRTMaterial( uniqueID )
    local materialID
    for k, v in ipairs( lyxShadows.TEMP.RTMaterials or {} ) do
        if( v != true ) then continue end

        materialID = k
        break
    end

    if( not materialID ) then
        lyxShadows.TEMP.RTMaterials = lyxShadows.TEMP.RTMaterials or {}
        materialID = #lyxShadows.TEMP.RTMaterials+1
    end

    lyxShadows.TEMP.RTMaterials[materialID] = uniqueID

    return CreateMaterial( "horizon_shadows_grayscale_" .. ScrW() .. "_id_" .. materialID, "UnlitGeneric", {
        ["$translucent"] = 1,
        ["$vertexalpha"] = 1,
        ["$alpha"] = 1,
        ["$color"] = "0 0 0",
        ["$color2"] = "0 0 0"
    } )
end

lyxShadows.TEMP.ShadowRenderTargets = lyxShadows.TEMP.ShadowRenderTargets or {}
local function getShadowRenderTarget( uniqueID )
    local targetID
    for k, v in ipairs( lyxShadows.TEMP.ShadowRenderTargets or {} ) do
        if( v == uniqueID ) then 
            targetID = k
            break
        end
    end

    if( not targetID ) then
        for k, v in ipairs( lyxShadows.TEMP.ShadowRenderTargets or {} ) do
            if( v == true ) then 
                targetID = k
                break
            end
        end

        if( not targetID ) then
            lyxShadows.TEMP.ShadowRenderTargets = lyxShadows.TEMP.ShadowRenderTargets or {}
            targetID = #lyxShadows.TEMP.ShadowRenderTargets+1
        end
    
        lyxShadows.TEMP.ShadowRenderTargets[targetID] = uniqueID
    end

    return GetRenderTarget( "horizon_shadows_rt_" .. ScrW() .. "_id_" .. targetID, ScrW(), ScrH() )
end

--Call this to begin drawing a shadow
function lyxShadows.BeginShadow( uniqueID, areaX, areaY, areaEndX, areaEndY )
    if( not lyxShadows.TEMP.CreatedShadows[uniqueID] ) then
        lyxShadows.TEMP.CreatedShadows[uniqueID] = {}
        lyxShadows.TEMP.CreatedShadows[uniqueID].Started = true
    end

    if( not lyxShadows.TEMP.CreatedShadows[uniqueID].Started ) then return end
    
    --Set the render target so all draw calls draw onto the render target instead of the screen
    render.PushRenderTarget(lyxShadows.TEMP.ShadowRenderTarget)

    --Clear is so that theres no color or alpha
    render.OverrideAlphaWriteEnable(true, true)
    render.Clear(0,0,0,0)
    render.OverrideAlphaWriteEnable(false, false)

    local shadowTable = lyxShadows.TEMP.CreatedShadows[uniqueID]
    if( areaX and (not shadowTable[4] or shadowTable[4] != areaX or shadowTable[5] != areaY or shadowTable[6] != areaEndX or shadowTable[7] != areaEndY) ) then
        shadowTable[4] = areaX
        shadowTable[5] = areaY
        shadowTable[6] = areaEndX
        shadowTable[7] = areaEndY
    end

    --Start Cam2D as where drawing on a flat surface 
    cam.Start2D()

    --Now leave the rest to the user to draw onto the surface
end

--This will draw the shadow, and mirror any other draw calls the happened during drawing the shadow
function lyxShadows.EndShadow( uniqueID, x, y, intensity, spread, blur, opacity, direction, distance, _shadowOnly )
    local shadowTable = lyxShadows.TEMP.CreatedShadows[uniqueID]
    if( not shadowTable.Started ) then return end
    
    -- Set default opcaity
    opacity = opacity or 255
    direction = direction or 0
    distance = distance or 0
    _shadowOnly = _shadowOnly or false

    if( not shadowTable[1] or (shadowTable[8] and (shadowTable[10] or 0) != shadowTable[8]) or (shadowTable[9] and (shadowTable[11] or 0) != shadowTable[9]) or (shadowTable[12] or 1) != surface.GetAlphaMultiplier() ) then
        local shadowRenderTarget = getShadowRenderTarget( uniqueID )
        -- Copy this render target to the other
        render.CopyRenderTargetToTexture(shadowRenderTarget)
    
        --Blur the second render target
        if blur > 0 then
            render.OverrideAlphaWriteEnable(true, true)
            render.BlurRenderTarget(shadowRenderTarget, spread, spread, blur)
            render.OverrideAlphaWriteEnable(false, false) 
        end

        if( not shadowTable[1] ) then
            shadowTable[1] = createRTMaterial( uniqueID )
        end
        
        shadowTable[2] = x
        shadowTable[3] = y

        if( shadowTable[8] ) then
            shadowTable[10] = shadowTable[8]
            shadowTable[11] = shadowTable[9]
        end

        shadowTable[12] = surface.GetAlphaMultiplier()

        shadowTable[1]:SetTexture("$basetexture", shadowRenderTarget)
        shadowTable[1]:SetFloat("$alpha", opacity/255)
    end

    --First remove the render target that the user drew
    render.PopRenderTarget()

    --Now update the material to what was drawn
    lyxShadows.TEMP.ShadowMaterial:SetTexture('$basetexture', lyxShadows.TEMP.ShadowRenderTarget)
    
    --Work out shadow offsets
    local xOffset = math.sin(math.rad(direction)) * distance 
    local yOffset = math.cos(math.rad(direction)) * distance

    if( shadowTable[4] ) then render.SetScissorRect( shadowTable[4], shadowTable[5], shadowTable[6], shadowTable[7], true ) end

    render.SetMaterial(shadowTable[1])
    for i = 1 , math.ceil(intensity) do
        render.DrawScreenQuadEx(xOffset+(x-shadowTable[2]), yOffset+(y-shadowTable[3]), ScrW(), ScrH())
    end

    if( not _shadowOnly ) then
        if( shadowTable[4] ) then 
            render.SetScissorRect( 0, 0, 0, 0, false )
            render.SetScissorRect( shadowTable[4], shadowTable[5], shadowTable[6], shadowTable[7], true ) 
        end

        lyxShadows.TEMP.ShadowMaterial:SetTexture('$basetexture', lyxShadows.TEMP.ShadowRenderTarget)
        render.SetMaterial(lyxShadows.TEMP.ShadowMaterial)
        render.DrawScreenQuad()
    end

    if( shadowTable[4] ) then render.SetScissorRect( 0, 0, 0, 0, false ) end

    cam.End2D()
end

function lyxShadows.SetShadowSize( uniqueID, w, h )
    if( not lyxShadows.TEMP.CreatedShadows[uniqueID] ) then return end

    lyxShadows.TEMP.CreatedShadows[uniqueID][8] = w
    lyxShadows.TEMP.CreatedShadows[uniqueID][9] = h
end

function lyxShadows.DeleteShadow( uniqueID )
    if( not lyxShadows.TEMP.CreatedShadows[uniqueID] ) then return end

    for k, v in ipairs( lyxShadows.TEMP.RTMaterials or {} ) do
        if( v != uniqueID ) then continue end

        lyxShadows.TEMP.RTMaterials[k] = true
        break
    end

    for k, v in ipairs( lyxShadows.TEMP.ShadowRenderTargets or {} ) do
        if( v != uniqueID ) then continue end

        lyxShadows.TEMP.ShadowRenderTargets[k] = true
        break
    end

    lyxShadows.TEMP.CreatedShadows[uniqueID][1] = nil
    lyxShadows.TEMP.CreatedShadows[uniqueID] = nil
end