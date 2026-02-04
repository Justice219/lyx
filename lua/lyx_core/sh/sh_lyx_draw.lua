lyx = lyx
do
    if SERVER then
        util.AddNetworkString("lyx_draw_circle")
        util.AddNetworkString("lyx_draw_line")
        util.AddNetworkString("lyx_draw_box")
    elseif CLIENT then
        lyx.drawing = {}
    end
    
    function lyx:DrawCircle(pos,tbl)
        if SERVER then
            net.Start("lyx_draw_circle")
            net.WriteVector(pos)
            net.WriteFloat(tbl.radius)
            net.WriteColor(tbl.color)
            net.WriteFloat(tbl.width)
    
            if IsValid(tbl.ply) then
                net.Send(tbl.ply)
            else
                net.Broadcast()
            end   
        return end
    
        local x,y = pos.x,pos.y
        local radius = tbl.radius
        local width = tbl.width
    
        local drawing = lyx:HookStart("PostDrawTranslucentRenderables", function(...)
            surface.SetDrawColor(tbl.color)
            surface.DrawCircle(x,y,radius,width)
        end)
    
        lyx.drawing[drawing] = {
            pos = pos,
            radius = radius,
            width = width,
            color = tbl.color,
            type = "circle"
        }
    
        lyx.Logger:Log("Drawing circle at "..tostring(pos).." with radius "..tostring(radius).." and width "..tostring(width))
        return drawing
    end
    
    function lyx:DrawBox(pos, tbl)
        if SERVER then
            net.Start("lyx_draw_box")
            net.WriteVector(pos)
            net.WriteAngle(tbl.ang)
            net.WriteVector(tbl.min)
            net.WriteVector(tbl.max)
            net.WriteColor(tbl.color)
    
            if IsValid(tbl.ply) then
                net.Send(tbl.ply)
            else
                net.Broadcast()
            end
        return end
    
        local ang = tbl.ang
        local min = tbl.min
        local max = tbl.max
        local color = tbl.color
    
        local drawing = lyx:HookStart("PostDrawTranslucentRenderables", function(...)
            render.SetColorMaterial() 
            render.DrawBox(pos, ang, min, max, color)
        end)
    
        lyx.drawing[drawing] = {
            pos = pos,
            ang = ang,
            min = min,
            max = max,
            color = color,
            type = "box"
        }
    
        lyx.Logger:Log("Drawing box at "..tostring(pos).." with angle "..tostring(ang).." and min "..tostring(min).." and max "..tostring(max))
        return drawing
    end
    
    function lyx:DrawLine()
        if SERVER then
            
        return end
    
    end
    
    if CLIENT then
        net.Receive("lyx_draw_circle", function()
            local pos = net.ReadVector()
            local radius = net.ReadFloat()
            local color = net.ReadColor()
            local width = net.ReadFloat()
            lyx:DrawCircle(pos, {
                radius = radius,
                color = color,
                width = width
            })
        end)
    
        net.Receive("lyx_draw_box", function()
            local pos = net.ReadVector()
            local ang = net.ReadAngle()
            local min = net.ReadVector()
            local max = net.ReadVector()
            local color = net.ReadColor()
            lyx:DrawBox(pos, {
                ang = ang,
                min = min,
                max = max,
                color = color
            })
        end)
    
        concommand.Add("lyx_draw_box", function(ply, cmd, args)
            lyx:DrawBox(Vector(944.000000, 289.625000, -79.000000), {
                ang = Angle(0.000000, 0.000000, 0.000000),
                min = Vector(5.000000, 20.000000, 5.000000),
                max = Vector(-5.000000, -5.000000, -5.000000),
                color = Color(46, 196, 255),
            })
        end)
    
        concommand.Add("lyx_print_drawing", function(ply, cmd, args)
            for k,v in pairs(lyx.drawing) do
                lyx.Logger:Log(tostring(k).." "..tostring(v.type).." at "..tostring(v.pos).." with angle "..tostring(v.ang).." and min "..tostring(v.min).." and max "..tostring(v.max))
            end
        end)
    
        concommand.Add("lyx_clear_drawing", function(ply, cmd, args)
            for k,v in pairs(lyx.drawing) do
                lyx:HookRemove("PostDrawTranslucentRenderables", k)
                lyx.Logger:Log("Removed drawing "..tostring(k))
            end
            lyx.drawing = {}
            lyx.Logger:Log("Cleared all drawings")
        end)
    end
end