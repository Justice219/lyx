do
    if CLIENT then
        function lyx.ChatText(label, color, text)
            if (!text or !label or !color) then return end
            chat.AddText(color_white, "(", color, label, color_white, ") ", text)
        end
    end

    function lyx.CreateAddon(name, color, loadOrder)
        loadOrder = loadOrder or {"sv", "sh", "cl", "vgui"}
        _G[name] = _G[name] or {}
        _G[name].Logger = lyx.CreateLogger(name, color)

        local hexColor = lyx.ColorToHex(color)

        local addonTbl = _G[name]
        local netMsh = name .. ".Say"

        if SERVER then
            lyx.Addons = lyx.Addons or {}
            lyx.Addons[name] = {
                name = name,
                color = color,
                hexColor = hexColor,
            }

            lyx.Logger:Log("added " .. name .. " to lyx.Addons")

            util.AddNetworkString(netMsh)
            function addonTbl:Say(ply, message)
                net.Start(netMsh)
                    net.WriteString(message)
                if (ply) then
                    net.Send(ply)
                else
                    net.Broadcast()
                end
            end
        else
            function addonTbl:Say(message)
                if (!message) then return end
                lyx.ChatText(name, color, message)
            end

            net.Receive(netMsh, function()
                local message = net.ReadString()
                addonTbl:Say(message)
            end)
        end

        -- make sure loadOrder is a table
        if !loadOrder[1] then return end
        local function load()
            for _, folderName in ipairs(loadOrder) do
                lyx.LoadDirectoryRecursive(string.lower(name) .. "/" .. folderName)
            end
        end

        -- pcall
        local success, err = pcall(load)
        if !success then
            lyx.Logger:Log("Failed to load " .. name .. ": " .. err)
            return
        else
            lyx.Logger:Log("Loaded " .. name)
        end
        addonTbl.Logger:Log("Loaded.") 
    end
end
