lyx = lyx
lyx.ranks = lyx.ranks or {}

--[[
.____                   __________                __            
|    |    ___.__.___  __\______   \_____    ____ |  | __  ______
|    |   <   |  |\  \/  /|       _/\__  \  /    \|  |/ / /  ___/
|    |___ \___  | >    < |    |   \ / __ \|   |  \    <  \___ \ 
|_______ \/ ____|/__/\_ \|____|_  /(____  /___|  /__|_ \/____  >
        \/\/           \/       \/      \/     \/     \/     \/ 

Enhanced Rank Management System with Security and Validation

]]--

do
    -- Configuration
    local RANK_FILE = "lyx_ranks.txt"
    local DEFAULT_RANKS = {"superadmin", "admin", "operator"}
    local MAX_RANK_NAME_LENGTH = 32
    local ranksLoaded = false
    
    --[[
        Validate a rank name
        @param name string - Rank name to validate
        @return boolean - True if valid
    ]]
    local function ValidateRankName(name)
        if type(name) ~= "string" then
            return false
        end
        
        if #name == 0 or #name > MAX_RANK_NAME_LENGTH then
            return false
        end
        
        -- Only allow alphanumeric and underscore
        if string.match(name, "[^%w_]") then
            return false
        end
        
        return true
    end
    
    -- CUSTOM ADDON RANKS
    
    --[[
        Add a rank to a custom file
        @param file string - Custom file name
        @param name string - Rank name
        @return boolean - True on success
    ]]
    function lyx:CustomAddRank(file, name)
        -- Validate inputs
        if not ValidateRankName(name) then
            lyx.Logger:Log("Invalid rank name: " .. tostring(name), 3)
            return false
        end
        
        -- Ensure file has proper extension
        if not string.match(file, "%.txt$") then
            file = file .. ".txt"
        end
        
        local ranks = lyx:JSONLoad(file, {})
        
        if ranks[name] then
            lyx.Logger:Log("Rank '" .. name .. "' already exists in file: " .. file, 2)
            return false
        end
        
        ranks[name] = true
        
        if not lyx:JSONSave(file, ranks) then
            lyx.Logger:Log("Failed to save rank to file: " .. file, 3)
            return false
        end
        
        lyx.Logger:Log("Added rank '" .. name .. "' to file: " .. file)
        return true
    end

    --[[
        Remove a rank from a custom file
        @param file string - Custom file name
        @param name string - Rank name
        @return boolean - True on success
    ]]
    function lyx:CustomRemoveRank(file, name)
        -- Validate inputs
        if not ValidateRankName(name) then
            lyx.Logger:Log("Invalid rank name: " .. tostring(name), 3)
            return false
        end
        
        -- Ensure file has proper extension
        if not string.match(file, "%.txt$") then
            file = file .. ".txt"
        end
        
        local ranks = lyx:JSONLoad(file)
        if not ranks then
            lyx.Logger:Log("No ranks file found: " .. file, 2)
            return false
        end
        
        if not ranks[name] then
            lyx.Logger:Log("Rank '" .. name .. "' not found in file: " .. file, 2)
            return false
        end

        ranks[name] = nil
        
        if not lyx:JSONSave(file, ranks) then
            lyx.Logger:Log("Failed to save ranks to file: " .. file, 3)
            return false
        end
        
        lyx.Logger:Log("Removed rank '" .. name .. "' from file: " .. file)
        return true
    end

    --[[
        Retrieve all ranks from a custom file
        @param file string - Custom file name
        @return table/nil - Table of ranks or nil on error
    ]]
    function lyx:CustomRetrieveRanks(file)
        -- Ensure file has proper extension
        if not string.match(file, "%.txt$") then
            file = file .. ".txt"
        end
        
        local ranks = lyx:JSONLoad(file)
        if not ranks then
            lyx.Logger:Log("No ranks to retrieve from file: " .. file, 1)
            return nil
        end

        -- Return a copy to prevent modification
        local tbl = {}
        for k, v in pairs(ranks) do
            if ValidateRankName(k) then
                tbl[k] = true
            end
        end

        return tbl
    end

    -- LYX BASED RANKS (CORE RANK SYSTEM)
    
    --[[
        Add a rank to the core system
        @param name string - Rank name
        @return boolean - True on success
    ]]
    function lyx:AddRank(name)
        -- Validate input
        if not ValidateRankName(name) then
            lyx.Logger:Log("Invalid rank name: " .. tostring(name), 3)
            return false
        end
        
        -- Convert to lowercase for consistency
        name = string.lower(name)
        
        if lyx.ranks[name] then
            lyx.Logger:Log("Rank '" .. name .. "' already exists!", 2)  
            return false
        end

        -- Load current ranks from file
        local ranks = lyx:JSONLoad(RANK_FILE, {})
        
        -- Add new rank
        lyx.ranks[name] = true
        ranks[name] = true
        
        -- Save to file
        if not lyx:JSONSave(RANK_FILE, ranks) then
            lyx.Logger:Log("Failed to save rank '" .. name .. "'", 3)
            lyx.ranks[name] = nil  -- Rollback
            return false
        end
        
        lyx.Logger:Log("Added rank '" .. name .. "'")
        
        -- Notify hooks
        hook.Run("lyx.RankAdded", name)
        
        return true
    end

    --[[
        Remove a rank from the core system
        @param name string - Rank name
        @return boolean - True on success
    ]]
    function lyx:RemoveRank(name)
        -- Validate input
        if not ValidateRankName(name) then
            lyx.Logger:Log("Invalid rank name: " .. tostring(name), 3)
            return false
        end
        
        -- Convert to lowercase for consistency
        name = string.lower(name)
        
        if not lyx.ranks[name] then
            lyx.Logger:Log("Rank '" .. name .. "' does not exist!", 2) 
            return false
        end
        
        -- Prevent removing default ranks
        for _, defaultRank in ipairs(DEFAULT_RANKS) do
            if name == defaultRank then
                lyx.Logger:Log("Cannot remove default rank '" .. name .. "'", 2)
                return false
            end
        end

        -- Load current ranks from file
        local ranks = lyx:JSONLoad(RANK_FILE)
        if not ranks then
            lyx.Logger:Log("No ranks file found", 3)
            return false
        end

        -- Remove rank
        lyx.ranks[name] = nil
        ranks[name] = nil
        
        -- Save to file
        if not lyx:JSONSave(RANK_FILE, ranks) then
            lyx.Logger:Log("Failed to save after removing rank '" .. name .. "'", 3)
            lyx.ranks[name] = true  -- Rollback
            return false
        end
        
        lyx.Logger:Log("Removed rank '" .. name .. "'")
        
        -- Notify hooks
        hook.Run("lyx.RankRemoved", name)
        
        return true
    end

    --[[
        Check if a player has an authorized rank
        @param ply Player - Player to check
        @param requiredRank string - Optional specific rank to check for
        @return boolean - True if player has authorization
    ]]
    function lyx:CheckRank(ply, requiredRank)
        -- Validate player
        if not IsValid(ply) then 
            return false
        end
        
        -- Get player's rank
        local playerRank = ply:GetUserGroup()
        if not playerRank then
            return false
        end
        
        -- Convert to lowercase for consistency
        playerRank = string.lower(playerRank)
        
        -- Check for specific rank if provided
        if requiredRank then
            requiredRank = string.lower(requiredRank)
            return playerRank == requiredRank
        end
        
        -- Check if player's rank is in authorized ranks
        return lyx.ranks[playerRank] == true
    end
    
    --[[
        Get a player's rank
        @param ply Player - Player to check
        @return string/nil - Player's rank or nil
    ]]
    function lyx:GetPlayerRank(ply)
        if not IsValid(ply) then
            return nil
        end
        
        return ply:GetUserGroup()
    end
    
    --[[
        Check if a rank exists
        @param name string - Rank name
        @return boolean - True if rank exists
    ]]
    function lyx:RankExists(name)
        if not ValidateRankName(name) then
            return false
        end
        
        name = string.lower(name)
        return lyx.ranks[name] == true
    end
    
    --[[
        Get all authorized ranks
        @return table - Table of authorized ranks
    ]]
    function lyx:GetAllRanks()
        local ranks = {}
        for rank, _ in pairs(lyx.ranks) do
            table.insert(ranks, rank)
        end
        table.sort(ranks)
        return ranks
    end

    --[[
        Load ranks from file (FIXED: Using pairs instead of ipairs)
        @return boolean - True if loaded successfully
    ]]
    function lyx:LoadRanks()
        local ranks = lyx:JSONLoad(RANK_FILE)
        
        if not ranks then
            lyx.Logger:Log("No ranks file found, creating default ranks", 2)
            
            -- Create default ranks
            ranks = {}
            for _, rank in ipairs(DEFAULT_RANKS) do
                ranks[rank] = true
            end
            
            -- Save default ranks
            if not lyx:JSONSave(RANK_FILE, ranks) then
                lyx.Logger:Log("Failed to save default ranks", 3)
                return false
            end
        end
        
        -- Clear current ranks
        lyx.ranks = {}
        
        -- Load ranks (FIXED: Using pairs instead of ipairs)
        local count = 0
        for rankName, enabled in pairs(ranks) do  -- FIX: Changed from ipairs to pairs
            if ValidateRankName(rankName) and enabled then
                lyx.ranks[string.lower(rankName)] = true
                count = count + 1
            end
        end

        lyx.Logger:Log("Loaded " .. count .. " ranks!")
        ranksLoaded = true
        
        -- Notify hooks
        hook.Run("lyx.RanksLoaded", lyx.ranks)
        
        return true
    end
    
    --[[
        Reload ranks from file
        @return boolean - True if reloaded successfully
    ]]
    function lyx:ReloadRanks()
        lyx.Logger:Log("Reloading ranks...")
        return lyx:LoadRanks()
    end
    
    --[[
        Initialize a player's rank on spawn
        @param ply Player - Player that spawned
    ]]
    local function InitializePlayerRank(ply)
        if not IsValid(ply) then return end
        
        local rank = ply:GetUserGroup()
        if rank then
            lyx.Logger:Log("Player " .. ply:Nick() .. " connected with rank: " .. rank)
            
            -- Check if rank is authorized
            if lyx:CheckRank(ply) then
                hook.Run("lyx.AuthorizedPlayerConnected", ply, rank)
            end
        end
    end
    
    -- Hooks for player management
    hook.Add("PlayerInitialSpawn", "lyx_rank_init", InitializePlayerRank)
    
    -- Initialize ranks on load
    timer.Simple(0, function()
        lyx:LoadRanks()
        
        -- Ensure default ranks exist
        for _, rank in ipairs(DEFAULT_RANKS) do
            if not lyx.ranks[rank] then
                lyx:AddRank(rank)
            end
        end
    end)
    
    -- Console commands for rank management (SERVER ONLY)
    if SERVER then
        concommand.Add("lyx_rank_add", function(ply, cmd, args)
            -- Only allow console or superadmin
            if IsValid(ply) and not lyx:CheckRank(ply, "superadmin") then
                ply:ChatPrint("Insufficient permissions")
                return
            end
            
            if #args < 1 then
                print("Usage: lyx_rank_add <rank>")
                return
            end
            
            if lyx:AddRank(args[1]) then
                print("Rank added successfully")
            else
                print("Failed to add rank")
            end
        end)
        
        concommand.Add("lyx_rank_remove", function(ply, cmd, args)
            -- Only allow console or superadmin
            if IsValid(ply) and not lyx:CheckRank(ply, "superadmin") then
                ply:ChatPrint("Insufficient permissions")
                return
            end
            
            if #args < 1 then
                print("Usage: lyx_rank_remove <rank>")
                return
            end
            
            if lyx:RemoveRank(args[1]) then
                print("Rank removed successfully")
            else
                print("Failed to remove rank")
            end
        end)
        
        concommand.Add("lyx_rank_list", function(ply, cmd, args)
            -- Allow any player to list ranks
            local ranks = lyx:GetAllRanks()
            
            if IsValid(ply) then
                ply:ChatPrint("Authorized ranks: " .. table.concat(ranks, ", "))
            else
                print("Authorized ranks: " .. table.concat(ranks, ", "))
            end
        end)
    end
end