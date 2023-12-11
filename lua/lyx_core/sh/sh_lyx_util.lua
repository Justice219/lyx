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

do
    function lyx:UtilNewID()
        local id = lyx.util.id or 0
        lyx.util.id = id + 1
        return id
    end    

    // random unqiue hash generator
    function lyx:UtilNewHash()
        local hash = ""
        for i = 1, 8 do
            hash = hash .. string.char(math.random(97, 122))
        end
        return hash
    end
end
