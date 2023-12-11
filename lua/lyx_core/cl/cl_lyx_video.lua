-- Use LYX Library
lyx = lyx

-- Variables
local medialib = include("lyx_core/thirdparty/sh_lyx_medialib.lua")
lyx.vid = nil
lyx.mediaClip = nil
medialib.YOUTUBE_API_KEY = "AIzaSyA4cNyvN4R4DmDSCmEStl9lf_vvzsNfX_s"

-- Video playing library
function lyx:VideoCreate(url, tbl)
    if IsValid(CLIP) then CLIP:stop() end

    lyx.Logger:Log("Creating video..." .. url)
    local service = medialib.load("media").guessService(url)
    lyx.mediaClip = service:load(url)
    CLIP = mediaclip

    lyx.mediaClip:play()
    lyx:VideoDraw(lyx.mediaClip, service, tbl)
end

function lyx:VideoDraw(mediaclip, service, tbl)
    lyx.vid = lyx:HookStart("HUDPaint", function()
        local w = ScrW() * tbl.width/1920
        local h = ScrH() * tbl.height/1080
    
        mediaclip:draw(0, 0, w, h)
    
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(0, h, w, 25)
    
        -- Request metadata. 'meta' will be nil if metadata is still being fetched.
        -- Note: this is a clientside shortcut to Service#query. You should use Service#query on serverside.
        local meta = mediaclip:lookupMetadata()
    
        local title, duration = tostring(meta and meta.title),
                                (meta and meta.duration) or 0
    
        draw.SimpleText(title, "DermaDefaultBold", 5, h+3, Color(0, 0, 0))
    
        local timeStr = string.format("%.1f / %.1f", mediaclip:getTime(), duration)
        draw.SimpleText(timeStr, "DermaDefaultBold", w - 5, h+3, Color(0, 0, 0), TEXT_ALIGN_RIGHT)
    end)
end

function lyx:VideoCheck(enable, url, tbl)
    if enable then
        if lyx.vid then
            lyx:HookRemove("HUDPaint", lyx.vid)
            lyx.mediaClip:stop()
            lyx.mediaClip = nil
            lyx.vid = nil
            lyx.Logger:Log("Video stopped")
        end

        lyx:VideoCreate(url, tbl)
        lyx.Logger:Log("Video created")
    else
        if lyx.vid then
            lyx:HookRemove("HUDPaint", lyx.vid)
            lyx.mediaClip:stop()
            lyx.mediaClip = nil
            lyx.vid = nil
            lyx.Logger:Log("Video stopped")
        else
            lyx.Logger:Log("Video is not playing.")
        end
    end
end

-- Net Recieves
net.Receive("lyx_video_start", function(len, ply)
    lyx.Logger:Log("Video Queueing")
    lyx:VideoCheck(true, net.ReadString(), {
        width = net.ReadInt(32),
        height = net.ReadInt(32)
    })
end)

net.Receive("lyx_video_stop", function(len, ply)
    lyx:VideoCheck(false)
end)