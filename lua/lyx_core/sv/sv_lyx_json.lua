lyx = lyx

--[[
.____                        ____.                    
|    |    ___.__.___  ___   |    | __________   ____  
|    |   <   |  |\  \/  /   |    |/  ___/  _ \ /    \ 
|    |___ \___  | >    </\__|    |\___ (  <_> )   |  \
|_______ \/ ____|/__/\_ \________/____  >____/|___|  /
        \/\/           \/             \/           \/ 

Secure JSON Library with validation, error handling, and atomic operations

]]--

do
    -- Configuration
    local MAX_FILE_SIZE = 10 * 1024 * 1024  -- 10MB max file size
    local BACKUP_SUFFIX = ".backup"
    local TEMP_SUFFIX = ".tmp"
    
    --[[
        Validate a filename for safe file operations
        @param name string - Filename to validate
        @return string/nil - Sanitized filename or nil if invalid
    ]]
    local function ValidateFilename(name)
        if not name or type(name) ~= "string" then
            return nil
        end
        
        -- Remove any path traversal attempts
        name = string.gsub(name, "%.%.", "")
        name = string.gsub(name, "[\\/]", "")
        
        -- Limit filename length
        if #name > 255 then
            name = string.sub(name, 1, 255)
        end
        
        -- Ensure .txt extension if not present
        if not string.match(name, "%.%w+$") then
            name = name .. ".txt"
        end
        
        return name
    end
    
    --[[
        Save a table as JSON with atomic write operations
        @param name string - Filename (will be sanitized)
        @param tbl table - Table to save
        @param pretty boolean - Whether to format JSON nicely (default false)
        @return boolean - True on success, false on failure
    ]]
    function lyx:JSONSave(name, tbl, pretty)
        -- Validate inputs
        name = ValidateFilename(name)
        if not name then
            lyx.Logger:Log("Invalid filename for JSONSave", 3)
            return false
        end
        
        if type(tbl) ~= "table" then
            lyx.Logger:Log("Invalid data type for JSONSave - expected table", 3)
            return false
        end
        
        -- Convert to JSON with error handling
        local success, json = pcall(util.TableToJSON, tbl, pretty)
        if not success or not json then
            lyx.Logger:Log("Failed to convert table to JSON: " .. tostring(json), 3)
            return false
        end
        
        -- Check size limit
        if #json > MAX_FILE_SIZE then
            lyx.Logger:Log("JSON data exceeds maximum file size limit", 3)
            return false
        end
        
        -- Atomic write: write to temp file first
        local tempName = name .. TEMP_SUFFIX
        
        -- Try to create directory if it doesn't exist
        file.CreateDir("lyx")
        
        local f = file.Open(tempName, "wb", "DATA")
        if not f then
            -- Fallback: try direct write without temp file
            file.Write(name, json)
            if file.Exists(name, "DATA") then
                lyx.Logger:Log("Used fallback direct write for: " .. name, 2)
                return true
            end
            lyx.Logger:Log("Failed to write file: " .. name, 3)
            return false
        end
        
        f:Write(json)
        f:Close()
        
        -- Create backup of existing file if it exists
        if file.Exists(name, "DATA") then
            local backupName = name .. BACKUP_SUFFIX
            file.Delete(backupName, "DATA")  -- Remove old backup
            file.Rename(name, backupName, "DATA")
        end
        
        -- Rename temp file to actual file
        file.Rename(tempName, name, "DATA")
        
        lyx.Logger:Log("Successfully saved JSON to " .. name)
        return true
    end

    --[[
        Load and parse a JSON file with validation
        @param name string - Filename (will be sanitized)
        @param fallback table - Optional fallback value if load fails
        @return table/nil - Parsed table or fallback/nil on failure
    ]]
    function lyx:JSONLoad(name, fallback)
        -- Validate filename
        name = ValidateFilename(name)
        if not name then
            lyx.Logger:Log("Invalid filename for JSONLoad", 3)
            return fallback
        end
        
        -- Check if file exists
        if not file.Exists(name, "DATA") then
            lyx.Logger:Log("File does not exist: " .. name, 1)
            return fallback
        end
        
        -- Read file
        local content = file.Read(name, "DATA")
        if not content then
            lyx.Logger:Log("Failed to read file: " .. name, 3)
            -- Try backup if main file is corrupted
            local backupName = name .. BACKUP_SUFFIX
            if file.Exists(backupName, "DATA") then
                lyx.Logger:Log("Attempting to load backup file", 2)
                content = file.Read(backupName, "DATA")
                if not content then
                    return fallback
                end
            else
                return fallback
            end
        end
        
        -- Check file size
        if #content > MAX_FILE_SIZE then
            lyx.Logger:Log("File exceeds maximum size limit: " .. name, 3)
            return fallback
        end
        
        -- Parse JSON with error handling
        local success, data = pcall(util.JSONToTable, content)
        if not success or not data then
            lyx.Logger:Log("Failed to parse JSON from " .. name .. ": " .. tostring(data), 3)
            return fallback
        end
        
        return data
    end

    --[[
        Load a specific line from a JSON file (legacy compatibility)
        @param name string - Filename
        @param lineNum number - Line number to parse
        @return table/nil - Parsed data from specified line
    ]]
    function lyx:JSONLoadLine(name, lineNum)
        -- Validate inputs
        name = ValidateFilename(name)
        if not name then
            lyx.Logger:Log("Invalid filename for JSONLoadLine", 3)
            return nil
        end
        
        if type(lineNum) ~= "number" or lineNum < 1 then
            lyx.Logger:Log("Invalid line number for JSONLoadLine", 3)
            return nil
        end
        
        local content = file.Read(name, "DATA")
        if not content then
            return nil
        end
        
        local lines = string.Explode("\n", content)
        if lineNum > #lines then
            lyx.Logger:Log("Line number exceeds file length", 2)
            return nil
        end
        
        local success, data = pcall(util.JSONToTable, lines[lineNum])
        if not success then
            lyx.Logger:Log("Failed to parse JSON from line " .. lineNum, 3)
            return nil
        end
        
        return data
    end
    
    --[[
        Delete a JSON file and its backup
        @param name string - Filename to delete
        @return boolean - True if deleted successfully
    ]]
    function lyx:JSONDelete(name)
        name = ValidateFilename(name)
        if not name then
            return false
        end
        
        -- Delete main file
        if file.Exists(name, "DATA") then
            file.Delete(name, "DATA")
        end
        
        -- Delete backup
        local backupName = name .. BACKUP_SUFFIX
        if file.Exists(backupName, "DATA") then
            file.Delete(backupName, "DATA")
        end
        
        lyx.Logger:Log("Deleted JSON file: " .. name)
        return true
    end
    
    --[[
        Check if a JSON file exists
        @param name string - Filename to check
        @return boolean - True if file exists
    ]]
    function lyx:JSONExists(name)
        name = ValidateFilename(name)
        if not name then
            return false
        end
        
        return file.Exists(name, "DATA")
    end
    
    --[[
        Get file size of a JSON file
        @param name string - Filename
        @return number/nil - File size in bytes or nil if not found
    ]]
    function lyx:JSONSize(name)
        name = ValidateFilename(name)
        if not name then
            return nil
        end
        
        return file.Size(name, "DATA")
    end
end