lyx = lyx
lyx.RegisteredFonts = lyx.RegisteredFonts or {}
local registeredFonts = lyx.RegisteredFonts

do
    lyx.SharedFonts = lyx.SharedFonts or {}
    local sharedFonts = lyx.SharedFonts

    function lyx.RegisterFontUnscaled(name, font, size, weight)
        weight = weight or 500

        local identifier = font .. size .. ":" .. weight

        local fontName = "lyx:" .. identifier
        registeredFonts[name] = fontName

        if sharedFonts[identifier] then return end
        sharedFonts[identifier] = true

        surface.CreateFont(fontName, {
            font = font,
            size = size,
            weight = weight,
            extended = true,
            antialias = true
        })
    end
end

do
    lyx.ScaledFonts = lyx.ScaledFonts or {}
    local scaledFonts = lyx.ScaledFonts

    function lyx.RegisterFont(name, font, size, weight)
        scaledFonts[name] = {
            font = font,
            size = size,
            weight = weight
        }

        lyx.RegisterFontUnscaled(name, font, lyx.ScaleW(size), weight)
    end

    hook.Add("OnScreenSizeChanged", "lyx.ReregisterFonts", function()
        for k,v in pairs(scaledFonts) do
            lyx.RegisterFont(k, v.font, v.size, v.weight)
        end
    end)
end

do
    local setFont = surface.SetFont
    local function setlyxFont(font)
        local lyxFont = registeredFonts[font]
        if lyxFont then
            setFont(lyxFont)
            return
        end

        setFont(font)
    end

    lyx.SetFont = setlyxFont

    local getTextSize = surface.GetTextSize
    function lyx.GetTextSize(text, font)
        if font then setlyxFont(font) end
        return getTextSize(text)
    end

    function lyx.GetRealFont(font)
        return registeredFonts[font]
    end
end