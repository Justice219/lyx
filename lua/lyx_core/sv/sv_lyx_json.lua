lyx = lyx

--[[
.____                        ____.                    
|    |    ___.__.___  ___   |    | __________   ____  
|    |   <   |  |\  \/  /   |    |/  ___/  _ \ /    \ 
|    |___ \___  | >    </\__|    |\___ (  <_> )   |  \
|_______ \/ ____|/__/\_ \________/____  >____/|___|  /
        \/\/           \/             \/           \/ 

Simple JSON Library for saving small amounts of data.

]]--

do
    -- Saves the table into json data.
    function lyx:JSONSave(name, tbl)
        local file = file.Open(name, "wb", "DATA")
        if file then
            file:Write(util.TableToJSON(tbl))
            file:Close()
        end
    end

    -- Loads a JSON file and returns a table.
    function lyx:JSONLoad(name)
        local file = file.Read(name, "DATA")
        if file then
            return util.JSONToTable(file)
        end
    end

    -- Probably a better way to do this, but I'm lazy.
    function lyx:JSONLoadLine(name, line)
        local file = file.Read(name, "DATA")
        if file then
            return util.JSONToTable(string.Explode("\n", file)[line])
        end
    end 
end