--[[
	LYXUI Miscellaneous Drawing
	Ported from PIXEL UI.

	Provides composite drawing helpers that combine text and rounded boxes,
	plus a panel blur effect.

	Functions:
	  LYXUI.DrawRoundedTextBox() - Text with an auto-sized rounded background
	  LYXUI.DrawFixedRoundedTextBox() - Text inside a fixed-size rounded box
	  LYXUI.DrawBlur() - Blurred background effect behind a panel region
]]

--- Draws text with an auto-sized rounded box background
-- @param text string Text to render
-- @param font string Font name (lyx font ID)
-- @param x number X position
-- @param y number Y position
-- @param xAlign number Text alignment (TEXT_ALIGN_LEFT/CENTER/RIGHT)
-- @param textCol Color Text color
-- @param boxRounding number Corner radius for the background box
-- @param boxPadding number Padding between text and box edge
-- @param boxCol Color Background box color
function LYXUI.DrawRoundedTextBox(text, font, x, y, xAlign, textCol, boxRounding, boxPadding, boxCol)
    local boxW, boxH = lyx.GetTextSize(text, font)

    local dblPadding = boxPadding * 2
    if xAlign == TEXT_ALIGN_CENTER then
        LYXUI.DrawRoundedBox(boxRounding, x - boxW / 2 - boxPadding, y - boxPadding, boxW + dblPadding, boxH + dblPadding, boxCol)
    elseif xAlign == TEXT_ALIGN_RIGHT then
        LYXUI.DrawRoundedBox(boxRounding, x - boxW - boxPadding, y - boxPadding, boxW + dblPadding, boxH + dblPadding, boxCol)
    else
        LYXUI.DrawRoundedBox(boxRounding, x - boxPadding, y - boxPadding, boxW + dblPadding, boxH + dblPadding, boxCol)
    end

    lyx.DrawText(text, font, x, y, textCol, xAlign)
end

--- Draws text centered inside a fixed-size rounded box
-- @param text string Text to render
-- @param font string Font name
-- @param x number Box X position
-- @param y number Box Y position
-- @param xAlign number Text alignment within box
-- @param textCol Color Text color
-- @param boxRounding number Corner radius
-- @param w number Box width
-- @param h number Box height
-- @param boxCol Color Box color
-- @param textPadding number Horizontal text padding (for left/right aligned text)
function LYXUI.DrawFixedRoundedTextBox(text, font, x, y, xAlign, textCol, boxRounding, w, h, boxCol, textPadding)
    LYXUI.DrawRoundedBox(boxRounding, x, y, w, h, boxCol)

    if xAlign == TEXT_ALIGN_CENTER then
        lyx.DrawSimpleText(text, font, x + w / 2, y + h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    if xAlign == TEXT_ALIGN_RIGHT then
        lyx.DrawSimpleText(text, font, x + w - textPadding, y + h / 2, textCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        return
    end

    lyx.DrawSimpleText(text, font, x + textPadding, y + h / 2, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

local blurPassesCvar = CreateClientConVar("lyxui_blur_passes", "4", true, false, "Amount of passes to draw blur with. 0 to disable blur entirely.", 0, 15)
local blurPassesNum = blurPassesCvar:GetInt()

cvars.AddChangeCallback("lyxui_blur_passes", function(_, _, passes)
    blurPassesNum = math.floor(tonumber(passes) + 0.05)
end)

local blurMat = Material("pp/blurscreen")
local scrW, scrH = ScrW, ScrH

--- Draws a blurred background effect for a panel region
-- @param panel Panel The panel to blur behind
-- @param localX number Local X offset within the panel
-- @param localY number Local Y offset within the panel
-- @param w number Width of the blur region
-- @param h number Height of the blur region
function LYXUI.DrawBlur(panel, localX, localY, w, h)
    if blurPassesNum == 0 then return end
    local x, y = panel:LocalToScreen(localX, localY)
    local scrw, scrh = scrW(), scrH()

    surface.SetMaterial(blurMat)
    surface.SetDrawColor(255, 255, 255)

    for i = 0, blurPassesNum do
        blurMat:SetFloat("$blur", i * .33)
        blurMat:Recompute()
    end
    render.UpdateScreenEffectTexture()
    surface.DrawTexturedRect(x * -1, y * -1, scrw, scrh)
end
