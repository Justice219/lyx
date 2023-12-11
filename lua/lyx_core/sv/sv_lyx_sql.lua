lyx = lyx

--[[
.____                      _________________  .____     
|    |    ___.__.___  ___ /   _____/\_____  \ |    |    
|    |   <   |  |\  \/  / \_____  \  /  / \  \|    |    
|    |___ \___  | >    <  /        \/   \_/.  \    |___ 
|_______ \/ ____|/__/\_ \/_______  /\_____\ \_/_______ \
        \/\/           \/        \/        \__>       \/

SQL Library for saving and loading data from a database.

]]--

do
    function lyx:SQLQuery(query)
        lyx.Logger:Log("Query: " .. query)
        sql.Query(query)
    end
    
    function lyx:SQLCreate(name, values)
        local str = ""
        local i = 0
        local max = table.maxn(values)
        for k,v in pairs(values) do
            -- the string needs to look something like id NUMBER, name TEXT
            i = i + 1
            if i == max then 
                str = str .. v.name .. " " .. v.type
            else
                str = str .. v.name .. " " .. v.type .. ", "
            end
        end
    
        sql.Query("CREATE TABLE IF NOT EXISTS " .. name .. " ( " .. str .. " )")
        lyx:Log("Created new DB table: " .. name)
        if !sql.LastError() then return end
        lyx.Logger:Log("Printing last SQL Error for debugging purposes, ")
        print(sql.LastError())
    end
    
    function lyx:SQLRemove(name)
        sql.Query("DROP TABLE " .. name)
    
        lyx.Logger:Log("Removed DB table: " .. name)
        if !sql.LastError() then return end
        lyx.Logger:Log("Printing last SQL Error for debugging purposes, ")
    end
    
    function lyx:SQLUpdateSpecific(name, row, method, value, key)
        local data = sql.Query("SELECT " .. row .. " FROM " .. name .. " WHERE " .. method .. " = " ..sql.SQLStr(key).. ";")
        if (data) then
            sql.Query("UPDATE " .. name .. " SET " .. row .. " = " .. sql.SQLStr(value) .. " WHERE " .. method .. " = " ..sql.SQLStr(key).. ";")
        else
            sql.Query("INSERT INTO " .. name .. " ( "..method..", "..row.." ) VALUES( "..sql.SQLStr(key)..", "..sql.SQLStr(value).." );")
        end
    end
    
    function lyx:SQLUpdateAll(name, row, value)
        lyx.Logger:Log("Updating all entries in DB table: " .. name)
        value = sql.SQLStr(value)
        local data = sql.Query("SELECT * FROM " .. name .. ";")
        if (data) then
            sql.Query("UPDATE " .. name .. " SET " .. row .. " = " .. value .. ";")
        else
            sql.Query("INSERT INTO " .. name .. " ( "..row.." ) VALUES( "..value.." )") 
        end
    end
    
    function lyx:SQLLoad(name, method)
        local val = sql.QueryValue("SELECT * FROM " .. name .. " WHERE " .. method .. " = " .. sql.SQLStr(method) .. ";")
        if !val then
            lyx.Logger:Log("Could not load data from DB table: " .. name .. " with method: " .. method)    
            return false
        else
            return val
        end
    end
    
    function lyx:SQLLoadSpecific(name, row, method, key)
        local val = sql.QueryValue("SELECT " .. row .. " FROM " .. name .. " WHERE " .. method .. " = " .. sql.SQLStr(key) .. ";")
        if !val then
            lyx.Logger:Log("Could not load data from DB table: " .. name .. " with method: " .. method)    
            return false
        else
            return val
        end
    end
    
    function lyx:SQLLoadAll(name, row)
        local val = sql.QueryValue("SELECT "..row.." FROM " .. name .. ";")
        if !val then
            lyx:Log("Could not load data from DB table: " .. name)    
            return false
        else
            return val
        end
    end 
end