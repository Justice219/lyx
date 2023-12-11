lyx = lyx

net.Receive("lyx:message", function(len, ply)
    local data = net.ReadTable()

    if data["type"] == "header" then
        chat.AddText(data["color1"], "[", data["header"], "] ", data["color2"], data["text"])
    elseif data["type"] == "single" then
        chat.AddText(data["color"], data["text"])
    end
end)