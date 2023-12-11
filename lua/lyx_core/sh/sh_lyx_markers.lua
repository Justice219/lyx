lyx = lyx

do
    if SERVER then
        util.AddNetworkString("lyx:marker:create")
    elseif CLIENT then
        lyx.markers = {}
    end
    
    function lyx:MarkerCreate(pos, data)
        if SERVER then
            net.Start("lyx:marker:create")
            net.WriteVector(pos)
            net.WriteTable(data)
            if data.player then
                net.Send(data.player)
            else
                net.Broadcast()
            end
        return end
            
        local startpos = pos
        local color = data.color or Color(255, 255, 255)
        local material = data.material or "models/debug/debugwhite"
        local model = data.model or "models/hunter/tubes/tube2x2x2.mdl"
        
        local marker = ents.CreateClientProp(model)
        marker:SetPos(startpos)
        marker:SetAngles(Angle(0, 0, 0))
        marker:SetColor(color)
        marker:SetMaterial(material)
        marker:Spawn()
    
        marker:GetPhysicsObject():EnableMotion(false)
        -- MAKE TRANSPARENT
        marker:SetRenderMode(RENDERMODE_TRANSALPHA)
        -- FIX SHADOW
        marker:DrawShadow(false)
    
        local think = nil
    
        think = lyx:HookStart("Think", function(...)
            print("think")
            if startpos:Distance(LocalPlayer():GetPos()) < 5 then
                if IsValid(marker) then
                    marker:Remove()
                end
                data.callback()
                lyx:HookRemove("Think", think)
            else
                chat.AddText(Color(255, 0, 0), "You are too far away from the marker.")
                chat.AddText(Color(255, 0, 0), startpos:Distance(LocalPlayer():GetPos()))
            end
        end)
    
        lyx.markers[marker] = {
            ent = marker,
            pos = pos,
        }
    
        lyx.Logger:Log("Marker created at " .. tostring(pos))
        return marker
    end
    
    if CLIENT then
        net.Receive("lyx:marker:create", function(len)
            local pos = net.ReadVector()
            local data = net.ReadTable()
            local drawing = lyx:MarkerCreate(pos, data)
        end)
    
        concommand.Add("lyx_marker_create", function(ply, cmd, args)
            local pos = Vector(-494.152191, -38.879238, -12223.968750) + Vector(0, 0, 45)
            local data = {
                player = ply,
                color = args[3] or Color(38, 255, 154, 154),
                alpha = args[4] or 225,
                material = "models/debug/debugwhite",
                model = "models/hunter/tubes/tube2x2x2.mdl",
                callback = function()
                    chat.AddText(Color(255, 255, 255), "Marker created at " .. tostring(pos))
                end
            }
            lyx:MarkerCreate(pos, data)
        end)
    end 
end