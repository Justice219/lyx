lyx = lyx

--[[
.____                     ___ ___                __            
|    |    ___.__.___  ___/   |   \  ____   ____ |  | __  ______
|    |   <   |  |\  \/  /    ~    \/  _ \ /  _ \|  |/ / /  ___/
|    |___ \___  | >    <\    Y    (  <_> |  <_> )    <  \___ \ 
|_______ \/ ____|/__/\_ \\___|_  / \____/ \____/|__|_ \/____  >
        \/\/           \/      \/                    \/     \/ 

This is literally just the gmod hook library with the benefit of 
unique hooks everytime you create one.

Plus it sort of looks nicer 🤤

--]]
do
    function lyx:HookCall(name, ...)
        hook.Run(name, ...)
    
        lyx.Logger:Log("Hook Request Called: " .. name)
    end
    
    function lyx:HookStart(name, func)
        local id = lyx:UtilNewID()
        hook.Add(name, "lyx_hook_" .. id, func)
    
        lyx.Logger:Log("Hook Started: " .. name .. " (" .. id .. ")")
        return id
    end
    
    function lyx:HookRemove(name, id)
        hook.Remove(name, "lyx_hook_" .. id)
    
        lyx.Logger:Log("Hook Removed: " .. name)
    end
    
    // Full Spawn Hook \\
    local meta = FindMetaTable("Player")
    
    if SERVER then
        hook.Add("PlayerInitialSpawn", "lyx:PISFull", function(ply)
            local PlayerHookID = string.format("lyx:PISFull:%s", ply:SteamID())
            hook.Add("SetupMove", PlayerHookID, function(pl2, _, mvc)
                if (!IsValid(pl2)) then return end
                if (ply != pl2) then return end
                if mvc:IsForced() then return end
    
                hook.Run("lyx:FullSpawn", ply)
                hook.Remove("SetupMove", PlayerHookID)
                ply:SetNWBool("lyx:FullSpawn", true)
            end)
        end)
    end
    
    function meta:Lyx_FullySpawned()
        if not IsValid(self) then return false end
        return self:GetNWBool("lyx:FullSpawn", false)
    end
end
----------------------------------------------------------------------------------------------------------------------
--Going to be honest, this honestly doesnt do anything the normal gmod hook library cant do. You could use either 🤷.
--The real plus of using the lyx library is auto generating IDs for your hooks.

-- Here is an example of how to use the lyx hook library.
----------------------------------------------------------------------------------------------------------------------
--local function ExampleHook()
--  lyx:HookCall("lyx_test", "Hello World!")            -- This or the hook.Run function can be used.
--end

--local test = lyx:HookStart("lyx_test", function(...)  -- Lets actually start the hook.
--    local args = {...}                                -- This returns an ID for the hook to ease removing it.
--    print(args[1])                                    -- Takes all arguments, you need to know what index to use.
--end)                                                  -- This is a sort of example on how to access arguments.

--ExampleHook()                                         -- Lets call the function to create a hook call.

--lyx:HookRemove("lyx_test", test)                      -- Lets remove just to keep random hooks off the server.
----------------------------------------------------------------------------------------------------------------------