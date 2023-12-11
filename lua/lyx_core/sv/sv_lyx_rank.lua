lyx = lyx
lyx.ranks = lyx.ranks or {}

--[[
.____                   __________                __            
|    |    ___.__.___  __\______   \_____    ____ |  | __  ______
|    |   <   |  |\  \/  /|       _/\__  \  /    \|  |/ / /  ___/
|    |___ \___  | >    < |    |   \ / __ \|   |  \    <  \___ \ 
|_______ \/ ____|/__/\_ \|____|_  /(____  /___|  /__|_ \/____  >
        \/\/           \/       \/      \/     \/     \/     \/ 

Lib Based Rank Restriction

]]--

do
    -- CUSTOM ADDON RANKS
    function lyx:CustomAddRank(file, name)
        local ranks = lyx:JSONLoad(file)
        if ranks then
            ranks[name] = true
            lyx:JSONSave(file, ranks)
        else
            local tbl = {}
            tbl[name] = true 
            lyx:JSONSave(file, tbl)
            lyx.Logger:Log("Created new rank file: " .. file)
        end
        lyx.Logger:Log("Added rank: " .. name .. " to file: " .. file)
    end

    function lyx:CustomRemoveRank(file, name)
        local ranks = lyx:JSONLoad(file)
        if not ranks then
            lyx.Logger:Log("No ranks to remove! in custom file: " .. file)
        return end

        ranks[name] = nil
        lyx:JSONSave(file, ranks)
        lyx.Logger:Log("Removed rank: " .. name .. " from file: " .. file)
    end

    function lyx:CustomRetrieveRanks(file)
        local ranks = lyx:JSONLoad(file)
        if not ranks then
            lyx.Logger:Log("No ranks to retrieve! in custom file: " .. file)
        return end

        local tbl = {}
        for k, v in pairs(ranks) do
            tbl[k] = true
        end

        return tbl
    end

    -- LYX BASED RANKS (RANK FUNCTIONS USED FOR LYX USE ONLY)
    function lyx:AddRank(name)
        if lyx.ranks[name] then
            lyx.Logger:Log("Rank " .. name .. " already exists!")  
        return end

        local ranks = lyx:JSONLoad("lyx_ranks.txt")

        if ranks then
            lyx.ranks[name] = true
            ranks[name] = true
            lyx:JSONSave("lyx_ranks.txt", ranks)
            lyx.Logger:Log("Added rank " .. name)
        else
            local tbl = {}
            tbl[name] = true
            lyx.ranks[name] = true
            lyx:JSONSave("lyx_ranks.txt", tbl)
        end
    end

    function lyx:RemoveRank(name)
        if not lyx.ranks[name] then
            lyx.Logger:Log("Rank " .. name .. " does not exist!") 
        return end

        local ranks = lyx:JSONLoad("lyx_ranks.txt")
        if not ranks then
            lyx.Logger:Log("No ranks to remove!")
            lyx.Logger:Log("Try adding a rank first!")
        return end

        lyx.ranks[name] = nil
        ranks[name] = nil
        lyx:JSONSave("lyx_ranks.txt", ranks)
        lyx.Logger:Log("Removed rank " .. name)

    end

    function lyx:CheckRank(ply)
        if !IsValid(ply) then return end

        if lyx.ranks[ply:GetUserGroup()] then
            return true
        else
            return false
        end
    end

    function lyx:LoadRanks()
        local ranks = lyx:JSONLoad("lyx_ranks.txt")
        if not ranks then
            lyx.Logger:Log("No ranks to load!")
        return end

        for k, v in ipairs(ranks) do
            lyx.ranks[k] = true
        end

        lyx.Logger:Log("Loaded " .. table.Count(ranks) .. " ranks!")
    end

    lyx:AddRank("superadmin") -- hard coded rank for testing obviously
    lyx:LoadRanks() 
end