lyx = lyx

--[[
    Lyx Admin Commands
    Server-side implementation of admin commands from the player management panel
]]--

-- Network strings
util.AddNetworkString("lyx:admin:kick")
util.AddNetworkString("lyx:admin:ban")
util.AddNetworkString("lyx:admin:freeze")
util.AddNetworkString("lyx:admin:goto")
util.AddNetworkString("lyx:admin:bring")
util.AddNetworkString("lyx:admin:return")
util.AddNetworkString("lyx:admin:slay")
util.AddNetworkString("lyx:admin:slap")
util.AddNetworkString("lyx:admin:ignite")
util.AddNetworkString("lyx:admin:giveweapon")

-- Store return positions
local returnPositions = {}

-- Kick command
net.Receive("lyx:admin:kick", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local target = net.ReadEntity()
    local reason = net.ReadString()
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    -- Check rank hierarchy
    if target:IsAdmin() and not ply:IsSuperAdmin() then
        ply:ChatPrint("You cannot kick other admins!")
        return
    end
    
    lyx.Logger:Log(ply:Nick() .. " kicked " .. target:Nick() .. " (Reason: " .. reason .. ")")
    
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint(target:Nick() .. " was kicked by " .. ply:Nick() .. " (Reason: " .. reason .. ")")
    end
    
    target:Kick(reason)
end)

-- Ban command
net.Receive("lyx:admin:ban", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local target = net.ReadEntity()
    local duration = net.ReadUInt(16)
    local reason = net.ReadString()
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    -- Check rank hierarchy
    if target:IsAdmin() and not ply:IsSuperAdmin() then
        ply:ChatPrint("You cannot ban other admins!")
        return
    end
    
    local banText = duration == 0 and "permanently" or "for " .. duration .. " minutes"
    
    lyx.Logger:Log(ply:Nick() .. " banned " .. target:Nick() .. " " .. banText .. " (Reason: " .. reason .. ")")
    
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint(target:Nick() .. " was banned " .. banText .. " by " .. ply:Nick() .. " (Reason: " .. reason .. ")")
    end
    
    -- Use ULX if available, otherwise use basic ban
    if ulx and ulx.ban then
        ulx.ban(ply, target, duration, reason)
    else
        if duration == 0 then
            target:Ban(0, true)
        else
            target:Ban(duration, true)
        end
        target:Kick("Banned: " .. reason)
    end
end)

-- Freeze command
net.Receive("lyx:admin:freeze", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local target = net.ReadEntity()
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    local frozen = target:IsFrozen()
    target:Freeze(not frozen)
    
    lyx.Logger:Log(ply:Nick() .. (frozen and " unfroze " or " froze ") .. target:Nick())
    
    ply:ChatPrint("You " .. (frozen and "unfroze " or "froze ") .. target:Nick())
    target:ChatPrint("You were " .. (frozen and "unfrozen" or "frozen") .. " by " .. ply:Nick())
end)

-- Goto command
net.Receive("lyx:admin:goto", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local target = net.ReadEntity()
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    -- Store return position
    returnPositions[ply:SteamID()] = ply:GetPos()
    
    -- Teleport to target
    ply:SetPos(target:GetPos() + Vector(50, 0, 0))
    
    lyx.Logger:Log(ply:Nick() .. " teleported to " .. target:Nick())
    
    ply:ChatPrint("Teleported to " .. target:Nick())
end)

-- Bring command
net.Receive("lyx:admin:bring", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local target = net.ReadEntity()
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    -- Store return position for target
    returnPositions[target:SteamID()] = target:GetPos()
    
    -- Bring target to admin
    target:SetPos(ply:GetPos() + ply:GetForward() * 100)
    
    lyx.Logger:Log(ply:Nick() .. " brought " .. target:Nick())
    
    ply:ChatPrint("Brought " .. target:Nick() .. " to you")
    target:ChatPrint("You were brought to " .. ply:Nick())
end)

-- Return command
net.Receive("lyx:admin:return", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local target = net.ReadEntity()
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    local returnPos = returnPositions[target:SteamID()]
    
    if not returnPos then
        ply:ChatPrint(target:Nick() .. " has no return position!")
        return
    end
    
    target:SetPos(returnPos)
    returnPositions[target:SteamID()] = nil
    
    lyx.Logger:Log(ply:Nick() .. " returned " .. target:Nick())
    
    ply:ChatPrint("Returned " .. target:Nick() .. " to their previous position")
    target:ChatPrint("You were returned to your previous position by " .. ply:Nick())
end)

-- Slay command
net.Receive("lyx:admin:slay", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local target = net.ReadEntity()
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    target:Kill()
    
    lyx.Logger:Log(ply:Nick() .. " slayed " .. target:Nick())
    
    ply:ChatPrint("Slayed " .. target:Nick())
    target:ChatPrint("You were slayed by " .. ply:Nick())
end)

-- Slap command
net.Receive("lyx:admin:slap", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local target = net.ReadEntity()
    local damage = net.ReadUInt(8)
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    -- Apply damage and knockback
    local dmg = DamageInfo()
    dmg:SetDamage(damage)
    dmg:SetAttacker(ply)
    dmg:SetDamageType(DMG_SLASH)
    target:TakeDamageInfo(dmg)
    
    -- Knockback effect
    target:SetVelocity(Vector(math.random(-200, 200), math.random(-200, 200), 300))
    
    -- Sound effect
    target:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav")
    
    lyx.Logger:Log(ply:Nick() .. " slapped " .. target:Nick() .. " for " .. damage .. " damage")
    
    ply:ChatPrint("Slapped " .. target:Nick() .. " for " .. damage .. " damage")
    target:ChatPrint("You were slapped by " .. ply:Nick() .. " for " .. damage .. " damage")
end)

-- Ignite command
net.Receive("lyx:admin:ignite", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local target = net.ReadEntity()
    local duration = net.ReadUInt(8)
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    target:Ignite(duration)
    
    lyx.Logger:Log(ply:Nick() .. " ignited " .. target:Nick() .. " for " .. duration .. " seconds")
    
    ply:ChatPrint("Ignited " .. target:Nick() .. " for " .. duration .. " seconds")
    target:ChatPrint("You were ignited by " .. ply:Nick() .. " for " .. duration .. " seconds")
end)

-- Give weapon command
net.Receive("lyx:admin:giveweapon", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    
    local target = net.ReadEntity()
    local weapon = net.ReadString()
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    -- Validate weapon class
    if not weapons.Get(weapon) then
        ply:ChatPrint("Invalid weapon class: " .. weapon)
        return
    end
    
    target:Give(weapon)
    target:SelectWeapon(weapon)
    
    lyx.Logger:Log(ply:Nick() .. " gave " .. target:Nick() .. " a " .. weapon)
    
    ply:ChatPrint("Gave " .. target:Nick() .. " a " .. weapon)
    target:ChatPrint("You received a " .. weapon .. " from " .. ply:Nick())
end)

-- Clean up return positions on disconnect
hook.Add("PlayerDisconnected", "Lyx.CleanupReturnPos", function(ply)
    returnPositions[ply:SteamID()] = nil
end)

lyx.Logger:Log("Admin commands system initialized")