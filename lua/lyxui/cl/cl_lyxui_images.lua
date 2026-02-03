--[[
	LYXUI Core Image System
	Ported from PIXEL UI.

	Provides URL-based image downloading, caching, and material creation.
	Images are fetched via HTTP, saved to the data folder, and served as
	Source Engine materials. Includes a download queue to prevent flooding.

	Key functions:
	  LYXUI.GetImage(url, callback, matSettings) - Fetches/caches an image by URL
	  LYXUI.GetImgur(id, callback, _, matSettings) - Shorthand for Imgur images
]]

local materials = {}
local queue = {}

local useProxy = false

file.CreateDir(LYXUI.DownloadPath)

--- Checks whether a URL/path ends with a file extension
-- @param str string The URL or file path to check
-- @return boolean True if the string ends with a file extension
local function endsWithExtension(str)
    local fileName = str:match(".+/(.-)$")
    if not fileName then
        return false
    end
    local extractedExtension = fileName and fileName:match("^.+(%..+)$")

    return extractedExtension and string.sub(str, -#extractedExtension) == extractedExtension or false
end

--- Processes the next item in the download queue sequentially
local function processQueue()
    if queue[1] then
        local url, filePath, matSettings, callback = unpack(queue[1])

        http.Fetch((useProxy and ("https://proxy.duckduckgo.com/iu/?u=" .. url)) or url,
            function(body, len, headers, code)
                if len > 2097152 or code ~= 200 then
                    materials[filePath] = Material("nil")
                else
                    local writeFilePath = filePath
                    if not endsWithExtension(filePath) then
                        writeFilePath = filePath .. ".png"
                    end

                    file.Write(writeFilePath, body)
                    materials[filePath] = Material("../data/" .. writeFilePath, matSettings or "noclamp smooth mips")
                end

                callback(materials[filePath])
            end,
            function(error)
                if useProxy then
                    materials[filePath] = Material("nil")
                    callback(materials[filePath])
                else
                    useProxy = true
                    processQueue()
                end
            end
        )
    end
end

--- Fetches an image from a URL and provides it as a material via callback.
-- If the image is already cached in memory or on disk, it returns immediately.
-- Otherwise it queues a download and calls back when ready.
-- @param url string The full URL of the image to fetch
-- @param callback function Called with the Material when ready: callback(mat)
-- @param matSettings string Optional material flags (default "noclamp smooth mips")
function LYXUI.GetImage(url, callback, matSettings)
    local protocol = url:match("^([%a]+://)")

    local hasTrailingSlash = url:sub(-1) == "/"
    local urlWithoutTrailingSlash = url
    if hasTrailingSlash then
        urlWithoutTrailingSlash = url:sub(1, -2)
    end

    local fileNameStart = urlWithoutTrailingSlash:find("[^/]+$")
    if not fileNameStart then
        return
    end

    local urlWithoutProtocol = url
    if not protocol then
        protocol = "http://"
    else
        urlWithoutProtocol = string.gsub(urlWithoutTrailingSlash, protocol, "")
    end

    local urlWithoutFileName = urlWithoutTrailingSlash:sub(protocol:len() + 1, fileNameStart - 1)

    local dirPath = LYXUI.DownloadPath .. urlWithoutFileName
    local filePath = LYXUI.DownloadPath .. urlWithoutProtocol

    file.CreateDir(dirPath)

    local readFilePath = filePath
    if not endsWithExtension(filePath) and file.Exists(filePath .. ".png", "DATA") then
        readFilePath = filePath .. ".png"
    end

    if materials[filePath] then
        callback(materials[filePath])
    elseif file.Exists(readFilePath, "DATA") then
        materials[filePath] = Material("../data/" .. readFilePath, matSettings or "noclamp smooth mips")
        callback(materials[filePath])
    else
        table.insert(queue, {
            url,
            filePath,
            matSettings,
            function(mat)
                callback(mat)
                table.remove(queue, 1)
                processQueue()
            end
        })

        if #queue == 1 then
            processQueue()
        end
    end
end

--- Shorthand for fetching Imgur images by ID
-- @param id string The Imgur image ID (e.g. "abcdefg")
-- @param callback function Called with the Material when ready
-- @param _ any Unused (legacy compatibility)
-- @param matSettings string Optional material flags
function LYXUI.GetImgur(id, callback, _, matSettings)
    local url = "https://i.imgur.com/" .. id .. ".png"
    LYXUI.GetImage(url, callback, matSettings)
end
