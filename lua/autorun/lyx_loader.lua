lyx = {}

function lyx:Log(str)
    MsgC(Color(14, 255, 163), "[LYX] ", Color(255, 255, 255), str, "\n")
end

function lyx:TextPrint(str)
    local f = file.Read(str, "LUA")
    if f then
        local t = string.Explode("\n", f)
        for k, v in ipairs(t) do
            MsgC(Color(14, 255, 163), "[LYX] ", Color(255, 255, 255), v, "\n")
        end
    end
end

local function loadServerFile(str)
    if CLIENT then return end
    include(str)
    lyx:Log("Loaded server file: " .. str)
end

local function loadClientFile(str)
    if SERVER then AddCSLuaFile(str) return end
    include(str)
    lyx:Log("Loaded client file: " .. str)
end

local function loadSharedFile(str)
    if SERVER then AddCSLuaFile(str) end
    include(str)
    lyx:Log("Loaded shared file: " .. str)
end

local function makeClientUsable(str)
    if CLIENT then return end
    AddCSLuaFile(str)
    lyx:Log("Made client usable: " .. str)
end


local function load()
    lyx:TextPrint("lyx/extra/logo.txt")

    local clientFiles = file.Find("lyx/cl/*.lua", "LUA")
    local sharedFiles = file.Find("lyx/sh/*.lua", "LUA")
    local serverFiles = file.Find("lyx/sv/*.lua", "LUA")
    local vguiFiles = file.Find("lyx/vgui/*.lua", "LUA")
    local thirdPartyFiles = file.Find("lyx/thirdparty/*.lua", "LUA")

    for _, fl in pairs(clientFiles) do
        loadClientFile("lyx/cl/" .. fl)
    end

    for _, fl in pairs(sharedFiles) do
        loadSharedFile("lyx/sh/" .. fl)
    end

    for _, fl in pairs(serverFiles) do
        loadServerFile("lyx/sv/" .. fl)
    end

    for _, fl in pairs(vguiFiles) do
        loadClientFile("lyx/vgui/" .. fl)
    end

    for _, fl in pairs(thirdPartyFiles) do
        makeClientUsable("lyx/thirdparty/" .. fl)
    end

    lyx:Log("Loaded " .. #clientFiles + #sharedFiles + #serverFiles .. " files.")
end

-- For all the cute niggas
load()