lyx = lyx

--[[
.____                    _______ ___________________  
|    |    ___.__.___  ___\      \\______   \_   ___ \ 
|    |   <   |  |\  \/  //   |   \|     ___/    \  \/ 
|    |___ \___  | >    </    |    \    |   \     \____
|_______ \/ ____|/__/\_ \____|__  /____|    \______  /
        \/\/           \/       \/                 \/ 

Simple library for creating npcs with little to no effort.

]]--

do
    function lyx:NPCSpawn(path, data)
        local npc = ents.Create(path)
        npc:SetPos(data.pos)
        npc:SetAngles(data.ang)
        npc:Spawn()
        npc:SetHealth(data.health)
    
        local id = lyx:UtilNewID()
        hook.Add("OnNPCKilled", "lyx_npc" .. id, function(npc, attacker, inflictor)
            if npc:GetClass() == path then
                data.death(npc, attacker, inflictor)
                hook.Remove("OnNPCKilled", "lyx_npc" .. id)
            end
        end)
    
        npc.id = id
        npc.death = data.death
        return npc
    end
    
    function lyx:NPCKill(npc)
        hook.Remove("OnNPCKilled", "lyx_npc" .. npc.id)
        npc.death(npc, nil, nil)
        npc:Remove()
    end 
end

--[[ Examples on how to use this library.

lyx:NPCSpawn("npc_monk", {
    pos = Vector(294.992615, 45.469769, -84.019943),
    ang = Angle(0, 0, 0),
    health = 5,
    death = function(npc, attacker, inflictor)
        attacker:ChatPrint("You have killed the npc!")
    end
})

--]]