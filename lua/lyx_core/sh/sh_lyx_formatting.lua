
do
    local tostring = tostring
    local find = string.find
    local abs = math.abs
    local round = math.Round

    local function formatCurrency(val, currency)
        if not val then return currency .. "0" end

        val = round(val)

        if val >= 1e14 then return currency .. tostring(val) end
        if val <= -1e14 then return "-" .. currency .. tostring(abs(val)) end

        local negative = val < 0

        val = tostring(abs(val))
        local dp = find(val, "%.") or #val + 1

        for i = dp - 4, 1, -3 do
            val = val:sub(1, i) .. "," .. val:sub(i + 1)
        end

        if val[#val - 1] == "." then
            val = val .. "0"
        end

        return (negative and "-" .. currency or currency) .. val
    end

    function lyx.FormatMoney(val)
        return formatCurrency(val, lyx.Settings:Get("override_currency") or "$")
    end

    function lyx.FormatCredits(val)
        return formatCurrency(val, "¢")
    end
end

do
    local floor, format = math.floor, string.format
    function lyx.FormatTime(time)
        if not time then return end
        if type(time) ~= "number" then return end

        local s = time % 60
        time = floor(time / 60)

        local m = time % 60
        time = floor(time / 60)

        local h = time % 24
        time = floor(time / 24)

        local d = time % 7
        local w = floor(time / 7)

        if w ~= 0 then
            return format("%iw %id %ih %im %is", w, d, h, m, s)
        elseif d ~= 0 then
            return format("%id %ih %im %is", d, h, m, s)
        elseif h ~= 0 then
            return format("%ih %im %is", h, m, s)
        end

        return format("%im %is", m, s)
    end
end

do
    function lyx.TextWrap(text, font, maxWidth)
        if (!text) then 
            return "" 
        end

        local totalWidth = 0

        surface.SetFont(font)

        local spaceWidth = surface.GetTextSize(' ')
        text = text:gsub("(%s?[%S]+)", function(word)
            local char = string.sub(word, 1, 1)
            if char == "\n" or char == "\t" then
                totalWidth = 0
            end

            local wordlen = surface.GetTextSize(word)
            totalWidth = totalWidth + wordlen

            if wordlen >= maxWidth then
                local splitWord, splitPoint = charWrap(word, maxWidth - (totalWidth - wordlen), maxWidth)
                totalWidth = splitPoint
                return splitWord
            elseif totalWidth < maxWidth then
                return word
            end

            if char == ' ' then
                totalWidth = wordlen - spaceWidth
                return '\n' .. string.sub(word, 2)
            end

            totalWidth = wordlen
            return '\n' .. word
        end)

        return text
    end
end