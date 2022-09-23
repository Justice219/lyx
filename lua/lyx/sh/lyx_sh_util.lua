lyx = lyx
lyx.util = lyx.util or {}

--[[
.____                    ____ ___   __  .__.__   
|    |    ___.__.___  __|    |   \_/  |_|__|  |  
|    |   <   |  |\  \/  /    |   /\   __\  |  |  
|    |___ \___  | >    <|    |  /  |  | |  |  |__
|_______ \/ ____|/__/\_ \______/   |__| |__|____/
        \/\/           \/                        

Provides a few tools to help out existing functions.

]]--

function lyx:UtilNewID()
    local id = lyx.util.id or 0
    lyx.util.id = id + 1
    return id
end