--[[
	LYXUI Image Drawing
	Ported from PIXEL UI.

	Provides high-level image drawing functions that integrate with
	the LYXUI.GetImage() caching system. Shows a progress spinner
	while images are being downloaded.

	Functions:
	  LYXUI.DrawProgressWheel(x, y, w, h, col) - Animated loading spinner
	  LYXUI.DrawImage(x, y, w, h, url, col) - Draws a URL-sourced image
	  LYXUI.DrawImageRotated(x, y, w, h, rot, url, col) - Draws a rotated URL image
	  LYXUI.DrawImgur(x, y, w, h, imgurId, col) - Draws an Imgur image by ID
	  LYXUI.DrawImgurRotated(x, y, w, h, rot, imgurId, col) - Draws a rotated Imgur image
]]

local progressMat

local drawProgressWheel
local setMaterial = surface.SetMaterial
local setDrawColor = surface.SetDrawColor

do
    local min = math.min
    local curTime = CurTime
    local drawTexturedRectRotated = surface.DrawTexturedRectRotated

    --- Draws an animated rotating progress/loading spinner
    -- @param x number X position
    -- @param y number Y position
    -- @param w number Width
    -- @param h number Height
    -- @param col Color Spinner color
    function LYXUI.DrawProgressWheel(x, y, w, h, col)
        local progSize = min(w, h)
        setMaterial(progressMat)
        setDrawColor(col.r, col.g, col.b, col.a)
        drawTexturedRectRotated(x + w * .5, y + h * .5, progSize, progSize, -curTime() * 100)
    end
    drawProgressWheel = LYXUI.DrawProgressWheel
end

local materials = {}
local grabbingMaterials = {}

local getImage = LYXUI.GetImage
getImage(LYXUI.ProgressImageURL, function(mat)
    progressMat = mat
end)

local drawTexturedRect = surface.DrawTexturedRect

--- Draws an image from a URL. Shows a progress spinner while loading.
-- @param x number X position
-- @param y number Y position
-- @param w number Width
-- @param h number Height
-- @param url string Image URL
-- @param col Color Tint/draw color
function LYXUI.DrawImage(x, y, w, h, url, col)
    if not materials[url] then
        drawProgressWheel(x, y, w, h, col)

        if grabbingMaterials[url] then return end
        grabbingMaterials[url] = true

        getImage(url, function(mat)
            materials[url] = mat
            grabbingMaterials[url] = nil
        end)

        return
    end

    setMaterial(materials[url])
    setDrawColor(col.r, col.g, col.b, col.a)
    drawTexturedRect(x, y, w, h)
end

local drawTexturedRectRotated = surface.DrawTexturedRectRotated

--- Draws a rotated image from a URL. Shows a progress spinner while loading.
-- @param x number Center X position
-- @param y number Center Y position
-- @param w number Width
-- @param h number Height
-- @param rot number Rotation angle in degrees
-- @param url string Image URL
-- @param col Color Tint/draw color
function LYXUI.DrawImageRotated(x, y, w, h, rot, url, col)
    if not materials[url] then
        drawProgressWheel(x - w * .5, y - h * .5, w, h, col)

        if grabbingMaterials[url] then return end
        grabbingMaterials[url] = true

        getImage(url, function(mat)
            materials[url] = mat
            grabbingMaterials[url] = nil
        end)

        return
    end

    setMaterial(materials[url])
    setDrawColor(col.r, col.g, col.b, col.a)
    drawTexturedRectRotated(x, y, w, h, rot)
end

--- Draws an Imgur image by its ID. Constructs the URL automatically.
-- @param x number X position
-- @param y number Y position
-- @param w number Width
-- @param h number Height
-- @param imgurId string Imgur image ID
-- @param col Color Tint color
function LYXUI.DrawImgur(x, y, w, h, imgurId, col)
    local url = "https://i.imgur.com/" .. imgurId .. ".png"
    LYXUI.DrawImage(x, y, w, h, url, col)
end

--- Draws a rotated Imgur image by its ID
-- @param x number Center X position
-- @param y number Center Y position
-- @param w number Width
-- @param h number Height
-- @param rot number Rotation angle
-- @param imgurId string Imgur image ID
-- @param col Color Tint color
function LYXUI.DrawImgurRotated(x, y, w, h, rot, imgurId, col)
    local url = "https://i.imgur.com/" .. imgurId .. ".png"
    LYXUI.DrawImageRotated(x, y, w, h, rot, url, col)
end
