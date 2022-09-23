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

function lyx:AddRank(name)
    if lyx.ranks[name] then
        lyx:Log("Rank " .. name .. " already exists!")  
    return end

    local ranks = lyx:JSONLoad("lyx_ranks.txt")
    local tbl = {}

    if ranks then
        tbl = ranks
    end

    lyx.ranks[name] = true
    tbl[name] = true
    lyx:JSONSave("lyx_ranks.txt", tbl)
    lyx:Log("Added rank " .. name)
end

function lyx:RemoveRank(name)
    if not lyx.ranks[name] then
        lyx:Log("Rank " .. name .. " does not exist!") 
    return end

    local ranks = lyx:JSONLoad("lyx_ranks.txt")
    if not ranks then
        lyx:Log("No ranks to remove!")
        lyx:Log("Try adding a rank first!")
    return end

    lyx.ranks[name] = nil
    ranks[name] = nil
    lyx:JSONSave("lyx_ranks.txt", ranks)
    lyx:Log("Removed rank " .. name)
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
        lyx:Log("No ranks to load!")
    return end

    for k, v in ipairs(ranks) do
        lyx.ranks[k] = true
    end

    lyx:Log("Loaded " .. table.Count(ranks) .. " ranks!")
end

lyx:AddRank("superadmin") -- hard coded rank for testing obviously
lyx:LoadRanks()