--[[
	LYXUI Imgur Button Element
	Ported from PIXEL UI. Image button with Imgur ID shorthand support.
]]

local PANEL = {}

AccessorFunc(PANEL, "ImgurID", "ImgurID", FORCE_STRING)
AccessorFunc(PANEL, "ImgurSize", "ImgurSize", FORCE_NUMBER)

function PANEL:SetImgurID(id)
    self.ImgurID = id
    self:SetImageURL("https://i.imgur.com/" .. id .. ".png")
end

function PANEL:GetImgurID()
    return (self:GetImageURL() or ""):match("https://i.imgur.com/(.*).png")
end

function PANEL:SetImgurSize(size)
    self.ImgurSize = size
    self:SetImageSize(size, size)
end

function PANEL:GetImgurSize()
    return self:GetImageSize()
end

function PANEL:Init()
end

vgui.Register("LYXUI.ImgurButton", PANEL, "LYXUI.ImageButton")
