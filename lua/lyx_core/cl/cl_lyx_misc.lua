
do
    function lyx.DrawRoundedTextBox(text, font, x, y, xAlign, textCol, boxRounding, boxPadding, boxCol)
        local boxW, boxH = lyx.GetTextSize(text, font)

        local dblPadding = boxPadding * 2
        if xAlign == TEXT_ALIGN_CENTER then
            lyx.DrawRoundedBox(boxRounding, x - boxW * 0.5 - boxPadding, y - boxPadding, boxW + dblPadding, boxH + dblPadding, boxCol)
        elseif xAlign == TEXT_ALIGN_RIGHT then
            lyx.DrawRoundedBox(boxRounding, x - boxW - boxPadding, y - boxPadding, boxW + dblPadding, boxH + dblPadding, boxCol)
        else
            lyx.DrawRoundedBox(boxRounding, x - boxPadding, y - boxPadding, boxW + dblPadding, boxH + dblPadding, boxCol)
        end

        lyx.DrawText(text, font, x, y, textCol, xAlign)
    end
end

do
    local drawRoundedBox = lyx.DrawRoundedBox
    local drawSimpleText = lyx.DrawSimpleText
    function lyx.DrawFixedRoundedTextBox(text, font, x, y, xAlign, textCol, boxRounding, w, h, boxCol, textPadding)
        drawRoundedBox(boxRounding, x, y, w, h, boxCol)

        if xAlign == TEXT_ALIGN_CENTER then
            drawSimpleText(text, font, x + w * 0.5, y + h * 0.5, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        if xAlign == TEXT_ALIGN_RIGHT then
            drawSimpleText(text, font, x + w - textPadding, y + h * 0.5, textCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            return
        end

        drawSimpleText(text, font, x + textPadding, y + h * 0.5, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

do
    local blurPassesCvar = CreateClientConVar("lyx_ui_blur_passes", "4", true, false, "Amount of passes to draw blur with. 0 to disable blur entirely.", 0, 15)
    local blurPassesNum = blurPassesCvar:GetInt()

    cvars.AddChangeCallback("lyx_ui_blur_passes", function(_, _, passes)
        blurPassesNum = math.floor(tonumber(passes) + 0.05)
    end )

    local blurMat = Material("pp/blurscreen")
    local scrW, scrH = ScrW, ScrH
    local setMaterial = surface.SetMaterial
    local setDrawColor = surface.SetDrawColor
    local updateScreenEffectTexture = render.UpdateScreenEffectTexture
    local drawTexturedRect = surface.DrawTexturedRect

    function lyx.DrawBlur(panel, localX, localY, w, h)
        if blurPassesNum == 0 then return end
        local x, y = panel:LocalToScreen(localX, localY)
        local scrw, scrh = scrW(), scrH()

        setMaterial(blurMat)
        setDrawColor(255, 255, 255)

        for i = 0, blurPassesNum do
            blurMat:SetFloat("$blur", i * .33)
            blurMat:Recompute()
        end
        updateScreenEffectTexture()
        drawTexturedRect(x * -1, y * -1, scrw, scrh)
    end
end