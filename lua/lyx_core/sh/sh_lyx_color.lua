
do
    local format = string.format
    function lyx.DecToHex(dec, zeros)
        return format("%0" .. (zeros or 2) .. "x", dec)
    end

    local max = math.max
    local min = math.min
    function lyx.ColorToHex(color)
        return format("#%02X%02X%02X",
            max(min(color.r, 255), 0),
            max(min(color.g, 255), 0),
            max(min(color.b, 255), 0)
        )
    end

    function lyx.ColorToHSL(col)
        local r = col.r / 255
        local g = col.g / 255
        local b = col.b / 255
        local mx, mn = max(r, g, b), min    (r, g, b)
        b = mx + mn

        local h = b * 0.5
        if mx == mn then return 0, 0, h end

        local s, l = h, h
        local d = mx - mn
        s = l > .5 and d / (2 - b) or d / b

        if mx == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif mx == g then
            h = (b - r) / d + 2
        elseif mx == b then
            h = (r - g) / d + 4
        end

        return h * .16667, s, l
    end
end

do
    local createColor = Color
    do
        local function hueToRgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1 / 6 then return p + (q - p) * 6 * t end
            if t < 1 * 0.5 then return q end
            if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
            return p
        end

        local pi = math.pi
        function lyx.HSLToColor(h, s, l, a)
            local r, g, b
            local t = h / (2 * pi)

            if s == 0 then
                r, g, b = l, l, l
            else
                local q
                if l < 0.5 then
                    q = l * (1 + s)
                else
                    q = l + s - l * s
                end

                local p = 2 * l - q
                r = hueToRgb(p, q, t + 1 / 3)
                g = hueToRgb(p, q, t)
                b = hueToRgb(p, q, t - 1 / 3)
            end

            return createColor(r * 255, g * 255, b * 255, (a or 1) * 255)
        end
    end

    function lyx.CopyColor(col)
        return createColor(col.r, col.g, col.b, col.a)
    end

    function lyx.OffsetColor(col, offset)
        return createColor(col.r + offset, col.g + offset, col.b + offset)
    end

    function lyx.LerpColor(t, from, to)
        return createColor(from.r, from.g, from.b, from.a):Lerp(t, to)
    end

    function lyx.IsColorEqualTo(from, to)
        return from.r == to.r and from.g == to.g and from.b == to.b and from.a == to.a
    end

    do
        local match = string.match
        local tonumber = tonumber

        function lyx.HexToColor(hex)
            local r, g, b = match(hex, "#(..)(..)(..)")
            return createColor(
                tonumber(r, 16),
                tonumber(g, 16),
                tonumber(b, 16)
            )
        end
    end
end

do
    local colorToHSL = ColorToHSL

    function lyx.IsColorLight(col)
        local _, _, lightness = colorToHSL(col)
        return lightness >= .5
    end
end

do
    local colorMeta = FindMetaTable("Color")

    colorMeta.Copy = lyx.CopyColor
    colorMeta.IsLight = lyx.IsColorLight
    colorMeta.EqualTo = lyx.IsColorEqualTo

    function colorMeta:Offset(offset)
        self.r = self.r + offset
        self.g = self.g + offset
        self.b = self.b + offset
        return self
    end

    local lerp = Lerp
    function colorMeta:Lerp(t, to)
        -- Validate t (fraction)
        if type(t) ~= "number" then
            -- If t is not a number, might be wrong argument order
            if type(t) == "table" and t.r then
                -- Arguments might be swapped, swap them back
                t, to = to, t
            else
                return self
            end
        end
        
        -- Ensure 'to' is a Color object
        if type(to) == "number" then
            -- If 'to' is a number, create a gray color
            to = Color(to, to, to)
        elseif not to or type(to) ~= "table" or not to.r then
            -- If 'to' is invalid, return self unchanged
            return self
        end
        
        -- Clamp t between 0 and 1
        t = math.Clamp(t, 0, 1)
        
        self.r = lerp(t, self.r, to.r)
        self.g = lerp(t, self.g, to.g)
        self.b = lerp(t, self.b, to.b)
        self.a = lerp(t, self.a, to.a or 255)
        return self
    end
end

do
    lyx.Colors = {
        Background = Color(30, 30, 30),
        Header = Color(51, 51, 51), //Color(130, 40, 200),
        Scroller = Color(61, 61, 61),
        Foreground =Color(40, 40, 40),

        PrimaryText = Color(255, 255, 255),
        SecondaryText = Color(220, 220, 220),
        DisabledText = Color(150, 150, 150),

        Primary = Color( 41, 41, 41),
        Disabled = Color(87, 21, 130 ),
        Positive = Color(66, 134, 50),
        Negative = Color(164, 50, 50),

        Diamond = Color(33, 193, 214),
        Gold = Color(219, 180, 40),
        Silver = Color(190, 190, 190),
        Bronze = Color(145, 94, 49),

        Transparent = Color(0, 0, 0, 0)
    }

    -- local sv = 0.9
    -- local rainbowHue = 0
    -- local hsv = HSVToColor
    -- hook.Add("Think", "lyx.RainbowColor", function()
    --     rainbowHue = (rainbowHue % 360) + 0.2
    --     lyx.Colors.Rainbow = hsv(rainbowHue, sv, sv)
    -- end)
end
