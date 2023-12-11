if SERVER then
    RunConsoleCommand("sv_hibernate_think", "1")
end

lyx = lyx or {}
lyx.UI = lyx.UI or {}
lyx.UI.Overrides = lyx.UI.Overrides or {}

do
    local rawLog
    do
        local msgc = MsgC
        local infoColor = Color(17, 142, 17)
        local debugColor = Color(66, 66, 66)
        local warnColor = Color(187, 201, 24)
        local errorColor = Color(255, 0, 0)
        rawLog = function(sev, msg, realm)
            if not sev then msgc(infoColor, "[LYX][Info]", realm and ("[" .. realm .. "] " .. msg) or msg, "\n") return end
            if sev == 1 and isDebug then msgc(debugColor, "[LYX][Debug]", realm and ("[" .. realm .. "] " .. msg) or msg, "\n") return end
            if sev == 2 then msgc(warnColor, "[LYX][Warn]", realm and ("[" .. realm .. "] " .. msg) or msg, "\n") return end
            if sev == 3 then msgc(errorColor, "[LYX][Error]", realm and ("[" .. realm .. "] " .. msg) or msg, "\n") return end
        end
    end

    lyx.GetLogger = function(realm)
        return function(msg, sev) rawLog(sev, msg, realm) end
    end

    coreLog = lyx.GetLogger("Core")
    lyx.Debug = isDebug

    local function loadServerFile(str)
        if CLIENT then return end
        include(str)
    end
    
    local function loadClientFile(str)
        if SERVER then AddCSLuaFile(str) return end
        include(str)
        if DebugLoadedFile then print("Loaded: " .. str) end
    end
    
    local function loadSharedFile(str)
        if SERVER then AddCSLuaFile(str) end
        include(str)
    end

    lyx.LoadServerFile = loadServerFile
    lyx.LoadClientFile = loadClientFile
    lyx.LoadSharedFile = loadSharedFile

    local function loadDirectory(path)
        local files, folders = file.Find(path .. "/*", "LUA")

        for _, fileName in ipairs(files) do
            local filePath = path .. "/" .. fileName
            if fileName:StartWith("cl_") then
                loadClientFile(filePath)
            elseif fileName:StartWith("sv_") then
                loadServerFile(filePath)
            elseif fileName:StartWith("sh_") then
                    loadSharedFile(filePath)
            elseif fileName:StartWith("vgui_") then
                loadClientFile(filePath)
            else
                print("LYX: Unknown file type: " .. fileName)
            end
        end

        return files, folders
    end

    local loadDirectoryRecursive
    loadDirectoryRecursive = function(basePath)
        local _, folders = loadDirectory(basePath)

        for _, folderName in ipairs(folders) do
            loadDirectoryRecursive(basePath .. "/" .. folderName)
        end
    end

    lyx.LoadDirectory = loadDirectory
    lyx.LoadDirectoryRecursive = loadDirectoryRecursive
end

local folderOrder = {"thirdparty", "sh", "sv", "cl", "vgui"}

-- Load the specified folders in the specified order
for _, folderName in ipairs(folderOrder) do
    lyx.LoadDirectoryRecursive("lyx_core/" .. folderName)
end

lyx.Loaded = true
hook.Run("lyx.Loaded")

do // fix scripts that load after lyx
    local original = hook.Add
    hook.Add = function(event, ident, fn)
    if event ~= "lyx.Loaded" then return original(event, ident, fn) end
    fn()
    end
end

lyx.Logger:Log("LYX loaded!")