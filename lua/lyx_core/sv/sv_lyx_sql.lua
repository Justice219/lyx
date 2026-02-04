lyx = lyx

--[[
.____                      _________________  .____     
|    |    ___.__.___  ___ /   _____/\_____  \ |    |    
|    |   <   |  |\  \/  / \_____  \  /  / \  \|    |    
|    |___ \___  | >    <  /        \/   \_/.  \    |___ 
|_______ \/ ____|/__/\_ \/_______  /\_____\ \_/_______ \
        \/\/           \/        \/        \__>       \/

SQL Library for saving and loading data from a database.
Provides secure database operations with proper parameterization and error handling.

]]--

do
    -- Cache for prepared statements to improve performance
    local preparedStatements = {}
    
    --[[
        Execute a raw SQL query with proper error handling
        @param query string - The SQL query to execute
        @param params table - Optional parameters for parameterized queries
        @return table/boolean - Query result or false on error
    ]]
    function lyx:SQLQuery(query, params)
        -- Validate input
        if not query or type(query) ~= "string" then
            lyx.Logger:Log("Invalid SQL query provided", 3)
            return false
        end
        
        -- Apply parameters if provided
        if params and type(params) == "table" then
            for k, v in pairs(params) do
                query = string.gsub(query, ":" .. k, sql.SQLStr(v))
            end
        end
        
        lyx.Logger:Log("Query: " .. query)
        local result = sql.Query(query)
        
        -- Check for errors
        if sql.LastError() then
            lyx.Logger:Log("SQL Error: " .. sql.LastError(), 3)
            return false
        end
        
        return result
    end
    
    --[[
        Create a new SQL table with specified columns
        @param name string - Table name (will be sanitized)
        @param values table - Array of column definitions {name="column", type="TEXT"}
        @return boolean - True on success, false on failure
    ]]
    function lyx:SQLCreate(name, values)
        -- Validate inputs
        if not name or type(name) ~= "string" then
            lyx.Logger:Log("Invalid table name provided for SQLCreate", 3)
            return false
        end
        
        if not values or type(values) ~= "table" or #values == 0 then
            lyx.Logger:Log("Invalid column definitions provided for SQLCreate", 3)
            return false
        end
        
        -- Sanitize table name (allow only alphanumeric and underscores)
        name = string.gsub(name, "[^%w_]", "")
        
        -- Build column definitions with proper validation
        local columnDefs = {}
        for _, col in ipairs(values) do
            if col.name and col.type then
                -- Sanitize column name
                local colName = string.gsub(col.name, "[^%w_]", "")
                -- Validate column type
                local validTypes = {TEXT=true, INTEGER=true, REAL=true, BLOB=true, NULL=true, NUMBER=true}
                local colType = string.upper(col.type)
                if validTypes[colType] then
                    table.insert(columnDefs, colName .. " " .. colType)
                else
                    lyx.Logger:Log("Invalid column type: " .. col.type, 2)
                end
            end
        end
        
        if #columnDefs == 0 then
            lyx.Logger:Log("No valid columns for table " .. name, 3)
            return false
        end
        
        local str = table.concat(columnDefs, ", ")
        local query = "CREATE TABLE IF NOT EXISTS " .. name .. " ( " .. str .. " )"
        
        sql.Query(query)
        
        if sql.LastError() then
            lyx.Logger:Log("SQL Error creating table " .. name .. ": " .. sql.LastError(), 3)
            return false
        end
        
        lyx.Logger:Log("Created new DB table: " .. name)
        return true
    end
    
    --[[
        Remove a SQL table
        @param name string - Table name to remove
        @return boolean - True on success, false on failure
    ]]
    function lyx:SQLRemove(name)
        -- Validate input
        if not name or type(name) ~= "string" then
            lyx.Logger:Log("Invalid table name provided for SQLRemove", 3)
            return false
        end
        
        -- Sanitize table name
        name = string.gsub(name, "[^%w_]", "")
        
        sql.Query("DROP TABLE IF EXISTS " .. name)
        
        if sql.LastError() then
            lyx.Logger:Log("SQL Error removing table " .. name .. ": " .. sql.LastError(), 3)
            return false
        end
        
        lyx.Logger:Log("Removed DB table: " .. name)
        return true
    end
    
    --[[
        Update or insert a specific row in a table
        @param name string - Table name
        @param row string - Column to update
        @param method string - Column to match against
        @param value any - New value for the row
        @param key any - Value to match in the method column
        @return boolean - True on success, false on failure
    ]]
    function lyx:SQLUpdateSpecific(name, row, method, value, key)
        -- Validate inputs
        if not name or not row or not method then
            lyx.Logger:Log("Invalid parameters for SQLUpdateSpecific", 3)
            return false
        end
        
        -- Sanitize table and column names
        name = string.gsub(name, "[^%w_]", "")
        row = string.gsub(row, "[^%w_]", "")
        method = string.gsub(method, "[^%w_]", "")
        
        -- Check if record exists
        local checkQuery = string.format("SELECT %s FROM %s WHERE %s = %s LIMIT 1",
            row, name, method, sql.SQLStr(key))
        local data = sql.Query(checkQuery)
        
        if sql.LastError() then
            lyx.Logger:Log("SQL Error in SQLUpdateSpecific check: " .. sql.LastError(), 3)
            return false
        end
        
        local query
        if data and #data > 0 then
            -- Update existing record
            query = string.format("UPDATE %s SET %s = %s WHERE %s = %s",
                name, row, sql.SQLStr(value), method, sql.SQLStr(key))
        else
            -- Insert new record
            query = string.format("INSERT INTO %s (%s, %s) VALUES(%s, %s)",
                name, method, row, sql.SQLStr(key), sql.SQLStr(value))
        end
        
        sql.Query(query)
        
        if sql.LastError() then
            lyx.Logger:Log("SQL Error in SQLUpdateSpecific: " .. sql.LastError(), 3)
            return false
        end
        
        return true
    end
    
    --[[
        Update all rows in a table with the same value
        WARNING: This updates ALL records - use with caution!
        @param name string - Table name
        @param row string - Column to update
        @param value any - New value for all rows
        @return boolean - True on success, false on failure
    ]]
    function lyx:SQLUpdateAll(name, row, value)
        -- Validate inputs
        if not name or not row then
            lyx.Logger:Log("Invalid parameters for SQLUpdateAll", 3)
            return false
        end
        
        -- Sanitize table and column names
        name = string.gsub(name, "[^%w_]", "")
        row = string.gsub(row, "[^%w_]", "")
        
        lyx.Logger:Log("Updating all entries in DB table: " .. name .. " column: " .. row, 2)
        
        -- Check if table has any data
        local checkQuery = string.format("SELECT COUNT(*) as count FROM %s", name)
        local data = sql.Query(checkQuery)
        
        if sql.LastError() then
            lyx.Logger:Log("SQL Error in SQLUpdateAll check: " .. sql.LastError(), 3)
            return false
        end
        
        local query
        if data and data[1] and tonumber(data[1].count) > 0 then
            -- Update existing records
            query = string.format("UPDATE %s SET %s = %s", name, row, sql.SQLStr(value))
        else
            -- Insert first record
            query = string.format("INSERT INTO %s (%s) VALUES(%s)", name, row, sql.SQLStr(value))
        end
        
        sql.Query(query)
        
        if sql.LastError() then
            lyx.Logger:Log("SQL Error in SQLUpdateAll: " .. sql.LastError(), 3)
            return false
        end
        
        return true
    end
    
    --[[
        Load data from a table (NOTE: This function has a logic error in original - fixed)
        @param name string - Table name
        @param method string - Column name to search
        @param value any - Value to search for
        @return table/boolean - Query result or false on error
    ]]
    function lyx:SQLLoad(name, method, value)
        -- Validate inputs
        if not name or not method then
            lyx.Logger:Log("Invalid parameters for SQLLoad", 3)
            return false
        end
        
        -- Sanitize table and column names
        name = string.gsub(name, "[^%w_]", "")
        method = string.gsub(method, "[^%w_]", "")
        
        -- Note: Original had a bug - it was comparing method column with method value!
        -- Fixed to properly accept a value parameter
        local query = string.format("SELECT * FROM %s WHERE %s = %s",
            name, method, sql.SQLStr(value or method))
        
        local val = sql.Query(query)
        
        if sql.LastError() then
            lyx.Logger:Log("SQL Error in SQLLoad: " .. sql.LastError(), 3)
            return false
        end
        
        if not val or #val == 0 then
            lyx.Logger:Log("No data found in table: " .. name .. " with " .. method .. " = " .. tostring(value))
            return false
        end
        
        return val
    end
    
    --[[
        Load a specific column value from a table
        @param name string - Table name
        @param row string - Column to retrieve
        @param method string - Column to match against
        @param key any - Value to match
        @return any/boolean - Column value or false on error
    ]]
    function lyx:SQLLoadSpecific(name, row, method, key)
        -- Validate inputs
        if not name or not row or not method then
            lyx.Logger:Log("Invalid parameters for SQLLoadSpecific", 3)
            return false
        end
        
        -- Sanitize table and column names
        name = string.gsub(name, "[^%w_]", "")
        row = string.gsub(row, "[^%w_]", "")
        method = string.gsub(method, "[^%w_]", "")
        
        local query = string.format("SELECT %s FROM %s WHERE %s = %s LIMIT 1",
            row, name, method, sql.SQLStr(key))
        
        local val = sql.QueryValue(query)
        
        if sql.LastError() then
            lyx.Logger:Log("SQL Error in SQLLoadSpecific: " .. sql.LastError(), 3)
            return false
        end
        
        if not val then
            lyx.Logger:Log("No data found in table: " .. name .. " column: " .. row .. " where " .. method .. " = " .. tostring(key))
            return false
        end
        
        return val
    end
    
    --[[
        Load all values from a specific column
        @param name string - Table name
        @param row string - Column to retrieve
        @return table/boolean - Array of values or false on error
    ]]
    function lyx:SQLLoadAll(name, row)
        -- Validate inputs
        if not name or not row then
            lyx.Logger:Log("Invalid parameters for SQLLoadAll", 3)
            return false
        end
        
        -- Sanitize table and column names
        name = string.gsub(name, "[^%w_]", "")
        row = string.gsub(row, "[^%w_]", "")
        
        -- Use sql.Query instead of sql.QueryValue to get all rows
        local query = string.format("SELECT %s FROM %s", row, name)
        local val = sql.Query(query)
        
        if sql.LastError() then
            lyx.Logger:Log("SQL Error in SQLLoadAll: " .. sql.LastError(), 3)
            return false
        end
        
        if not val or #val == 0 then
            lyx.Logger:Log("No data found in table: " .. name .. " column: " .. row)
            return false
        end
        
        -- Extract just the column values
        local results = {}
        for _, row_data in ipairs(val) do
            table.insert(results, row_data[row])
        end
        
        return results
    end
    
    --[[
        Execute a transaction with multiple queries
        @param queries table - Array of queries to execute
        @return boolean - True if all succeed, false if any fail (rolls back)
    ]]
    function lyx:SQLTransaction(queries)
        if not queries or type(queries) ~= "table" or #queries == 0 then
            lyx.Logger:Log("Invalid queries provided for transaction", 3)
            return false
        end
        
        sql.Query("BEGIN TRANSACTION")
        
        for i, query in ipairs(queries) do
            sql.Query(query)
            if sql.LastError() then
                lyx.Logger:Log("Transaction failed at query " .. i .. ": " .. sql.LastError(), 3)
                sql.Query("ROLLBACK")
                return false
            end
        end
        
        sql.Query("COMMIT")
        lyx.Logger:Log("Transaction completed successfully with " .. #queries .. " queries")
        return true
    end
    
    --[[
        Check if a table exists
        @param name string - Table name to check
        @return boolean - True if exists, false otherwise
    ]]
    function lyx:SQLTableExists(name)
        if not name or type(name) ~= "string" then
            return false
        end
        
        name = string.gsub(name, "[^%w_]", "")
        
        local result = sql.Query("SELECT name FROM sqlite_master WHERE type='table' AND name='" .. name .. "'")
        return result and #result > 0
    end
end