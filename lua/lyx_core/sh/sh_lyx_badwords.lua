local string_match = string.match
local string_lower = string.lower

do
    local dodgy_words = {
        "nigger",
        "faggot",
        "fag",
        "nigga",
        "nig",
    }

    function lyx.ContainBadWord(str)
        local lower = string_lower(str)
        for _, v in ipairs(dodgy_words) do
            if string_match(lower, v) then
                return true
            end
        end
        if string_match(lower, "www[.]") || string_match(lower, "http") && !string_match(lower, "horizonnetwork") then
            return true
        end
        return false 
    end
end