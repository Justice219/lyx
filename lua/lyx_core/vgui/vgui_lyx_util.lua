lyx.Materials1 = {
    ["Cross"] = Material("lyx/white/cross.png"),
    ["Player"] = Material("lyx/white/player.png"),
    ["Server"] = Material("lyx/white/server.png"),
    ["World"] = Material("lyx/white/world.png"),
    ["Settings"] = Material("lyx/white/settings.png"),
    ["Stats"] = Material("lyx/white/stats.png"),
    ["Info"] = Material("lyx/white/info.png"),
    ["Buy"] = Material("lyx/white/buy.png"),
    ["Sell"] = Material("lyx/white/sell.png"),
}
lyx.Icons1 = {
    ["Cross"] = "lyx/white/cross.png",
    ["Player"] = "lyx/white/player.png",
    ["Server"] = "lyx/white/server.png",
    ["World"] = "lyx/white/world.png",
    ["Settings"] = "lyx/white/settings.png",
    ["Stats"] = "lyx/white/stats.png",
    ["Info"] = "lyx/white/info.png",
    ["Sell"] = "lyx/white/sell.png",
    ["Buy"] = "lyx/white/buy.png",
}
lyx.Colors1 = {
    ["Primary"] = Color(41,41,41),
    ["Secondary"] = Color(51,51,51),
    ["Topbar"] = Color(58,58,58),
    ["White"] = Color(255,255,255),   
    ["Green"] = Color(83,241,117),
    ["Selected"] = Color(194,194,194),
}
lyx.Scaling1 = {
    ScaleW = function(size)
        return size * ScrH() / 1920
    end,
    ScaleH = function(size)
        return size * ScrW() / 1080
    end,
}

-- FONT N SHIT
surface.CreateFont("lyx.font.primary", {
    font = "Roboto",
    size = lyx.Scaling1.ScaleH(20),
    weight = 500,
    antialias = true,
    shadow = false,
    outline = false,
})
surface.CreateFont("lyx.font.secondary", {
    font = "Roboto",
    size = lyx.Scaling1.ScaleH(15),
    weight = 500,
    antialias = true,
    shadow = false,
    outline = false,
})
surface.CreateFont("lyx.font.button", {
    font = "Roboto",
    size = lyx.Scaling1.ScaleH(12.5),
    weight = 500,
    antialias = true,
    shadow = false,
    outline = false,
})
surface.CreateFont("lyx.font.title", {
    font = "Roboto",
    size = lyx.Scaling1.ScaleH(15),
    weight = 500,
    antialias = true,
    shadow = false,
    outline = false,
})
surface.CreateFont("lyx.font.subtitle", {
    font = "Roboto",
    size = lyx.Scaling1.ScaleH(10),
    weight = 500,
    antialias = true,
    shadow = false,
    outline = false,
})